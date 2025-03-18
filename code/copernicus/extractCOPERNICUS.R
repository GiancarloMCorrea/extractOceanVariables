# Download environmental information and match it with observations.
extractCOPERNICUS <- function(data, savePath, dataid, fields,
                              saveEnvFiles = FALSE){

  # Define input data col names used in this function:
  lonlatdate = c("Lon", "Lat", "Date")
  
  # Create id rows to do match later:
  data = data %>% mutate(id_row = 1:n())
  
  # Preprocess the data:
  exPts <- data %>% select(all_of(c(lonlat_cols, date_col, 'id_row'))) %>% 
                    dplyr::rename(Lon = lonlat_cols[1],
                                  Lat = lonlat_cols[2],
                                  Date = date_col)
  exPts$Date = as.Date(exPts$Date)
  
  # Add month column:
  exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))
  
  # Create folder to save env information:
  if(!dir.exists(savePath)) dir.create(path = savePath, showWarnings = FALSE, recursive = TRUE)
  
  # Set new column name with env information:
  newNames <- "new_envir"
  names(newNames) <- paste(fields, "HYCOM", sep = "_")
  
  # List to save results
  monthList <- unique(exPts$month)
  
  # Definir una lista vacía que guardará los datos de salida
  output <- list()

  # Loop over unique months
  for(i in seq_along(monthList)){
    
    # Subset month
    tempPts <- exPts %>% filter(month == monthList[i])
    
    # Lon lat time ranges:
    xlim = range(tempPts[,lonlatdate[1]]) + 0.5*c(-1, 1)
    ylim = range(tempPts[,lonlatdate[2]]) + 0.5*c(-1, 1)
    datelim = seq(from = monthList[i], by = "month", length.out = 2) - c(0, 1)
    
    # Download information from COPERNICUS::
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
    max_days_diff = max(as.numeric(tempPts$Date - as.Date(time(envirData))[index]))
    
    # Match spatially and temporally
    envirValues <- envirData %>% 
        extract(y = as.matrix(tempPts[,lonlatdate[1:2]])) %>% 
        mutate(index, .before = 1) %>% 
        apply(1, function(x) x[-1][x[1]])
      
    # Create new column with env information:
    output[[i]] <- tempPts %>% 
        mutate(new_envir = envirValues) %>% 
        rename(all_of(newNames))  %>% 
        select(c(names(newNames), 'id_row'))
      
    if(saveEnvFiles) {
      # Rename the downloaded NC file:
      file.rename(from = NCtmpname, 
                to = paste0(saveEnvDir, '/',
                                paste(fields, 'COPERNICUS', 
                                      format(datelim[1], format = '%Y-%m-%d'),
                                      format(datelim[2], format = '%Y-%m-%d'),
                                      sep = '_'),
                                ".nc") )
    } else {
      file.remove(NCtmpname)
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
  n_nas = sum(is.na(pull(output_df, names(newNames))))
  perc_nas = round(n_nas/nrow(output_df)*100, 1)
  
  cat("Assignation of environmental information finished. Number of NAs found:", n_nas, paste0("(", perc_nas, "%"), "of your observations)", "\n")
  
  return(output_df)
    
}
