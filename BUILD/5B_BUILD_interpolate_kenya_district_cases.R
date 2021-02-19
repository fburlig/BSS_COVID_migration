
# Interpolate district-level daily COVID cases for Kenya

setwd("[YOUR DIRECTORY PATH HERE]")

# Load packages
rm(list=ls())
library(tidyverse)
library(sf)
library(haven)
library(maptools)
library(raster)
library(exactextractr)
library(fasterize)
library(plyr)

# Set paths
dirpath_data <- "./data"
dirpath_raw <- paste0(dirpath_data, "/raw")
dirpath_raw_shp <- paste0(dirpath_raw, "/shapefiles")
dirpath_raw_shp_nonindia <- paste0(dirpath_raw_shp, "/non india")
dirpath_raw_rasters <- paste0(dirpath_raw, "/rasters")
dirpath_raw_rasters_worldpop <- paste0(dirpath_raw_rasters, "/world pop")
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_int <- paste0(dirpath_gen, "/intermediate")
dirpath_int_worldpop <- paste0(dirpath_int, "/World pop")
dirpath_int_covid <- paste0(dirpath_int, "/covid")

# Read in county shapefile
counties <- sf::st_read(paste0(dirpath_raw_shp_nonindia, "/kenya/county/ken_county.shp")) %>%
  dplyr::select(COUNTY, geometry) %>%
  dplyr::rename(subregion1_name = COUNTY) %>%
  dplyr::mutate_at("subregion1_name", tolower) %>%
  dplyr::mutate(subregion1_name = 
                  ifelse(subregion1_name == "keiyo-marakwet", "elgeyo-marakwet",
                         ifelse(subregion1_name == "tharaka", "tharaka-nithi",
                                ifelse(subregion1_name == "nairobi", "nairobi city",
                                       ifelse(subregion1_name == "taita taveta", "taita-taveta", 
                                              subregion1_name)))))

# Merge covid county data in
covid <- read_dta(paste0(dirpath_int_covid, "/cleaned_non_india_covid_data.dta")) %>%
  filter(country_name == "kenya") %>%
  dplyr::mutate(county_cases_per_capita = num_cases / population) %>%
  dplyr::select(subregion1_name, county_cases_per_capita, date, travel_rls)

counties <- left_join(counties, covid, by = "subregion1_name")

# Read in district shapefile
districts <- st_read(paste0(dirpath_raw_shp_nonindia, "/kenya/adm2/geo2_ke2009.shp")) %>%
  dplyr::select(ADMIN_NAME, geometry) %>%
  dplyr::rename(district = ADMIN_NAME)

# Get district populations from worldpop
KY_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/ken_ppp_2020_constrained.tif"))
KY_pop <- exact_extract(KY_wp, districts, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(KY_wp)
districts$population <- KY_pop

# Initialize dataframe to collect results
df <- data.frame()

# Rasterize county shapefile for each day and extract on districts
day_list <- c("06-07", "06-08", "06-09", "06-10", "06-11", "06-12", "06-13", "06-14",
              "06-15", "06-16", "06-17", "06-18", "06-19", "06-20",
              "06-21", "06-22", "06-23", "06-24", "06-25","06-26",
              "06-27", "06-28", "06-29", "06-30", "07-01", "07-02",
              "07-03", "07-04", "07-05", "07-06", "07-07", "07-08",
              "07-09", "07-10", "07-11", "07-12", "07-13", "07-14",
              "07-15", "07-16", "07-17", "07-18", "07-19", "07-20",
              "07-21", "07-22", "07-23", "07-24", "07-25", "07-26",
              "07-27", "07-28", "07-29", "07-30", "07-31", "08-01",
              "08-02", "08-03", "08-04", "08-05", "08-06")
for (day in day_list) {
  
  print(day)
  
  # Create blank raster
  blank_raster <- raster(nrow = 10000, ncol = 10000, extent(counties))
  
  # Subset counties data for each day
  counties_subset <- counties %>%
    dplyr::filter(date == paste0("2020-", day))
  
  # Rasterize, using cases per capita as the field value
  print("Rasterizing...")
  counties_raster <- fasterize(counties_subset, blank_raster, 
                               field = "county_cases_per_capita")
  
  # Extract the county grid points onto the district shapefile
  print("Extracting...")
  districts_covid <- exact_extract(counties_raster, districts, "mean")
  districts_subset <- districts
  districts_subset$cases_per_capita <- districts_covid
  
  # Multiply cases per capita by district population to get district cases
  districts_subset <- districts_subset %>%
    dplyr::mutate(num_cases = population * cases_per_capita,
                  date = paste0("2020-", day))
  
  # Convert to df
  districts_subset <- districts_subset %>%
    as.data.frame() %>%
    dplyr::select(-geometry)
  
  # Append to master dataframe
  df <- rbind.fill(df, districts_subset)
}

# Check to see daily case totals are similar
df %>%
  group_by(date) %>%
  dplyr::summarize(num_cases = sum(num_cases)) %>% 
  write_dta("~/downloads/interpolation_timeseries.dta")

# Merge with migrant counts
migrants <- read_dta("/Users/garyschlauch/Box/Eko_Remittances/Covid/Data/Generated/Intermediate/Census/kenya_hotspot_to_nonhotspot_migrants.dta") %>%
  # Combine mombasa and kilindini
  mutate(subregion2_name = 
           ifelse(subregion2_name == "kilindini", "mombasa", 
                  subregion2_name)) %>%
  group_by(subregion1_name, subregion2_name) %>%
  dplyr::summarize(migrants = sum(migrants)) %>%
  ungroup()

df_final <- df %>%
  dplyr::rename(subregion2_name = district) %>%
  mutate(subregion2_name = tolower(subregion2_name),
         country_name = "kenya") %>%
  # drop hotspot regions/misc
  filter(!(subregion2_name %in% 
             c("nairobi east", "nairobi north", "nairobi west", "westlands", "waterbodies")
  )) %>%
  # Fix names
  mutate(subregion2_name = 
           ifelse(subregion2_name == "kaijiado central", "kajiado central", 
                  ifelse(subregion2_name == "kaijiado north", "kajiado north",
                         ifelse(subregion2_name == "kilindini", "mombasa",
                                subregion2_name)))) %>%
  # aggregate cases for mombasa/kilindini
  group_by(country_name, subregion2_name, date) %>%
  dplyr::summarize(num_cases = sum(num_cases)) %>%
  ungroup()

# If dropping mombasa
df_final <- df_final %>%
  filter(subregion2_name != "mombasa")

df_final <- left_join(df_final, migrants, by = "subregion2_name")

# This should have 0 obs
df_final %>%
  filter(is.na(migrants)) %>%
  nrow()

write_dta(df_final, paste0(dirpath_int_covid, "/cleaned_kenya_covid_data.dta"))

