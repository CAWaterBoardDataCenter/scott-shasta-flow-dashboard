library(shiny)
library(flexdashboard)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)
library(readr)
library(glue)
library(stringr)
library(curl)

sta_info <- read_csv("station-info2.csv")

# Station IDs to poll.----
cdec_stations <- c("SFJ", # Scott R. near Fort Jones
                   "SRY", # Shasta R. at Yreka
                   "SRM"#, # Shasta R. near Montague
#                   "SPU"  # Shasta R. at Grenada Pump Plant
)

# Define the function to get the latest row of data
get_sensor20_flows <- function(x, sensor = 20) {
  # Retrieve the data from the CDER API
  data <- cder::cdec_query(station = x,
                           sensor = sensor,
                           start_date = as.Date(now()),
                           end_date = as.Date(now()))

  # Check if data is retrieved
  if (nrow(data) == 0) {
    stop("No data available for the specified station and sensor.")
  }

  # Filter for the latest row
  latest_data <- data %>%
    filter(!is.na(Value)) %>%
    arrange(desc(DateTime)) %>%
    slice(1) %>%
    select(StationID, DateTime, Value)

  return(latest_data)
}

# Define the function to fetch flow values
source("cdecFlowQuery.R")


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
    new_data <- sta_info[, 1:3] %>%
      pmap_dfr(., cdecFlowQuery)  %>%
      mutate(
        Date = as.Date(DateTime, tz = "America/Los_Angeles"),
        Time = format(as.POSIXct(DateTime, tz = "America/Los_Angeles"), "%H:%M:%S")
      ) %>%
      select(StationID, Date, Time, Value) # Only keep relevant columns for gauge display

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
