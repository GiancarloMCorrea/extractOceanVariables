# Function to find the vector position (in env Dates) with the closest date
find_date = function(obs_date, env_date) {
  which(abs(env_date-obs_date) == min(abs(env_date-obs_date)))[1]
}

# -------------------------------------------------------------------------

# Fill NA values based on the average values within a radius of X km:
fill_NAvals = function(data, lonlat_cols, group_col, var_col, radius = 10) {
  
  require(geosphere)
  n_init_na = sum(is.na(pull(data, var_col)))
  these_factors = unique(pull(data, group_col))
  
  save_df = list()
  # Loop over categories in group col:
  for(i in seq_along(these_factors)) {
    
    tmpDat = data %>% dplyr::filter(!!as.symbol(group_col) == these_factors[i])
    na_obs = which(is.na(pull(tmpDat, var_col)))
    
    if(length(na_obs) > 0) {
      # Loop over NA obs:
      for(j in seq_along(na_obs)) {
      this_pos = na_obs[j]
      this_obs = as.vector(as.matrix(tmpDat[this_pos, lonlat_cols]))
      # Find near points
      coord = cbind("longitude" = pull(tmpDat, lonlat_cols[1]),
                    "latitude" = pull(tmpDat, lonlat_cols[2]))
      coord_df <- data.frame(coord, within_radius = geosphere::distHaversine(
        coord, this_obs
      ) / 1000 < radius) 
      fill_value = mean(pull(tmpDat, var_col)[which(coord_df$within_radius)], na.rm = TRUE)
      if(is.nan(fill_value)) fill_value = NA
      tmpDat[this_pos, var_col] = fill_value
      
      } # loop over NAs

    } # if missing values present
    save_df[[i]] = tmpDat
    
    cat("Group", i, "done", "\n")
    
  } # Loop over group
  
  out_df = bind_rows(save_df)
  
  n_end_na = sum(is.na(pull(out_df, var_col)))
  
  cat("Number of NAs reduced from", n_init_na, "to", n_end_na, "\n")
  
  return(out_df)
  
}

# -------------------------------------------------------------------------
# Plot map with environmental variable
plot_map = function(data, lonlat_cols, group_col, var_col, pointSize = 0.5) {
  require(sf)
  require(viridis)
  xLim = range(envData[,lonlat_cols[1]]) + 0.5*c(-1, 1)
  yLim = range(envData[,lonlat_cols[2]]) + 0.5*c(-1, 1)
  MyPoints = data %>% st_as_sf(coords = lonlat_cols, crs = 4326, remove = FALSE)
  worldmap = ggplot2::map_data("world")
  colnames(worldmap) = c("X", "Y", "PID", "POS", "region", "subregion")
  
  p1 = ggplot() +
    geom_sf(data = MyPoints, aes(color = .data[[var_col]]), size = pointSize) +
    viridis::scale_colour_viridis() +
    geom_polygon(data = worldmap, aes(X, Y, group=PID), fill = "gray60", color=NA) +
    coord_sf(expand = FALSE, xlim = xLim, ylim = yLim) +
    xlab(NULL) + ylab(NULL) +
    theme_classic() +
    facet_wrap(vars(.data[[group_col]]))
  return(p1)
}


