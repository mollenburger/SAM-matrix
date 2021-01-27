# ag employment model

agemployment<-read_csv('./inputs/ag_employment_pct.csv')
popdata<-read_csv('./inputs/rural_pop.csv')
laborforce<-read_csv('./inputs/labor_pop.csv')

agemployment %>%
  select(-c(`Series Name`,`Series Code`)) %>%
  pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='agemploypct') %>%
  rename("country"=`Country Name`, "iso" = `Country Code`) %>%
  mutate(year=as.numeric(substr(year,1,4)),agemploypct=as.numeric(agemploypct))%>%
  filter(year %in% 2010:2020) %>%
  mutate(iso=recode(iso,"rou"="rom"))%>%
  group_by(country,iso) %>%
  summarize(agemploypct=mean(agemploypct, na.rm=T)) %>%
  ungroup()->agemploypct


popdata %>%
  filter(`Series Name`=="Rural population (% of total population)") %>%
  select(-c(`Series Name`,`Series Code`)) %>%
  pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='popruralpct') %>%
  rename("country"=`Country Name`, "iso" = `Country Code`) %>%
  mutate(year=as.numeric(substr(year,1,4)),popruralpct=as.numeric(popruralpct),
         iso=recode(iso,"rou"="rom"))%>%
  filter(year %in% 2010:2020) %>%
  group_by(country, iso) %>%
  summarize(popruralpct=mean(popruralpct, na.rm=T)) %>%
  ungroup() ->popruralpct



laborforce %>% filter(`Series Name`=="Population, total")%>%
  select(-c(`Series Name`,`Series Code`)) %>%
  pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='poptot') %>%
  rename("country"=`Country Name`, "iso" = `Country Code`) %>%
  mutate(year=as.numeric(substr(year,1,4)),poptot=as.numeric(poptot),iso=recode(iso,"rou"="rom")) %>%
  filter(year %in% 2010:2020)%>%
  group_by(country,iso) %>%
  summarize(poptot=mean(poptot, na.rm=T)) %>%
  ungroup() ->poptot



laborforce %>% filter(`Series Name`=="Labor force, total")  %>%
  select(-c(`Series Name`,`Series Code`)) %>%
  pivot_longer(-c(`Country Name`,`Country Code`),names_to='year',values_to='labtot') %>%
  rename("country"=`Country Name`, "iso" = `Country Code`) %>%
  mutate(year=as.numeric(substr(year,1,4)),labtot=as.numeric(labtot),iso=recode(iso,"rou"="rom")) %>%
  filter(year %in% 2010:2020) %>%
  drop_na(labtot) %>%
  group_by(country,iso) %>%
  summarize(labtot=mean(labtot, na.rm=T)) %>%
  ungroup() ->labtot


# # identify mismatches
#
# popruralpct %>%
#   mutate(iso=tolower(iso)) %>%
#   select(-country) %>%
#   full_join(iso_reg, by = "iso")->regempl
#
# regempl %>% filter(is.na(GCAM_region_ID)) %>%
#   select(iso) %>% unique()->iso_mismatch
#
# agemploypct %>% filter(iso %in% toupper(iso_mismatch$iso)) %>%
#   select(country,iso) %>% unique()->ctry_mismatch
#
# # mismatches are all regional groups in WB db (not countries) so
# # can be removed

popruralpct %>%
  left_join(agemploypct, by=c("country", "iso")) %>%
  left_join(poptot, by = c("country", "iso")) %>%
  left_join(labtot, by = c("country", "iso")) %>%
  mutate(iso=tolower(iso),iso=recode(iso,"rom"="rou")) %>%
  select(-country)%>%
  full_join(iso_reg,by='iso')%>%
  drop_na(country) %>%
  mutate(agemploypct=agemploypct/100,popruralpct=popruralpct/100) %>%
  mutate(ruralpoptot=popruralpct*poptot,agemploytot=agemploypct*labtot) ->
  agemploy_ctry

agemploy_ctry %>%
  group_by(GCAM_region_ID) %>%
  summarize(ruraltot=sum(ruralpoptot,na.rm=T),
            agemploytot=sum(agemploytot, na.rm=T),
            poptot=sum(poptot, na.rm=T)) %>%
  mutate(popruralpct=ruraltot/poptot,
         agemploypct=agemploytot/poptot) %>%
  ungroup() %>%
  drop_na(poptot)->agemploy_region

write_csv(agemploy_region,'./inputs/agemploy_region.csv')

write_csv(agemploy_ctry,'./inputs/agemploy_ctry.csv')


# SSP population projections (for rural population)
popsspurban<-read_csv('./inputs/SSP_db_population_urban.csv')
popssptotal<-read_csv('./inputs/SSP_db_population_total.csv')


popsspurban %>%
  select(-c(MODEL,SCENARIO,UNIT,VARIABLE)) %>%
  pivot_longer(-REGION,names_to="year",values_to="popurbanpct")%>%
  mutate(popruralpct=100-popurbanpct, year=as.numeric(year)) ->popruralssp


popssptotal %>%
  select(-c(MODEL,SCENARIO,UNIT,VARIABLE)) %>%
  pivot_longer(-REGION,names_to="year",values_to="poptotal") %>%
  mutate(year=as.numeric(year), poptotal=poptotal*1e6)->poptotalssp

poptotalssp %>% full_join(popruralssp,by=c('REGION','year'))%>%
  filter(!is.na(popurbanpct))%>%
  rename(iso=REGION) %>%
  mutate(iso=tolower(iso)) %>%
  full_join(iso_reg,by="iso") %>%
  mutate(ruralpoptot=poptotal*(popruralpct/100))->popssp_ctry

popssp_ctry %>%
  group_by(GCAM_region_ID,year) %>%
  summarize(poptot=sum(poptotal),ruralpoptot=sum(ruralpoptot))%>%
  mutate(popruralpct=ruralpoptot/poptot) %>%
  select(-ruralpoptot) %>%
  ungroup()-> popssp_region

write_csv(popssp_region,'./inputs/popssp_region.csv')


agemploy_lm<-lm(formula=agemploypct~popruralpct,data=agemploy_region)

##predictions

popssp_region %>%
  left_join(GCAMreg,by='GCAM_region_ID') %>%
  filter(year %in% 2010:2050)->mod_predictors


newiv<-data.frame(popruralpct=mod_predictors$popruralpct)

agemploy_ssp<-predict(agemploy_lm,newdata=newiv)


mod_predictors %>%
  select(region,year,GCAM_region_ID,poptot,popruralpct) %>%
  bind_cols('pctagemploy_pred'=agemploy_ssp) %>%
  mutate(pctagemploy_pred=if_else(pctagemploy_pred<0,0,pctagemploy_pred),
         totagemploy_pred=poptot*pctagemploy_pred) -> #17 cases of predictions slightly less than zero
  pop_agemploy_pred

write_csv(pop_agemploy_pred,'./inputs/pop_agemploy_pred')
