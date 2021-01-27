# value of agriculture products (incl. animal production and forestry)
cropprod<-getQuery(SAMout,"ag production by subsector (land use region)")
agprice<-getQuery(SAMout,"ag commodity prices" )
anprod<-getQuery(SAMout,"meat and dairy production by tech")
anprice<-getQuery(SAMout, "meat and dairy prices")

agprice %>% select(-Units) %>%
  rename("output"=sector, "price"=value) %>%
  left_join(cropprod %>% select(-Units), by=c("scenario", "region", "output", "year")) %>%
  rename("prod"=value) %>%
  group_by(scenario,region,output,year) %>%
  summarize(price=mean(price,na.rm=T),prod=sum(prod,na.rm=T)) %>%
  ungroup()->ag_commod

anprice %>% select(-Units) %>%
  rename("output"=sector, "price"=value) %>%
  left_join(anprod %>% select(-Units),
            by = c("scenario", "region", "output", "year")) %>%
  rename("prod"=value) %>%
  group_by(scenario,region,output,year) %>%
  summarize(price=mean(price,na.rm=T),prod=sum(prod,na.rm=T)) %>%
  ungroup()->an_commod

ag_commod %>% bind_rows(an_commod) %>%
  mutate(price2010=gdp_deflator(2010,1975)*price,
         value=price2010*prod*1e9) %>%
  filter(year%in%2010:2050)->ag_an_value

###
# traded fractions
###
tradesect<-getQuery(SAMout,"outputs by subsector")
#exports from other regions are stored in USA as subsector "[region] traded [commodity]"
tradesect %>% filter(region=="USA")%>%
  separate(output,sep=" ",into=c("first","second")) %>%
  filter(first=="traded", second %in% c(tolower(allcrops),tolower(animals))) %>%
  separate(subsector,sep = " ", into=c('region','tradeval','out')) %>%
  select(scenario,region,second,year,value) %>%
  rename("output"=second,"exported"=value)->exports_agan

tradesect %>%
  separate(output,sep=" ",into=c("first","second")) %>%
  filter(is.na(second), tolower(first) %in% c(tolower(allcrops),tolower(animals)))->nontrade



ag_an_value %>%
  left_join(exports_agan, by = c("scenario", "region", "output", "year")) %>%
  mutate(export_val=price2010*exported*1e9)->export_agan_vals

export_agan_vals %>%
  group_by(scenario,region,year) %>%
  summarize(singleval=sum(value),exportval=sum(export_val,na.rm=T)) %>%
  mutate(value=exportval/singleval) %>%
  mutate(variable="Export percent", Unit="%") %>%
  select(scenario,region,year,variable,value,Unit)->exportpct

####
# ag labor productivity
###

pop_agemploy_pred<-read_csv('./inputs/pop_agemploy_pred')
ag_an_value %>%
  group_by(scenario,region,year) %>%
  summarize(value=sum(value))->agval_region

agval_region %>%
  left_join(pop_agemploy_pred, by = c("region", "year")) %>%
  drop_na(GCAM_region_ID) %>%
  mutate(value=value/totagemploy_pred, variable="Ag Labor Productivity",
         Unit="$ per ag. worker") %>%
  select(scenario,region,year,variable,value,Unit)->AgLabProd

###
# food affordability
###
income1q<-read_csv('inputs/income_1q.csv')

staples<-c('Corn','Wheat','Rice','OtherGrain')

agprice %>% filter(sector %in% staples) %>%
  mutate(price=gdp_deflator(2010,1975)*value) %>%
  select(-value,-Units) %>%
  pivot_wider(names_from = sector, values_from=price) %>%
  filter(year %in% modelfuture) %>%
  rowwise() %>%
  mutate(meanprice=mean(Corn,Wheat,Rice,OtherGrain))->staples_price

staples_price %>%
  left_join(income1q, by = c("scenario", "region", "year")) %>%
  drop_na(gdpcap1q) %>%
  mutate(value=meanprice/gdpcap1q, variable="Food affordability",
         Unit="Staple price as fraction of income of lowest 20%") %>%
  select(scenario,region,year, variable, value, Unit)  ->food_afford


ag_an_value %>%
  filter(output!='biomass') %>%
  group_by(scenario,region,year) %>%
  summarize(totval=sum(value)) %>%
  ungroup() -> totvals

totvals %>%
  left_join(ag_an_value, by = c("scenario", "region", "year")) %>%
  select(scenario,region,year,output,value,totval) %>%
  mutate(propval=if_else(totval==0, 0, value/totval)) %>%
  mutate(logprop=log(propval),indexval=propval*logprop)->proportions

proportions %>%
  group_by(scenario,region,year) %>%
  summarize(Hindex=sum(indexval,na.rm=T)*(-1))->Hindex
