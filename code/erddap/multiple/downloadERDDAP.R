# Download environmental information
downloadERDDAP <- function(xlim, ylim, datelim,
                          fields, datasetid,
                          depthlim = NULL, # c(-100, 0)
                          saveEnvDir = getwd(),
                          url = "https://upwell.pfeg.noaa.gov/erddap/") 
{
  # Find first and last day of the month to download data:
  rangeDays = c(lubridate::floor_date(datelim[1], "month"),
                lubridate::ceiling_date(datelim[2], "month"))
  startDay = seq(from = rangeDays[1], to = rangeDays[2], by = "month")
  endDay   = startDay[2:length(startDay)] - 1
  startDay = startDay[1:(length(startDay) - 1)]
  
  # Create subfolder to save NC files:
  if(!dir.exists(saveEnvDir)) dir.create(saveEnvDir, showWarnings = FALSE, recursive = TRUE)
  
  for(i in seq_along(endDay)) {
    tmp_datelim = c(startDay[i], endDay[i])
    if(is.null(depthlim)) {
      gettingData = griddap(datasetx = datasetid, 
                            time = format(x = tmp_datelim, 
                                          format = "%Y-%m-%dT12:00:00Z"),
                            longitude = xlim, 
                            latitude = ylim, 
                            fields = fields, 
                            read = FALSE,
                            url = url,
                            store = disk(saveEnvDir))
    } else {
      gettingData = griddap(datasetx = datasetid, 
                            time = format(x = tmp_datelim, 
                                          format = "%Y-%m-%dT12:00:00Z"),
                            longitude = xlim, 
                            latitude = ylim, 
                            depth = depthlim,
                            fields = fields, 
                            read = FALSE,
                            url = url,
                            store = disk(saveEnvDir))
    }
    
    # Save it:
    file.rename(from = gettingData$summary$filename, 
                to = paste0(saveEnvDir, '/',
                            paste(format(tmp_datelim[1], format = '%Y-%m-%d'),
                                  format(tmp_datelim[2], format = '%Y-%m-%d'),
                                  sep = '_'),
                            ".nc"))
    
    cat("Information from", as.character(startDay[i]), "to", as.character(endDay[i]), "downloaded.", "\n")
  
  }
  
}
