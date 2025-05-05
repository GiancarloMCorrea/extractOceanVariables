rm(list = ls())

# Load libraries:
require(readr)
require(ggplot2)
require(sf)
require(dplyr)
require(stars)
require(viridis)
require(lubridate)
require(reticulate)

# Load auxiliary functions:
source("code/copernicus/multiple/downloadCOPERNICUS.R")
source("code/copernicus/multiple/matchCOPERNICUS.R")
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Define longitude and latitude limits:
# Make your that your observations are within these limits
lonLims = c(-83, -69)
latLims = c(-19, -3)
dateLims = c("2015-02-01", "2015-03-31") # %Y-%m-%d format

# -------------------------------------------------------------------------
# Define dataset id and variable
dataid = "cmems_mod_glo_phy_my_0.083deg_P1M-m"
field = "thetao"

# -------------------------------------------------------------------------
# Define folder where environmental datasets will be stored:
savedir = file.path("C:/Use/GitHub/extractOceanVariables/env_data", field)

# -------------------------------------------------------------------------
# Define name for Phyton virtual environment:
entorno = "DownloadCopernicus"
virtualenv_create(envname = entorno)
virtualenv_install(envname = entorno, packages = "copernicusmarine")
use_virtualenv(virtualenv = entorno, required = TRUE)
atributos_cms <- import(module = "copernicusmarine")
# Introduce your username and password (Copernicus Marine)
# atributos_cms$login("username", "password")

# -------------------------------------------------------------------------
# Download environmental information and save it:
# You only need to do this once.
download_data = TRUE
if(download_data) {
  downloadCOPERNICUS(xlim = lonLims, ylim = latLims, 
                     datelim = dateLims,
                     field = field, 
                     dataid = dataid,
                     savedir = savedir)
}


# -------------------------------------------------------------------------
# Read data with observations:
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols = c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = matchCOPERNICUS(data           = mainDat, 
                          lonlat_cols    = lonlat_cols,
                          date_col       = date_col,
                          var_label      = field, 
                          var_path       = savedir)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_COPERNICUS.csv")), row.names = FALSE)
