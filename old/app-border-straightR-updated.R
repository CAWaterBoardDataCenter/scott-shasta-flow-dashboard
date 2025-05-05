
library(shiny)
library(leaflet)
library(sf)

# Load geojson file from data folder.
watershedBoundaries <- st_read("./data/scott-shasta-huc8s/scott-shasta-huc8s.geojson") %>%
  st_transform('+proj=longlat +datum=WGS84')

ui <- fluidPage(
  leafletOutput("map", height = 500)
)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Esri.WorldStreetMap, group = "Street") %>%
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Topographic") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial") %>%
      addLayersControl(
        baseGroups = c("Street", "Topographic", "Aerial"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })

  observe({
    req(input$map_groups)

    color <- if ("Aerial" %in% input$map_groups) "white" else "black"

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

shinyApp(ui, server)
