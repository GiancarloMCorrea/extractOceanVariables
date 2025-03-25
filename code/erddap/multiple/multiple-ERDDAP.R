rm(list = ls())

# Load libraries:
require(readr)
require(ggplot2)
require(sf)
require(dplyr)
require(terra)
require(viridis)
require(lubridate)
require(rerddap)
# Load auxiliary functions:
source("code/erddap/multiple/downloadERDDAP.R")
source("code/erddap/multiple/matchERDDAP.R")
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Define longitude and latitude limits:
# Make your that your observations are within these limits
lonLims = c(-83, -69)
latLims = c(-19, -3)
dateLims = c(as.Date("2013-01-01"), as.Date("2013-12-31"))

# -------------------------------------------------------------------------
# Define environmental information from ERDDAP
datasetid <- "jplMURSST41mday" 
url <- eurl()
fields <- "sst" # should be in NC files

# -------------------------------------------------------------------------
# Define folder where environmental datasets will be stored:
saveEnvDir = file.path("C:/Use/GitHub/extractOceanVariables/env_data", fields)

# -------------------------------------------------------------------------
# Download environmental information and save it:
# You only need to do this once.
download_data = TRUE
if(download_data) {
downloadERDDAP(xlim = lonLims, ylim = latLims, 
               datelim = dateLims,
               fields = fields, 
               datasetid = datasetid,
               saveEnvDir = saveEnvDir,
               url = url)
}

# -------------------------------------------------------------------------
# Read data with observations:
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols = c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# Match environmental information with observations:
# A column with the environmental variable will be added
envData = matchERDDAP(data           = mainDat, 
                      lonlat_cols    = lonlat_cols,
                      date_col       = date_col,
                      var_label      = fields,
                      varPath        = saveEnvDir)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", var_label, ".csv")), row.names = FALSE)
