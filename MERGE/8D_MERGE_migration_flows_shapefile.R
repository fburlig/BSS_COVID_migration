# Prepare district-level shapefile for mumbai migrant heatmap
setwd("[YOUR DIRECTORY PATH HERE]")
  
rm(list=ls())
dirpath_in_flows <- "./data/Generated/Intermediate/map/"
dirpath_in_shp <- "./data/Generated/Intermediate/Shapefiles/districts/aggregated/"
dirpath_out <- "./data/Generated/final/Shapefiles/"
  
library(sf)
library(dplyr)
library(stringi)
library(lubridate)
library(rgdal)
library(haven)
library(rmapshaper)
  
load_data <- 1
clean_data <- 1
aggregate_polygons <- 1
merge_shp_flows <- 1
output <- 1
  
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 1. Load data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
if (load_data == 1) {
  
  flows <- read_dta(paste0(dirpath_in_flows, 
                           "covid19india_migrants_map_initialization.dta"))
      
  dist_shp <- readOGR(paste0(dirpath_in_shp, 
                             "districts_delhiagg.shp"))
  
}
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 2. Clean data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
if (clean_data == 1) {
  
  #### Shapefile
  # Convert to sf object
  dist_shp_cleaned <- st_as_sf(dist_shp) %>%
    select(-JID)

  # Aggregate names to match flows
  dist_shp_cleaned <- dist_shp_cleaned %>%
  # DAMAN & DIU: clean state names
  mutate(
      stname = ifelse(stname == "DADRA & NAGAR HAVE", "DAMAN & DIU", stname),
      dtname = ifelse(dtname == "DADRA & NAGAR HAVE", "DADRA & NAGAR HAVELI", dtname)
    ) %>%
  # TELANGANA
  mutate(
      dtname = ifelse(stname == "TELANGANA", "TELANGANA", dtname)
    ) %>%
  # ASSAM
  mutate(
      dtname = ifelse(stname == "ASSAM", "ASSAM", dtname)
    ) %>%
  # SIKKIM
   mutate(
      dtname = ifelse(stname == "SIKKIM", "SIKKIM", dtname)
    ) %>%
  # GOA
  mutate(
      dtname = ifelse(stname == "GOA", "GOA", dtname)
    ) %>%
  # MANIPUR
  mutate(
      dtname = ifelse(stname == "MANIPUR", "MANIPUR", dtname)
    ) %>%
    filter(!(stname %in% c("ANDAMAN & NICOBAR", "LAKSHADWEEP")),
           !(dtname %in% c("MUZAFFARABAD", "MIRPUR") & 
               stname == "JAMMU & KASHMIR"))
  
}
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 3. Aggregate polygons
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
if (aggregate_polygons == 1) {
  
  # Aggregate district polygon boundaries
  dist_shp_cleaned <- dist_shp_cleaned %>%
    dplyr::group_by(stname, dtname) %>%
    dplyr::summarise(geometry = st_union(geometry)) %>%
    dplyr::ungroup()


}
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 4. Merge district-shapefile with flows
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
if (merge_shp_flows == 1) {
  
  # Join
  dist_shp_flows <- left_join(dist_shp_cleaned, flows, 
                              by = c("stname" = "state", 
                                     "dtname" = "district")) %>%
    mutate_at(c("dtname", "stname"), stri_trans_totitle)
  
  # Simplify shapefile to reduce size and make easier to plot
  dist_shp_flows <- ms_simplify(dist_shp_flows, keep = 0.25, keep_shapes = T)
  
}
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 5. Output
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
if (output == 1) {
  
  st_write(dist_shp_flows, paste0(dirpath_out, "districts_flows_map.shp"))
  
  
}



