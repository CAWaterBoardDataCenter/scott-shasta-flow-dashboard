library(shiny)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)
library(flexdashboard)

# Define the function to fetch flow values
source("cdec-scrape-function.R")

# UI Definition
ui <- fluidPage(
  titlePanel("Live Flow Data"),
  fluidRow(
    column(12, uiOutput("gauges"))
  ),
  textOutput("lastUpdated")
)

# Server Logic
server <- function(input, output, session) {

  # Reactive values to store data and update time
  flow_data <- reactiveVal(NULL)
  last_update <- reactiveVal(Sys.time())

  # Function to update data
  update_data <- function() {
    new_data <- map_df(cdec_stations, get_sensor20_flows) %>%
      mutate(
        Date = as.Date(DateTime, tz = "America/Los_Angeles"),
        Time = format(as.POSIXct(DateTime, tz = "America/Los_Angeles"), "%H:%M:%S")
      ) %>%
      select(StationID, Value) # Only keep relevant columns for gauge display

    flow_data(new_data)
    last_update(Sys.time())
  }

  # Refresh data every 15 minutes safely
  observe({
    invalidateLater(15 * 60 * 1000, session)
    update_data()
  })

  # Render Gauges in a left-aligned row layout
  output$gauges <- renderUI({
    req(flow_data())
    data <- flow_data()

    gauge_list <- lapply(1:nrow(data), function(i) {
      div(style = "display: inline-block; width: 200px; margin: 5px;",
          flexdashboard::gauge(
            value = data$Value[i],
            min = 0, max = max(data$Value, na.rm = TRUE) * 1.2,
            label = paste("Station", data$StationID[i]),
            gaugeSectors(success = c(0, max(data$Value, na.rm = TRUE) * 0.5),
                         warning = c(max(data$Value, na.rm = TRUE) * 0.5, max(data$Value, na.rm = TRUE) * 0.8),
                         danger = c(max(data$Value, na.rm = TRUE) * 0.8, max(data$Value, na.rm = TRUE) * 1.2))
          ))
    })

    do.call(div, c(gauge_list, list(style = "text-align: left;")))
  })

  # Render Last Updated Time
  output$lastUpdated <- renderText({
    paste("Last updated:", format(last_update(), "%Y-%m-%d %H:%M:%S"))
  })
}

# Run the Shiny App
shinyApp(ui = ui, server = server)
