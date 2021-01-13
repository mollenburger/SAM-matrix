
irr_withdrawals<-getQuery(SAMout,"irrigation water withdrawals by crop type and land region")
sust_available<-getQuery(SAMout,"Basin level available runoff")

#basin names in outputs have errors, need to replace with correct names
basin_cor<-read_csv("inputs/basin_name_cor.csv")
sust_available %>%
  separate(basin, sep="_",into=c('Basin_name','thing')) %>%
  select(-thing) %>%
  mutate(Basin_name=str_replace_all(Basin_name, "[- ]", "_")) %>%
  left_join(basin_cor,by="Basin_name")  -> basins_witherrors

basins_witherrors %>%
  filter(!is.na(Basin_name_cor))%>%
  mutate(Basin_name=Basin_name_cor)->basins_corrected

basins_witherrors %>% filter(is.na(Basin_name_cor)) %>%
  bind_rows(basins_corrected) %>%
  select(-Basin_name_cor,-region) %>%
  left_join(basin_glu %>%
              select(GCAM_basin_ID,Basin_name,GLU_code,GLU_name),
            by='Basin_name') %>%
  rename("sust_avail"=value) %>%
  filter(year %in% modelfuture)->sust_basin

irr_withdrawals %>%
  select(-Units, -input) %>%
  separate(subsector,sep="_",into=c('output','GLU_name')) %>%
  rename("irr_withd"=value) %>%
  filter(year %in% modelfuture)-> irr_basin_crop

irr_basin_crop %>%
  group_by(scenario,region,GLU_name,year) %>%
  summarize(irr_total=sum(irr_withd,na.rm=T)) %>%
  ungroup()->irr_basin

irr_basin %>%
  left_join(sust_basin, by = c("scenario", "GLU_name", "year")) %>%
  mutate(frac=irr_total/sust_avail)->irr_sust
