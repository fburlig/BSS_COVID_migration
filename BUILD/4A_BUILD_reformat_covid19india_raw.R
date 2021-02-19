
# Reformat raw covid19india json data to a csv 

setwd("[YOUR DIRECTORY PATH HERE]")

library(rjson)
library(dplyr)
library(jsonlite)
library(tidyverse)
library(readxl)

rm(list=ls())

dirpath_data <- "./data"
dirpath_raw <- paste0(dirpath_data, "/raw")
dirpath_raw_covid <- paste0(dirpath_raw, "/covid")
dirpath_raw_misc <- paste0(dirpath_raw, "/misc")
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_int <- paste0(dirpath_gen, "/intermediate")
dirpath_int_covid <- paste0(dirpath_int, "/covid")

data_raw <- read_csv(paste0(dirpath_raw_covid, "/covid19india_raw_oct1_json_to_csv.csv"))

# Update names for 3 districts, whose periods in their names are not parsed
# properly
data_raw <- data_raw %>%
  mutate(name = str_replace(name, "Y.S.R. Kadapa", "Kadapa")) %>%
  mutate(name = str_replace(name, "S.A.S. Nagar", "SAS")) %>%
  mutate(name = str_replace(name, "S.P.S. Nellore", "SPS"))

rgx_split <- "\\."
n_cols_max <-
  data_raw %>%
  pull(name) %>% 
  str_split(rgx_split) %>% 
  map_dbl(~length(.)) %>% 
  max()

# Number of columns to separate data into
nms_sep <- paste0("name", 1:n_cols_max)

# Separate data for all district-wise data
data_sep <- data_raw %>% 
  separate(name, into = nms_sep, sep = rgx_split, fill = "right") %>%
  filter(
    !(name2 %in% c("DL", "TG", "GA", "MN", "AS", "AN", "SK")),
    name3 == "districts",
    name4 != "Unknown",
    name5 == "delta" | (name5 == "meta" & name6 == "population"),
    name6 %in% c("confirmed", "deceased", "population", "tested"),
  ) %>%
  dplyr::rename(date = name1, state = name2, 
                district = name4, cases_deaths_pop = name6) %>%
  dplyr::select(date, state, district, cases_deaths_pop, value) %>%
  spread(cases_deaths_pop, value, fill = 0) %>%
  dplyr::rename(num_cases = confirmed, num_deaths = deceased, 
                pop_2011 = population, num_tested = tested) %>%
  arrange(date, state, district)

state_abv <- read_excel(paste0(dirpath_raw_misc, "/state_abbreviations.xlsx"))

# Add state names to separated data, clean a few district names
data_sep <- left_join(data_sep, state_abv, by = "state") %>%
  dplyr::select(date, name, district, num_cases, num_deaths, pop_2011, num_tested) %>%
  dplyr::rename(state = name) %>%
  dplyr::mutate_at(c("state", "district"), toupper) %>%
  dplyr::mutate(state = ifelse(state == "JAMMU AND KASHMIR", "JAMMU & KASHMIR",
                               ifelse(state == "ORISSA", "ODISHA",
                                      ifelse(state == "PONDICHERRY", "PUDUCHERRY",
                                             state)))) %>%
  mutate(state = ifelse(district %in% c("DAMAN", "DIU", "DADRA AND NAGAR HAVELI"), 
                        "DAMAN & DIU", state)) %>%
  mutate(district = ifelse(district == "SPS", "S.P.S. NELLORE", 
                           ifelse(district == "SAS", "S.A.S. NAGAR", district)))

# Separate data for all state-wise data
data_sep_state_ags <- data_raw %>%
  separate(name, into = nms_sep, sep = rgx_split, fill = "right") %>%
  filter(name2 %in% c("DL", "TG", "GA", "MN", "AS", "SK"),
         name3 == "delta" | name4 == "population",
         name4 %in% c("confirmed", "population", "tested", "deceased")) %>%
  dplyr::rename(date = name1, state = name2, cases_deaths_pop = name4) %>%
  dplyr::select(date, state, cases_deaths_pop, value) %>%
  spread(cases_deaths_pop, value, fill = 0) %>%
  dplyr::rename(num_cases = confirmed, num_deaths = deceased,
                pop_2011 = population, num_tested = tested) %>%
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
  dplyr::select(-pop_2011)

write_csv(data_final, paste0(dirpath_int_covid, "/covid19india_api.csv"))


