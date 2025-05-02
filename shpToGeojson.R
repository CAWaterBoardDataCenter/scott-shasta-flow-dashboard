library(sf)

# Load watershed boundaries for the map.
huc8_boundaries <- sf::st_read("./data/scott-shasta-huc8s/scott-shasta-huc8s.shp") %>%
  sf::st_transform('+proj=longlat +datum=WGS84')

# Save huc8_boundaries as a geojson file.
sf::st_write(huc8_boundaries,
             dsn = "./data/scott-shasta-huc8s/scott-shasta-huc8s.geojson",
             driver = "GeoJSON",
             delete_dsn = TRUE)
