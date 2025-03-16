rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(rerddap)
require(dplyr)
# Load function
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
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data:
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 
mainDat = mainDat %>% dplyr::filter(Year == 2018)

# Define Lan Lot Date columns in 'mainDat':
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# For temperature (SST)
# Define source and variable

# MUR analysis (0.01 deg resolution):
envirSource <- "MUR"
datasetid <- "jplMURSST41mday" # daily: "jplMURSST41", monthly: "jplMURSST41mday"
url <- eurl()
info(datasetid = datasetid, url = url) # check nae of 'field'
fields <- "sst"

# -------------------------------------------------------------------------
# For chlorophyll (CHL)
# Define source and variable

# # MODIS (4km resolution):
# envirSource <- "MODIS"
# timeResolution = "month" # 'day' or 'month'
# datasetid <- "erdMH1chlamday" # daily: "erdMH1chla1day", monthly: "erdMH1chlamday"
# url <- eurl()
# info(datasetid = datasetid, url = url) # check nae of 'field'
# fields <- "chlorophyll"

# -------------------------------------------------------------------------

# Get environmental information:
envData = extractERDDAP(data           = mainDat, 
                        lonlat_cols    = lonlat_cols,
                        date_col       = date_col,
                        envirSource    = envirSource, 
                        fields         = fields, 
                        datasetid      = datasetid, 
                        url            = url)

# Save new data with environmental information:
write.csv(envData, file = paste0("data_with_", fields, "_", envirSource, ".csv"), row.names = FALSE)


# -------------------------------------------------------------------------
# 
# Make some plots:
MyPoints = envData %>% st_as_sf(coords = c("Lon_M", "Lat_M"), crs = 4326, remove = FALSE)
worldmap = map_data("world")
colnames(worldmap) = c("X", "Y", "PID", "POS", "region", "subregion")

ggplot() +
  geom_sf(data = MyPoints, aes(color = sst_MUR), size = 1) +
  geom_polygon(data = worldmap, aes(X, Y, group=PID), fill = "gray60", color=NA) +
  coord_sf(expand = FALSE, xlim = c(-84, -70), ylim = c(-19, -3)) +
  scale_color_viridis_c() +
  xlab(NULL) + ylab(NULL) +
  facet_wrap(~Crucero_2)
