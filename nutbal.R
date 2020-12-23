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
  left_join(nfix, by = c("GCAM_commodity", "GCAM_region_ID"))%>%
  left_join(metaregions, by = "region")  ->nutio

nutio %>%
  mutate(Nin=Nfixkg.yld*prodMt+NfertMt,
         Nout=prodMt*contentN,
         Pin=PfertMt,
         Pout=prodMt*contentP) %>%
  select(scenario,metaregion,mr2,region,GCAM_commodity,year,prodMt,Nin,Nout,Pin,Pout) %>%
  mutate(Nsur=Nin-Nout, Psur=Pin-Pout) ->nutbal

exregions=c('Africa_Eastern','EU-15','China','USA','India','Brazil')
excrops=c('Corn','Wheat','Soybean','Rice','NutsSeeds','SugarCrop','Vegetables')
exyears=2010:2050

ggplot(nutbal %>% filter(region %in% exregions, GCAM_commodity %in% excrops, year %in% exyears))+
  geom_point(aes(x=year,y=prodMt,color=scenario))+facet_grid(GCAM_commodity~region, scales="free_y")

ggplot(nutbal %>% filter(region %in% exregions,year %in% exyears,GCAM_commodity %in% excrops))+
  geom_point(aes(x=year,y=prodMt,color=scenario))+facet_grid(region~GCAM_commodity, scales="free")


nutbal %>%
  group_by(scenario, GCAM_commodity, year, metaregion) %>%
  summarize(Nin=sum(Nin,na.rm=T),Nout=sum(Nout,na.rm=T),
            Pin=sum(Pin,na.rm=T),Pout=sum(Pout,na.rm=T),
            prodMt=sum(prodMt, na.rm=T)) %>%
  mutate(Nsur=Nin-Nout, Psur=Pin-Pout) ->nutbal_mr


ggplot(nutbal_mr%>%
         filter(GCAM_commodity%in%allcrops))+
  geom_point(aes(x=year,y=prodMt,color=scenario))+facet_grid(GCAM_commodity~metaregion, scales="free_y")

nutbal %>%
  group_by(scenario,GCAM_commodity,year) %>%
  summarize(Nin=sum(Nin,na.rm=T),Nout=sum(Nout,na.rm=T),
            Pin=sum(Pin,na.rm=T),Pout=sum(Pout,na.rm=T),
            prodMt=sum(prodMt, na.rm=T)) %>%
  mutate(Nsur=Nin-Nout, Psur=Pin-Pout) %>%
  filter(year%in%2000:2050)->nutbal_world




ggplot(nutbal_world)+
  geom_point(aes(x=year,y=Nsur/prodMt,color=scenario))+facet_wrap(~GCAM_commodity, scales="free")

nutbal %>%
  group_by(scenario,region,year) %>%
  summarize(Nin=sum(Nin,na.rm=T),Nout=sum(Nout,na.rm=T),
            Pin=sum(Pin,na.rm=T),Pout=sum(Pout,na.rm=T),
            prodMt=sum(prodMt, na.rm=T)) %>%
  mutate(Nsur=Nin-Nout, Psur=Pin-Pout) %>%
  filter(year%in%2000:2050)->nutbal_regions

ggplot(nutbal_regions)+
  geom_point(aes(x=year,y=Psur,color=scenario))+facet_wrap(~region, scales="free")
