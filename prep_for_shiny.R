library(tidyverse)
library(rgdal)
library(rgeos)
library(sf)


nutbal %>%  filter(GCAM_commodity %in% allcrops,year %in% modelfuture) %>%
  group_by(scenario,region,year) %>%
  summarize(Psur=sum(Psur,na.rm=T),Nsur=sum(Nsur,na.rm=T)) %>%
  ungroup() %>%
  pivot_longer(-c(scenario,region,year),names_to='variable') %>%
  mutate(Unit="kg/ha")-> NPsur


forest_change %>% select(scenario,region,year,forest_change,forest_frac) %>%
  pivot_longer(-c(scenario,region,year),names_to='variable') %>%
  mutate(Unit='thous km2')->forest_plot

tot_gross %>% pivot_longer(-c(scenario,region,year,Unit),names_to='variable') %>%
  select(scenario,region,year,variable,value,Unit)->grosscrops

region_vals<-NPsur %>% bind_rows(forest_plot) %>% bind_rows(grosscrops) %>%
  left_join(GCAMreg, by = "region")

regions<-st_read('~/Dropbox/JGCRI/Geospatial/GCAM 32 (with Taiwan)/regions_plot.shp')

GCAMreg %>% rename("GCAM_30_re"=GCAM_region_ID) %>%
  left_join(region_vals) %>% as.data.frame()->regions_data


regions_shape<-merge(regions,regions_data)
st_write(regions_shape,"./outdata/regions_shape.shp")





basins<-st_read('~/Dropbox/JGCRI/Geospatial/BasinMap/basins_simpl.shp')

irr_sust %>% left_join(GCAMreg,by = "region") %>%
  select(scenario,GCAM_basin_ID,year,irr_total,sust_avail,frac,Units)%>%
  rename(Unit=Units) %>%
  pivot_longer(-c(scenario,GCAM_basin_ID,year,Unit),names_to='variable') %>%
  rename(GLU=GCAM_basin_ID)->watbal

basins_shape<-merge(basins,watbal)
st_write(basins_shape,"./outdata/basins_shape.shp")
