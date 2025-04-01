rm(list = ls())

# Load libraries:
require(readr)
require(ggplot2)
require(sf)
require(dplyr)
require(terra)
require(viridis)
require(lubridate)
require(marmap)
# Load auxiliary functions:
source('code/auxFunctions.R')
source('code/bathy/extractBATHY.R')

# -------------------------------------------------------------------------
# Read data with observations:
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot column names in your dataset:
lonlat_cols <- c("Lon_M", "Lat_M")

# -------------------------------------------------------------------------
# Get bathymetry information for each observation: 
envData = extractBATHY(data = mainDat, lonlat_cols = lonlat_cols)#agregar

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_bathy.csv")), row.names = FALSE)
