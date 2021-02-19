
# Aggregate Mumbai and Delhi in the India district shapefile
setwd("[YOUR DIRECTORY PATH HERE]")

rm(list=ls())

dirpath_data <- "./data"
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_int <- paste0(dirpath_gen, "/intermediate")
dirpath_int_shp <- paste0(dirpath_int, "/shapefiles")
dirpath_int_shp_districts <- paste0(dirpath_int_shp, "/districts")
dirpath_int_shp_districts_comb <- paste0(dirpath_int_shp_districts, "/combined")
dirpath_int_shp_districts_agg <- paste0(dirpath_int_shp_districts, "/aggregated")

# LOAD PACKAGES
library(sf)
library(dplyr)
library(haven)

## 1. Load data
# District-level shapefile (unaggregated)
dist <- st_read(paste0(dirpath_int_shp_districts_comb, "/districts.shp")) %>%
  mutate(dtname = toupper(dtname))

## 2. Create lists of districts that will be aggregated
# Mumbai
Mumbai_list <- c("Mumbai Suburban", "Mumbai") %>%
  toupper()

# 3. subset district shapefile for each list of districts, aggregate
# shapefiles
dist_Mumb <- dist %>%
  filter(dtname %in% Mumbai_list) %>%
  st_union() %>%
  st_sf() %>%
  # Add back state and district name
  mutate(dtname = "MUMBAI", 
         stname = "MAHARASHTRA",
         JID = 1111)

dist_delhi <- dist %>%
  filter(stname == "DELHI") %>%
  st_union() %>%
  st_sf() %>%
  mutate(dtname = "DELHI", 
         stname = "DELHI",
         JID = 9999)

# 4. Add these aggregated districts back into shapefile
dist_not_in_lists <- dist %>%
  filter(!(dtname %in% Mumbai_list), !(stname == "DELHI"))

dist_agg <- rbind(dist_not_in_lists, dist_delhi, dist_Mumb)

write_sf(dist_agg, paste0(dirpath_int_shp_districts_agg, "/districts_delhiagg.shp"))

# 5. Output attributes
dist_agg_df <- dist_agg %>%
  as.data.frame() %>%
  dplyr::select(-geometry)

write_dta(dist_agg_df, paste0(dirpath_int_shp_districts_agg, "/districts_delhiagg.dta"))

