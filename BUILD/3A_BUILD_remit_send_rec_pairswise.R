# Set working directory
setwd("[YOUR DIRECTORY PATH HERE]")

# Input: Geocoded recipient bank locations and transaction-level remittances (senders) datasets
# Output: transaction-level sender-receiver remittances 

##########################
rm(list=ls())

# Load packages
library(sf)
library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tidyr)
library(plyr)
library(nngeo)
library(rlist)

# Initialize directories
remit_dir <- "./data/Raw/remittances/"
bank_dir <- "./data/Generated/Intermediate/Banks/Geocoded/"
shp_dir <- "./data/Generated/Intermediate/Shapefiles/"
output_dir <- "./data/Generated/Intermediate/Remittances/"

dist <- st_read(paste0(shp_dir,
                       "districts/aggregated/",
                       "districts_delhiagg.shp")) %>%
  dplyr::mutate_at("dtname", toupper)

vlg <- st_read(paste0(shp_dir, "villages/combined/","villages.shp")) %>%
  select(LEVEL, TOT_P)

# Calculate district centroids
dist_cent <- st_centroid(dist) %>%
  as.data.frame() %>%
  mutate(geometry = str_replace_all(geometry,
                                    c("POINT" = "",
                                      "\\(" = "",
                                      "\\)" = "",
                                      "c" = ""))) %>%
  separate(col = geometry, into = c("lon_dist_cent", "lat_dist_cent"), sep = ",") %>%
  mutate(lon_dist_cent = as.numeric(lon_dist_cent),
         lat_dist_cent = as.numeric(lat_dist_cent)) %>%
  select(JID, lon_dist_cent, lat_dist_cent)

#########################################################
# Match sending locations to a district, classify them as rural or urban based on
# their pincode centroid
remit <- read_csv(paste0(remit_dir, "remittance_loactions_Apr2019_2020_v5.csv")) %>%
  mutate(ifsc = toupper(ifsc)) %>%
  dplyr::rename(remitID = X1, lon_send = longitude, lat_send = latitude) %>%
  select(-c(branch_codes, leading_digit))

# Add group id for unique lat/lon pairs
remit$latlon_group <- dplyr::group_indices(remit, .dots=c("lon_send", "lat_send"))

# Observations without a legit lat/lon
remit_ngeo <- remit %>%
  filter(is.na(lon_send) | is.na(lat_send) | lon_send == 0 | lat_send == 0)

# Observations with a potentially legit lat/lon
remit_geo <- remit %>%
  filter(!is.na(lon_send), !is.na(lat_send), lon_send != 0, lat_send != 0)

# Select distinct lat/lon pairs, make into spatial data frame
remit_sf <- remit_geo %>%
  distinct(lon_send, lat_send, latlon_group) %>%
  st_as_sf(coords = c("lon_send", "lat_send")) %>%
  st_set_crs("WGS84")

# Delete original remittances dataset to save space
rm(remit)

# Match sender locations to a district and state
remit_dist <- st_join(remit_sf, dist, join = st_intersects) %>%
  as.data.frame() %>%
  dplyr::rename(dtname_send = dtname, stname_send = stname,
                JID_send = JID) %>%
  select(-geometry)

# Add district centroids for shiny map
remit_dist_cent <- left_join(remit_dist, dist_cent, 
                             by = c("JID_send" = "JID")) %>%
  dplyr::rename(lon_dist_cent_send = lon_dist_cent,
                lat_dist_cent_send = lat_dist_cent)

# Join these distinct sender lat/lon district/state matches back onto the full
# set of sender data
remit_geo <- left_join(remit_geo, remit_dist_cent,
                       by = "latlon_group")

# Add population of nearest town from 2001 village shapefile
remit_vlg <- st_join(remit_sf, vlg, join = st_intersects) %>%
  as.data.frame() %>%
  select(-geometry) %>%
  mutate(Rural = ifelse((LEVEL == "VILLAGE" | LEVEL == "COMMUNUE PANCHAYAT") & 
                          !is.na(LEVEL), 1, 0)) %>%  
  arrange(latlon_group, 
          match(LEVEL, c("TOWN", "TEHSIL", "TALUK", "COMMUNUE PANCHAYAT", "VILLAGE",  "NA"))
  ) %>%
  group_by(latlon_group) %>%
  dplyr::mutate(row_number = row_number()) %>%
  filter(row_number == 1) %>%
  ungroup() %>%
  select(-c(row_number, LEVEL)) %>%
  dplyr::rename(TOT_P_send = TOT_P, Rural_send = Rural)

