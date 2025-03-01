rm(list = ls())
require(readr)
require(ggplot2)
require(sf)
require(rerddap)
require(dplyr)
theme_set(theme_classic())

# Explore dataset id for the desired variable:
out <- ed_search(query='sst')
out$info

# Check info of datasetid:
info(datasetid = "ncdcOisst2Agg_LonPM180")

# Define URL (default):
url <- eurl()

# -------------------------------------------------------------------------
# For temperature (SST)
# Definir fuente de descarga de datos y campo (variable) que se busca obtener de esa fuente
envirSource <- "MODIS"
fields <- "sst"
datasetid <- "ncdcOisst2Agg_LonPM180"
# is rotation needed?
flip_direction <- "none" # 'v' or 'h'

# Definir ID de la fuente de datos, así como el url
# datasetid <- "erdMH1chla1day"
# datasetid <- "erdMBsstd1day_LonPM180"

# Definir el objeto que contiene los datos de coordenadas y tiempo.
# Si este objeto se define como una ruta (i.e. un objeto de clase character y de
# longitud 1), esta ruta deberá ser de un archivo .csv. 
mainDat <- readr::read_csv(file = "data/Surveys13_20LonLat.csv")
mainDat = mainDat %>% filter(Year < 2020) # no sst data before mid2020

# Indicar los nombres de las columnas que serán usadas para extraer los valores
# de longitud, latitud y fecha
lonlat_cols <- c("Lon_M", "Lat_M")
date_col = "Date"

# Preprocess your survey data:
exPts <- mainDat %>% select(all_of(c(lonlat_cols, date_col))) %>% dplyr::rename(Lon = lonlat_cols[1],
                                                                               Lat = lonlat_cols[2],
                                                                               Date = date_col)
exPts$Date = as.Date(exPts$Date)
# Specify date column again: IMPORTANT!!
# exPts$Date = strptime(as.character(exPts$Date), format = "%Y%m%d")
# Add month column:
exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))

# Definir la carpeta en donde se irán guardando los archivos .nc que se 
# descargarán durante el proceso. Si la carpeta NO existe, la función se encargará
# de crearla
outDir <- "D:/EnvData_jointSDM/"

# Cargar función
source("assignEnvir.R")

# Ejecutar función
newDat = assignEnvir(data           = exPts, 
                      envirSource    = envirSource, 
                      fields         = fields, 
                      datasetid      = datasetid, 
                      url            = url, 
                      flip_direction = flip_direction)

# Add new variable to main dataframe:
mainDat$sst = newDat$sst_MODIS
write.csv(mainDat, file = "data/Surveys13_20LonLat_sst.csv", row.names = FALSE)

# Make some plots:
MyPoints = newDat %>% st_as_sf(coords = c("Lon", "Lat"), crs = 4326, remove = FALSE)
worldmap = map_data("world")
colnames(worldmap) = c("X", "Y", "PID", "POS", "region", "subregion")

ggplot() + 
  geom_sf(data = MyPoints, aes(color = sst_MODIS), size = 1) +
  geom_polygon(data = worldmap, aes(X, Y, group=PID), fill = "gray60", color=NA) +
  coord_sf(expand = FALSE, xlim = c(-84, -70), ylim = c(-19, -3)) +
  scale_color_viridis_c() +
  xlab(NULL) + ylab(NULL) +
  facet_wrap(~month)
  

