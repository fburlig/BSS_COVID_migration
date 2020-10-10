# Create a district-level heatmap of the number of arriving mumbai migrants
setwd("/Users/garyschlauch/desktop/covid_india_migrants")

library(sf)
library(dplyr)
library(stringi)
library(lubridate)
library(readr)
library(tidyr)
library(haven)

rm(list=ls())
dirpath_shp <- "./data/Generated/Intermediate/Shapefiles/districts/aggregated/"
dirpath_remittance <- "./data/Raw/Remittances/"
dirpath_out <- "./data/Generated/Intermediate/Remittances/"

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 1. Load data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

# District shapefile
districts <- st_read(paste0(dirpath_shp,
                            "districts_delhiagg.shp"))

# Monthly transaction data
volume <- read_csv(paste0(dirpath_remittance, 
                          "April2019_26July2020_monthly_remittances.csv")) %>%
  select(month, depositorid, latitude, longitude, sum_amt)
  

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 2. Match sending lat/lons to a district
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

# Sum transaction amounts by sending location
volume_agg <- volume %>%
  # Remove missing lat/lons and those not in India
  filter(latitude > 0, longitude > 0, !is.na(latitude), !is.na(longitude)) %>%
  group_by(month, depositorid, latitude, longitude) %>%
  dplyr::summarize(sum_amt = sum(sum_amt)) %>%
  ungroup()

# Add group id for unique lat/lon pairs
volume_agg$latlon_id <- dplyr::group_indices(volume_agg, 
                                             .dots=c("longitude", "latitude"))

# Make unique latitude/longitude pairs into spatial data frame
volume_sf <- volume_agg %>%
  distinct(latitude, longitude, latlon_id) %>%
  st_as_sf(coords = c("longitude", "latitude")) %>%
  st_set_crs("WGS84")

# Match to a district
volume_matched <- st_join(volume_sf, districts, by = st_intersects) %>%
  as.data.frame() %>%
  select(latlon_id, stname, dtname)

# Match back to monthly-level dataset
volume_agg <- left_join(volume_agg, volume_matched, by = "latlon_id")

# Aggregate to district-monthly level
volume_agg <- volume_agg %>%
  group_by(month, dtname, stname) %>%
  dplyr::summarize(sum_amt = sum(sum_amt)) %>%
  ungroup()

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 3. Output
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

write_dta(volume_agg, paste0(
  dirpath_out, "monthly_transaction_volume_cleaned.dta")
  )


