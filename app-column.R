library(shiny)
library(bslib)
library(flexdashboard)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)
library(readr)
library(glue)
library(stringr)
library(curl)

ui <- page_fillable(

  # Primary rows
  fluidRow(
    column(width = 4,

           fluidRow(
             card(
               # #      height = "25vh",  # This row takes up 25% of the screen
               #      full_screen = TRUE,
               #      card(
               #      card_header("Gauge 1", class = "gray-400"),
               #      card_body(
               gaugeOutput("gauge1"), # Content for Gauge 1
               #   )
               # ),
               # card(
               #   full_screen = TRUE,
               #    card_header("Gauge 2", class = "gray-400"),
               #   card_body(
               gaugeOutput("gauge2") # Content for Gauge 2
             )
           )
    )
  ),
  column(width = 8,

         card(
           full_screen = TRUE,
           card_header("Map", class = "gray-400"),
           card_body(
             leafletOutput("map") # Content for map.
           )
         )

  ),

  fluidRow(
    column(width = 12,
           card(
             full_screen = TRUE,
             card_header("About The Dashboard", class = "gray-400"),
             card_body(
               p("This dashboard is a concept for monitoring the flow of the Scott and Shasta Rivers. It includes gauges and a map to visualize the data."

               )
             )
           )
           #  )
    )
  )
)



server <- function(input, output) {

}


# ui <- fluidPage(
#
#   # Primary rows
#   fluidRow(
#     column(6
#            , fluidRow(
#              column(6, style = "background-color:yellow;")
#              , column(6, style = "background-color:green")
#            )
#            , fluidRow(
#              column(12, style = "background-color:red;")
#            )
#     )
#     , column(6, style = "background-color:blue;")
#   )
# )
#
#
server <- function(input, output) {

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
