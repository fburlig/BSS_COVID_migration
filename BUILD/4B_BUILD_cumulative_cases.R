# Reformat the covid19india json cumulative cases
setwd("[YOUR DIRECTORY PATH HERE]")

library(rjson)
library(dplyr)
library(jsonlite)
library(tidyverse)
library(readxl)
library(haven)
library(lubridate)

rm(list=ls())

path_in_raw <- "./data/Raw/covid/"
path_stateabv <- "./data/Raw/misc/"

data_raw <- read_csv(paste0(path_in_raw, "covid19india_raw_oct1_json_to_csv.csv"))

data_raw <- data_raw %>%
  mutate(name = str_replace(name, "Y.S.R. Kadapa", "Kadapa")) %>%
  mutate(name = str_replace(name, "S.P.S. Nellore", "Nellore")) %>%
  mutate(name = str_replace(name, "S.A.S. Nagar", "SAS"))

rgx_split <- "\\."
n_cols_max <-
  data_raw %>%
  pull(name) %>% 
  str_split(rgx_split) %>% 
  map_dbl(~length(.)) %>% 
  max()

# Number of columns to separate data into
nms_sep <- paste0("name", 1:n_cols_max)

# Separate data for all but Manipur, Assam, and Goa
data_sep <- data_raw %>% 
  separate(name, into = nms_sep, sep = rgx_split, fill = "right") %>%
  filter(
    !(name2 %in% c("DL", "TG", "GA", "MN", "AS", "AN", "SK")),
    name3 == "districts",
    name4 != "Unknown",
    name5 %in% c("total", "delta"),
    name6 == "confirmed",
  ) %>%
  dplyr::rename(date = name1, state = name2, 
                district = name4, daily_cum = name5) %>%
  select(-c(name6, name7)) %>%
  spread(daily_cum, value, fill = 0) %>%
  select(date, state, district, delta, total) %>%
  arrange(date, state, district)

state_abv <- read_excel(paste0(path_stateabv, "state_abbreviations.xlsx"))

# Add state names to separated data, fix a few district names
data_sep <- left_join(data_sep, state_abv, by = "state") %>%
  select(date, name, district, delta, total) %>%
  dplyr::rename(state = name) %>%
  dplyr::mutate_at(c("state", "district"), toupper) %>%
  dplyr::mutate(state = ifelse(state == "JAMMU AND KASHMIR", "JAMMU & KASHMIR",
                               ifelse(state == "ORISSA", "ODISHA",
                                      ifelse(state == "PONDICHERRY", "PUDUCHERRY",
                                             state)))) %>%
  mutate(state = ifelse(district %in% c("DAMAN", "DIU", "DADRA AND NAGAR HAVELI"), 
                        "DAMAN & DIU", state)) %>%
  mutate(district = ifelse(district == "NELLORE", "S.P.S. NELLORE", 
                           ifelse(district == "SAS", "S.A.S. NAGAR", district)))

# Deal with Delhi, Telangana, Andamana and Nicobar, Manipur, Assam, and Goa
data_sep_state_ags <- data_raw %>%
  separate(name, into = nms_sep, sep = rgx_split, fill = "right") %>%
  filter(name2 %in% c("DL", "TG", "GA", "MN", "AS", "SK"),
         name3 %in% c("delta", "total"),
         name4 == "confirmed") %>%
  dplyr::rename(date = name1, state = name2, delta_total = name3) %>%
  select(date, state, delta_total, value) %>%
  spread(delta_total, value, fill = 0) %>%
  mutate(state = ifelse(state == "AS", "ASSAM",
                        ifelse(state == "MN", "MANIPUR",
                               ifelse(state == "DL", "DELHI",
                                      ifelse(state == "TG", "TELANGANA",
                                             ifelse(state == "SK", "SIKKIM",
                                                    ifelse(state == "GA", "GOA",
                                                           state)))))),
         district = state)

