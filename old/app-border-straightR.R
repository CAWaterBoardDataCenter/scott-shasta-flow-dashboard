library(shiny)
library(leaflet)
library(sf)

# Load geojson file from data folder.
watershedBoundaries <- st_read("./data/scott-shasta-huc8s/scott-shasta-huc8s.geojson")# %>%
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

      # Enable layer control to allow switching between basemaps.
      addLayersControl(
        baseGroups = c("Street", "Topographic", "Aerial"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%

      # Add watershed boundary polygons.
      addPolygons(
        data = watershedBoundaries,
        color = NA,  # Black outline for the topographic view.
        weight = 2,
        fill = FALSE,
        group = "watershedGroup"
       )

  })

  # Observe basemap changes. The leaflet package creates a reactive input named
  # input$map_baselayer that reflects the name of the current base layer.
  observe({
    req(input$map_groups)

    color <- if (input$map_groups == "Aerial") "white" else "black"

    leafletProxy("map") %>%
      clearGroup("watershedGroup") %>%
      addPolygons(
        data = watershedBoundaries,
        color = color,
        weight = 2,
        fill = FALSE,
        group = "watershedGroup"
      )
  })

  }

# Run the Shiny app.
shinyApp(ui, server)
