library(aws.s3)
library(shiny)
library(flexdashboard)
library(bslib)
library(leaflet)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)
library(readr)
library(glue)
library(stringr)
library(curl)
library(DT)
library(sf)

## Load watershed boundaries for the map. ----
huc8_boundaries <- sf::st_read("./data/scott-shasta-huc8s/scott-shasta-huc8s.shp") %>%
  sf::st_transform('+proj=longlat +datum=WGS84')
names(st_geometry(huc8_boundaries)) <- NULL

# Save huc8_boundaries as a geo

leaflet() %>%

 # addProviderTiles(providers$Esri.WorldTopoMap, group = "Topo Map") %>%




  ## Add watershed boundaries. ----
addPolygons(
  data = huc8_boundaries,
  group = "watersheds",
  color = "blue",
  weight = 1.5,
  opacity = 1.0,
  fillOpacity = 0.0,
 # layerId = "watersheds",
  label = ~paste(name, "River Watershed")
  #    labelOptions = labelOptions(noHide = TRUE)
)

