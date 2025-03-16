extractBATHY <- function(data, lonlat_cols) {
  
  # Preprocess the data:
  tempPts <- data 

    # Obtener límites en lon, lat y tiempo para el subset de puntos
    xlim <- range(tempPts[,lonlat_cols[1]]) + 0.5*c(-1, 1)
    ylim <- range(tempPts[,lonlat_cols[2]]) + 0.5*c(-1, 1)

    # Get bathy information:
    bathydf = getNOAA.bathy(lon1 = xlim[1], lon2 = xlim[2], 
                            lat1 = ylim[1], lat2 = ylim[2], resolution = 4)
    
    # Plot:
    plot(bathydf)
     
    # Get bathy information for sample points:
    output = get.depth(mat = bathydf, x = as.matrix(tempPts[,lonlat_cols]), locator = FALSE)
    tempPts$depth = output$depth
    
  # Return object:  
  return(tempPts)
    
}
