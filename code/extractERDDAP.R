extractERDDAP <- function(data, 
                        envirSource, fields, datasetid,
                        url = "https://upwell.pfeg.noaa.gov/erddap/", 
                        timeResolution = 'day',
                        flip_direction = "none") {
  
  # Cargar paquetes necesarios
  require(terra)
  require(lubridate)
  
  # Define input data col names:
  lonlatdate = c("Lon", "Lat", "Date")
  
  # Si la carpeta de descarga de archivos no existe, se creará
  if(!dir.exists(saveEnvDir)) dir.create(path = saveEnvDir, showWarnings = FALSE, recursive = TRUE)

  # Specify data:
  exPts = data
  
  # Obtener vector con todos los mes-año sin repeticiones
  monthList <- unique(exPts$month)
  
  # Definir una lista vacía que guardará los datos de salida
  output <- list()
  
  # Iniciar un bucle a lo largo de los valores únicos de año-mes
  for(i in seq_along(monthList)){
    
    # Tomar la tabla de ejemplo
    tempPts <- exPts %>% filter(month == monthList[i])
    
    # Obtener límites en lon, lat y tiempo para el subset de puntos
    xlim <- range(tempPts[,lonlatdate[1]]) + 0.5*c(-1, 1)
    ylim <- range(tempPts[,lonlatdate[2]]) + 0.5*c(-1, 1)
    datelim <- seq(from = monthList[i], by = "month", length.out = 2) - c(0, 1)
    
    # Descargar la información ambiental SOLO PARA LOS LÍMITES DE lon, lat y tiempo
    # Esta función descargará un archivo y le asignará un nombre temporal sin 
    # mucho sentido, por lo que en la parte final del bucle se realizará un 
    # renombramiento del archivo
    gettingData <- griddap(datasetx = datasetid, 
                           time = format(x = datelim, 
                                         format = "%Y-%m-%dT12:00:00Z"),
                           longitude = xlim, 
                           latitude = ylim, 
                           fields = fields, 
                           read = FALSE,
                           url = url,
                           store = disk(saveEnvDir))  
    
    # Leer el archivo nc descargado
    # La función rast (del paquete terra) lee los datos del archivo descargado 
    # considerando TODOS los días. En este ejemplo, cada archivo descargado 
    # contendrá la información de un mes (año-mes), por lo que cada archivo podrá
    # tener hasta 31 capas (días)
    envirData <- rast(x = gettingData$summary$filename) 
    plot(envirData)
     
    # Si se define un valor v o h para 'flip_direction', realizar el giro
    if(tolower(flip_direction) == "v"){
      envirData <- flip(x = envirData, direction = "vertical")
    }else if(tolower(flip_direction) == "h"){
      envirData <- flip(x = envirData, direction = "horizontal")
    }
    
    # Find the closest date position:
    index <- sapply(tempPts$Date, find_date, env_date = as.Date(time(envirData)))
        
    # Tomar el objeto con la información ambiental
    envirValues <- envirData %>% 
      
      # Hacer el match entre las coordenadas y los datos ambientales
      # Lo que este paso hace es cruzar las coordenadas y la información ambiental
      # y lo hace con TODAS las capas (días dentro del año-mes descargado) y luego
      # devuelve un data.frame en donde cada fila es el dato ambiental para la 
      # coordenada correspondiente y cada columna es el valor para cada una de las
      # capas (día del año-mes)
      extract(y = as.matrix(tempPts[,lonlatdate[1:2]])) %>% 
      
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
    names(newNames) <- paste(fields, envirSource, sep = "_")
    
    # Tomar los datos temporales de nuestro año-mes
    output[[i]] <- tempPts %>% 
      
      # Añadir la información ambiental y darle 'new_envir' como nombre temporal 
      # de la columna
      mutate(new_envir = envirValues) %>% 
      
      # Renombrar la columna pegando el nombre del campo (variable) y la fuente
      rename(all_of(newNames))
    
    # Renombrar el archivo descargado
    file.rename(from = gettingData$summary$filename, 
                to = paste0(saveEnvDir, 
                            paste(fields, envirSource, 
                                  format(datelim[1], format = '%Y-%m-%d'),
                                  format(datelim[2], format = '%Y-%m-%d'),
                                  sep = '_'),
                            ".nc")
                )
                  
    cat("Month", as.character(monthList[i]), "ready", "\n")

  } # by month loop
  
  # Concatenar los resultados almacenados en output para obtener un data frame
  # que será el retorno de la función
  bind_rows(output)
    
}
