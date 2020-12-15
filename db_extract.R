library(rgcam)
library(tidyverse)

setwd('~/Dropbox/JGCRI/rgcam/GGCMI')

# 
# Then to run the server they simply need to provide the path to where the databases are stored:
#   ```
# [pralitp@constance03 ~]$ ./basex-server-helper.sh scratch-home/run-irr-const/pbs/output
# DB Path: scratch-home/run-irr-const/pbs/output

# # Note you should use the exact PIC login node that is running the server
# ssh -L 8984:localhost:8984 constance03
# # this will open an ssh connection however you can now make requests to
# # http://localhost:8984 and the request will get forwarded to http://constance03:8984


out <- localDBConn('/Users/mollenburger/git/gcam-outputs/exoginten', 'database_basexdb')


#out1 <- localDBConn('/Users/olle240/Documents/GCAM/PIC_output/exogintens/mueller', 'database_basexdb2')
#out <- localDBConn('/Users/mollenburger/Documents/Output/exog-intens', 'database_basexdb')
# 
#out1<- remoteDBConn("database_basexdb", "mollen", "Banamba1905")
# 
# 
# cropprod<-addScenario(out, './results/agLU_cropprod.dat', scenario=c("GGCMI_PotYld50_2050", "GGCMI_PotYld50_2090", "GGCMI_PotYld75_2050", "GGCMI_PotYld75_2090", "GGCMI_PotYld100_2090"), queryFile='../queries/cropprod.xml',clobber=TRUE)
# landuse<-addScenario(out, './results/agLU_landuse.dat', scenario=c("GGCMI_PotYld50_2050", "GGCMI_PotYld50_2090", "GGCMI_PotYld75_2050", "GGCMI_PotYld75_2090", "GGCMI_PotYld100_2090"), queryFile='../queries/landuse.xml',clobber=TRUE)

# cropprodG<-addScenario(out, "./results/agLU_GGCMI.dat", 
#                       scenario=c("GGCMI_PotYld50_2050", "GGCMI_PotYld50_2090", "GGCMI_PotYld75_2050", 
#                                  "GGCMI_PotYld75_2090", "GGCMI_PotYld100_2050", "GGCMI_PotYld100_2090"), 
#                       queryFile="../queries/crops_1.xml",warn.empty = F)


cropprod<-addScenario(out, "./results/agLU_compare.dat", 
                      queryFile="../queries/crops_1.xml",scenario=c("PotYld_srcM100_2090","PotYld_srcG100_2090"),warn.empty = T,clobber=F)


cropprod<-addScenario(out, "./results/agLU_compare.dat", 
                      queryFile="../queries/crops_2.xml",scenario=c("PotYld_srcM100_2090","PotYld_srcG100_2090"),warn.empty = T,clobber=F)



cropprod<-addScenario(out, "./results/agLU_compare.dat", 
                      queryFile="../queries/animalfeed.xml",scenario=c("PotYld_srcM100_2090","PotYld_srcG100_2090"),warn.empty = T,clobber=T)


cropprod<-addScenario(out, "./results/agLU_compare.dat", 
                      queryFile="../queries/water.xml",scenario=c("GGCMI_PotYld100_2090","Mueller_PotYld100_2090"),warn.empty = T,clobber=F)



ref <- localDBConn('/Users/mollenburger/git/gcam-outputs/miscsplit', 'database_basexdb')

cropref<-addScenario(ref,'./results/ref_crop.dat',queryFile='../queries/crops_1.xml',clobber=TRUE)
cropref<-addScenario(ref,'./results/ref_crop.dat',queryFile='../queries/water.xml',clobber=FALSE)


cropref<-addScenario(ref, "./results/ref_crop.dat", 
                      queryFile="../queries/animalfeed.xml",clobber=T)

cropref<-addScenario(ref, "./results/ref_crop.dat", 
                     queryFile="../queries/crops_2.xml",clobber=T)



# 
# query_name<-"ag production by land use region"
# agprod_detail<-'<supplyDemandQuery title="ag production by land use region">
# <axis1 name="technology">technology[@name]</axis1>
# <axis2 name="Year">physical-output[@vintage]</axis2>
# <xPath buildList="true" dataName="output" group="false" sumAll="false">*[@type="sector" and (local-name()="AgSupplySector")]/
# *[@type="subsector"]//output-primary/physical-output/node()</xPath>
# <comments>primary output only (no residue biomass)</comments>
# </supplyDemandQuery>'
# 
# apd<-addSingleQuery(out, "./results/agLU_cropprod.dat", query_name, agprod_detail, scenario=c("GGCMI_PotYld50_2050", "GGCMI_PotYld50_2090", "GGCMI_PotYld75_2050", 
#                                                                                               "GGCMI_PotYld75_2090", "GGCMI_PotYld100_2050", "GGCMI_PotYld100_2090"))
# 
# 
# 
# query_name<-"meat and dairy production by type"
# anprod<-'<supplyDemandQuery title="meat and dairy production by type">
#   <axis1 name="sector">sector</axis1>
#   <axis2 name="Year">physical-output[@vintage]</axis2>
#   <xPath buildList="true" dataName="output" group="false" sumAll="false">*[@type="sector" and
#                                                                            (@name="Beef" or @name="SheepGoat" or @name="Pork" or @name="Dairy" or @name="Poultry")]//
#   *[@type="output"]/physical-output/node()</xPath>
#   <comments/>
#   </supplyDemandQuery>'
# 
# anpr<-addSingleQuery(out, "./results/agLU_comp2.dat", query_name, anprod, scenario=c("GGCMI_PotYld100_2090","Mueller_PotYld100_2090"))
# anpr_ref<-addSingleQuery(ref, "./results/ref_crop.dat", query_name, anprod)
  
# 
#                    
# lucquery_name="LUC emissions by LUT"
# lucquery<- '<query title="LUC emissions by LUT">
#   <axis1 name="LandLeaf">LandLeaf</axis1>
#   <axis2 name="Year">land-use-change-emission[@year]</axis2>
#   <xPath buildList="true" dataName="land-use-change-emission" group="false" sumAll="false"><![CDATA[/LandNode[@name="root" or @type="LandNode" (:collapse:)]//
#                                                                                                       land-use-change-emission[@year>1970]/text()]]></xPath>
#   <comments/>
#   </query>'
# 
# lucquery<-'<query title="LUC emissions by region">
#   <axis1 name="LandLeaf">LandLeaf</axis1>
#   <axis2 name="Year">land-use-change-emission[@year]</axis2>
#   <xPath buildList="true" dataName="land-use-change-emission" group="false" sumAll="true"><![CDATA[/LandNode[@name="root" or @type="LandNode" (:collapse:)]//
#                                                                                                      land-use-change-emission[@year>1970]/text()]]></xPath>
#   <comments/>
#   </query>'
# 
# 
# 
# anpr<-addSingleQuery(out, "./results/agLU_comp2.dat", lucquery_name, lucquery, scenario=c("GGCMI_PotYld100_2090","Mueller_PotYld100_2090"))
# 
# anpr_ref<-addSingleQuery(ref, "./results/ref_crop.dat", lucquery_name, lucquery)

                   