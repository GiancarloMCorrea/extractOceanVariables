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
source("code/hycom/single/extractHYCOM.R")
source('code/hycom/getHYCOM.R')
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Define folder where environmental datasets will be stored:
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data:
# IMPORTANT: do not change the 'mainDat' object name
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# Variable name:
fields = 'salinity'

# -------------------------------------------------------------------------
# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = extractHYCOM(data        = mainDat,
                       lonlat_cols = lonlat_cols,
                       date_col    = date_col,
                       saveEnvDir  = saveEnvDir,
                       fields      = fields)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_HYCOM.csv")), row.names = FALSE)