remit_geo <- left_join(remit_geo, remit_vlg,
                       by = "latlon_group")

# Add back senders that did not have a lat/lon
remit_cleaned <- rbind.fill(remit_geo, remit_ngeo) %>%
  dplyr::rename(ifsc_orig = ifsc) %>%
  select(-latlon_group)

# Remove unneeded datasets
rm(remit_geo, remit_ngeo, remit_sf, remit_dist, remit_dist_cent, remit_vlg)

################################################################################
## Joining on ifsc_orig (non-updated banks, used only when couldn't update bank
# code or for when an IFSC was manually entered)
#################################################################################

# Load non-updated bank data
orig <- read_csv(paste0(bank_dir, "remaining_banks_pin_cent.csv"))

# Add group id for unique lat/lon pairs
orig$latlon_group <- dplyr::group_indices(orig, 
                                          .dots=c("lon_pin_cent_rec_orig", 
                                                  "lat_pin_cent_rec_orig"))

# Observations without a lat/lon
orig_ngeo <- orig %>%
  filter(is.na(lon_pin_cent_rec_orig) | is.na(lat_pin_cent_rec_orig) |
           lon_pin_cent_rec_orig == 0  | lat_pin_cent_rec_orig == 0)

# Observations with a lat/lon
orig_geo <- orig %>%
  filter(!is.na(lon_pin_cent_rec_orig), !is.na(lat_pin_cent_rec_orig),
         lon_pin_cent_rec_orig != 0, lat_pin_cent_rec_orig != 0)

# Make distinct pincode centroid lat/lon pairs into a spatial data frame
orig_sf <- orig_geo %>%
  distinct(lon_pin_cent_rec_orig, lat_pin_cent_rec_orig, latlon_group) %>%
  st_as_sf(coords = c("lon_pin_cent_rec_orig", "lat_pin_cent_rec_orig")) %>%
  st_set_crs("WGS84")

# Match each pincode centroid onto a district/state
orig_dist <- st_join(orig_sf, dist, join = st_intersects) %>%
  as.data.frame() %>%
  dplyr::rename(dtname_rec_orig = dtname, stname_rec_orig = stname,
                JID_rec_orig = JID) %>%
  select(-geometry)

# Add district centroids for shiny map
orig_dist_cent <- left_join(orig_dist, dist_cent, 
                            by = c("JID_rec_orig" = "JID")) %>%
  dplyr::rename(lon_dist_cent_rec_orig = lon_dist_cent,
                lat_dist_cent_rec_orig = lat_dist_cent)

# Match pincode centroids onto a village to get urban/rural classification
orig_vlg <- st_join(orig_sf, vlg, join = st_intersects) %>%
  as.data.frame() %>%
  select(-geometry) %>%
  # Rural iff level == village
  mutate(Rural = ifelse((LEVEL == "VILLAGE" | LEVEL == "COMMUNUE PANCHAYAT") & !is.na(LEVEL), 1, 0)) %>%  
  arrange(latlon_group, 
          match(LEVEL, c("TOWN", "TEHSIL", "TALUK", "COMMUNUE PANCHAYAT", "VILLAGE",  "NA"))
  ) %>%
  group_by(latlon_group) %>%
  dplyr::mutate(row_number = row_number()) %>%
  filter(row_number == 1) %>%
  ungroup() %>%
  select(-row_number) %>%
  dplyr::rename(TOT_P_rec_orig = TOT_P, Rural_rec_orig = Rural)

# Join district and vlg matches by lat/lon
orig_dist_cent_vlg <- left_join(orig_dist_cent, orig_vlg, 
                                by = "latlon_group")

# Match district/village info back onto full lat/lon bank dataset
orig_geo <- left_join(orig_geo, orig_dist_cent_vlg,
                      by = "latlon_group")

# Add bank data without a lat/lon
orig_cleaned <- rbind.fill(orig_geo, orig_ngeo)

# Select only necessary variables
orig_cleaned <- orig_cleaned %>%
  select(-c(LEVEL, pin_rec_orig, latlon_group,
            lon_pin_cent_rec_orig, lat_pin_cent_rec_orig))

