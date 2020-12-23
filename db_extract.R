library(rgcam)
library(tidyverse)

file.path <- '~/git/gcam-sam/output/'
dbFile <- c('database_basexdb')
conn <- localDBConn(dbPath=file.path, dbFile, migabble = FALSE, maxMemory="1g")


gcam_home='/Users/mollenburger/git/gcam-sam/'

prj.name <- 'SAM-matrix_data.dat'
scenario.names <- c('Reference', 'DietaryTransition','PotYld')
query.fname  <- paste0(gcam_home,'output/queries/SAM_querylist.xml')

prj <- addScenario(conn, prj.name, scenario=scenario.names, clobber=TRUE, queryFile=query.fname)
SAMout<-addScenario(conn, "./outdata/SAM-matrix.dat", queryFile = "SAM_querylist.xml")

#SAMout<-loadProject(proj='./outdata/SAM-matrix.dat')

SAMq<-listQueries(SAMout)

fertcons<-getQuery(SAMout,SAMq)

###FILTERS###
allcrops=c('Corn','FiberCrop','Fruits', 'Legumes','MiscCrop','NutsSeeds','OilCrop','OtherGrain','PalmFruit','Rice','RootTuber',
           'Soybean','SugarCrop','Vegetables','Wheat','FodderGrass','FodderHerb','biomass')
foodcrops=c('Corn','Fruits', 'Legumes','NutsSeeds','OilCrop','OtherGrain','PalmFruit','Rice','RootTuber',
            'Soybean','SugarCrop','Vegetables','Wheat')
maincrops<-c('Corn','OilCrop','OtherGrain','Rice','SugarCrop','Wheat')
excrops = c('Corn','OilCrop','Rice','Wheat')
uncropped<-c('Forest','Grassland','OtherArableLand','Pasture','ProtectedGrassland','ProtectedShrubland','ProtectedUnmanagedForest','ProtectedUnmanagedPasture','Shrubland','UnmanagedForest','UnmanagedPasture')
biomass = c('biomass_grass','biomass_tree')
fodder=c('FodderHerb','FodderGrass')

metaregions<-read_csv('inputs/metaregions.csv')

# Then to run the server they simply need to provide the path to where the databases are stored:
#   ```
# [pralitp@constance03 ~]$ ./basex-server-helper.sh scratch-home/run-irr-const/pbs/output
# DB Path: scratch-home/run-irr-const/pbs/output

# # Note you should use the exact PIC login node that is running the server
# ssh -L 8984:localhost:8984 constance03
# # this will open an ssh connection however you can now make requests to
# # http://localhost:8984 and the request will get forwarded to http://constance03:8984
