library(tidyr)
library(dplyr)
library(leaflet)
library(readr)

# Load dataset
pod_curtail_status_raw <- read_csv("pod-curtail-status.csv")

# Process data
pod_curtail_status <- pod_curtail_status_raw %>%
  select(wr_id = `Application Number`,
         owner = `Primary Owner`,
         lat = Latitude,
         lon = Longitude,
         curtail_status = `Curtailment Status`) %>%
  mutate(curtail_status = trimws(as.character(curtail_status)))  # Remove spaces

# Get actual unique values present in the dataset
actual_levels <- unique(pod_curtail_status$curtail_status)
actual_levels <- actual_levels[!is.na(actual_levels) & actual_levels != ""]  # Remove NA/empty values

# Convert to factor *after* extracting actual levels
pod_curtail_status <- pod_curtail_status %>%
  mutate(curtail_status = factor(curtail_status, levels = actual_levels))

# Create a color palette dynamically based on actual values in the dataset
color_palette <- c("green", "red")  # Define base colors
pal <- colorFactor(palette = color_palette[1:length(actual_levels)], domain = actual_levels)

# Create Leaflet map
leaflet(pod_curtail_status) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~lon,
    lat = ~lat,
    popup = ~paste("WR ID:", wr_id, "<br>Owner:", owner, "<br>Status:", curtail_status),
    radius = 6,
    color = ~pal(curtail_status),
    stroke = FALSE,
    fillOpacity = 0.6
  )
