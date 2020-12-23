library(R.matlab)
library(tidyverse)

flatten<-function(array3d){
  array_named<-array(array3d,dim=c(218,170,54),dimnames=list(country=countries$country,crop=tolower(crops$crop),year=1961:2014))
  array2d<-as.data.frame.table(array_named,responseName = "value")
  return(array2d)
}

GSlabels<-function(df){
  as.tibble(flatten(df)) %>%
    filter(!is.na(value)) %>%
    mutate(country=as.character(country), crop=as.character(crop),
           country=substr(country,2,nchar(country)-1),
           crop=substr(crop,2,nchar(crop)-1))%>%
    left_join(SAMcols,by='country') %>%
    left_join(FAOcrops %>% select(item, GCAM_commodity, crop), by='crop')->
    flat_tibble
  return(flat_tibble)}

crops<-read_csv("inputs/170Crops.csv",col_names=F)
names(crops)="crop"

countries<-read_csv("inputs/218Countries.csv",col_names=F)
names(countries)="country"

gcam_home='/Users/mollenburger/git/gcam-sam/'
FAOcrops<-read_csv(paste0(gcam_home,'input/gcamdata/inst/extdata/aglu/FAO/FAO_ag_items_PRODSTAT.csv'), skip=7) %>%
  mutate(crop=tolower(item))
iso_reg<-read_csv(paste0(gcam_home,"input/gcamdata/inst/extdata/common/iso_GCAM_regID.csv"),skip=6) %>%
  rename(country=country_name)
FAO_prod<-read_csv(paste0(gcam_home,'input/gcamdata/inst/extdata/aglu/FAO/FAO_ag_Prod_t_PRODSTAT.csv'),skip=5)
FAO_prod%>%
  pivot_longer(cols=`1961`:`2012`,names_to="year") %>%
  select(countries,item,year,value) %>%
  mutate(year=as.numeric(year)) %>%
  rename("country"=countries)->FAOprod


#read labeling data
sam1<-readMat("inputs/Country_SAM.mat")
FAOSTAT.CoABR.ISO<-unlist(sam1$FAOSTAT.CoABR.ISO)
FAOSTAT.CoName.FAO<-unlist(sam1$FAOSTAT.CoName.FAO)

SAMcols<-as_tibble(data.frame(FAOSTAT.CoABR.ISO,FAOSTAT.CoName.FAO))%>%
  mutate(FAOSTAT.CoName.FAO=as.character(FAOSTAT.CoName.FAO)) %>%
  rename("country"=FAOSTAT.CoName.FAO,"iso"=FAOSTAT.CoABR.ISO) %>%
  mutate(country=as.character(country),iso=tolower(as.character(iso)),
         iso=recode(iso,"rou"="rom"))
#several missing ISOs, the ones relevant to the current (post-2004) period are corrected based on iso_GCAM_regID
#SAMcols %>% filter(iso=="[]")
# 1 []    Belgium-Luxembourg
# 2 []    Czechoslovakia
# 3 []    Ethiopia PDR
# 4 []    Occupied Palestinian Territory
# 5 []    Pacific Islands Trust Territory -- same country name
# 6 []    Serbia and Montenegro           -- same country name
# 7 []    USSR                            -- code as Russia since it doesn't matter for current vals
# 8 []    Yugoslav SFR

SAMcols %>%
  mutate(country=recode(country,"Belgium-Luxembourg"="Belgium",
                        'Czechoslovakia'= 'Czech Republic',
                        'Ethiopia PDR'= 'Ethiopia',
                        'Occupied Palestinian Territory' = 'Palestinian Territory, Occupied',
                        'Yugoslav SFR' = 'Yugoslavia, Federal Republic of',
                        'USSR' = 'Russian Federation',
                        'Iran (Islamic Republic of)' = 'Iran, Islamic Republic of',
                        'Antigua and Barbuda'='Antigua & Barbuda' # match iso_reg
                        )) %>%
  select(-iso) %>%
  left_join(iso_reg,by='country') %>%
  select(iso,country,GCAM_region_ID)->  SAMcols_cor

#read from N database
data <- readMat("inputs/N database/dataN_partA1_Bou.mat", sparseMatrixClass="SparseM")
for(i in 1:length(names(data))) assign(names(data)[i], data[[i]]); rm(data)

#Nfer_kg<-GSlabels(Nfer.kg) %>% rename("Nferkg"=value)
Nfix<-GSlabels(Nfix.kg) %>% rename("Nfixkg"=value) %>%
  mutate(year=as.numeric(as.character(year)))


