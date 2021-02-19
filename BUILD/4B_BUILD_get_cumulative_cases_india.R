
# Get cumulative cases for India
# Note: cumulative case counts do not necessarily match daily case counts
# due to an initial lag in reporting of the latter. We use the cumulative
# case counts to obtain 1. the number of cumulative cases in each district/unit
# by april 26th, and 2. the number of cumulative cases in each district/unit
# prior to May 1st

setwd("[YOUR DIRECTORY PATH HERE]")

library(rjson)
library(dplyr)
library(jsonlite)
library(tidyverse)
library(readxl)
library(haven)
library(lubridate)

rm(list=ls())

dirpath_data <- "./data"
dirpath_raw <- paste0(dirpath_data, "/raw")
dirpath_raw_covid <- paste0(dirpath_raw, "/covid")
dirpath_raw_misc <- paste0(dirpath_raw, "/misc")

data_raw <- read_csv(paste0(dirpath_raw_covid, "/covid19india_raw_oct1_json_to_csv.csv"))

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
  dplyr::select(-c(name6, name7)) %>%
  spread(daily_cum, value, fill = 0) %>%
  dplyr::select(date, state, district, delta, total) %>%
  arrange(date, state, district)

state_abv <- read_excel(paste0(dirpath_raw_misc, "/state_abbreviations.xlsx"))

# Add state names to separated data, fix a few district names
data_sep <- left_join(data_sep, state_abv, by = "state") %>%
  dplyr::select(date, name, district, delta, total) %>%
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
  dplyr::select(date, state, delta_total, value) %>%
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

# Add observation for KURUNG KUMEY, which has no cases in the data by the end
# of our sample
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

# Cumulative cases by apr 26
cum_may1 <- data_final %>%
  filter(total != 0) %>%
  filter(date <= as.Date("2020-04-26")) %>%
  arrange(state, district, desc(date)) %>%
  group_by(state, district) %>%
  dplyr::mutate(rowid = row_number()) %>%
  filter(rowid == 1) %>%
  ungroup() %>%
  dplyr::select(state, district, total, date)

# Cumulative cases prior to may1
cum_may1 <- data_final %>%
  filter(total != 0) %>%
  filter(date < as.Date("2020-05-01")) %>%
  arrange(state, district, desc(date)) %>%
  group_by(state, district) %>%
  dplyr::mutate(rowid = row_number()) %>%
  filter(rowid == 1) %>%
  ungroup() %>%
  dplyr::select(state, district, total, date)
