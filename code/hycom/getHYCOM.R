## Original code: https://github.com/cran/HMMoce/blob/master/R/get.hycom.R

#' Download HYCOM data
#' @param limits A list of length 4; minlon, maxlon, minlat, maxlat. Longitude values are -180,180
#' @param time A vector of length 2 with the minimum and maximum times in form
#'   \code{as.Date(date)}.
#' @param vars A list of variables to download. This can contain
#'   'water_temp', 'water_u', 'water_v', 'salinity' or 'surf_el' but is not checked
#'   for errors.
#' @param include_latlon Should the array of latitude and longitude values be
#'   included?
#' @param filename An optional filename. If provided, then the data is
#'   downloaded to that file. Otherwise the data is not downloaded and the url
#'   is returned.
#' @param download.file Logical. Should use the default \code{download.file} to
#'   query the server and download or use the optional \code{curl}. Some users
#'   may need to use \code{curl} in order to get this to work.
#' @param dir is local directory where ncdf files should be downloaded to.
#'   default is current working directory. if enter a directory that doesn't
#'   exist, it will be created.
#' @param depLevels is an integer describing which depth levels to download from Hycom (e.g. 1=surface). Default is NULL and all levels are downloaded.
#' @return The url used to extract the requested data from the NetCDF subset
#'   service.
#' @importFrom curl curl_download

getHYCOM <- function(limits, time, vars=c('water_temp'), include_latlon=TRUE,
                     filename='tmp_hycom.nc', download.file=TRUE,
                     dir = getwd(), depLevels=1, ...) {

  ## Set the base URL based on the start date. If the ending date exceeds the
  ## period for this experiment, then print a warning and truncate the output
  ## early.
  
  # # Original:
  # expts = data.frame(
  #   start=c(as.Date('1992-10-02'), as.Date('1995-08-01'),
  #           as.Date('2013-01-01'), as.Date('2013-08-20'),
  #           as.Date('2014-04-05'), as.Date('2016-04-18'),
  #           as.Date('2018-12-04')),
  #   end=c(as.Date('1995-07-31'), as.Date('2012-12-31'),
  #         as.Date('2013-08-19'), as.Date('2014-04-04'),
  #         as.Date('2016-04-17'), as.Date('2018-11-20'),
  #         Sys.Date() + 1),
  #   url=c('http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_19.0/',
  #         'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_19.1/',
  #         'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_90.9?',
  #         'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_91.0?',
  #         'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_91.1?',
  #         'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_91.2?',
  #         'http://ncss.hycom.org/thredds/ncss/GLBy0.08/expt_93.0?'))
  
  # Modified (especially Nov and Dec 2018)
  expts = data.frame(
    start=c(as.Date('1992-10-02'), as.Date('1995-08-01'),
            as.Date('2013-01-01'), as.Date('2013-08-20'),
            as.Date('2014-04-05'), as.Date('2016-04-18'),
            as.Date('2018-12-01')),
    end=c(as.Date('1995-07-31'), as.Date('2012-12-31'),
          as.Date('2013-08-19'), as.Date('2014-04-04'),
          as.Date('2016-04-17'), as.Date('2018-11-30'),
          as.Date('2024-09-04')),
    url=c('http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_19.0/',
          'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_19.1/',
          'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_90.9?',
          'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_91.0?',
          'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_91.1?',
          'http://ncss.hycom.org/thredds/ncss/GLBu0.08/expt_91.2?',
          'http://ncss.hycom.org/thredds/ncss/GLBy0.08/expt_93.0?'))
  
  if(time[1] < expts$start[1])
    stop('Data begins at %s and is not available at %s.',
         strftime(expts$start[1], '%d %b %Y'),
         strftime(time[1], '%d %b %Y'))
  if(time[1] > expts$end[nrow(expts)])
    stop('Data ends at %s and is not available at %s.',
         strftime(expts$end[nrow(expts)], '%d %b %Y'),
         strftime(time[1], '%d %b %Y'))
  for(k in seq(nrow(expts))) {
    if((time[1] >= expts$start[k]) & (time[1] <= expts$end[k])) {
      url = expts$url[k]
      this_info = expts[k,]
    }
  }
  
  if(any(grep('19', url))) url = sprintf('%s%s?', url, as.numeric(format(time[1], '%Y')))
  
  ## Add the variables.
  for(var in vars){
    url = sprintf('%svar=%s&', url, var)
  }
  
  ## Add the spatial domain.
  url = sprintf('%snorth=%f&west=%f&east=%f&south=%f&horizStride=1&',
                url, limits[[4]], limits[[1]], limits[[2]], limits[[3]])
  # north, west, east, south
  
  ## Add the time domain.
  if(length(time) == 2){
    url = sprintf('%stime_start=%s%%3A00%%3A00Z&time_end=%s%%3A00%%3A00Z&',
                  url, strftime(time[1], '%Y-%m-%dT00'),
                  strftime(time[2], '%Y-%m-%dT00'))
  } else if(length(time) == 1){
    url = sprintf('%stime_start=%s%%3A00%%3A00Z&time_end=%s%%3A00%%3A00Z&',
                  url, strftime(time[1], '%Y-%m-%dT00'),
                  strftime(time[1], '%Y-%m-%dT00'))
  }
  
  ## Check for the newer HYCOM experiments (3hr time resolution) and add stride=8 if needed, otherwise 1 for daily HYCOM data
  if(any(grep('GLBy', url))){
    url = sprintf('%stimeStride=%s&', url, 8)
  } else{
    url = sprintf('%stimeStride=%s&', url, 1)
  }
  
  ## Add the lat-lon points if requested.
  if(include_latlon)
    url = sprintf('%saddLatLon=true&', url)
  
  ## Finish the URL.
  if (is.null(depLevels)){
    url = sprintf('%sdisableProjSubset=on&vertCoord=&accept=netcdf', url)
  } else{
    url = paste(url,'disableProjSubset=on&vertCoord=', depLevels, '&accept=netcdf', sep='')
  }
  
  #print(url)
  
  ## Download the data if a filename was provided.
  nc_file = file.path(dir, filename)
  if(download.file == TRUE){
    curl::curl_download(url, nc_file, quiet=FALSE)
  } else {
    system(sprintf('curl -o "%s" "%s"', nc_file, url))
  }

  out_list = list(info = this_info, filename = nc_file)
  return(out_list)
}
