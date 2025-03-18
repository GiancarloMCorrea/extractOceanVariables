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
source("code/erddap/extractERDDAP.R")
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Explore dataset id for the desired variable:
# out <- ed_search(query='hycom_GLBa008_yx')
# View(out$info)
# 
# # Remember to also search in different URLs:
# ed_search(query='hycom_GLBa008_yx', url = "https://coastwatch.noaa.gov/erddap/")

# -------------------------------------------------------------------------

# Define folder where environmental datasets will be stored:
saveEnvDir = "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data with observations:
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 
mainDat = mainDat %>% dplyr::filter(Year == 2015)

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols = c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST)
# Define ERDDAP source and variable name

# MUR analysis (0.01 deg resolution):
envirSource <- "MUR"
datasetid <- "jplMURSST41mday" # daily: "jplMURSST41", monthly: "jplMURSST41mday"
url <- eurl()
info(datasetid = datasetid, url = url) # check 'field'
fields <- "sst"

# -------------------------------------------------------------------------
# For chlorophyll (CHL)
# Define source and variable

# # MODIS (4km resolution):
# envirSource <- "MODIS"
# datasetid <- "erdMH1chlamday" # daily: "erdMH1chla1day", monthly: "erdMH1chlamday"
# url <- eurl()
# info(datasetid = datasetid, url = url) # check 'field'
# fields <- "chlorophyll"

# -------------------------------------------------------------------------

# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = extractERDDAP(data           = mainDat, 
                        lonlat_cols    = lonlat_cols,
                        date_col       = date_col,
                        envirSource    = envirSource, 
                        fields         = fields, 
                        datasetid      = datasetid, 
                        url            = url)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_", envirSource, ".csv")), row.names = FALSE)

# -------------------------------------------------------------------------
# Fill NAs if desired:
envData_fill = fill_NAvals(data = envData, 
                           lonlat_cols = lonlat_cols,
                           group_col = 'Crucero_2',
                           var_col = 'sst_MUR', 
                           radius = 5)

# -------------------------------------------------------------------------
# Make explorative maps:
plot_map(data = envData_fill, lonlat_cols = c("Lon_M", "Lat_M"), 
         group_col = 'Crucero_2', var_col = 'sst_MUR')