# N fixation varies with time; use last 20 years, merge with prod vals
FAOprod %>%
  filter(!is.na(value)) %>%
  left_join(Nfix,  by = c("country", "item", "year")) %>%
  filter(year>1994) %>%
  mutate(Nfixkg=replace_na(Nfixkg,0))->Nfix_kg

Nfix_kg %>%group_by(GCAM_region_ID,GCAM_commodity) %>%
  summarize(totval=sum(value,na.rm=T)) %>%
  ungroup() %>%
  right_join(Nfix_kg, by = c("GCAM_region_ID", "GCAM_commodity")) %>%
  mutate(weights=value/totval) -> Nfix_region_wts

Nfix_kg %>%group_by(GCAM_region_ID,iso,GCAM_commodity) %>%
  summarize(totval=sum(value,na.rm=T)) %>%
  ungroup() %>%
  right_join(Nfix_kg, by = c("GCAM_region_ID", "iso", "GCAM_commodity")) %>%
  mutate(weights=value/totval) %>%
  group_by(GCAM_commodity,GCAM_region_ID,iso) %>%
  summarize(Nfixkg=sum(Nfixkg*weights,na.rm=T),totval=sum(value,na.rm = T)) %>%
  mutate(Nfixkg.yld=Nfixkg/totval)->Nfix_commod_ctry

Nfix_kg %>%group_by(GCAM_region_ID,GCAM_commodity) %>%
  summarize(totval=sum(value,na.rm=T)) %>%
  ungroup() %>%
  right_join(Nfix_kg, by = c("GCAM_region_ID", "GCAM_commodity")) %>%
  mutate(weights=value/totval) %>%
  group_by(GCAM_commodity,GCAM_region_ID) %>%
  summarize(Nfixkg=sum(Nfixkg*weights,na.rm=T),totval=sum(value,na.rm = T)) %>%
  mutate(Nfixkg.yld=Nfixkg/totval)->Nfix_commod_region

data <- readMat("inputs/N database/projectIndexDefinitions.mat", sparseMatrixClass="SparseM")
#can't use above shortcut because dimensions/structure are different for different variables so:

contentNBou<-data$contentNBou
contentP<-data$contentP

content_N<-GSlabels(contentNBou) %>% rename("contentN"=value)
content_P<-GSlabels(contentP)%>% rename("contentP"=value)

#nutrient contents are constant through time
NutCont<-left_join(content_N,content_P, by = c("GCAM_region_ID","country","iso","crop", "year", "item", "GCAM_commodity")) %>%
  filter(year==2010) %>% select(GCAM_region_ID,country,iso,item,GCAM_commodity,contentN,contentP)

# N fixation varies with time; use last 10 year avg
FAOprod %>% filter(year>2004) %>%
  mutate(value=replace_na(value,0)) %>%
  group_by(country,item) %>%
  summarize(value=mean(value)) %>%
  ungroup() %>%
  left_join(NutCont, by = c("item","country")) %>%
  drop_na(iso)->NutCont_ctry

NutCont_ctry %>% group_by(GCAM_region_ID,GCAM_commodity) %>%
  summarise(totval=sum(value,na.rm=T)) %>%
  ungroup %>%
  right_join(NutCont_ctry, by = c("GCAM_region_ID", "GCAM_commodity")) %>%
  mutate(weights=value/totval) %>%
  group_by(GCAM_commodity,GCAM_region_ID) %>%
  summarize(contentN=sum(contentN*weights, na.rm=T),contentP=sum(contentN*weights,na.rm=T)) %>%
  ungroup()->NutCont_region_commod

NutCont_ctry %>% group_by(GCAM_region_ID,GCAM_commodity,iso) %>%
  summarise(totval=sum(value,na.rm=T)) %>%
  ungroup %>%
  right_join(NutCont_ctry, by = c("GCAM_region_ID", "GCAM_commodity", "iso")) %>%
  mutate(weights=value/totval) %>%
  group_by(GCAM_commodity,GCAM_region_ID,iso) %>%
  summarize(contentN=sum(contentN*weights, na.rm=T),contentP=sum(contentN*weights,na.rm=T)) %>%
  ungroup()->NutCont_ctry_commod


write_csv(NutCont_region_commod,"inputs/NutCont_region_commod.csv")
write_csv(NutCont_ctry_commod,"inputs/NutCont_ctry_commod.csv")

write_csv(Nfix_commod_region,"inputs/Nfix_commod_region.csv")
write_csv(Nfix_commod_ctry,"inputs/Nfix_commod_ctry.csv")

