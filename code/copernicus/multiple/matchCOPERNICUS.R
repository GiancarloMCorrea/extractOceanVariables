# Download environmental information and match it with observations.
matchCOPERNICUS <- function(data, lonlat_cols, date_col, var_label = 'env_var',
                              varPath){

  # Define input data col names used in this function:
  lonlatdate = c("Lon", "Lat", "Date")
  
  # Create id rows to do match later:
  data = data %>% mutate(id_row = 1:n())
  
  # Preprocess the data:
  exPts <- data %>% dplyr::select(dplyr::all_of(c(lonlat_cols, date_col, 'id_row'))) %>% 
    dplyr::rename(Lon = lonlat_cols[1],
                  Lat = lonlat_cols[2],
                  Date = date_col)
  exPts$Date = as.Date(exPts$Date)
  
  # Add month column:
  exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))
  
  # Get unique months
  monthList <- unique(exPts$month)
  
  # Set new column name with env information:
  newNames <- "new_envir"
  names(newNames) <- var_label
  
  # List to save results
  output <- list()
  
  # Loop over unique months
  for(i in seq_along(monthList)){
    
    # Find start and end day of month:
    start_day = lubridate::floor_date(monthList[i], "month")
    end_day = lubridate::ceiling_date(monthList[i], "month") - 1
    
    # Subset month
    tempPts <- exPts %>% filter(month == monthList[i])
    
    # Find NC file for that month:
    nc_file = file.path(varPath, paste0(start_day, "_", end_day, ".nc"))
    
    if(!file.exists(nc_file)){
      stop("Netcdf file not found. Did you download environmental data for that date range? Check if the file is in the correct path.")
    }  
    
    # Read file:
    envirData <- rast(x = nc_file) 
    plot(envirData)
      
    # Find the closest date position:
    index <- sapply(tempPts$Date, find_date, env_date = as.Date(time(envirData)))
    max_days_diff = max(abs(as.numeric(tempPts$Date - as.Date(time(envirData))[index])))
    
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
