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

# Define expected order of curtailment statuses
expected_levels <- c("Not Curtailed", "Curtailed")

# Extract actual levels present in the dataset while preserving expected order
actual_levels <- expected_levels[expected_levels %in% unique(pod_curtail_status$curtail_status)]

# Convert to factor using expected order to maintain color consistency
pod_curtail_status <- pod_curtail_status %>%
  mutate(curtail_status = factor(curtail_status, levels = expected_levels))

# Create a color palette ensuring "Not Curtailed" is green & "Curtailed" is red
pal <- colorFactor(palette = c("red", "green"), domain = expected_levels)

# Create Leaflet map
leaflet(pod_curtail_status) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~lon,
    lat = ~lat,
    popup = ~paste("WR ID:", wr_id, "<br>Owner:", owner, "<br>Status:", curtail_status),
    radius = 6,
    color = ~pal(curtail_status),  # Now correctly mapped
    stroke = FALSE,
    fillOpacity = 0.6
  )

data.frame(
  Package = names(sessionInfo()$otherPkgs),
  Version = sapply(sessionInfo()$otherPkgs, `[[`, "Version")
)
