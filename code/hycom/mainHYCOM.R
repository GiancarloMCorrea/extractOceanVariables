rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(dplyr)
# Load auxiliary functions
source("code/hycom/extractHYCOM.R")
source('code/hycom/downloadHYCOM.R')
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

# Define Lan Lot Date columns in 'mainDat':
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST): 'water_temp'
# For salinity (SSS): 'salinity'
# Define source and variable
fields = 'salinity'

# -------------------------------------------------------------------------

# Get environmental information:
envData = extractHYCOM(data = mainDat,
                       lonlat_cols = lonlat_cols,
                       date_col = date_col,
                       savePath = saveEnvDir,
                       fields = fields)

# Save new data with environmental information:
write.csv(envData, file = paste0("data_with_", fields, "_HYCOM.csv"), row.names = FALSE)


# -------------------------------------------------------------------------
# 
# # Make some plots:
# MyPoints = mainDat %>% st_as_sf(coords = c("Lon_M", "Lat_M"), crs = 4326, remove = FALSE)
# worldmap = map_data("world")
# colnames(worldmap) = c("X", "Y", "PID", "POS", "region", "subregion")
# 
# ggplot() + 
#   geom_sf(data = MyPoints, aes(color = chlorophyll_MODIS), size = 1) +
#   geom_polygon(data = worldmap, aes(X, Y, group=PID), fill = "gray60", color=NA) +
#   coord_sf(expand = FALSE, xlim = c(-84, -70), ylim = c(-19, -3)) +
#   scale_color_viridis_c() +
#   xlab(NULL) + ylab(NULL) +
#   facet_wrap(~Crucero_2)
