
# Extract populations from WorldPop's constrained individual countries 
# 2020 (100m resolution) rasters

###################################################################
# Load packages
###################################################################
remove(list=ls()) 

setwd("[YOUR DIRECTORY PATH HERE]")

library(raster)
library(sf)
library(readr)
library(rgdal)
library(exactextractr)
library(haven)
library(dplyr)
library(plyr)

dirpath_data <- "./data"
dirpath_raw <- paste0(dirpath_data, "/raw")
dirpath_raw_shp <- paste0(dirpath_raw, "/shapefiles")
dirpath_raw_shp_nonindia <- paste0(dirpath_raw_shp, "/non india")
dirpath_raw_rasters <- paste0(dirpath_raw, "/rasters")
dirpath_raw_rasters_worldpop <- paste0(dirpath_raw_rasters, "/world pop")
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_int <- paste0(dirpath_gen, "/intermediate")
dirpath_int_worldpop <- paste0(dirpath_int, "/World pop")

###################################################################
# Indonesia
###################################################################
# Load WP raster from https://www.worldpop.org/geodata/summary?id=49726
ID_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/idn_ppp_2020_constrained.tif"))

# Load admin 1 shapefile from https://data.humdata.org/dataset/indonesia-administrative-boundary-polygons-lines-and-places-levels-0-4b
# idn_adm_bps_20200401_SHP.zip
ID_shp <- st_read(paste0(dirpath_raw_shp_nonindia, "/indonesia/idn_admbnda_adm1_bps_20200401.shp")) %>%
  dplyr::select(ADM0_EN, ADM1_EN, geometry) %>%
  dplyr::rename(country_name = ADM0_EN,
                subregion1_name = ADM1_EN)

