library(shiny)
library(leaflet)
library(flexdashboard)
library(bslib)
library(shinyWidgets)

# Define UI
ui <- fluidPage(

  # Apply Bootstrap 5 theme
  theme = bs_theme(version = 5),

  # Custom CSS for layout
  tags$head(tags$style(HTML("
    .row-container { height: 75vh; display: flex; }
    .gauge-card { width: 30%; height: 100%; padding: 10px; }
    .map-card { width: 70%; height: 100%; padding: 10px; }
    .bottom-card { width: 100%; height: 25vh; padding: 10px; }
    .card { background: white; border-radius: 10px; padding: 20px; box-shadow: 2px 2px 10px rgba(0,0,0,0.1); }
  "))),

  # First row (75% height)
  div(class = "row-container",
      # First card - Gauges
      div(class = "gauge-card card",
          h4("Gauge Indicators"),
          gaugeOutput("gauge1"),
          gaugeOutput("gauge2")
      ),

      # Second card - Leaflet Map
      div(class = "map-card card",
          h4("Map of Sacramento"),
          leafletOutput("map", height = "100%")
      )
  ),

  # Second row (25% height)
  div(class = "bottom-card card",
      h4("Additional Information"),
      p("This section can be used for further insights, data tables, or other visualizations.")
  )
)

# Define Server Logic
server <- function(input, output, session) {

  # Render Flexdashboard Gauges
  output$gauge1 <- renderGauge({
    gauge(75, min = 0, max = 100, symbol = "%", label = "Completion", sectors = gaugeSectors(success = c(70, 100), warning = c(30, 69), danger = c(0, 29)))
  })

  output$gauge2 <- renderGauge({
    gauge(45, min = 0, max = 100, symbol = "%", label = "Efficiency", sectors = gaugeSectors(success = c(70, 100), warning = c(30, 69), danger = c(0, 29)))
  })

  # Render Leaflet Map
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -121.4944, lat = 38.5816, zoom = 12)
  })
}

# Run App
shinyApp(ui, server)
