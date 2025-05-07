# Download environmental information and match it with observations.
downloadCOPERNICUS <- function(xlim, ylim, datelim, 
                               depthlim = NULL,
                               dataid, field,
                               savedir = paste0(getwd(), "/")){
  
  # Load required libraries:
  require(lubridate)
  
  # Make date as Date class:
  datelim = as.Date(datelim)
  
  # Find first and last day of the month to download data:
  rangeDays = c(lubridate::floor_date(datelim[1], "month"),
                lubridate::ceiling_date(datelim[2], "month"))
  startDay = seq(from = rangeDays[1], to = rangeDays[2], by = "month")
  endDay   = startDay[2:length(startDay)] - 1
  startDay = startDay[1:(length(startDay) - 1)]
  
  # Create subfolder to save NC files:
  if(!dir.exists(savedir)) dir.create(savedir, showWarnings = FALSE, recursive = TRUE)
  
  # Loop over unique months
  for(i in seq_along(endDay)){
    
    # Date limits:
    tmp_datelim = c(startDay[i], endDay[i])
    
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
        start_datetime    = format(x = tmp_datelim[1], format = "%Y-%m-%dT00:00:00"),
        end_datetime      = format(x = tmp_datelim[2], format = "%Y-%m-%dT00:00:00"),
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
        start_datetime    = format(x = tmp_datelim[1], format = "%Y-%m-%dT00:00:00"),
        end_datetime      = format(x = tmp_datelim[2], format = "%Y-%m-%dT00:00:00"),
        minimum_depth     = depthlim[1],
        maximum_depth     = depthlim[2],
        output_filename   = NCtmpname
      )
    }
    
    # Rename the downloaded NC file:
    file.rename(from = NCtmpname, 
                to = paste0(savedir, 
                            paste(format(tmp_datelim[1], format = '%Y-%m-%d'),
                                  format(tmp_datelim[2], format = '%Y-%m-%d'),
                                  sep = '_'),
                            ".nc") )
    
    cat("Information from", as.character(startDay[i]), "to", as.character(endDay[i]), "downloaded.", "\n")
    
  } # by month loop
  
}