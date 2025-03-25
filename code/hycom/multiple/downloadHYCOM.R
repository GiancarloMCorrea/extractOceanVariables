# Download environmental information and match it with observations.
downloadHYCOM <- function(xlim, ylim, datelim, fields,
                          saveEnvDir = getwd()) {
  
  # Find first and last day of the month to download data:
  rangeDays = c(lubridate::floor_date(datelim[1], "month"),
                lubridate::ceiling_date(datelim[2], "month"))
  startDay = seq(from = rangeDays[1], to = rangeDays[2], by = "month")
  endDay   = startDay[2:length(startDay)] - 1
  startDay = startDay[1:(length(startDay) - 1)]
  
  # Create subfolder to save NC files:
  if(!dir.exists(saveEnvDir)) dir.create(saveEnvDir, showWarnings = FALSE, recursive = TRUE)
  
  # Loop over months:
  for(i in seq_along(endDay)) {
    # List to save month date lims:
    tmp_datelim = list()
    
    # Date limits for month
    tmp_datelim[[1]] = c(startDay[i], endDay[i])
    
    # Split for months with different sources:
    # This is done because there are different HYCOM sources with
    # different start and end date
    if(startDay[i] == as.Date("2013-08-01")) { 
      tmp_datelim[[1]] = as.Date(c("2013-08-01", "2013-08-19"))
      tmp_datelim[[2]] = as.Date(c("2013-08-20", "2013-08-31"))
    }
    if(startDay[i] == as.Date("2014-04-01")) { 
      tmp_datelim[[1]] = as.Date(c("2014-04-01", "2014-04-04"))
      tmp_datelim[[2]] = as.Date(c("2014-04-05", "2014-04-30"))
    }
    if(startDay[i] == as.Date("2016-04-01")) { 
      tmp_datelim[[1]] = as.Date(c("2016-04-01", "2016-04-17"))
      tmp_datelim[[2]] = as.Date(c("2016-04-18", "2016-04-30"))
    }    
    
    # Loop over date limits:
    for(k in seq_along(tmp_datelim)) {
      
      # Download information from HYCOM:
      gettingData <- getHYCOM(limits = list(xlim[1], xlim[2], ylim[1], ylim[2]), 
                              time = tmp_datelim[[k]],
                              vars = fields,
                              dir = saveEnvDir)  

      # Rename the downloaded NC file:
      file.rename(from = gettingData$filename, 
                  to = paste0(saveEnvDir, '/',
                              paste(format(tmp_datelim[[k]][1], format = '%Y-%m-%d'),
                                    format(tmp_datelim[[k]][2], format = '%Y-%m-%d'),
                                    sep = '_'),
                              ".nc") )

      cat("Information from", as.character(tmp_datelim[[k]][1]), "to", as.character(tmp_datelim[[k]][2]), "downloaded.", "\n")
      
    } # date range loop
      
  } # by month loop
  
}
