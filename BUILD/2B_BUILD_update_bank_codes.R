# Set working directory
setwd("[YOUR DIRECTORY PATH HERE]")

# Input: Cleaned bankcode-pincode crosswalk for updated bank codes and 
# transaction-level remittances data
# Output: transaction-level remittances datasets with updated ifsc codes and 
# recipient locations

rm(list=ls())

# Load packages
library(tidyverse)
library(readxl)
library(readr)

# Initialize directories
bank_dir <- "./data/Generated/Intermediate/Banks/SolID_pin/"
remit_dir <- "./data/Raw/remittances/"
output_dir <- "./data/Generated/Intermediate/Banks/Remit_matched/"

# Load data
remit <- read_csv(paste0(remit_dir, "remittance_loactions_Apr2019_2020_v5.csv")) %>%
  mutate(ifsc = toupper(ifsc),
         branch_codes_fixed = str_sub(x_branch_codes, 3, 7)) %>%
  dplyr::rename(remitID = X1, ifsc_orig = ifsc)

baroda <- read_csv(paste0(bank_dir, "baroda_solID_pin.csv"))
punjab <- read_csv(paste0(bank_dir, "punjab_solID_pin.csv"))
united <- read_csv(paste0(bank_dir, "united_solID_pin.csv"))
union_sol_id <- read_csv(paste0(bank_dir, "union_solID_branchcode.csv"))
union_pin <- read_csv(paste0(bank_dir, "union_ifsc_updt_pin.csv"))
multibank <- read_csv(paste0(bank_dir, "multibank_ifsc_updt_pin.csv"))

## Join bank data onto remittances
# Baroda
# Join first 4 branch code with first 4 solID
remit_baroda <- remit %>%
  filter(str_sub(ifsc_orig, 1, 4) == "BARB") %>%
  mutate(branch_code_1st4 = str_sub(branch_codes_fixed, 1, 4)) %>%
  group_by(ifsc_orig, branch_codes_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  ungroup() %>%
  select(ifsc_orig, branch_code_1st4, branch_codes_fixed)

remit_baroda_join <- left_join(remit_baroda, baroda, 
                               by = c("branch_code_1st4" = "solID_fixed")) %>%
  select(-branch_code_1st4)

write_csv(remit_baroda_join, paste0(output_dir, "baroda_remit.csv"))

# Punjab
# Join first 4 branch code with first 4 solID
remit_punjab <- remit %>%
  filter(str_sub(ifsc_orig, 1, 4) == "PUNB") %>%
  mutate(branch_code_1st4 = str_sub(branch_codes_fixed, 1, 4)) %>%
  group_by(ifsc_orig, branch_codes_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  ungroup() %>%
  select(ifsc_orig, branch_code_1st4, branch_codes_fixed) 

remit_punjab_join <- left_join(remit_punjab, punjab, 
                               by = c("branch_code_1st4" = "solID_fixed")) %>%
  select(-branch_code_1st4)

write_csv(remit_punjab_join, paste0(output_dir, "punjab_remit.csv"))

# United
# Join first 4 branch code with first 4 solID
remit_united <- remit %>%
  filter(str_sub(ifsc_orig, 1, 4) == "UTBI") %>%
  mutate(branch_code_1st4 = str_sub(branch_codes_fixed, 1, 4)) %>%
  group_by(ifsc_orig, branch_codes_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  ungroup() %>%
  select(ifsc_orig, branch_code_1st4, branch_codes_fixed)

remit_united_join <- left_join(remit_united, united, 
                               by = c("branch_code_1st4" = "solID_fixed")) %>%
  select(-branch_code_1st4)

write_csv(remit_united_join, paste0(output_dir, "united_remit.csv"))

# Union
remit_union <- remit %>%
  filter(str_sub(ifsc_orig, 1, 4) == "UBIN") %>%
  group_by(ifsc_orig, branch_codes_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  ungroup() %>%
  select(ifsc_orig, branch_codes_fixed) 

union_sol_id <- union_sol_id %>%
  mutate_at(.vars = c("solID_fixed", "branch_code_pdf"), as.character)

remit_union_join <- left_join(remit_union, union_sol_id, 
                              by = c("branch_codes_fixed" = "solID_fixed")) %>%
  mutate(ifsc_updt = ifelse(!is.na(branch_code_pdf), 
                            paste0(str_sub(ifsc_orig, 1, 4), "0", branch_code_pdf), NA)) %>%
  select(ifsc_orig, branch_codes_fixed, ifsc_updt)

# Join on pincodes
remit_union_join_pin <- left_join(remit_union_join, union_pin, 
                                  by = "ifsc_updt")

write_csv(remit_union_join_pin, paste0(output_dir, "union_remit.csv"))

# Multibank
multbnk_list_first4 <- c("ANDB", "BKID", "CNRB", "CORP", "IOBA")

remit_multbnk <- remit %>%
  mutate(ifsc_1st4 = str_sub(ifsc_orig, 1, 4)) %>%
  filter((ifsc_1st4 %in% multbnk_list_first4) | ifsc_1st4 == "TMBL") %>%
  mutate(ifsc_updt = ifelse(ifsc_1st4 == "TMBL", 
                            paste0(str_sub(ifsc_orig, 1, 8), str_sub(branch_codes_fixed, 1, 3)),
                            paste0(str_sub(ifsc_orig, 1, 7), str_sub(branch_codes_fixed, 1, 4)))) %>%
  group_by(ifsc_orig, branch_codes_fixed) %>%
  dplyr::mutate(id = row_number()) %>%
  filter(id == 1) %>%
  ungroup() %>%
  select(ifsc_orig, ifsc_updt, branch_codes_fixed)

remit_multibank_join <- left_join(remit_multbnk, multibank, by = "ifsc_updt")

write_csv(remit_multibank_join, paste0(output_dir, "multibank_remit.csv"))

