# Get HYCOM data based on lonlat time:
extractHYCOM <- function(data, savePath, fields){
  
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
    datelim <- list(seq(from = monthList[i], by = "month", length.out = 2) - c(0, 1))
    
    # Split for months with different sources:
    if(monthList[i] == as.Date("2013-08-01")) { 
      datelim[[1]] = as.Date(c("2013-08-01", "2013-08-19"))
      datelim[[2]] = as.Date(c("2013-08-20", "2013-08-31"))
    }
    if(monthList[i] == as.Date("2014-04-01")) { 
      datelim[[1]] = as.Date(c("2014-04-01", "2014-04-04"))
      datelim[[2]] = as.Date(c("2014-04-05", "2014-04-30"))
    }
    if(monthList[i] == as.Date("2016-04-01")) { 
      datelim[[1]] = as.Date(c("2016-04-01", "2016-04-17"))
      datelim[[2]] = as.Date(c("2016-04-18", "2016-04-30"))
    }    
    
    for(k in seq_along(datelim)) {
      
      # Subset by days
      daysPts <- tempPts %>% dplyr::filter(Date >= datelim[[k]][1] & Date <= datelim[[k]][2])
      
      if(nrow(tempPts) > 0) {
      
      # Descargar la información ambiental SOLO PARA LOS LÍMITES DE lon, lat y tiempo
      # Esta función descargará un archivo y le asignará un nombre temporal sin 
      # mucho sentido, por lo que en la parte final del bucle se realizará un 
      # renombramiento del archivo
      gettingData <- downloadHYCOM(limits = list(xlim[1], xlim[2], ylim[1], ylim[2]), 
                                    time = datelim[[k]],
                                    vars = fields,
                                    dir = savePath)  
      
      # Leer el archivo nc descargado
      # La función rast (del paquete terra) lee los datos del archivo descargado 
      # considerando TODOS los días. En este ejemplo, cada archivo descargado 
      # contendrá la información de un mes (año-mes), por lo que cada archivo podrá
      # tener hasta 31 capas (días)
      envirData <- rast(x = gettingData$filename) 
      # plot(envirData)
      # is.flipped(envirData)
      # cat(raster::crs(envirData), '\n')
      
      # Check if flip needed:
      if(is.flipped(envirData)){
        envirData <- flip(x = envirData, direction = "vertical")
      }
      plot(envirData)
      
      # Find the closest date position:
      index <- sapply(daysPts$Date, find_date, env_date = as.Date(time(envirData)))
      
      # Matrix with observed locations:
      lonlat_mat = as.matrix(daysPts[,lonlatdate[1:2]])
      # Check if rotation needed:
      rotation_need = grepl(pattern = "6326.*9122", x = crs(envirData))
      if(rotation_need){
        lonlat_mat[,1] <- lonlat_mat[,1] %% 360
      }
      
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
      names(newNames) <- paste(fields, "HYCOM", sep = "_")
      
      # Tomar los datos temporales de nuestro año-mes
      output[[listCount]] <- daysPts %>% 
        
        # Añadir la información ambiental y darle 'new_envir' como nombre temporal 
        # de la columna
        mutate(new_envir = envirValues) %>% 
        
        # Renombrar la columna pegando el nombre del campo (variable) y la fuente
        rename(all_of(newNames))
      
        # Renombrar el archivo descargado
        file.rename(from = gettingData$filename, 
                    to = paste0(saveEnvDir, 
                                paste(fields, 'HYCOM', 
                                      format(datelim[1], format = '%Y-%m-%d'),
                                      format(datelim[2], format = '%Y-%m-%d'),
                                      sep = '_'),
                                ".nc") )
        listCount = listCount + 1
      
      } # conditional if data exists
    } # date range loop
      
    cat("Month", as.character(monthList[i]), "ready, rotation =", rotation_need, "\n")
                  
  } # by month loop
  
  # Concatenar los resultados almacenados en output para obtener un data frame
  # que será el retorno de la función
  bind_rows(output)
    
}
