# Download environmental information and match it with observations.
extractHYCOM <- function(data, lonlat_cols, date_col,
                         saveEnvDir = getwd(), fields, saveEnvFiles = FALSE,
						 show_plot = FALSE){
  
  # Define input data col names used in this function:
  lonlatdate = c("Lon", "Lat", "Date")
  
  # Create id rows to do match later:
  data = data %>% mutate(id_row = 1:n())
  
  # Preprocess the data:
  exPts <- data %>% dplyr::select(all_of(c(lonlat_cols, date_col, 'id_row'))) %>% 
                    dplyr::rename(Lon = lonlat_cols[1],
                                  Lat = lonlat_cols[2],
                                  Date = date_col)
  exPts$Date = as.Date(exPts$Date)
  
  # Add month column:
  exPts = exPts %>% mutate(month = as.Date(format(x = Date, format = "%Y-%m-01")))
  
  # Create folder to save env information:
  if(!dir.exists(saveEnvDir)) dir.create(path = saveEnvDir, showWarnings = FALSE, recursive = TRUE)
  
  # Set new column name with env information:
  newNames <- "new_envir"
  names(newNames) <- fields
  
  # Get unique months
  monthList <- unique(exPts$month)
  
  # List to save results
  output <- list()
  listCount = 1
  # Loop over unique months
  for(i in seq_along(monthList)){
    
    # Subset month
    tempPts = exPts %>% filter(month == monthList[i])
    
    # Lon lat time ranges:
    xlim = range(tempPts[,lonlatdate[1]]) + 0.5*c(-1, 1)
    ylim = range(tempPts[,lonlatdate[2]]) + 0.5*c(-1, 1)
    datelim = list(seq(from = monthList[i], by = "month", length.out = 2) - c(0, 1))
    
    # Split for months with different sources:
    # This is done because there are different HYCOM sources with
    # different start and end date
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
    
    max_days_diff = numeric(length(datelim))
    for(k in seq_along(datelim)) {
      
      # Subset by days
      daysPts <- tempPts %>% dplyr::filter(Date >= datelim[[k]][1] & Date <= datelim[[k]][2])
      
      if(nrow(tempPts) > 0) {
      
      # Download information from HYCOM:
      gettingData <- getHYCOM(limits = list(xlim[1], xlim[2], ylim[1], ylim[2]), 
                              time = datelim[[k]],
                              vars = fields,
                              dir = saveEnvDir)  
      
      # Read downloaded data using terra:
      envirData <- rast(x = gettingData$filename) 

      # Check if flip needed:
      if(is.flipped(envirData)){
        envirData <- flip(x = envirData, direction = "vertical")
      }
      if(show_plot) plot(envirData)
      
      # Find the closest date position:
      index <- sapply(daysPts$Date, find_date, env_date = as.Date(time(envirData)))
      max_days_diff[k] = max(abs(as.numeric(daysPts$Date - as.Date(time(envirData))[index])))
      
      # Matrix with observed locations:
      lonlat_mat = as.matrix(daysPts[,lonlatdate[1:2]])
      # Check if rotation needed:
      rotation_need = grepl(pattern = "6326.*9122", x = crs(envirData))
      if(rotation_need){
        lonlat_mat[,1] <- lonlat_mat[,1] %% 360
      }
      
      # Match spatially and temporally
      envirValues <- envirData %>% 
        terra::extract(y = lonlat_mat) %>% 
        mutate(index, .before = 1) %>% 
        apply(1, function(x) x[-1][x[1]])
      
      # Add new column
      output[[listCount]] <- daysPts %>% 
        mutate(new_envir = envirValues) %>% 
        rename(all_of(newNames)) %>% 
        dplyr::select(c(names(newNames), 'id_row'))
      listCount = listCount + 1
      
      if(saveEnvFiles) {
        # Rename the downloaded NC file:
        file.rename(from = gettingData$filename, 
                    to = paste0(saveEnvDir, '/',
                                paste(fields, 
                                      format(datelim[[k]][1], format = '%Y-%m-%d'),
                                      format(datelim[[k]][2], format = '%Y-%m-%d'),
                                      sep = '_'),
                                ".nc") )
      } else {
        file.remove(gettingData$filename)
      }
        
      } # conditional if data exists
    } # date range loop
      
    cat("Month", as.character(monthList[i]), "ready. Maximum number of days difference:", max(max_days_diff), "\n")
    
  } # by month loop
  
  merged_output =  bind_rows(output)
  
  # Match rows with original dataset:
  output_df = left_join(data, merged_output, by = 'id_row')
  
  if(!identical(nrow(data), nrow(output_df)) | any(is.na(output_df$id_row))){
    stop('Unexpected error detected when matching. Check step by step carefully.')
  }
  
  output_df = output_df %>% dplyr::select(-id_row)
  n_nas = sum(is.na(pull(output_df, names(newNames))))
  perc_nas = round(n_nas/nrow(output_df)*100, 1)
  
  cat("Assignation of environmental information finished. Number of NAs found:", n_nas, paste0("(", perc_nas, "%"), "of your observations)", "\n")
  
  return(output_df)
    
}
