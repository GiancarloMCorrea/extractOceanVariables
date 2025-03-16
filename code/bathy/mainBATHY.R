rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(marmap)
require(dplyr)
# Load function
source('code/auxFunctions.R')
source('code/bathy/extractBATHY.R')

# -------------------------------------------------------------------------
# Read data:
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 
mainDat = mainDat %>% dplyr::filter(Year == 2018)

# Define Lan Lot Date columns in 'mainDat':
lonlat_cols <- c("Lon_M", "Lat_M")

# -------------------------------------------------------------------------

# Get bathymetry information: 
envData = extractBATHY(data = mainDat, lonlat_cols = lonlat_cols)

# Save new data with environmental information:
write.csv(envData, file = paste0("data_with_bathy.csv"), row.names = FALSE)