# Add these 3 states to the main data
data_final <- rbind(data_sep, data_sep_state_ags) %>%
  mutate_at(c("state", "district"), toupper) %>%
  arrange(state, district, date) %>%
  # Drop duplicates in Tripura
  unique() %>%
  # Drop observations not tied to particular districts within states
  filter(!(district %in% c("OTHER STATE", "OTHERS", "OTHER REGION", 
                           "RAILWAY QUARANTINE", "AIRPORT QUARANTINE",
                           "ITALIANS", "FOREIGN EVACUEES", "BSF CAMP",
                           "EVACUEES", "CAPF PERSONNEL", "STATE POOL"))) %>%
  # Combine observations for certain districts
  mutate(district = ifelse(district == "GAURELA PENDRA MARWAHI",
                           "BILASPUR", district),
         district = ifelse(district == "DIBANG VALLEY",
                           "UPPER DIBANG VALLEY", district),
         district = ifelse(district == "KRA-DAADI", "KRA DAADI",
                           district)) %>%
  mutate_at(.vars = c("delta", "total"), as.numeric) %>%
  group_by(state, district, date) %>%
  dplyr::summarize(delta = sum(delta),
                   total = sum(total))

# Add observation for KURUNG KUMEY, which has no cases in the data
kk_df <- data.frame("state" = "ARUNACHAL PRADESH", 
                    "district" = "KURUNG KUMEY", 
                    "date" = "2020-03-26", 
                    "delta" = 0, 
                    "total" = 0)

data_final <- rbind(data_final, kk_df)

# Convert date to a date variable
data_final <- data_final %>%
  mutate(date = as_date(date))

# Sort data by state date district
data_final <- data_final %>%
  arrange(state, district, date)

# Find percentage of districts whose initial observation has a cumulative
# count but no daily count
tot_districts <- data_final %>%
  distinct(state, district) %>%
  nrow()

nodelt_districts <- data_final %>%
  # Keep observations prior to sep 30
  filter(date <= as.Date("2020-08-30")) %>%
  # List of districts that have a different delta than total on the 1st day
  arrange(state, district, date) %>%
  group_by(state, district) %>%
  dplyr::mutate(rowid = row_number()) %>%
  filter(rowid == 1) %>%
  ungroup() %>%
  filter(total > delta)

# Cumulative cases by may1
cum_may1 <- data_final %>%
  filter(total != 0) %>%
  filter(date <= as.Date("2020-05-01")) %>%
  arrange(state, district, desc(date)) %>%
  group_by(state, district) %>%
  dplyr::mutate(rowid = row_number()) %>%
  filter(rowid == 1) %>%
  ungroup() %>%
  select(state, district, total, date)

# Number of cumulative cases by sep 30 in phase 2 and phase 3 districts
cum_sep30_phase2_3 <- data_final %>%
  filter(state == "MAHARASHTRA",
         district != "MUMBAI" & district != "PUNE",
         date <= as.Date("2020-09-30")) %>%
  arrange(district, desc(date)) %>%
  group_by(district) %>%
  dplyr::mutate(rownum = row_number()) %>%
  filter(rownum == 1) %>%
  ungroup() %>%
  summarize(tot_cases = sum(total))

cum_may1 <- data_final %>%
  filter(total != 0) %>%
  filter(date <= as.Date("2020-05-01")) %>%
  arrange(state, district, desc(date)) %>%
  group_by(state, district) %>%
  dplyr::mutate(rowid = row_number()) %>%
  filter(rowid == 1) %>%
  ungroup() %>%
  select(state, district, total, date)



data_final %>%
  filter(total != 0) %>%
  filter(date <= as.Date("2020-04-26")) %>%
  arrange(state, district, desc(date)) %>%
  group_by(state, district) %>%
  dplyr::mutate(rowid = row_number()) %>%
  filter(rowid == 1) %>%
  ungroup() %>%
  select(state, district, total, date) %>%
  View()
