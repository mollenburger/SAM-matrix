library(rgcam)
library(tidyverse)

setwd('~/Dropbox/JGCRI/rgcam/GGCMI')

cropprod<-loadProject(proj='./results/agLU_compare.dat')

cropref<-loadProject(proj='./results/ref_crop.dat')

cpQ <- listQueries(cropprod)

#simulated
landsc=getQuery(cropprod,cpQ[5])
cprsc=getQuery(cropprod,cpQ[1])
yldsc=getQuery(cropprod,cpQ[3])
pricesc=getQuery(cropprod,cpQ[8])
consc=getQuery(cropprod,cpQ[11])


#reference
landsc_ref<-getQuery(cropref,cpQ[5], scenarios = 'GGCMI_PotYld') %>% mutate(scenario=recode(scenario,GGCMI_PotYld="Reference"))
cprsc_ref<-getQuery(cropref,cpQ[1], scenarios = "GGCMI_PotYld") %>% mutate(scenario=recode(scenario,GGCMI_PotYld="Reference"))
landscdet_ref=getQuery(cropref,cpQ[2], scenarios = "GGCMI_PotYld") %>% mutate(scenario=recode(scenario,GGCMI_PotYld="Reference"))
yld_ref=getQuery(cropref,cpQ[3], scenarios = "GGCMI_PotYld") %>% mutate(scenario=recode(scenario,GGCMI_PotYld="Reference"))
price_ref<-getQuery(cropref,cpQ[8], scenarios = "GGCMI_PotYld") %>% mutate(scenario=recode(scenario,GGCMI_PotYld="Reference"))
con_ref<-getQuery(cropref,cpQ[11], scenarios = "GGCMI_PotYld") %>% mutate(scenario=recode(scenario,GGCMI_PotYld="Reference"))


###FILTERS###
allcrops=c('Corn','FiberCrop','OilCrop','OtherGrain','PalmFruit','Rice','RootTuber','SugarCrop','Wheat','FruitVeg',
           'Pulses','CashCrop','FodderGrass','FodderHerb','biomass_grass','biomass_tree')
foodcrops=c('Corn','OilCrop','OtherGrain','PalmFruit','Rice','RootTuber','SugarCrop','Wheat','FruitVeg', 'Pulses')
maincrops<-c('Corn','OilCrop','OtherGrain','Rice','SugarCrop','Wheat')
excrops = c('Corn','OilCrop','Rice','Wheat')
metaregions<-tibble('region'=unique(landsc$region),'metaregion'='RestOfWorld')
metaregions$metaregion=c('Africa','Africa','Africa','Africa','South_Am','Asia','South_Am','North_Am','North_Am','Asia','Asia',
                         'South_Am','Europe','Europe','Europe','Europe','Europe','Asia','Asia','Asia','North_Am','Asia',
                         'Asia','Europe','Africa','South_Am','South_Am','Asia','Asia','Asia','North_Am')
uncropped<-c('Forest','Grassland','OtherArableLand','Pasture','ProtectedGrassland','ProtectedShrubland','ProtectedUnmanagedForest','ProtectedUnmanagedPasture','Shrubland','UnmanagedForest','UnmanagedPasture')
uncropped_join<-c('Forest','Grassland','OtherArableLand','Pasture','Grassland','OtherArableLand','Forest','Pasture','OtherArableLand','Forest','Pasture')
uc <- data.frame(uncropped, uncropped_join)
names(uc)<-c('crop','landtype')
uc$forest<-c('Forest','Other','Other','Other','Other','Other','Forest','Other','Other','Forest','Other')

excrops = c('Corn','OilCrop','Rice','Wheat')
biomass = c('biomass_grass','biomass_tree')
fodder=c('FodderHerb','FodderGrass')




mr2<-metaregions


attach(mr2)
mr2[region=="Central Asia",2]<-'CSAsia'
mr2[region=="China",2]<-'ESEAsia'
mr2[region=="India",2]<-'CSAsia'
mr2[region=="Indonesia",2]<-'ESEAsia'
mr2[region=="Japan",2]<-'ESEAsia'
mr2[region=="Middle East",2]<-'MENA'
mr2[region=="Africa_Northern",2]<-'MENA'
mr2[region=="Pakistan",2]<-'CSAsia'
mr2[region=="South Asia",2]<-'CSAsia'
mr2[region=="South Korea",2]<-'ESEAsia'
mr2[region=="Southeast Asia",2]<-'ESEAsia'
mr2[region=="Russia",2]<-'Europe'
detach(mr2)


