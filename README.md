# Get oceanographic information for ecological applications

Codes to easily get oceanographic information from [ERDDAP](https://www.ncei.noaa.gov/erddap/index.html), [HYCOM](https://www.hycom.org/), or [COPERNICUS](https://data.marine.copernicus.eu/products) from R. You can also get bathymetric data using the [marmap](https://cran.r-project.org/web/packages/marmap/index.html) R package.

The provided codes (found in the `codes` folder) efficiently download oceanographic data and then find the value corresponding to each observation in your data based on spatial location and time. A new column to your data is added with the values of the desired environmental variable. Minimum handling is required. The R codes there are self-explanatory and have comments to guide you through the process.

> **Requirements** Your data need to have longitude (numeric, [-180, 180]), latitude (numeric, [-90, 90]), and date (Date class, %Y-%m-%d) columns.

There are two main ways to do this, and I call them *single* or *multiple-use* approaches.

-   *Single-use*: For a given month, the oceanographic data is downloaded (netCDF file) based on the spatial extent of your observations during that month, and then matching is performed based on longitude, latitude, and time (year, month, and day). The downloaded oceanographic dataset can be kept or immediately deleted. This procedure is repeated for every month-year combination in your data. This approach is more efficient when you only want to extract the environmental information and are not interested in keeping the oceanographic data files.
-   *Multiple-use*: For this approach, you first must define the spatial extent and time range of interest (make sure that all your observations are within these ranges). Then, you need to download the oceanographic data (netCDF file) and store it somewhere on your computer. After having the oceanographic data downloaded, you do the matching with your observations based on longitude, latitude, and time (year, month, and day). This approach is useful when you want to download oceanographic data for a given study area only once, and then use it for different purposes.

> **Limitations** The current version ignores the z dimension (i.e., depth). Therefore, it only works for surface oceanographic variables. If you need to download data for a specific depth, you will need to modify the code.

Below, I provide specific instructions for each data source.

## Get data from ERDDAP

You need to be familiar with the [ERDDAP](https://www.ncei.noaa.gov/erddap/index.html) database. You can find different types of oceanographic datasets in ERDDAP, which may be found in different URLs. Each dataset contains information on certain oceanographic variables, which may be global or local (e.g., Gulf of Mexico). Therefore, in order to download oceanographic data from ERDDAP, you need to know the dataset id, the URL where that dataset lives, and the variable name of interest in that dataset.

I recommend you first explore all the URLs available using `rerddap::servers()`. The default URL in most functions in the `rerddap` R package can be found by running `rerddap::eurl()`. Once you have found the URL with the desired dataset, you need to know the dataset id, which can be found using `rerddap::ed_search(query, url)`, where *query* is a keyword (e.g., sst) and *url* is the chosen URL. Remember to correctly specify the URL since some datasets may be available on some sites and not on others.

Once you know the URL and the dataset id, you need to know the variable name of interest in the chosen dataset. You can check this using `rerddap::info(datasetid, url)`.

You only need to focus on the `code/erddap/single/single-ERDDAP.R` or `code/erddap/multiple/multiple-ERDDAP.R` scripts, depending on the approach. You can ignore the rest.

Example 1: if you want to download monthly sea surface temperature data from the [Multi-scale Ultra-high Resolution (MUR)](https://podaac.jpl.nasa.gov/MEaSUREs-MUR) Analyses, you need to specify:

``` r
datasetid = "jplMURSST41mday"
url = eurl()
fields = "sst"
```

Example 2: if you want to download monthly chlorophyll-a concentration from [Aqua-MODIS](https://modis.gsfc.nasa.gov/data/dataprod/chlor_a.php), you need to specify:

``` r
datasetid = "erdMH1chlamday"
url = eurl()
fields = "chlorophyll"
```

## Get data from HYCOM

You can find information about HYCOM [here](https://www.hycom.org/). HYCOM is an open-source ocean general circulation modelling system at a global scale. In this case, you only need to know the variable code you want to use. These are the options available:

-   `water_temp`: sea surface temperature
-   `salinity`: salinity
-   `surf_el`: sea surface elevation
-   `water_u`: eastward sea water velocity
-   `water_v`: northward sea water velocity

There is information from October 1992 to August 2024.

You only need to focus on the `code/hycom/single/single-HYCOM.R` or `code/hycom/multiple/multiple-HYCOM.R` scripts, depending on the approach. You can ignore the rest.

## Get data from COPERNICUS

First, explore the [COPERNICUS Marine Data Store](https://data.marine.copernicus.eu/products). Like in the ERDDAP case, COPERNICUS has different oceanographic datasets, and each of them has certain oceanographic variables. You need to know the dataset id and the variable name of interest. However, it is quite easy to find this information by exploring the [COPERNICUS website](https://data.marine.copernicus.eu/products). Each dataset has associated documentation with all the needed information.

To download data from COPERNICUS, the only challenging step is that you first need to install Phyton (in case you do not have it installed). You can easily do that from R by running:

``` r
reticulate::install_python()
```

Then, you will also need to create an account on the COPERNICUS website. You can do it [here](https://marine.copernicus.eu/) (click on Register). Remember your username and password!

After completing those two steps successfully, you can start downloading data from COPERNICUS. In the provided code (`code/copernicus`), you will see a step that creates a virtual environment in Phyton.

You only need to focus on the `code/copernicus/single/single-COPERNICUS.R` or `code/copernicus/multiple/multiple-COPERNICUS.R` scripts, depending on the approach. You can ignore the rest.

Example 1: if you want to download daily data on ocean mixed layer thickness, you need to specify:

``` r
dataid = "cmems_mod_glo_phy_my_0.083deg_P1D-m"
fields = "mlotst"
```

## Get bathymetry data

This section is quite straightforward. The provided code uses the `marmap` R package to download bathymetric data, which is then matched to your observations. There is no *single* or *multiple-use* option for this case.

## Filling missing values

For some datasets and oceanographic variables, missing values (`NA`) could be present. If you want to *fill* in those missing values, I have prepared a function (`fill_NAvals`, found in `code/auxFunctions.R`) that fills those `NA` with the average value around a specific number of kilometres in a selected period.

For example, after extracting the environmental information and adding it to your data (`sst_MUR` column), you notice that you have many missing values. You could fill all or some of them by running:

``` r
envData = fill_NAvals(data = envData, 
                      lonlat_cols = c("Lon_M", "Lat_M"),
                      group_col = 'Year', # will do it year by year
                      var_col = 'sst_MUR', 
                      radius = 5) # in km
```

## Plot the extracted environmental variable

After adding the environmental information to your data (`sst_MUR`), you can explore it by plotting the data. I have prepared a function (`plot_map`, found in `code/auxFunctions.R`) that allows you to plot the environmental information for a specific period (`group_col`):

``` r
plot_map(data = envData, lonlat_cols = c("Lon_M", "Lat_M"), 
         group_col = 'Year', var_col = 'sst_MUR')
```

## Recommendations

Carefully explore the oceanographic dataset you want to download. Make sure it covers the spatial and temporal extent of your observations. Also, notice that there are different spatial resolutions. Likewise, there are different temporal resolutions (e.g., daily or monthly). Usually, finer temporal resolution will have more missing values for some variables (e.g., chlorophyll).

These codes have not been tested for all possible scenarios. Therefore, you may encounter errors. If you have any questions or suggestions, please let me know.
