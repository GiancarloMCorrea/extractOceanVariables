rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(rerddap)
require(dplyr)
# Load auxiliary functions
source("code/extractHYCOM.R")
source('code/downloadHYCOM.R')
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Get familiar with HYCOM data:
# https://www.hycom.org/dataserver
# In most cases, you are interested in GLBv0.08 and GLBy0.08

# Define folder where environmental datasets will be stored:
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data/"

# -------------------------------------------------------------------------
# Read data:
# IMPORTANT: do not change the 'mainDat' object name
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 
mainDat = mainDat %>% dplyr::filter(Year == 2018, Month %in% c('11'))
head(mainDat)

# Define Lan Lot Date columns in 'mainDat':
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST): 'water_temp'
# For salinity (SSS): 'salinity'
# Define source and variable
fields = 'salinity'

# -------------------------------------------------------------------------
# Preprocess the data:
exPts <- mainDat %>% dplyr::select(all_of(c(lonlat_cols, date_col))) %>% 
            dplyr::rename(Lon = lonlat_cols[1],
                          Lat = lonlat_cols[2],
                          Date = date_col)
exPts$Date = as.Date(exPts$Date)
# Add month column:
exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))

# Ejecutar función
envData = extractHYCOM(data = exPts,
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
