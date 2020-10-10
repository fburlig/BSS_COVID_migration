# Create a district-level heatmap of the number of arriving mumbai migrants
setwd("[YOUR DIRECTORY PATH HERE]")

rm(list=ls())
dirpath_in <- "./data/Generated/final/shapefiles/"
dirpath_out <- "./Outputs/Maps/"

library(sf)
library(dplyr)
library(stringi)
library(lubridate)
library(ggplot2)
library(readr)
library(rgdal)
library(extrafont)
library(grDevices)
library(rmapshaper)
library(shades)
library(RColorBrewer)


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 1. Load data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
  
  # Districts
  dist_shp_flows <- readOGR(paste0(dirpath_in, 
                                   "districts_flows_map.shp"))
  dist_shp_flows <- st_as_sf(dist_shp_flows)


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 2. Simplify Shapefiles
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#


# Separate phase 2 and phase 3 lockdown districts from shapefile
phase2_shp <- dist_shp_flows %>%
  filter(stname == "Maharashtra",
         dtname %in% c("Thane", "Palghar", "Raigarh", "Mumbai"))

phase3_shp <- dist_shp_flows %>%
  filter(stname == "Maharashtra",
         !(dtname %in% c("Thane", "Palghar", "Raigarh", "Mumbai")))


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 3. Make maps
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

  loadfonts()
  
  map <- ggplot() + 
    geom_sf(data = dist_shp_flows,
            aes(fill = reorder(qval, qT5m_Drmt)),
            lwd = 0.1, color="white") +
    scale_fill_manual(
      labels = c("0", "<300", "300-860", "860-2,030", 
                 "2,030-6,050", ">6,050", "Excluded"),
      values = c("#EFF3FF", "#C6DBEF", "#9ECAE1",
                 "#6BAED6", "#3182BD", "#08519C"),
      na.value = "grey85"
    ) +
    theme(axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          rect = element_blank(),
          plot.title = element_blank(),
          legend.title = element_text(size = 26, color = "black"),
          legend.title.align = 0.5,
          legend.key = element_rect(linetype = "solid", color = "grey85"),
          legend.spacing.y = unit("6", "mm"),
          legend.text = element_text(size = 24, color = "black", hjust = 0),
          plot.margin = unit(c(0,-5,0,-5), "cm"),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          legend.key.size = unit(1.05, "cm"),
          legend.position = c(0.8, 0.25)) +
    labs(fill = "Migrants departing\nMumbai")
  
  ggsave(paste0(dirpath_out, "Map_mumbai_migrants.pdf"), width = 9, height = 10)
  
  
  map <- ggplot() + 
    geom_sf(data = phase2_shp,
            aes(fill = reorder(qval, qT5m_Drmt)),
            lwd = 0.7, col = "white") +
    scale_fill_manual(
      labels = c(">6,050", "Excluded"),
      values = c("#08519C"),
      na.value = "grey85"
    ) +
    theme(axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          rect = element_blank(),
          plot.title = element_text(face = "bold", hjust = 0.5, vjust = 0,
                                    size = 36, family = "Arial"),
          axis.title.x = element_blank(),
          legend.position = "none",
          axis.title.y = element_blank())
  
  ggsave(paste0(dirpath_out, "Map_mumbai_migrants_phase2.pdf"), width = 4, height = 7)
  
  
  map <- ggplot() + 
    geom_sf(data = phase3_shp,
            aes(fill = reorder(qval, qT5m_Drmt)),
            lwd = 0.5, col = "white") +
    scale_fill_manual(
      values = c("#C6DBEF", "#9ECAE1",
                 "#6BAED6", "#3182BD", "#08519C"),
      na.value = "grey85"
    ) +
    theme(axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          rect = element_blank(),
          plot.title = element_text(face = "bold", hjust = 0.5, vjust = 0,
                                    size = 36, family = "Arial"),
          axis.title.x = element_blank(),
          legend.position = "none",
          axis.title.y = element_blank())
  
  ggsave(paste0(dirpath_out, "Map_mumbai_migrants_phase3.pdf"))
  
  
  
  
  
  