# Remove intermediary dfs to save space
rm(orig, orig_dist, orig_dist_cent, orig_dist_cent_vlg, 
   orig_geo, orig_ngeo, orig_sf, orig_vlg)

#################################################################################
## Repeat above but for updated bank codes (preferred over non-updated ones and
# manually entered IFSC's)
#################################################################################

# Load updated bank codes
updt <- read_csv(paste0(bank_dir, "updated_banks_pin_cent.csv")) %>%
  mutate(x_branch_codes = paste("x", as.character(branch_codes_fixed), 
                                sep = "_")) %>%
  select(-branch_codes_fixed)

# Add group id for unique lat/lon pairs
updt$latlon_group <- dplyr::group_indices(updt, 
                                          .dots=c("lon_pin_cent_rec_updt", 
                                                  "lat_pin_cent_rec_updt"))

# Separate into with/without lat/lon pairs
updt_ngeo <- updt %>%
  filter(is.na(lon_pin_cent_rec_updt) | is.na(lat_pin_cent_rec_updt) |
           lon_pin_cent_rec_updt == 0 | lat_pin_cent_rec_updt == 0)

updt_geo <- updt %>%
  filter(!is.na(lon_pin_cent_rec_updt), !is.na(lat_pin_cent_rec_updt),
         lon_pin_cent_rec_updt != 0, lat_pin_cent_rec_updt != 0)

# Select unique lat/lon pairs for matching
updt_sf <- updt_geo %>%
  distinct(latlon_group, lon_pin_cent_rec_updt, lat_pin_cent_rec_updt) %>%
  st_as_sf(coords = c("lon_pin_cent_rec_updt", "lat_pin_cent_rec_updt")) %>%
  st_set_crs("WGS84")

# Match onto districts
updt_dist <- st_join(updt_sf, dist, join = st_intersects) %>%
  as.data.frame() %>%
  dplyr::rename(dtname_rec_updt = dtname, stname_rec_updt = stname,
                JID_rec_updt = JID) %>%
  select(-geometry)

# Add district centroids
updt_dist_cent <- left_join(updt_dist, dist_cent, 
                            by = c("JID_rec_updt" = "JID")) %>%
  dplyr::rename(lon_dist_cent_rec_updt = lon_dist_cent,
                lat_dist_cent_rec_updt = lat_dist_cent)

# Match onto villages shapefile for urban/rural classification
updt_vlg <- st_join(updt_sf, vlg, join = st_intersects) %>%
  as.data.frame() %>%
  select(-geometry) %>%
  mutate(Rural = ifelse((LEVEL == "VILLAGE" | LEVEL == "COMMUNUE PANCHAYAT") & !is.na(LEVEL), 1, 0)) %>%  
  arrange(latlon_group, 
          match(LEVEL, c("TOWN", "TEHSIL", "TALUK", "COMMUNUE PANCHAYAT", "VILLAGE",  "NA"))
  ) %>%
  group_by(latlon_group) %>%
  dplyr::mutate(row_number = row_number()) %>%
  filter(row_number == 1) %>%
  ungroup() %>%
  select(-row_number) %>%
  dplyr::rename(TOT_P_rec_updt = TOT_P, Rural_rec_updt = Rural)

# Join district and vlg matches by lat/lon
updt_dist_cent_vlg <- left_join(updt_dist_cent, updt_vlg, 
                                by = "latlon_group")

# Match district/village info back onto full lat/lon bank dataset
updt_geo <- left_join(updt_geo, updt_dist_cent_vlg,
                      by = "latlon_group")

# Add bank data without a lat/lon
updt_cleaned <- rbind.fill(updt_geo, updt_ngeo)

# Remove intermediary dfs to save space
rm(updt, updt_dist, updt_dist_cent, updt_dist_cent_vlg, 
   updt_geo, updt_ngeo, updt_sf, updt_vlg)

# Select only necessary variables
updt_cleaned <- updt_cleaned %>%
  select(-c(pin_rec_updt, lon_pin_cent_rec_updt, lat_pin_cent_rec_updt,
            LEVEL, latlon_group))

rm(dist, dist_cent, pincodes, vlg)

# Create sender-receiver pair dataset, choosing updated bank codes over
# non-updated ones where possible
################################################################################

