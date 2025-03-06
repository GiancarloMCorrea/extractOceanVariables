rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(rerddap)
require(dplyr)
theme_set(theme_classic())
# Cargar función
source("assignEnvir.R")

# -------------------------------------------------------------------------
# Explore dataset id for the desired variable:
out <- ed_search(query='noaacwSMOSsssDaily')
View(out$info)

# Define URL (default):
url <- eurl()

# Define folder where environmental datasets will be stored:
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data/"

# -------------------------------------------------------------------------
# Read data:
# IMPORTANT: do not change the 'mainDat' object name
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 

# Define Lan Lot Date columns in 'mainDat':
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST)
# Define source and variable

# MUR analysis (0.01 deg resolution):
envirSource <- "MUR"
timeResolution = "month" # 'day' or 'month'
datasetid <- "jplMURSST41mday" # daily: "jplMURSST41", monthly: "jplMURSST41mday"
info(datasetid = datasetid) # check nae of 'field'
fields <- "sst"
flip_direction <- "none" # is rotation needed?: 'v' or 'h' or 'none


# -------------------------------------------------------------------------
# For chlorophyll (CHL)
# Define source and variable

# MODIS (4km resolution):
envirSource <- "MODIS"
timeResolution = "month" # 'day' or 'month'
datasetid <- "erdMH1chlamday" # daily: "erdMH1chla1day", monthly: "erdMH1chlamday"
info(datasetid = datasetid) # check nae of 'field'
fields <- "chlorophyll"
flip_direction <- "none" # is rotation needed?: 'v' or 'h' or 'none

# -------------------------------------------------------------------------
# Preprocess the data:
exPts <- mainDat %>% select(all_of(c(lonlat_cols, date_col))) %>% dplyr::rename(Lon = lonlat_cols[1],
                                                                               Lat = lonlat_cols[2],
                                                                               Date = date_col)
exPts$Date = as.Date(exPts$Date)
# Add month column:
exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))

# Ejecutar función
envData = assignEnvir(data           = exPts, 
                     envirSource    = envirSource, 
                     fields         = fields, 
                     datasetid      = datasetid, 
                     url            = url, 
                     timeResolution = timeResolution,
                     flip_direction = flip_direction)

# Add env variable column 
col_name = tail(names(newDat), 1)
env_vector = as.vector(newDat[tail(names(newDat), 1)])
mainDat[,col_name] = env_vector

# Save new data with environmental information:
write.csv(mainDat, file = "data_with_env_var.csv", row.names = FALSE)


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
