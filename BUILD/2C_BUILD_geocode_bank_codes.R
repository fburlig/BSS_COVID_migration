# Set working directory
setwd("[YOUR DIRECTORY PATH HERE]")

# Input: Bankcode-pincode crosswalk for updated and original bank codes
# Output: pincode-centroid geocoded bank codes
#

rm(list=ls())

# Load packages
library(tidyverse)
library(readr)
library(sf)
library(plyr)

# Initialize directories
bank_dir <- "./data/Generated/Intermediate/Banks/Remit_matched/"
pincode_dir <- "./data/Raw/Shapefiles/Pincodes/"
output_dir <- "./data/Generated/Intermediate/Banks/Geocoded/"

# Load data
baroda <- read_csv(paste0(bank_dir, "baroda_remit.csv"))
punjab <- read_csv(paste0(bank_dir, "punjab_remit.csv"))
united <- read_csv(paste0(bank_dir, "united_remit.csv"))
union <- read_csv(paste0(bank_dir, "union_remit.csv"))
multibank <- read_csv(paste0(bank_dir, "multibank_remit.csv"))
remaining <- read_csv(paste0(bank_dir, "remaining_ifsc_orig_pin.csv")) %>%
  mutate_at("pin_rec_orig", as.character)

pincodes_shp <- st_read(paste0(pincode_dir, "india_pincodes.shp")) %>%
  select(pincode)

# Stack data for updated bank codes (all but remaining), to be merged onto remit
# by ifsc_orig and branch_codes_fixed
updt_banks <- rbind.fill(baroda, punjab, united, union, multibank)

# Calculate pincode centroids
pincode_cent <- st_centroid(pincodes_shp) %>%
  as.data.frame() %>%
  mutate(geometry = str_replace_all(geometry,
                                    c("POINT" = "",
                                      "\\(" = "",
                                      "\\)" = "",
                                      "c" = ""))) %>%
  separate(col = geometry, into = c("lon_pin_cent", "lat_pin_cent"), sep = ",") %>%
  mutate_at(c("lon_pin_cent", "lat_pin_cent"), as.numeric)
  

# Join pincode centroids onto data
updt_banks_pin_cent <- left_join(updt_banks, pincode_cent, 
                                 by = c("pin_rec_updt" = "pincode")) %>%
  dplyr::rename(lon_pin_cent_rec_updt = lon_pin_cent,
                lat_pin_cent_rec_updt = lat_pin_cent)

write_csv(updt_banks_pin_cent, paste0(output_dir, "updated_banks_pin_cent.csv"))

remaining_pin_cent <- left_join(remaining, pincode_cent, 
                                by = c("pin_rec_orig" = "pincode")) %>%
  dplyr::rename(lon_pin_cent_rec_orig = lon_pin_cent,
                lat_pin_cent_rec_orig = lat_pin_cent)

write_csv(remaining_pin_cent, paste0(output_dir, "remaining_banks_pin_cent.csv"))

