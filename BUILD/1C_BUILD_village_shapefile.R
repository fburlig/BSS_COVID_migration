# Set working directory
setwd("[YOUR DIRECTORY PATH HERE]")

# Input: Individual town-or-lower-level shape files for India circa 2001
# Output: Combined town-or-lower-level shape file

##########################
rm(list=ls())

# LOAD PACKAGES
library(sf)
library(dplyr)

# Initialize directories
input_dir <- "./data/Raw/Shapefiles/Villages/"
int_dir <- "./data/Generated/Intermediate/Shapefiles/villages/separated/"
output_dir <- "./data/Generated/Intermediate/Shapefiles/villages/combined/"

# Initialize state abbreviations to input files
state.ab <- c("ap", "as", "br", "cg", "ga", "gj", "hr", "hp", "jk",
              "jh", "ka", "kl", "mp", "mh", "mn", "mz", "or",
              "pb", "rj", "sk", "tn", "tr", "up", "uk", "wb", "uterr") %>%
  toupper()
state.ab[26] <- "UTerr"

# Load .shp files
shp_file <- do.call("rbind", lapply(state.ab, FUN = function(X) {
  # Make state abbreviations lowercase
  x <- tolower(X)
  # Initialize .zip file names
  zip_name <- paste0(input_dir,
                     "india-india-village-level-geospatial-socio-econ-1991-2001-", 
                     x, "-2001-shp.zip")
  # Unzip
  unzip(zip_name, exdir = int_dir)
  # Initialize .shp file names
  shp_name <- paste0(int_dir, "india-village-census-2001-", X, ".shp")
  # Read shapefiles
  shp_file <- st_read(shp_name) %>%
    select(NAME, SID, DID, C_CODE01, LEVEL, No_HH, TOT_P, NEAR_TOWN, 
           DIST_TOWN, TOT_INC, TOT_EXP)
  return(shp_file)
}))

# Initialize .gdb file names
state.ab_gdb <- c("ar", "ml", "nl")

# Load .gbd files
gdb_file <- do.call("rbind", lapply(state.ab_gdb, FUN = function(x) {
  # Initialize .zip file names
  zip_names <- paste0(input_dir,
                      "india-india-village-level-geospatial-socio-econ-1991-2001-", 
                      x, "-2001-gdb.zip")
  # Unzip
  unzip(zip_names, exdir = int_dir)
  # Make state abbreviations uppercase
  X <- toupper(x)
  # Initialize .gdb file names
  gdb_names <- paste0(int_dir,
                      "india-village-census-2001-", X, ".gdb")
  gdb_file <- st_read(gdb_names) %>%
    select(NAME, SID, DID, C_CODE01, LEVEL, No_HH, TOT_P, NEAR_TOWN, 
           DIST_TOWN, TOT_INC, TOT_EXP) %>%
    dplyr::rename(geometry = Shape)
  return(gdb_file)
}))

# Combine .shp and .gdb files
shp_gdb <- rbind(shp_file, gdb_file) %>%
  # Transform to WGS84
  st_transform(crs = "WGS84")

# Output
st_write(shp_gdb, paste0(output_dir, "villages.shp"))
