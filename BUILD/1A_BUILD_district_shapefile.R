# Set working directory
setwd("[YOUR DIRECTORY PATH HERE]")

# Input: Individual district-level shapefiles for India circa 2019
# Output: Combined district-level shapefile

# LOAD PACKAGES
library(sf)
library(dplyr)
library(plyr)

# Initialize directories
input_dir <- "./data/Raw/Shapefiles/Districts/"
int_dir <- "./data/Generated/Intermediate/Shapefiles/districts/separated"
output_dir <- "./data/Generated/Intermediate/Shapefiles/districts/combined/"


# List zip files
zipfiles <- list.files(path = input_dir, pattern = "*.zip", full.names = TRUE)

# Unzip files
ldply(.data = zipfiles, .fun = unzip, exdir = int_dir)

# Get file names ending in .shp
shpfiles <- list.files(path = int_dir, pattern = "*.shp", full.names = TRUE)

# Combine individual district-level .shp files
dist <- do.call("rbind", lapply(shpfiles, st_read)) %>%
  # Select district name, state name, unique district ID
  select(dtname, stname, JID)

# Output
st_write(dist, paste0(output_dir, "districts.shp"))


