library(shiny)
library(leaflet)

ui <- fluidPage(
  # Display the Leaflet map.
  leafletOutput("map", height = 500)
)

server <- function(input, output, session) {
  # Define the coordinates for the square polygon.
  square_coords <- data.frame(
    lng = c(-122.446747, -122.446747, -122.436747, -122.436747, -122.446747),
    lat = c(37.773972, 37.763972, 37.763972, 37.773972, 37.773972)
  )

  # Render the initial map.
  output$map <- renderLeaflet({
    leaflet() %>%
      # Set the initial view.
      setView(lng = -122.441747, lat = 37.768972, zoom = 14) %>%
      # Add the topographic base map (OpenTopoMap) and the aerial base map (Esri World Imagery).
      addProviderTiles(providers$OpenTopoMap, group = "Topographic") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial") %>%
      # Add the square polygon with initial styling for the topographic basemap.
      # We assign it to group "polygonGroup" to facilitate later updates.
      addPolygons(
        data = square_coords,
        lng = ~lng,
        lat = ~lat,
        color = "black",  # Black outline for the topographic view.
        weight = 2,
        fill = FALSE,
        group = "polygonGroup",
        layerId = "poly"
      ) %>%
      # Enable layer control to allow switching between basemaps.
      addLayersControl(
        baseGroups = c("Topographic", "Aerial"),
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
      clearGroup("polygonGroup") %>%
      addPolygons(
        data = square_coords,
        lng = ~lng,
        lat = ~lat,
        color = polygonColor,
        weight = 2,
        fill = FALSE,
        group = "polygonGroup",
        layerId = "poly"
      )
  })
}

# Run the Shiny app.
shinyApp(ui, server)
