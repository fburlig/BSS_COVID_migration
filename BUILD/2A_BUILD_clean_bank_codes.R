# Set working directory
setwd("[YOUR DIRECTORY PATH HERE]")

# Input: Bankcode-pincode crosswalk for updated and original bank codes. 
# Output: Cleaned bank codes with pincodes. "Remaining" bank codes do not contain
# ifsc-branch code crosswalks to update ifsc codes


rm(list=ls())

# Load packages
library(tidyverse)
library(readxl)
library(readr)

# Initialize directories
input_dir <- "./data/Raw/Banks/"
output_dir1 <- "./data/Generated/Intermediate/Banks/SolID_pin/"
output_dir2 <- "./data/Generated/Intermediate/Banks/Remit_matched/"

# Load data
baroda <- read_csv(paste0(input_dir, "baroda_raw.csv"))
punjab <- read_excel(paste0(input_dir, "punjab_raw.xlsx"))
united <- read_excel(paste0(input_dir, "united_raw.xlsx"))
multibank <- read_csv(paste0(input_dir, "multibank_raw.csv"))
union_matched <- read_csv(paste0(input_dir, "union_raw_pincodes.csv"))  # For pincodes
union_unmatched <- read_excel(paste0(input_dir, "union_raw_solid.xlsx")) %>%
  filter(row_number() > 2) # For sol IDs

remaining <- read_csv(paste0(input_dir, "remaining_banks_raw.csv"))

## Clean data

# Bank of Baroda
baroda_cleaned <- baroda %>%
  # Drop entries with a missing sol ID as these are not useful for updating bank codes
  filter(sol_id != 0) %>%
  select(sol_id, ifsc_code, pincode) %>%
  dplyr::rename(ifsc_updt = ifsc_code, pin_rec_updt = pincode) %>%
  group_by(sol_id) %>%
  dplyr::mutate(id = row_number()) %>%
  # Remove duplicate sol IDs
  filter(id == 1) %>%
  ungroup() %>%
  select(-id) %>%
  dplyr::rename(solID_fixed = sol_id)

write_csv(baroda_cleaned, paste0(output_dir1, "baroda_solID_pin.csv"))

# Punjab Bank
punjab_cleaned <- punjab %>%
  select(SolID, IFSC, ADDRESS, PIN) %>%
  # Drop missing sol IDs
  filter(!is.na(SolID)) %>%
  # Add leading 0s to sol IDs
  mutate(solID_fixed = ifelse(nchar(SolID) == 1, paste0("000", SolID),
                              ifelse(nchar(SolID) == 2, paste0("00", SolID),
                                     ifelse(nchar(SolID) == 3, paste0("0", SolID),
                                            SolID))),
         PIN = as.character(PIN)) %>%
  select(solID_fixed, PIN, IFSC) %>%
  dplyr::rename(pin_rec_updt = PIN, ifsc_updt = IFSC) %>%
  group_by(solID_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  # Select unique sol IDs. For the 3 duplicate entries, the pincodes are identical or sufficiently
  # close to choose one at random
  filter(id == 1) %>%
  ungroup() %>%
  select(-id)

write_csv(punjab_cleaned, paste0(output_dir1, "punjab_solID_pin.csv"))

# United bank
united_cleaned <- united %>%
  dplyr::rename("solID" = 'SOL ID', "pin_rec_updt" = "Pin Code") %>%
  # Add leading 0s to solid
  mutate(solID_fixed = ifelse(nchar(solID) == 1, paste0("000", solID),
                              ifelse(nchar(solID) == 2, paste0("00", solID),
                                     ifelse(nchar(solID) == 3, paste0("0", solID),
                                            solID))),
         pin_rec_updt = as.character(pin_rec_updt)) %>%
  group_by(solID_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  # Select unique sol IDs. Duplicates are sufficiently close geographically
  filter(id == 1) %>%
  ungroup() %>%
  select(solID_fixed, pin_rec_updt)

write_csv(united_cleaned, paste0(output_dir1, "united_solID_pin.csv"))

# Several banks
multibank_cleaned <- multibank %>%
  filter(row_number() != 1) %>%
  dplyr::rename(ifsc_updt = ifsc_input, pin_rec_updt = pincode) %>%
  group_by(ifsc_updt) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1, pin_rec_updt != "ERROR") %>%
  select(ifsc_updt, pin_rec_updt)

write_csv(multibank_cleaned, paste0(output_dir1, "multibank_ifsc_updt_pin.csv"))

## Union bank
# Geocoded data
union_matched_cleaned <- union_matched %>%
  filter(row_number() != 1) %>%
  dplyr::rename(ifsc_updt = ifsc_input, pin_rec_updt = pincode) %>%
  group_by(ifsc_updt) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  select(ifsc_updt, pin_rec_updt) %>%
  mutate_at("pin_rec_updt", as.character)

write_csv(union_matched_cleaned, paste0(output_dir1, "union_ifsc_updt_pin.csv"))

# SolIDand branch information
names(union_unmatched) <- union_unmatched[1, ]
union_unmatched_cleaned <- union_unmatched %>%
  dplyr::rename(branch_code_pdf = 'Branch Code', solID_fixed = 'Sol ID') %>%
  filter(row_number() > 1) %>%
  mutate_at(.vars = c("solID_fixed", "branch_code_pdf"), as.numeric) %>%
  mutate_at(.vars = c("solID_fixed", "branch_code_pdf"), as.character) %>%
  select(solID_fixed, branch_code_pdf) %>%
  filter(!is.na(branch_code_pdf)) %>%
  group_by(solID_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  ungroup() %>%
  select(-id)

write_csv(union_unmatched_cleaned, paste0(output_dir1, "union_solID_branchcode.csv"))

# Non-updated banks
remaining_cleaned <- remaining %>%
  filter(row_number() != 1) %>%
  # These bank codes are not used to update existing ifscs and are therefore 
  # given the label orig. Even if some of the banks are able to be updated, 
  # for example United, they were missing from the United-solID crosswalk and 
  # can therefore not be updated
  dplyr::rename(ifsc_orig = ifsc_input, pin_rec_orig = pincode) %>%
  group_by(ifsc_orig) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  select(ifsc_orig, pin_rec_orig) %>%
  mutate_at("pin_rec_orig", as.character)

write_csv(remaining_cleaned, paste0(output_dir2, "remaining_ifsc_orig_pin.csv"))


