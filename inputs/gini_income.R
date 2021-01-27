histginis<-read_csv('./inputs/gini_income1q.csv')
gdpdata<-read_csv('./inputs/gdp_2010.csv')

gdpdata %>%
  filter(`Series Name`=="GDP (constant 2010 US$)") %>%
  select(-c(`Series Name`,`Series Code`)) %>%
  pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='gdp') %>%
  rename("country"=`Country Name`, "iso" = `Country Code`)%>%
  mutate(year=as.numeric(substr(year,1,4)),gdp=as.numeric(gdp),iso=tolower(iso))%>%
  filter(year %in% 2010:2020) %>%
  select(-country) %>%
  group_by(iso) %>%
  summarize(gdp=mean(gdp,na.rm=T)) %>%
  ungroup() %>%
  left_join(iso_reg,by = "iso") %>%
  select(-region_GCAM3)->gdp


histginis %>%
  filter(`Series Name`=="Gini index (World Bank estimate)") %>%
  select(-c(`Series Name`,`Series Code`)) %>%
  pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='gini') %>%
  rename("country"=`Country Name`, "iso" = `Country Code`)%>%
  mutate(year=as.numeric(substr(year,1,4)),gini=as.numeric(gini))%>%
  filter(year %in% 2010:2020) %>%
  group_by(country,iso) %>%
  summarize(gini=mean(gini,na.rm=T)) %>%
  ungroup()->gini


  histginis %>%
    filter(`Series Name`=="Income share held by lowest 20%") %>%
    select(-c(`Series Name`,`Series Code`)) %>%
    pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='share1q') %>%
    rename("country"=`Country Name`, "iso" = `Country Code`)%>%
    mutate(year=as.numeric(substr(year,1,4)),share1q=as.numeric(share1q))  %>%
    filter(year %in% 2010:2020) %>%
    group_by(country,iso) %>%
    summarize(share1q=mean(share1q,na.rm=T)) %>%
    ungroup()->share1q

share1q %>%
  full_join(gini, by = c("country", "iso")) %>%
  mutate(iso=tolower(iso)) %>%
  select(-country) %>%
  left_join(iso_reg)%>%
  mutate(iso=recode(iso,"rou"="rom")) %>%
  drop_na(GCAM_region_ID) %>%
  filter(!is.na(gini))%>%
  select(-region_GCAM3)->income_dist

gdp %>%
  group_by(GCAM_region_ID) %>%
  summarize(gdp=sum(gdp,na.rm=T)) %>%
  rename(region_gdp=gdp) %>%
  left_join(income_dist, by = "GCAM_region_ID") %>%
  left_join(gdp,by=c('iso','country','GCAM_region_ID'))%>%
  mutate(weight=gdp/region_gdp)->gdp_wts

gdp_wts %>%
  group_by(GCAM_region_ID) %>%
  summarize( wtgini=weighted.mean(gini,weight,na.rm=T),
             wtshare=weighted.mean(share1q,weight,na.rm=T))->region_gini

income_lm<-lm(formula=wtshare~wtgini,data=region_gini)

##predictions

gini<-read_csv('inputs/NRao_Gini_projections_SSPs.csv')
gini %>%
  filter(scenario=="SSP2", year %in% modelfuture)%>%
  select(-scenario) %>%
  pivot_longer(-year,names_to="iso",values_to="gini")%>%
  mutate(iso=tolower(iso))->ctry_gini


gdp_wts %>% select(GCAM_region_ID,iso,weight) %>%
  left_join(ctry_gini, by = "iso") %>%
  group_by(GCAM_region_ID,year) %>%
  summarize(wtgini=weighted.mean(gini,weight))->region_gini


newiv<-data.frame(wtgini=region_gini$wtgini)


share1q_ssp<-predict(income_lm,newdata=newiv)

region_gini %>%
  bind_cols(share1q_pred=share1q_ssp)->region_share1q


# GDP conversions based on GINI
gdpGCAM<-getQuery(SAMout,"GDP MER by region") %>%
  mutate(gdp=gdp_deflator(2010,1990)*value*1e6)


gdpGCAM %>%
  left_join(GCAMreg,by = "region") %>%
  left_join(region_share1q,by = c("year", "GCAM_region_ID")) %>%
  select(scenario,region,GCAM_region_ID,year,gdp,share1q_pred) %>%
  filter(year %in% modelfuture) %>%
  mutate(gdp1q=gdp*share1q_pred/100) %>%
  left_join(popssp_region, by = c("GCAM_region_ID", "year")) %>%
  drop_na(poptot) %>%
  mutate(gdpcap1q=gdp1q/(poptot/5))->income_1q

income_1q %>% select(scenario,region,GCAM_region_ID,year,gdpcap1q) %>%
  write_csv('inputs/income_1q.csv')
