rm(list = ls())

# Load libraries:
require(readr)
require(ggplot2)
require(sf)
require(dplyr)
require(terra)
require(viridis)
require(lubridate)

# Load auxiliary functions:
source("code/hycom/extractHYCOM.R")
source('code/hycom/getHYCOM.R')
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Get familiar with HYCOM data:
# https://www.hycom.org/dataserver
# In most cases, you are interested in GLBv0.08 and GLBy0.08

# Define folder where environmental datasets will be stored:
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data:
# IMPORTANT: do not change the 'mainDat' object name
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 
mainDat = mainDat %>% dplyr::filter(Year == 2018)

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST): 'water_temp'
# For salinity (SSS): 'salinity'
# Define source and variable
fields = 'salinity'

# -------------------------------------------------------------------------

# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = extractHYCOM(data = mainDat,
                       lonlat_cols = lonlat_cols,
                       date_col = date_col,
                       saveEnvDir = saveEnvDir,
                       fields = fields)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_HYCOM.csv")), row.names = FALSE)


# -------------------------------------------------------------------------
# Fill NAs if desired:
envData_fill = fill_NAvals(data = envData, 
                           lonlat_cols = lonlat_cols,
                           group_col = 'Crucero_2',
                           var_col = 'salinity_HYCOM', 
                           radius = 5)

# -------------------------------------------------------------------------
# Make explorative maps:
plot_map(data = envData_fill, lonlat_cols = c("Lon_M", "Lat_M"), 
         group_col = 'Crucero_2', var_col = 'salinity_HYCOM')
