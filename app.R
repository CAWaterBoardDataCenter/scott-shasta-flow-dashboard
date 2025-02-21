library(shiny)
library(flexdashboard)
library(bslib)
library(leaflet)
library(dplyr)
library(purrr)
library(cder)
library(lubridate)
library(readr)
library(glue)
library(stringr)
library(curl)
library(DT)

# Load station information. ----
sta_info <- read_csv("station-info.csv")

# Load functions to fetch flow values. ----
source("cdecFlowQuery.R")

# Define cards. ----

# Define Gauge 1 card.
g1_card <- card(
  card_header("Scott R. at Fort Jones (SFJ)"),
  card_body(
    textOutput("sfj_recorded"),
    gaugeOutput("gauge_sfj"),
  )
)

# Define Gauge 2 card.
g2_card <- card(
  card_header("Shasta R. at Yreka (SRY)"),
  card_body(
    textOutput("sry_recorded"),
    gaugeOutput("gauge_sry")
  )
)

#Define Map card.
map_card <- card(
  full_screen = TRUE,
  card_header("Map"),
  card_body(
    leafletOutput("map", height = "100%")
  )
)

# Define About card.
about_card <- card(
  height = "25vh",
  #  full_screen = TRUE,
  card_header("About The Dashboard"),
  card_body(
    p("This dashboard is a concept for monitoring the flow of the Scott and Shasta Rivers."),
    br(),
    textOutput("lastUpdated")
  )
)

# Define UI. ----
ui <- fluidPage(
  theme = bslib::bs_theme(preset = "litera"),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard"),

  layout_column_wrap(
    width = NULL,
    height = 700,
    fill = FALSE,
    style = css(grid_template_columns = "1fr 3fr"),
    layout_column_wrap(
      width = 1,
      heights_equal = "row",
      g1_card, g2_card
    ),
    map_card,
  ),
  about_card

)

# Define Server. ----
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

      mutate(Value = as.numeric(Value))

    flow_data(new_data)
    last_update(Sys.time())
  }

  # Refresh data every 15 minutes safely
  observe({
    invalidateLater(15 * 60 * 1000, session)
    update_data()
  })



  # Render SFJ gauge
  output$gauge_sfj <- renderGauge({
    req(flow_data())
    data <- flow_data()
    data <- data %>%
      filter(StationID == "SFJ")

    gauge(
      value = data$Value,
      min = 0, max = 1000,
      label = NA,
      symbol = "cfs",
      sectors = gaugeSectors(success = c(241, 1000),
                             warning = c(201, 240),
                             danger = c(0,200)
      )
    )
  })

  # render last recorded date.
  output$sfj_recorded <- renderText({
    req(flow_data())
    data <- flow_data()
    data <- data %>%
      filter(StationID == "SFJ")
    paste("Last recorded:", data$DateTime)
  })

  # Render SRY gauge.
  output$gauge_sry <- renderGauge({
    req(flow_data())
    data <- flow_data()
    data <- data %>%
      filter(StationID == "SRY")

    gauge(
      value = data$Value,
      min = 0, max = 1000,
      label = NA,
      symbol = "cfs",
      sectors = gaugeSectors(success = c(241, 1000),
                             warning = c(201, 240),
                             danger = c(0,200)
      )
    )
  })

  # render last recorded date.
  output$sry_recorded <- renderText({
    req(flow_data())
    data <- flow_data()
    data <- data %>%
      filter(StationID == "SRY")
    paste("Last recorded:", data$DateTime)
  })

  # Render leaflet map centered on Sacramento, CA.
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenTopoMap) %>%
 #     addTiles() %>%
      #add points for SFJ and SRY
      addCircleMarkers(lng = -123.0150,
                       lat = 41.64069,
                       radius = 10,
                       color = "red",
                       fillOpacity = 1,
                       label = "SFJ",
                       labelOptions = labelOptions(noHide = TRUE,
                                                   textsize = "15px")) %>%
      addCircleMarkers(lng = -122.5956,
                 lat = 41.82292,
                 radius = 10,
                 color = "red",
                 fillOpacity = 1,
                 label = "SRY",
                 labelOptions = labelOptions(noHide = TRUE,
                                             textsize = "15px"))
  })

  # Render Last Updated Time
  output$lastUpdated <- renderText({
    paste("Last update:", format(last_update(), "%Y-%m-%d %H:%M:%S"))
  })

  # Render flow datatable.
  output$flow_table <- renderDT({
    req(flow_data())
    data <- flow_data()
    datatable(data, rownames = FALSE)
  })


}

# Run App
shinyApp(ui, server)
