rm(list = ls())

# Load libraries:
require(readr)
require(ggplot2)
require(sf)
require(dplyr)
require(terra)
require(viridis)
require(lubridate)
require(reticulate)

# Load auxiliary functions:
source("code/copernicus/multiple/downloadCOPERNICUS.R")
source("code/copernicus/multiple/matchCOPERNICUS.R")
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Define folder where environmental datasets will be stored:
# A subfolder will be created in this folder with the variable name
saveEnvDir = "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Define longitude and latitude limits:
# Make your that your observations are within these limits
lonLims = c(-83, -69)
latLims = c(-19, -3)
dateLims = c(as.Date("2013-01-01"), as.Date("2013-12-31"))

# -------------------------------------------------------------------------
# Define dataset id and variable
dataid = "cmems_mod_glo_phy_my_0.083deg_P1D-m"
fields = "mlotst"

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
                     fields = fields, 
                     dataid = dataid,
                     saveEnvDir = saveEnvDir)
}


# -------------------------------------------------------------------------
# Read data with observations:
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols = c("Lon_M", "Lat_M")
date_col = "Date"

# Specify path where environmental information is saved and some label for the variable
var_label = 'mlotst_COPERNICUS'
var_path = file.path(saveEnvDir, var_label)

# -------------------------------------------------------------------------
# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = matchCOPERNICUS(data           = mainDat, 
                          lonlat_cols    = lonlat_cols,
                          date_col       = date_col,
                          var_label      = var_label, 
                          varPath        = var_path)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_COPERNICUS.csv")), row.names = FALSE)
