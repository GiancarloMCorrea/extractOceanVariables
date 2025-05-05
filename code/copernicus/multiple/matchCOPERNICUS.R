# Download environmental information and match it with observations.
matchCOPERNICUS <- function(data, lonlat_cols, date_col, 
                            var_label = 'env_var', varPath, 
                            depth_range = NULL,
                            depth_FUN = "mean",
                            #time_lag = 0,
                            #time_FUN = "mean",
                            na_rm = TRUE,
							              show_plot = FALSE,
							              nc_dimnames = c("longitude", "latitude", "time")){

  # Create id rows to do match later:
  data = data %>% mutate(id_row = 1:n())
  
  # Preprocess the data:
  exPts = data[,c(lonlat_cols, date_col, 'id_row')]
  colnames(exPts)[1:3] = nc_dimnames
  exPts[,nc_dimnames[3]] = as.POSIXct(exPts %>% pull(nc_dimnames[3]), tz = "UTC")
  
  # Add month column:
  exPts$month = as.Date(format(exPts %>% pull(nc_dimnames[3]), format = "%Y-%m-01"))
  
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
    envirData <- stars::read_ncdf(nc_file) 
    if(show_plot) plot(envirData)
    
    if(i == 1) {
      # Print dimension names and values:
      dim_names = dimnames(envirData)
      cat("Dimensions are:", paste(dim_names, collapse = ', '), "\n")
    }
    
    # Filter depth:
    if(!is.null(depth_range)) {
      envirData = envirData %>% dplyr::filter(depth > depth_range[1], depth < depth_range[2])
    }
    
    # Aggregate over depths:
    agg_dpt = st_apply(envirData, nc_dimnames, depth_FUN, na.rm = na_rm) %>% setNames(var_label)
    # Extract time values from NC file:
    these_nctimes = sort(unique(st_get_dimension_values(agg_dpt, nc_dimnames[3])))
    
    # # Function to match times:
    # match_times = function(x) {
    #   pts = x %>% st_as_sf(coords = lonlatdate[1:2], crs = 'OGC:CRS84') %>% 
    #     st_as_stars()
    #   lag_times = as.POSIXct(ymd(x$time) + time_lag, tz = "UTC")
    #   index = sapply(lag_times, find_date, env_date = these_nctimes)
    #   rpt_time = agg_dpt %>% dplyr::slice(time, index)
    #   agg_time = st_apply(rpt_time, lonlatdate[1:2], time_FUN, na.rm = na_rm) %>% setNames(var_label)
    #   extr_vals = st_extract(agg_time, pts) %>% dplyr::pull(var_label)
    #   return(extr_vals)
    # }
    # 
    # # Apply function over rows
    # # This way is important to aggregate over times (lags):
    # tempPts %>% rowwise() %>% mutate(var = match_times(pick(all_of(lonlatdate)))) %>% 
    #   ungroup() -> tempPts2
    
    # Find the closest date position:
    index = sapply(tempPts %>% pull(nc_dimnames[3]), find_date, env_date = these_nctimes)
    max_days_diff = max(abs(as.numeric(difftime(tempPts %>% pull(nc_dimnames[3]), these_nctimes[index], units = "days"))))
    
    # Prepare observed data for matching:
    pts = tempPts[,nc_dimnames]
    pts = pts %>% st_as_sf(coords = nc_dimnames[1:2], crs = 'OGC:CRS84')
    pts = st_as_stars(pts)
    
    # Repeat ocean data by index (time):
    # This is important for monthly oceanographic data:
    if(length(these_nctimes) == 1) { # monthly data, do not slice
      rpt_time = agg_dpt %>% dplyr::slice(time, 1)
      envirValues = st_extract(rpt_time, pts) %>% dplyr::pull(var_label)
    } else { # otherwise
      rpt_time = agg_dpt %>% dplyr::slice(time, index)
      extr_vals = st_extract(rpt_time, pts) %>% dplyr::pull(var_label)
      envirValues = diag(extr_vals)
    }
    
    # Create new column with env information:
    output[[i]] <- tempPts %>% 
        mutate(new_envir = envirValues) %>% 
        rename(all_of(newNames))  %>% 
        dplyr::select(c(names(newNames), 'id_row'))

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
