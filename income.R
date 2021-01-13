commod_prices<-getQuery(SAMout,"ag commodity prices")

commod_prices %>%
  rename("price"=value) %>%
  left_join(cropprod, by = c("scenario", "region", "sector", "year")) %>%
  rename("prod"=value) %>%
  filter(sector %in% cropsnobio) %>%
  mutate(prodkg=prod * 10^9,
         price2010=price*gdp_deflator(2010,1975),
         grossval=prodkg*price2010)->prod_value

prod_value %>%
  select(scenario,region,sector,subsector,technology,year, grossval) %>%
  group_by(scenario,region,sector,year) %>%
  summarize(totgross=sum(grossval)/1e9) %>%
  mutate(Unit="billionUSD2010")->crops_gross

prod_value %>%
  select(scenario,region,sector,subsector,technology,year, grossval) %>%
  group_by(scenario,region,year) %>%
  summarize(totgross=sum(grossval)/1e9) %>%
  mutate(Unit="billionUSD2010")->tot_gross

GDPcap<-getQuery(SAMout,"GDP per capita PPP by region")






gini<-read_csv('inputs/NRao_Gini_projections_SSPs.csv')
gini %>%
  filter(scenario=="SSP2", year %in% modelfuture) %>%
  select(-scenario) %>%
  pivot_longer(-year,names_to="iso",values_to="gini") %>%
  mutate(iso=tolower(iso),gini=gini/100)->ctry_gini
