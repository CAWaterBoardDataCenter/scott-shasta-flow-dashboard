# app.R
library(shiny)
library(leaflet)
library(htmlwidgets)

ui <- fluidPage(
  # Create a Leaflet map output with a specified height.
  leafletOutput("map", height = 500)
)

server <- function(input, output, session) {

  # Define the coordinates for the square polygon.
  # This example uses a square located over a San Francisco area.
  square_coords <- list(
    lng = c(-122.446747, -122.446747, -122.436747, -122.436747, -122.446747),
    lat = c(37.773972, 37.763972, 37.763972, 37.773972, 37.773972)
  )

  output$map <- renderLeaflet({
    leaflet() %>%
      # Set an initial view that centers the polygon
      setView(lng = -122.441747, lat = 37.768972, zoom = 14) %>%
      # Add the topographic basemap (OpenTopoMap) as one base group
      addProviderTiles(providers$OpenTopoMap, group = "Topographic") %>%
      # Add an aerial basemap (Esri World Imagery) as another base group
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial") %>%
      # Draw the polygon with initial styling for the topographic map.
      addPolygons(
        lng = square_coords$lng,
        lat = square_coords$lat,
        layerId = "poly",   # an ID to easily reference the polygon layer later
        color = "yellow",    # yellow outline for the topographic map
        weight = 2,
        fill = FALSE        # no fill
      ) %>%
      # Add a layers control to switch between basemaps.
      addLayersControl(
        baseGroups = c("Topographic", "Aerial"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      # Use onRender to attach a JavaScript function that listens for baselayer changes.
      onRender("
        function(el, x) {
          var map = this;
          // Listen for the baselayerchange event.
          map.on('baselayerchange', function(e) {
            map.eachLayer(function(layer) {
              // Identify our polygon by its layerId.
              if (layer.options && layer.options.layerId === 'poly') {
                // If the user selects the aerial basemap, change polygon outline to white.
                if (e.name === 'Aerial') {
                  layer.setStyle({color: 'white'});
                } else {
                  // Otherwise (topographic), set the outline to black.
                  layer.setStyle({color: 'yellow'});
                }
              }
            });
          });
        }
      ")
  })
}

# Launch the Shiny app
shinyApp(ui, server)

