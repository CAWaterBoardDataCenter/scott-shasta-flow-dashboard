library(shiny)
library(bslib)
library(flexdashboard)
library(leaflet)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)
library(readr)
library(glue)
library(stringr)
library(curl)

ui <- page_fillable(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    "font-size-base" = "1.1rem"
  ),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard - Concept"),

  fluidRow(
    layout_columns(
      col_widths = c(5, 7),
      # heights_equal = "row",
      # style = "height: 75vh;",

      layout_columns(
        col_widths = c(6, 6),
        card(
          full_screen = TRUE,
          card_header("Gauge 1", class = "gray-400"),
          card_body(
            gaugeOutput("gauge1") # Content for Gauge 1
          )
        ),
        card(
          full_screen = TRUE,
          height = "25vh",  # This row takes up 25% of the screen
          card_header("Gauge 2", class = "gray-400"),
          card_body(
            gaugeOutput("gauge2") # Content for Gauge 2
          )
        ),

        card(
          full_screen = TRUE,
          height = "25vh",  # This row takes up 25% of the screen
          card_header("Map", class = "gray-400"),
          card_body(
            leafletOutput("map", height = "100%")
          )
        )
      )
    )
  ),

#
#   fluidRow(
#     # layout_column_wrap(
#     #   col_widths = c(12),
#     card(
#       full_screen = TRUE,
#       width = 12,
#       card_header("About The Dashboard", class = "gray-400"),
#       card_body(
#         p("This dashboard is a concept for monitoring the flow of the Scott and Shasta Rivers. It includes gauges and a map to visualize the data."
#
#         )
#       )
#     )
#   )
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
}

shinyApp(ui, server)
