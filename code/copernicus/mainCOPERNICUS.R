rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(reticulate)
require(dplyr)
require(terra)
# Load function
source("code/copernicus/extractCOPERNICUS.R")
source('code/auxFunctions.R')

# -------------------------------------------------------------------------
# Install python if needed:
# install_python()
# Get familiar with the data IDs:
# https://data.marine.copernicus.eu/products
# Manual:
# https://documentation.marine.copernicus.eu/PUM/CMEMS-GLO-PUM-001-024.pdf

# Temperature:
# "cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m" - "thetao"
# MLD:
# "cmems_mod_glo_phy_anfc_0.083deg_P1D-m" - "mlotst"

# -------------------------------------------------------------------------
# Define name for virtual environment:
entorno <- "DescargaCopernicus"
virtualenv_create(envname = entorno)
virtualenv_install(envname = entorno, packages = "copernicusmarine")
use_virtualenv(virtualenv = entorno, required = TRUE)
# Module attributes:
atributos_cms <- import(module = "copernicusmarine")
# Introduce your username and password (Copernicus Marine)
# Create your account here: https://marine.copernicus.eu/
# atributos_cms$login("gcorrea", "sSCT1208!")

# -------------------------------------------------------------------------
# Define folder where environmental datasets will be stored:
saveEnvDir <- "C:/Use/GitHub/extractOceanVariables/env_data"

# -------------------------------------------------------------------------
# Read data:
# IMPORTANT: do not change the 'mainDat' object name
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv") 
mainDat = mainDat %>% dplyr::filter(Year == 2015)

# Define Lan Lot Date columns in 'mainDat':
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# -------------------------------------------------------------------------
# Define source and variable
dataid = "cmems_mod_glo_phy_my_0.083deg_P1D-m"
fields = "mlotst"


# -------------------------------------------------------------------------
# Get environmental information:
envData = extractCOPERNICUS(data = mainDat,
                            savePath = saveEnvDir,
                            dataid = dataid,
                            fields = fields)

# Save new data with environmental information:
write.csv(envData, file = paste0("data_with_", fields, "_COPERNICUS.csv"), row.names = FALSE)

