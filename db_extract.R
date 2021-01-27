# query model output xml database
library(rgcam)

gcam_home='/Users/mollenburger/git/gcam-sam/'
file.path <- paste0(gcam_home,'pic-out/')
dbFile <- c('database_basexdb')
conn <- localDBConn(dbPath=file.path, dbFile, migabble = FALSE, maxMemory="8g")



prj.name <- 'outdata/SAM-matrix_data.dat'
scenario.names <- c('Reference', 'DietaryTransition','PotYld','PotYld_Diet')
query.fname  <- 'SAM_querylist.xml'

prj <- addScenario(conn, prj.name, scenario=scenario.names, clobber=FALSE, queryFile=query.fname)
