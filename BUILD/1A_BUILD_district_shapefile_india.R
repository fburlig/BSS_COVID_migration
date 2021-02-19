
# Create the India district shapefile

setwd("[YOUR DIRECTORY PATH HERE]")

rm(list=ls())

dirpath_data <- "./data"
dirpath_raw <- paste0(dirpath_data, "/raw")
dirpath_raw_shp <- paste0(dirpath_raw, "/shapefiles")
dirpath_raw_shp_districts <- paste0(dirpath_raw_shp, "/districts")
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_int <- paste0(dirpath_gen, "/intermediate")
dirpath_int_map <- paste0(dirpath_int, "/map")
dirpath_int_shp <- paste0(dirpath_int, "/shapefiles")
dirpath_int_shp_districts <- paste0(dirpath_int_shp, "/districts")
dirpath_int_shp_districts_sep <- paste0(dirpath_int_shp_districts, "/separated")
dirpath_int_shp_districts_comb <- paste0(dirpath_int_shp_districts, "/combined")

# Input: Individual district-level shapefiles for India circa 2019
# Output: Combined district-level shapefile

# LOAD PACKAGES
library(sf)
library(dplyr)
library(plyr)

# List zip files
zipfiles <- list.files(path = dirpath_raw_shp_districts, pattern = "*.zip", full.names = TRUE)

# Unzip files
ldply(.data = zipfiles, .fun = unzip, exdir = dirpath_int_shp_districts_sep)

# Get file names ending in .shp
shpfiles <- list.files(path = dirpath_int_shp_districts_sep, pattern = "*.shp", full.names = TRUE)

# Combine individual district-level .shp files
dist <- do.call("rbind", lapply(shpfiles, st_read)) %>%
  # Select district name, state name, unique district ID
  dplyr::select(dtname, stname, JID)

# Output
st_write(dist, paste0(dirpath_int_shp_districts_comb, "/districts.shp"))

