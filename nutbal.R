nutcont<-read_csv("inputs/NutCont_region_commod.csv")
nfix<-read_csv("inputs/Nfix_commod_region.csv") %>% select(GCAM_commodity,GCAM_region_ID,Nfixkg.yld)
GCAMreg<-read_csv(paste0(gcam_home,"input/gcamdata/inst/extdata/common/GCAM_region_names.csv"),skip=6)



Nfert %>% select(scenario,region,sector,year,NfertMt) %>%
  rename("GCAM_commodity"=sector) ->Nfertcons

Pfert %>% select(scenario,region,sector,year,PfertMt) %>%
  rename("GCAM_commodity"=sector)->Pfertcons

cropprod %>%
  select(scenario,region,output,year,prodMt) %>%
  rename("GCAM_commodity"=output) %>%
  left_join(Nfertcons, by = c("scenario", "region", "GCAM_commodity", "year")) %>%
  left_join(Pfertcons, by = c("scenario", "region", "GCAM_commodity", "year")) %>%
  left_join(GCAMreg, by = "region") %>%
  left_join(nutcont, by = c("GCAM_commodity", "GCAM_region_ID")) %>%
  left_join(nfix, by = c("GCAM_commodity", "GCAM_region_ID"))  ->nutio

nutio %>%
  mutate(Nin=Nfixkg.yld*prodMt+NfertMt,
         Nout=prodMt*contentN,
         Pin=PfertMt,
         Pout=prodMt*contentP) %>%
  select(scenario,region,GCAM_commodity,year,prodMt,Nin,Nout,Pin,Pout) %>%
  mutate(Nsur=Nin-Nout, Psur=Pin-Pout)->nutbal

exregions=c('Africa_Eastern','EU-15','China','USA','India','Brazil')
excrops=c('Corn','Wheat','Soybean','Rice')
exyears=2010:2050

ggplot(nutbal %>% filter(region %in% exregions, GCAM_commodity %in% excrops, year %in% exyears))+
  geom_point(aes(x=year,y=prodMt,color=scenario))+facet_grid(GCAM_commodity~region, scales="free_y")

ggplot(nutbal %>% filter(region %in% exregions, GCAM_commodity %in% excrops, year %in% exyears))+
  geom_point(aes(x=year,y=Nsur,color=scenario))+facet_grid(GCAM_commodity~region, scales="free_y")
