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
source("code/erddap/single/extractERDDAP.R")
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Define folder where environmental datasets will be stored:
saveEnvDir = "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data with observations:
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols = c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST)
# Define ERDDAP source and variable name

# MUR analysis (0.01 deg resolution):
datasetid <- "jplMURSST41mday"
url <- eurl()
info(datasetid = datasetid, url = url) # check 'field'
fields <- "sst" # should be in NC files

# -------------------------------------------------------------------------
# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = extractERDDAP(data           = mainDat, 
                        lonlat_cols    = lonlat_cols,
                        date_col       = date_col,
                        fields         = fields, 
                        datasetid      = datasetid, 
                        saveEnvDir     = saveEnvDir,
                        url            = url)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_", envirSource, ".csv")), row.names = FALSE)

# -------------------------------------------------------------------------
# Fill NAs if desired:
envData = fill_NAvals(data = envData, 
                      lonlat_cols = lonlat_cols,
                      group_col = 'Year',
                      var_col = 'sst', 
                      radius = 5)

# -------------------------------------------------------------------------
# Make explorative maps:
envData = envData %>% mutate(Year = format(Date, '%Y'))
plot_map(data = envData, lonlat_cols = c("Lon_M", "Lat_M"), 
         group_col = 'Year', var_col = 'sst')
