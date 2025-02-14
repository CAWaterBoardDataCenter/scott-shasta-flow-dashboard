library(bslib)
library(shinydashboard)
library(shinydashboardPlus)
library(leaflet)
library(flexdashboard)  # For gauge function

ui <- page_fillable(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    #  primary = "#0d6efd",
    "font-size-base" = "1.1rem"
  ),

  # Title Bar with Navy Blue Background
  # div(
  #   style = "background-color: #0d6efd; color: white; text-align: center;
  #            font-size: 24px; font-weight: bold; padding: 15px; width: 100%;",
  #   "Scott and Shasta Rivers Flow Monitoring Dashboard"
  # ),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard - Concept"),

  # Four Gauge Cards Side-by-Side - Takes up 25% of screen height
  layout_column_wrap(
    width = 1/4,  # Each gauge card gets 1/4th of the width (so they are side-by-side)
    height = "25vh",  # This row takes up 25% of the screen
    gap = "1rem",  # Adds space between the cards
    card(
      full_screen = TRUE,
      card_header( "Gauge 1", class = "gray-400"),
      card_body(
        gaugeOutput("gauge1")
      )
    ),
    card(
      full_screen = TRUE,
      card_header( "Gauge 2", class = "gray-400"),
      card_body(
        gaugeOutput("gauge2")
      )
    ),
    card(
      full_screen = TRUE,
      card_header( "Gauge 3", class = "gray-400"),
      card_body(
        gaugeOutput("gauge3")
      )
    ),
    card(
      full_screen = TRUE,
      card_header( "Gauge 4", class = "gray-400"),
      card_body(
        gaugeOutput("gauge4")
      )
    )
  ),

  # Properly aligned Notes (1/3) & Map (2/3)
  layout_columns(
    col_widths = c(4, 8),  # Ensures Notes takes 1/4 and Map takes 3/4
    heights_equal = "row",  # Keeps both cards the same height
    style = "height: 75vh;",  # Makes this row 75% of the screen height

    card(
      full_screen = TRUE,
      card_header( "Information", class = "gray-400"),
      card_body(
        markdown("This space can be used to provide information about the dashboard.")
      )
    ),

    card(
      full_screen = TRUE,
      card_header( "Map", class = "gray-400"),
      card_body(
        leafletOutput("map", height = "100%")
      )
    )
  )


)

server <- function(input, output, session) {

  # Render Leaflet Map centered at Sacramento, CA
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -121.4944, lat = 38.5816, zoom = 7) # Sacramento, CA
  })

  # Render Gauges with Random Values
  output$gauge1 <- renderGauge({
    gauge(sample(1:100, 1), min = 0, max = 100, symbol = "%", sectors = gaugeSectors(
      success = c(75, 100), warning = c(40, 74), danger = c(0, 39)
    ))
  })

  output$gauge2 <- renderGauge({
    gauge(sample(1:100, 1), min = 0, max = 100, symbol = "%", sectors = gaugeSectors(
      success = c(75, 100), warning = c(40, 74), danger = c(0, 39)
    ))
  })

  output$gauge3 <- renderGauge({
    gauge(sample(1:100, 1), min = 0, max = 100, symbol = "%", sectors = gaugeSectors(
      success = c(75, 100), warning = c(40, 74), danger = c(0, 39)
    ))
  })

  output$gauge4 <- renderGauge({
    gauge(sample(1:100, 1), min = 0, max = 100, symbol = "%", sectors = gaugeSectors(
      success = c(75, 100), warning = c(40, 74), danger = c(0, 39)
    ))
  })
}

shinyApp(ui, server)
