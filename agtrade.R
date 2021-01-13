GDPcap<-getQuery(SAMout,"GDP per capita PPP by region")



tradesect<-getQuery(SAMout,"outputs by subsector")
#exports from other regions are stored in USA as subsector "[region] traded [commodity]"
tradesect %>% filter(region=="USA")%>%
  separate(output,sep=" ",into=c("first","second")) %>%
  filter(first=="traded", second %in% tolower(allcrops)) %>%
  separate(subsector,sep = " ", into=c('region','tradeval','out')) %>%
  select(scenario,region,second,year,value) %>%
  rename("output"=second,"exported"=value)->exports_crops


tradesect %>%
  separate(output,sep=" ",into=c("first","second")) %>%
  filter(is.na(second))->nontrade

tradesect %>% filter(sector=="regional corn for ethanol" | sector == "biomass" )->bioenergy

tradesect %>%
  separate(output,sep=" ",into=c("first","second")) %>%
  filter(second %in% tolower(allcrops),second != "biomass")->crops
