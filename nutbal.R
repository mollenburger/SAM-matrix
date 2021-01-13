###
# Read in external input data from N fertilizer database (Zhang et al. 2015)
###

# Nutrient (P and N) content of crops by GCAM region and commodity
nutcont<-read_csv("inputs/NutCont_region_commod.csv")
# N fixation (kgN per kg yield)
nfix<-read_csv("inputs/Nfix_commod_region.csv") %>% select(GCAM_commodity,GCAM_region_ID,Nfixkg.yld)

####
# Read in GCAM outputs from .dat file; process and combine for i/o relationships
###

Nfertcons<-getQuery(SAMout,"fertilizer consumption by crop type")
Pfertcons<-getQuery(SAMout,"P_fertilizer consumption by crop type")
cropprod<-getQuery(SAMout,"ag production by subsector (land use region)")

Nfertcons %>% select(scenario,region,sector,year,value) %>%
  rename("GCAM_commodity"=sector,"NfertMt"=value) ->Nfertcons

Pfertcons %>% select(scenario,region,sector,year,value) %>%
  rename("GCAM_commodity"=sector,"PfertMt"=value)->Pfertcons

# combine production, fertilizer consumption, and N content/fixation for nutrient i/o
cropprod %>%
  select(scenario,region,output,year,value) %>%
  rename("GCAM_commodity"=output, "ProdMt"=value)%>%
  left_join(Nfertcons, by = c("scenario", "region", "GCAM_commodity", "year")) %>%
  left_join(Pfertcons, by = c("scenario", "region", "GCAM_commodity", "year")) %>%
  left_join(GCAMreg, by = "region") %>%
  left_join(nutcont, by = c("GCAM_commodity", "GCAM_region_ID")) %>%
  left_join(nfix, by = c("GCAM_commodity", "GCAM_region_ID"))%>%
  left_join(metaregions, by = "region")  ->nutio

# calculate N and P surplus
nutio %>%
  mutate(Nin=Nfixkg.yld*ProdMt+NfertMt,
         Nout=ProdMt*contentN,
         Pin=PfertMt,
         Pout=ProdMt*contentP) %>%
  select(scenario,metaregion,mr2,region,GCAM_commodity,year,ProdMt,Nin,Nout,Pin,Pout) %>%
  mutate(Nsur=Nin-Nout, Psur=Pin-Pout) ->nutbal
