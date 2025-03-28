# Download environmental information and match it with observations.
extractERDDAP <- function(data, lonlat_cols, date_col,
                          fields, datasetid,
                          saveEnvDir = getwd(),
                          depthlim = NULL, # c(-100, 0)
                          summ_fun = "mean", na_rm = TRUE,
                          url = "https://upwell.pfeg.noaa.gov/erddap/", 
                          saveEnvFiles = FALSE,
						  show_plot = FALSE) {
  
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
  
  # Create folder to save environmental information:
  if(!dir.exists(saveEnvDir)) dir.create(path = saveEnvDir, showWarnings = FALSE, recursive = TRUE)
  
  # Set new column name with env information:
  newNames <- "new_envir"
  names(newNames) <- fields
  
  # Get unique months
  monthList <- unique(exPts$month)
  
  # List to save results
  output <- list()
  
  # Loop over unique months
  for(i in seq_along(monthList)){
    
    # Filter month
    tempPts = exPts %>% filter(month == monthList[i])
    
    # Lon lat time ranges:
    xlim = range(tempPts[,lonlatdate[1]]) + 0.5*c(-1, 1)
    ylim = range(tempPts[,lonlatdate[2]]) + 0.5*c(-1, 1)
    datelim = seq(from = monthList[i], by = "month", length.out = 2) - c(0, 1)
    
    # Download information from ERDDAP:
    if(is.null(depthlim)) {
    gettingData = griddap(datasetx = datasetid, 
                           time = format(x = datelim, 
                                         format = "%Y-%m-%dT12:00:00Z"),
                           longitude = xlim, 
                           latitude = ylim, 
                           fields = fields, 
                           read = FALSE,
                           url = url,
                           store = disk(saveEnvDir))
    } else {
    gettingData = griddap(datasetx = datasetid, 
                          time = format(x = datelim, 
                                        format = "%Y-%m-%dT12:00:00Z"),
                          longitude = xlim, 
                          latitude = ylim, 
                          depth = depthlim,
                          fields = fields, 
                          read = FALSE,
                          url = url,
                          store = disk(saveEnvDir))
    }
    
    # Read downloaded data using terra:
    envirData = rast(x = gettingData$summary$filename) 
     
    # Check if flip is needed
    if(is.flipped(envirData)){
      envirData = flip(x = envirData)
    }
    if(show_plot) plot(envirData)
    
    # Find the closest date position:
    these_nctimes = sort(unique(as.Date(time(envirData)))) # remove depth effect
    index <- sapply(tempPts$Date, find_date, env_date = these_nctimes)
    max_days_diff = max(abs(as.numeric(tempPts$Date - these_nctimes[index])))
    
    # Find number of depths:
    depth_byTime = as.vector(table(time(envirData)))
    group_vec = rep(1:length(these_nctimes), depth_byTime)
    
    # Match spatially and temporally
    envirValues <- envirData %>% 
      terra::extract(y = as.matrix(tempPts[,lonlatdate[1:2]])) %>% 
      t() %>% as.data.frame() %>% mutate(gr = group_vec) %>%
      group_by(gr) %>% summarise_all(summ_fun, na.rm = na_rm) %>% 
      dplyr::select(-gr) %>% t() %>% as.data.frame() %>%
      mutate(index, .before = 1) %>% 
      apply(1, function(x) x[-1][x[1]]) %>% as.vector()
    
    # Create new column with env information:
    output[[i]] = tempPts %>% 
                    mutate(new_envir = envirValues) %>% 
                    rename(all_of(newNames)) %>% 
                    dplyr::select(c(names(newNames), 'id_row'))
    if(saveEnvFiles) {
    # Rename the downloaded NC file:
    file.rename(from = gettingData$summary$filename, 
                to = paste0(saveEnvDir, '/',
                            paste(fields, 
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
  
  output_df = output_df %>% dplyr::select(-id_row)
  n_nas = sum(is.na(pull(output_df, names(newNames))))
  perc_nas = round(n_nas/nrow(output_df)*100, 1)
  
  cat("Assignation of environmental information finished. Number of NAs found:", n_nas, paste0("(", perc_nas, "%"), "of your observations)", "\n")
  
  return(output_df)

}
