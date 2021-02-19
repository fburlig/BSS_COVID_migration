
# Create a heat map of mumbai migrants home districts

setwd("[YOUR DIRECTORY PATH HERE]")

rm(list=ls())

dirpath_data <- "./data"
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_final <- paste0(dirpath_gen, "/final")
dirpath_final_shp <- paste0(dirpath_final, "/shapefiles")
dirpath_outputs <- "./outputs"
dirpath_outputs_maps <- paste0(dirpath_outputs, "/maps")

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

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 1. Load data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

# Districts
dist_shp_flows <- readOGR(paste0(dirpath_final_shp, 
                                 "/districts_flows_map.shp"))
dist_shp_flows <- st_as_sf(dist_shp_flows)

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 2. Create additional shapefiles for plotting
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

# Create shapefile to plot Indian borders
india_border_shp <- dist_shp_flows %>%
  dplyr::summarise()

# Get centroid coordinates for Mumbai
mumbai_shp <- dist_shp_flows %>%
  filter(stname == "Maharashtra",
         dtname == "Mumbai") %>%
  st_centroid()

line_dataframe <- data.frame(
  longitude = c(72.87652, 71.87652),
  latitude = c(19.08974, 18.08974)
)

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
# 3. Make map
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

loadfonts()

map <- ggplot() +
  geom_sf(data = dist_shp_flows,
          aes(fill = reorder(qval, q_mig)),
          lwd = 0,
          color=NA) +
  scale_fill_manual(
    labels = c(" <50 ", " 50-150", " 150-250",
               " 250-450", " 450-750", " 750-1,100",
               " 1,100-1,550", " 1,550-2,600", " 2,600-4,800",
               " >4,800", " Excluded"),
    values = c("grey95", "grey88", "grey81", "grey74",
               "grey67", "grey60", "grey53",
               "grey46", "grey39", "grey32"),
    na.value = "white"
  ) +
  geom_sf_text(
    data = mumbai_shp, 
    aes(label = dtname, geometry = geometry),
    nudge_x = -2.25,
    nudge_y = -1.5,
    size = 9
  ) +
  geom_line(
    data = line_dataframe, 
    aes(x = longitude, y = latitude)
    ) +
  geom_sf(
    data = india_border_shp,
    lwd = 0.5,
    color = "grey60",
    fill = "transparent"
  ) +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        rect = element_blank(),
        plot.title = element_blank(),
        legend.title = element_text(size = 1, color = "black"),
        legend.title.align = 0.5,
        legend.key = element_rect(linetype = "solid", color = "grey60"),
        legend.spacing.y = unit("6", "mm"),
        legend.text = element_text(size = 26, color = "black", hjust = 0),
        plot.margin = unit(c(0,-5,0,-5), "cm"),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.key.size = unit(0.975, "cm"),
        legend.position = c(0.8, 0.25)
        ) +
  labs(fill = "")

ggsave(paste0(dirpath_outputs_maps, "/Map_mumbai_migrants.pdf"),
       width = 9, height = 10)

