library(shiny)
library(leaflet)
library(sf)

# Load geojson file from data folder.
watershedBoundaries <- st_read("scott-shasta-huc8s.geojson")# %>%
#  st_transform('+proj=longlat +datum=WGS84')


ui <- fluidPage(
  # Display the Leaflet map.
  leafletOutput("map", height = 500)
)

server <- function(input, output, session) {
  # Define the coordinates for the square polygon.


  # Render the initial map.
  output$map <- renderLeaflet({
    leaflet() %>%

      # Add provider tiles for different basemaps.
      addProviderTiles(providers$Esri.WorldStreetMap, group = "Street") %>%
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Topographic") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial") %>%

      # Add watershed boundary polygons.
      addPolygons(
        data = watershedBoundaries,
        color = "black",  # Black outline for the topographic view.
        weight = 2,
        fill = FALSE,
        group = "watershedGroup"
       ) %>%
      # Enable layer control to allow switching between basemaps.
      addLayersControl(
        baseGroups = c("Topographic", "Aerial", "Street"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })

  # Observe basemap changes. The leaflet package creates a reactive input named
  # input$map_baselayer that reflects the name of the current base layer.
  observeEvent(input$map_baselayer, {
    # Choose polygon color based on selected basemap.
    polygonColor <- if (input$map_baselayer == "Aerial") "white" else "black"

    # Update the polygon by clearing the previous one and then re-adding it with the new style.
    leafletProxy("map", session) %>%
      clearGroup("watershedGroup") %>%
      addPolygons(
        data = watershedBoundaries,
        color = polygonColor,
        weight = 2,
        fill = FALSE,
        group = "watershedGroup"
      )
  })

  }

# Run the Shiny app.
shinyApp(ui, server)
