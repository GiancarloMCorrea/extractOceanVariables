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
source("code/copernicus/single/extractCOPERNICUS.R")
source('code/auxFunctions.R')

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
# Define folder where environmental datasets will be stored:
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data with observations:
mainDat = readr::read_csv(file = "data/example_data.csv") 

# Define Lan/Lot and Date column names in your dataset:
lonlat_cols = c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# Define dataset id and variable
dataid = "cmems_mod_glo_phy_my_0.083deg_P1D-m"
fields = "mlotst"

# -------------------------------------------------------------------------
# Download environmental information and matching with observations:
# A column with the environmental variable will be added
envData = extractCOPERNICUS(data       = mainDat,
                            saveEnvDir = saveEnvDir,
                            dataid     = dataid,
                            fields     = fields)

# Save new data with environmental information:
write.csv(envData, file = file.path('data', paste0("data_with_", fields, "_COPERNICUS.csv")), row.names = FALSE)