# Extract population at admin 1:
# sum of population in each raster cell weighted by coverage fraction
ID_pop <- exact_extract(ID_wp, ID_shp, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(ID_wp)

# Add population to shapefile
ID_shp$population <- ID_pop

# Convert to data frame
ID_df <- ID_shp %>% 
  as.data.frame() %>% 
  dplyr::select(-geometry)

###################################################################
# Kenya
###################################################################

# Load WP raster from https://www.worldpop.org/geodata/summary?id=49643
KY_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/ken_ppp_2020_constrained.tif"))

# Load admin 1 shapefile from https://data.humdata.org/dataset/ken-administrative-boundaries
# ken_adm_iebc_20191031_SHP.zip
KY_shp <- st_read(paste0(dirpath_raw_shp_nonindia, "/kenya/adm1/ken_admbnda_adm1_iebc_20191031.shp")) %>%
  dplyr::select(ADM0_EN, ADM1_EN, geometry) %>%
  dplyr::rename(country_name = ADM0_EN,
                subregion1_name = ADM1_EN)

# Extract population at admin 1:
# sum of population in each raster cell weighted by coverage fraction
KY_pop <- exact_extract(KY_wp, KY_shp, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(KY_wp)

# Add population to shapefile
KY_shp$population <- KY_pop

# Convert to data frame
KY_df <- KY_shp %>% 
  as.data.frame() %>% 
  dplyr::select(-geometry)

###################################################################
# South Africa
###################################################################

# Load WP raster from https://www.worldpop.org/geodata/summary?id=49663
ZA_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/zaf_ppp_2020_constrained.tif"))

# Load admin 2 shapefile from https://data.humdata.org/dataset/south-africa-admin-level-1-boundaries
# zaf_adm_sadb_ocha_20201109_SHP.zip
ZA_shp <- st_read(paste0(dirpath_raw_shp_nonindia, "/South Africa/zaf_admbnda_adm2_sadb_ocha_20201109.shp")) %>%
  dplyr::select(ADM0_EN, ADM1_EN, ADM2_EN, geometry) %>%
  dplyr::rename(country_name = ADM0_EN,
                subregion1_name = ADM1_EN,
                subregion2_name = ADM2_EN)

# Extract population at admin 2:
# sum of population in each raster cell weighted by coverage fraction
ZA_pop <- exact_extract(ZA_wp, ZA_shp, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(ZA_wp)

# Add population to shapefile
ZA_shp$population <- ZA_pop

# Convert to data frame
ZA_df <- ZA_shp %>% 
  as.data.frame() %>% 
  dplyr::select(-geometry)

###################################################################
# Philippines
###################################################################

# Load WP raster from https://www.worldpop.org/geodata/summary?id=49861
PH_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/phl_ppp_2020_constrained.tif"))

# Load admin 2 shapefile from https://data.humdata.org/dataset/philippines-administrative-levels-0-to-3
# phl_adm_psa_namria_20200529_SHP.zip
PH_shp <- st_read(paste0(dirpath_raw_shp_nonindia, "/philippines/phl_admbnda_adm2_psa_namria_20200529.shp")) %>%
  dplyr::select(ADM0_EN, ADM1_EN, ADM2_EN, geometry) %>%
  dplyr::rename(country_name = ADM0_EN,
                subregion1_name = ADM1_EN,
                subregion2_name = ADM2_EN)

# Aggregate national capital region
PH_shp <- PH_shp %>%
  dplyr::mutate(ncr = ifelse(subregion1_name == "National Capital Region", 
                1, 0))

PH_shp_no_ncr <- PH_shp %>%
  filter(ncr == 0) %>%
  dplyr::select(-ncr)

PH_shp_ncr <- PH_shp %>%
  filter(ncr == 1) %>%
  dplyr::group_by(country_name, subregion1_name) %>%
  dplyr::summarise(geometry = st_union(geometry)) %>%
  dplyr::ungroup() %>%
  mutate(subregion2_name = "national capital region")

PH_shp <- rbind(PH_shp_no_ncr, PH_shp_ncr)

# Aggregate cotabato city and its province maguindanao
PH_shp_no_cotabato_agg <- PH_shp %>%
  filter(!(subregion2_name %in% c("Cotabato City", "Maguindanao")))

PH_shp_cotabato_agg <- PH_shp %>%
  filter(subregion2_name %in% c("Cotabato City", "Maguindanao")) %>%
  mutate(subregion1_name = "Autonomous Region in Muslim Mindanao",
         subregion2_name = "Maguindanao") %>%
  dplyr::group_by(country_name, subregion1_name, subregion2_name) %>%
  dplyr::summarise(geometry = st_union(geometry)) %>%
  dplyr::ungroup()

PH_shp <- rbind(PH_shp_cotabato_agg, PH_shp_no_cotabato_agg)

# Aggregate isabela city and its province basilan
PH_shp_no_city_isabella_agg <- PH_shp %>%
  filter(!(subregion2_name %in% c("City of Isabela", "Basilan")))

PH_shp_city_isabella_agg <- PH_shp %>%
  filter(subregion2_name %in% c("City of Isabela", "Basilan")) %>%
  mutate(subregion1_name = "Autonomous Region in Muslim Mindanao",
         subregion2_name = "Basilan") %>%
  dplyr::group_by(country_name, subregion1_name, subregion2_name) %>%
  dplyr::summarise(geometry = st_union(geometry)) %>%
  dplyr::ungroup()

PH_shp <- rbind(PH_shp_city_isabella_agg, PH_shp_no_city_isabella_agg)

# Extract population at admin 2:
# sum of population in each raster cell weighted by coverage fraction
PH_pop <- exact_extract(PH_wp, PH_shp, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(PH_wp)

# Add population to shapefile
PH_shp$population <- PH_pop

# Convert to data frame
PH_df <- PH_shp %>% 
  as.data.frame() %>% 
  dplyr::select(-geometry) %>%
  mutate(country_name = "Philippines")

###################################################################
# China
###################################################################

# Load WP raster from https://www.worldpop.org/geodata/summary?id=49730
CN_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/chn_ppp_2020_constrained.tif"))

# Load admin 1 shapefile from https://data.humdata.org/dataset/china-administrative-boundaries
# chn_adm_ocha_2020_SHP.zip
CN_shp <- st_read(paste0(dirpath_raw_shp_nonindia, "/china/chn_admbnda_adm1_ocha_2020.shp")) %>%
  dplyr::select(ADM0_EN, ADM1_EN, geometry) %>%
  dplyr::rename(country_name = ADM0_EN,
                subregion1_name = ADM1_EN) %>%
  filter(!(subregion1_name %in% c("Taiwan Province",
                                  "Hong Kong Special Administrative Region",
                                  "Macao Special Administrative Region")))

# Extract population at admin 1:
# sum of population in each raster cell weighted by coverage fraction
CN_pop <- exact_extract(CN_wp, CN_shp, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(CN_wp)

# Add population to shapefile
CN_shp$population <- CN_pop

# Convert to .data frame
CN_df <- CN_shp %>% 
  as.data.frame() %>% 
  dplyr::select(-geometry)

###################################################################
# India
###################################################################

# Load WP raster from https://www.worldpop.org/geodata/summary?id=49804
IN_wp <- raster(paste0(dirpath_raw_rasters_worldpop, "/ind_ppp_2020_constrained.tif"))

# Load shapefile
# chn_adm_ocha_2020_SHP.zip
IN_shp <- st_read("./Data/Generated/Intermediate/Shapefiles/districts/aggregated/districts_delhiagg.shp") %>%
  dplyr::select(stname, dtname, geometry) %>%
  dplyr::rename(subregion1_name = stname,
                subregion2_name = dtname) %>%
  dplyr::mutate(country_name = "India") %>%
  filter(!(subregion1_name %in% c("LAKSHADWEEP", "ANDAMAN & NICOBAR")),
         !(subregion2_name %in% c("MUZAFFARABAD", "MIRPUR")))

# Aggregate shapefile to match case data
IN_shp <- IN_shp %>%
  mutate(subregion2_name = ifelse(subregion1_name == "TELANGANA", "TELANGANA",
                           ifelse(subregion1_name == "ASSAM", "ASSAM",
                           ifelse(subregion1_name == "GOA", "GOA",
                           ifelse(subregion1_name == "MANIPUR", "MANIPUR",
                           ifelse(subregion1_name == "SIKKIM", "SIKKIM",
                           ifelse(subregion1_name == "DADRA & NAGAR HAVE", "DADRA & NAGAR HAVELI",
                                  subregion2_name)))))),
         subregion1_name = ifelse(subregion1_name == "DADRA & NAGAR HAVE", "DAMAN & DIU",
                                  subregion1_name))

IN_shp <- IN_shp %>%
  dplyr::group_by(country_name, subregion1_name, subregion2_name) %>%
  dplyr::summarise(geometry = st_union(geometry)) %>%
  dplyr::ungroup()

# Extract population:
# sum of population in each raster cell weighted by coverage fraction
IN_pop <- exact_extract(IN_wp, IN_shp, function(values, coverage_fraction)
  sum(values * coverage_fraction, na.rm=TRUE))
rm(IN_wp)

# Add population to shapefile
IN_shp$population <- IN_pop

# Convert to .dta and export
IN_shp %>% 
  as.data.frame() %>% 
  dplyr::select(-geometry) %>%
  mutate_at(.vars = c("country_name", "subregion1_name", "subregion2_name"),
            tolower) %>%
  write_dta(paste0(dirpath_int_worldpop, "/india_worldpop.dta"))

###################################################################
# Stack population datasets for all countries except India
###################################################################

# Stack data frames for each country
country_pops <- plyr::rbind.fill(ID_df, KY_df, ZA_df, PH_df, CN_df) %>%
  mutate_at(.vars = c("country_name", "subregion1_name", "subregion2_name"),
            tolower) %>%
  dplyr::mutate(wp_id = row_number()) %>%
  select(country_name, subregion1_name, subregion2_name, population, wp_id)

# Output
write_dta(country_pops, paste0(dirpath_int_worldpop, "/non_india_worldpop.dta"))

