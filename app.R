library(shiny)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)

# Define the function to fetch flow values
source("cdec-scrape-function.R")

# UI Definition
ui <- fluidPage(
  titlePanel("Live Flow Data"),
  dataTableOutput("flowTable"),
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
      select(StationID, Date, Time, Value) # Reordering columns for clarity

    flow_data(new_data)
    last_update(Sys.time())
  }

  # Refresh data every 15 minutes safely
  observe({
    invalidateLater(15 * 60 * 1000, session)
    update_data()
  })

  # Render Data Table
  output$flowTable <- renderDataTable({
    req(flow_data())
    flow_data()
  })

  # Render Last Updated Time
  output$lastUpdated <- renderText({
    paste("Last updated:", format(last_update(), "%Y-%m-%d %H:%M:%S"))
  })
}

# Run the Shiny App
shinyApp(ui = ui, server = server)
