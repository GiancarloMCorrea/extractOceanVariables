# Download environmental information and match it with observations.
extractCOPERNICUS <- function(data, saveEnvDir, dataid, fields,
                              depthlim = c(0, 100),
                              summ_fun = "mean", na_rm = TRUE,
                              saveEnvFiles = FALSE,
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
    NCtmpname = file.path(saveEnvDir, "tmp_copernicus.nc")
    atributos_cms$subset(
      dataset_id        = dataid,
      variables         = list(fields),
      minimum_longitude = xlim[1],
      maximum_longitude = xlim[2],
      minimum_latitude  = ylim[1],
      maximum_latitude  = ylim[2],
      start_datetime    = format(x = datelim[1], format = "%Y-%m-%dT00:00:00"),
      end_datetime      = format(x = datelim[2], format = "%Y-%m-%dT00:00:00"),
      minimum_depth     = depthlim[1],
      maximum_depth     = depthlim[2],
      output_filename   = NCtmpname
    ) 
      
    # Read file:
    envirData <- rast(x = file.path(saveEnvDir, "tmp_copernicus.nc")) 
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
    output[[i]] <- tempPts %>% 
        mutate(new_envir = envirValues) %>% 
        rename(all_of(newNames))  %>% 
        dplyr::select(c(names(newNames), 'id_row'))
      
    if(saveEnvFiles) {
      # Rename the downloaded NC file:
      file.rename(from = NCtmpname, 
                to = paste0(saveEnvDir, '/',
                                paste(fields, 
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
  
  output_df = output_df %>% dplyr::select(-id_row)
  n_nas = sum(is.na(pull(output_df, names(newNames))))
  perc_nas = round(n_nas/nrow(output_df)*100, 1)
  
  cat("Assignation of environmental information finished. Number of NAs found:", n_nas, paste0("(", perc_nas, "%"), "of your observations)", "\n")
  
  return(output_df)
    
}
