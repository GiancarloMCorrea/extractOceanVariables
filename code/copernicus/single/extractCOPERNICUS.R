# Download environmental information and match it with observations.
extractCOPERNICUS <- function(data, lonlat_cols, date_col,
                              savedir, 
                              dataid, field,
                              depthlim = NULL,
                              depth_FUN = "mean", na_rm = TRUE,
                              nc_dimnames = c("x", "y", "time"))
  {

  # Load required libraries:
  require(dplyr)
  require(lubridate)
  require(stars)
  
  # Define input data col names used in this function:
  lonlatdate = nc_dimnames
  
  # Create id rows to do match later:
  data = data %>% mutate(id_row = 1:n())
  
  # Preprocess the data:
  exPts = data[,c(lonlat_cols, date_col, 'id_row')]
  colnames(exPts)[1:3] = nc_dimnames
  exPts[,nc_dimnames[3]] = as.POSIXct(exPts %>% pull(nc_dimnames[3]), tz = "UTC")
  
  # Add month column:
  exPts$month = as.Date(format(exPts %>% pull(nc_dimnames[3]), format = "%Y-%m-01"))
  
  # Create folder to save env information:
  if(!dir.exists(savedir)) dir.create(path = savedir, showWarnings = FALSE, recursive = TRUE)
  
  # Set new column name with env information:
  newNames <- "new_envir"
  names(newNames) <- field
  
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
    NCtmpname = paste0(savedir, "tmp_copernicus.nc")
    if(is.null(depthlim)) {
      atributos_cms$subset(
        dataset_id        = dataid,
        variables         = list(field),
        minimum_longitude = xlim[1],
        maximum_longitude = xlim[2],
        minimum_latitude  = ylim[1],
        maximum_latitude  = ylim[2],
        start_datetime    = format(x = datelim[1], format = "%Y-%m-%dT00:00:00"),
        end_datetime      = format(x = datelim[2], format = "%Y-%m-%dT00:00:00"),
        output_filename   = NCtmpname
      ) 
    } else {
      atributos_cms$subset(
        dataset_id        = dataid,
        variables         = list(field),
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
    }
      
    # Read file:
    envirData <- stars::read_stars(NCtmpname)
    st_crs(envirData) = 'OGC:CRS84'
    dim_names = dimnames(envirData)
    
    if(i == 1) {
      # Print dimension names and values:
      cat("Dimensions are:", paste(dim_names, collapse = ', '), "\n")
    }
    
    # Aggregate over depths:
    if('depth' %in% dim_names) {
      agg_dpt = st_apply(envirData, nc_dimnames, depth_FUN, na.rm = na_rm) %>% setNames(field)
    } else {
      agg_dpt = envirData %>% setNames(field)
    }
    # Extract time values from NC file:
    these_nctimes = sort(unique(st_get_dimension_values(agg_dpt, nc_dimnames[3])))
    
    # Find the closest date position:
    index = sapply(tempPts %>% pull(nc_dimnames[3]), find_date, env_date = these_nctimes)
    max_days_diff = max(abs(as.numeric(difftime(tempPts %>% pull(nc_dimnames[3]), these_nctimes[index], units = "days"))))
    
    # Prepare observed data for matching:
    pts = tempPts[,nc_dimnames]
    pts = pts %>% st_as_sf(coords = nc_dimnames[1:2], crs = 'OGC:CRS84')

    # Repeat ocean data by index (time):
    # This is important for monthly oceanographic data:
    if(length(these_nctimes) == 1) { # monthly data, do not slice
      rpt_time = agg_dpt %>% dplyr::slice(time, 1)
      envirValues = st_extract(rpt_time, pts) %>% dplyr::pull(field)
    } else { # otherwise
      extr_vals = st_extract(agg_dpt, pts) %>% dplyr::pull(field)
      envirValues = extr_vals %>% as.data.frame() %>% mutate(index, .before = 1) %>% 
                        apply(1, function(x) x[-1][x[1]]) %>% as.vector()
    }
    
    # Assuming all variables are numeric: (may cause problems with caterogial variables if any)
    envirValues = as.numeric(envirValues)
    
    # Create new column with env information:
    output[[i]] <- tempPts %>% 
      mutate(new_envir = envirValues) %>% 
      rename(all_of(newNames))  %>% 
      dplyr::select(c(names(newNames), 'id_row'))
    
    # Remove downloaded file:
    file.remove(NCtmpname)

    cat("Month", as.character(substr(monthList[i], start = 1, stop = 7)), "ready. Maximum number of days difference:", max_days_diff, "\n")
    
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
