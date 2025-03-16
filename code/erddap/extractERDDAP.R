extractERDDAP <- function(data, lonlat_cols, date_col,
                        envirSource, fields, datasetid,
                        url = "https://upwell.pfeg.noaa.gov/erddap/", 
                        saveEnvFiles = FALSE) {
  
  # Cargar paquetes necesarios
  require(terra)
  require(lubridate)
  
  # Define input data col names used in this function:
  # DO NOT CHANGE
  lonlatdate = c("Lon", "Lat", "Date")
  
  # Create id rows to do match later:
  data = data %>% mutate(id_row = 1:n())
  
  # Preprocess the data:
  exPts <- data %>% select(all_of(c(lonlat_cols, date_col, 'id_row'))) %>% dplyr::rename(Lon = lonlat_cols[1],
                                                                               Lat = lonlat_cols[2],
                                                                               Date = date_col)
  exPts$Date = as.Date(exPts$Date)
  # Add month column:
  exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))
  
  # Create folder to save env information:
  if(!dir.exists(saveEnvDir)) dir.create(path = saveEnvDir, showWarnings = FALSE, recursive = TRUE)
  
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
    
    # Download information from ERDDAP:
    gettingData <- griddap(datasetx = datasetid, 
                           time = format(x = datelim, 
                                         format = "%Y-%m-%dT12:00:00Z"),
                           longitude = xlim, 
                           latitude = ylim, 
                           fields = fields, 
                           read = FALSE,
                           url = url,
                           store = disk(saveEnvDir))  
    
    # Read downloaded data using terra:
    envirData <- rast(x = gettingData$summary$filename) 
     
    # Check if flip is needed
    if(is.flipped(envirData)){
      envirData <- flip(x = envirData)
    }
    plot(envirData)
    
    # Find the closest date position to match:
    index <- sapply(tempPts$Date, find_date, env_date = as.Date(time(envirData)))
    max_days_diff = max(as.numeric(tempPts$Date - as.Date(time(envirData))[index]))
        
    # Match spatially and temporally
    envirValues <- envirData %>% 
      extract(y = as.matrix(tempPts[,lonlatdate[1:2]])) %>% 
      mutate(index, .before = 1) %>% 
      apply(1, function(x) x[-1][x[1]])
    
    # Create new column with env information:
    newNames <- "new_envir"
    names(newNames) <- paste(fields, envirSource, sep = "_")
    output[[i]] = tempPts %>% 
                    mutate(new_envir = envirValues) %>% 
                    rename(all_of(newNames)) %>% 
                    select(c(names(newNames), 'id_row'))
    if(saveEnvFiles) {
    # Rename the downloaded NC file:
    file.rename(from = gettingData$summary$filename, 
                to = paste0(saveEnvDir, '/',
                            paste(fields, envirSource, 
                                  format(datelim[1], format = '%Y-%m-%d'),
                                  format(datelim[2], format = '%Y-%m-%d'),
                                  sep = '_'),
                            ".nc")
                )
    } else {
      file.remove(gettingData$summary$filename)
    }
                  
    cat("Month", as.character(monthList[i]), "ready. Maximum number of days difference:", max_days_diff, "\n")

  } # by month loop
  
  merged_output =  bind_rows(output)

  # Match rows with original dataset:
  output_df = left_join(data, merged_output, by = 'id_row')
  
  if(!identical(nrow(data), nrow(output_df)) | any(is.na(output_df$id_row))){
    stop('Unexpected error detected when matching. Check step by step carefully.')
  }
  
  output_df = output_df %>% select(-id_row)
  return(output_df)

}
