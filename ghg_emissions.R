# GHGs from ag
nonco2<-getQuery(SAMout,"nonCO2 emissions by sector") %>%
  filter(sector %in% c(allcrops,animals))

nonco2 %>%
  mutate(ghg_grouped=substr(ghg,1,3)) %>%
  group_by(scenario,region,ghg_grouped,year) %>%
  summarize(value=sum(value),Units=first(Units)) %>%
  ungroup()->nonco2_totals

gwp<-tibble(ghg_grouped=c('CO2','CH4','N20'),
            gwp=c(1,28,265))

nonco2_totals %>%
  filter(ghg_grouped %in% c('CH4','N2O','CO2')) %>%
  left_join(gwp, by="ghg_grouped")%>%
  mutate(ghg_gwp=value*gwp) %>%
  group_by(scenario,region,year) %>%
  summarize(nonco2=sum(ghg_gwp,na.rm=T)) %>%
  ungroup()->nonco2_eq

co2sector<-getQuery(SAMout,"CO2 emissions by sector (no bio)") %>%
  filter(sector %in% c(allcrops,animals))

co2sector %>%
  group_by(scenario,region, year) %>%
  summarize(value=sum(value),Units=first(Units))->co2_totals

co2_totals %>%
  left_join(nonco2_eq, by = c("scenario", "region", "year")) %>%
  mutate(value=sum(value,nonco2,na.rm=T)) %>%
  filter(year %in% modelfuture) %>%
  mutate(variable="Emissions (gwp)",Unit="MTCO2_eq") %>%
  select(scenario,region,year,variable,value,Unit)->ghg_totals
