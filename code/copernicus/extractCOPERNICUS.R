# Get HYCOM data based on lonlat time:
extractCOPERNICUS <- function(data, savePath, dataid, fields){
  
  # Cargar paquetes necesarios
  require(terra)
  require(lubridate)
  
  # Define input data col names:
  lonlatdate = c("Lon", "Lat", "Date")
  
  # Si la carpeta de descarga de archivos no existe, se creará
  if(!dir.exists(savePath)) dir.create(path = savePath, showWarnings = FALSE, recursive = TRUE)
  
  # Specify data:
  exPts = data
  
  # Obtener vector con todos los mes-año sin repeticiones
  monthList <- unique(exPts$month)
  
  # Definir una lista vacía que guardará los datos de salida
  output <- list()
  listCount = 1
  # Iniciar un bucle a lo largo de los valores únicos de año-mes
  for(i in seq_along(monthList)){
    
    # Subset month
    tempPts <- exPts %>% filter(month == monthList[i])
    
    # Obtener límites en lon, lat y tiempo para el subset de puntos
    xlim <- range(tempPts[,lonlatdate[1]]) + 0.5*c(-1, 1)
    ylim <- range(tempPts[,lonlatdate[2]]) + 0.5*c(-1, 1)
    datelim <- seq(from = monthList[i], by = "month", length.out = 2) - c(0, 1)
    
    # Download data:
    NCtmpname = file.path(savePath, "tmp_copernicus.nc")
    atributos_cms$subset(
      dataset_id        = dataid,
      variables         = list(fields),
      minimum_longitude = xlim[1],
      maximum_longitude = xlim[2],
      minimum_latitude  = ylim[1],
      maximum_latitude  = ylim[2],
      start_datetime    = format(x = datelim[1], format = "%Y-%m-%dT00:00:00"),
      end_datetime      = format(x = datelim[2], format = "%Y-%m-%dT00:00:00"),
      minimum_depth     = 0,
      maximum_depth     = 0.5,
      output_filename   = NCtmpname
    ) 
      
    # Read file:
    envirData <- rast(x = file.path(savePath, "tmp_copernicus.nc")) 
    plot(envirData)
      
    # Find the closest date position:
    index <- sapply(tempPts$Date, find_date, env_date = as.Date(time(envirData)))
      
    # Matrix with observed locations:
    lonlat_mat = as.matrix(tempPts[,lonlatdate[1:2]])

    # Tomar el objeto con la información ambiental
    envirValues <- envirData %>% 
        
        # Hacer el match entre las coordenadas y los datos ambientales
        # Lo que este paso hace es cruzar las coordenadas y la información ambiental
        # y lo hace con TODAS las capas (días dentro del año-mes descargado) y luego
        # devuelve un data.frame en donde cada fila es el dato ambiental para la 
        # coordenada correspondiente y cada columna es el valor para cada una de las
        # capas (día del año-mes)
        extract(y = lonlat_mat) %>% 
        
        # Añadir como primera columna el índice calculado anteriormente
        mutate(index, .before = 1) %>% 
        
        # En este paso, para cada fila de datos, se utiliza el valor almacenado en
        # 'index' para quedarnos únicamente con el valor del día correspondiente, 
        # por lo que al final de esta línea obtendremos un vector con los valores
        # específicos para nuestra coordenada en espacio y tiempo
        apply(1, function(x) x[-1][x[1]])
      
    # Este paso es necesario para hacer un cambio de nombre de columna en el paso 
    # siguiente
    newNames <- "new_envir"
    names(newNames) <- paste(fields, "COPERNICUS", sep = "_")
      
    # Tomar los datos temporales de nuestro año-mes
    output[[listCount]] <- tempPts %>% 
        
        # Añadir la información ambiental y darle 'new_envir' como nombre temporal 
        # de la columna
        mutate(new_envir = envirValues) %>% 
        
        # Renombrar la columna pegando el nombre del campo (variable) y la fuente
        rename(all_of(newNames))
      
    # Renombrar el archivo descargado
    file.rename(from = NCtmpname, 
                to = paste0(saveEnvDir, '/',
                                paste(fields, 'COPERNICUS', 
                                      format(datelim[1], format = '%Y-%m-%d'),
                                      format(datelim[2], format = '%Y-%m-%d'),
                                      sep = '_'),
                                ".nc") )

    cat("Month", as.character(monthList[i]), "ready", "\n")
                  
  } # by month loop
  
  # Concatenar los resultados almacenados en output para obtener un data frame
  # que será el retorno de la función
  bind_rows(output)
    
}