# Add non-updated bank codes
remit_cleaned <- left_join(remit_cleaned, orig_cleaned, 
                           by = "ifsc_orig")
# Add updated bank codes
remit_cleaned <- left_join(remit_cleaned, updt_cleaned, 
                           by = c("ifsc_orig", "x_branch_codes"))

# Remove unneeded data frames
rm(orig_cleaned, updt_cleaned)

# List of updated bank codes
bank_code_translated_list <- c("ANDB", "BKID", "CNRB", "CORP", "IOBA", "TMBL", "BARB",
                               "UTBI", "PUNB", "UBIN")

# List of bank codes with usable geographic information contained in their 
# automatically generated IFSCs
bank_code_usable_list <- c("ALLA", "ANDB", "ASBL", "BARB", "BCBM", "BKDN", "BKID", "CBIN", "CNRB", "CORP",
                           "COSB", "CSBK", "DCBL", "DNSB", "FDRL", "ICIC", "IDIB", "IOBA", "KAIJ", "KARB",
                           "KKBK", "KLGB", "KUCB", "KVBL", "LAVB", "MAHB", "MSNU", "NKGS", "PKGB", "PSIB",
                           "PUNB", "SIBL", "SRCB", "SVCB", "TJSB", "UBIN", "UCBA", "UTBI", "UTIB", "YESB")

# Top 7 manually entered IFSC codes
top_7_manual_only_ifsc_list <- c("SBIN0RRPUGB", "CBIN0R10001", "SBIN0009062",
                                 "PYTM0123456", "MAHB0000001", "SBIN0000001",
                                 "UCBA0000002")

# Add indicators for preferred/updated/original IFSC-based information
remit_cleaned <- remit_cleaned %>%
  mutate(is_geocoded_send = ifelse(!is.na(lon_send) & !is.na(lat_send) & 
                                     !is.na(dtname_send), 1, 0),
         is_geocoded_rec_orig = ifelse(!is.na(dtname_rec_orig), 1, 0),
         is_geocoded_rec_updt = ifelse(!is.na(dtname_rec_updt), 1, 0),
         bank_code_translated = ifelse(str_sub(ifsc_orig, 1, 4) %in% bank_code_translated_list, 1, 0),
         bank_code_usable = ifelse(str_sub(ifsc_orig, 1, 4) %in% bank_code_usable_list, 1, 0),
         transfer_ok_to_use = ifelse(ifsc_manual == 1, 1, 
                                     ifelse(bank_code_translated == 1 & bank_code_usable == 1, 
                                            1, 0)),
         ifsc = ifelse(is_geocoded_rec_updt == 1, ifsc_updt, ifsc_orig),
         dtname_rec = ifelse(is_geocoded_rec_updt == 1, dtname_rec_updt, dtname_rec_orig),
         stname_rec = ifelse(is_geocoded_rec_updt == 1, stname_rec_updt, stname_rec_orig),
         JID_rec = ifelse(is_geocoded_rec_updt == 1, JID_rec_updt, JID_rec_orig),
         TOT_P_rec = ifelse(is_geocoded_rec_updt == 1, TOT_P_rec_updt, TOT_P_rec_orig),
         Rural_rec = ifelse(is_geocoded_rec_updt == 1, Rural_rec_updt, Rural_rec_orig),
         lon_dist_cent_rec = ifelse(is_geocoded_rec_updt == 1, 
                                    lon_dist_cent_rec_updt, lon_dist_cent_rec_orig),
         lat_dist_cent_rec = ifelse(is_geocoded_rec_updt == 1, 
                                    lat_dist_cent_rec_updt, lat_dist_cent_rec_orig),
         is_geocoded_rec = ifelse(!is.na(dtname_rec), 1, 0),
         is_geocoded_send_rec = ifelse(is_geocoded_rec == 1 & is_geocoded_send == 1, 1, 0),
         top_7_manual_only_ifsc = ifelse(ifsc %in% top_7_manual_only_ifsc_list,
                                         1, 0)) %>%
  # Remove intermediate variables
  select(-ends_with(c("orig", "updt"))) %>%
  # Remove unnecessary variables
  select(-c(is_geocoded_send, is_geocoded_rec, x_branch_codes, ifsc))

write_csv(remit_cleaned, paste0(output_dir, "remittances_send_rec_locations.csv"))

