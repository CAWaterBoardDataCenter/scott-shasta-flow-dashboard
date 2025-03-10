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

# Load data. ----
# Station information.
sta_info <- read_csv("data/station-info.csv")

# Minimum instream flow time series.
load("data/mif-tables.RData")

# Load functions to fetch flow values. ----
source("cdecFlowQuery.R")

# Pull today's mimumum instream flow values. ----

sameMonthDay <- function(date1, date2) {
  # Convert the strings to date objects
  d1 <- ymd(date1)
  d2 <- ymd(date2)

  # Compare month and day
  identical(month(d1), month(d2)) && identical(day(d1), day(d2))
}

mifs_today <- map(mifs, ~
                    filter(.x, map_lgl(day_month,
                                       ~ sameMonthDay(.x, Sys.Date())))
)

# Define cards. ----

# Define Gauge 1 card.
g1_card <- card(
  card_header(HTML("Scott R. at Fort Jones<br/>(SFJ)")),
  card_body(
    textOutput("sfj_recorded"),
    gaugeOutput("gauge_sfj"),
    textOutput("sfj_mif")
  )
)

# Define Gauge 2 card.
g2_card <- card(
  card_header(HTML("Shasta R. at Yreka<br/>(SRY)")),
  card_body(
    textOutput("sry_recorded"),
    gaugeOutput("gauge_sry"),
    textOutput("sry_mif")
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
  # height = "25vh",
  fillable = TRUE,
  fill = TRUE,
  card_header("About The Dashboard"),
  card_body(
    "This dashboard monitors the flow of the Scott and Shasta Rivers at the gauges where Minimum Instream Flows must be met.",br(),
    "Click Station labels on the map to view plots of recent flows."
  )
)

# Define UI. ----
ui <- page_fillable(
  theme = bslib::bs_theme(preset = "litera"),

  # Load CSS styles for the dashboard.
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard"),

  layout_column_wrap(
    width = NULL,
    height = 600,
    fill = FALSE,
    style = css(grid_template_columns = "1fr 3fr"),
    layout_column_wrap(
      width = 1,
      heights_equal = "row",
      g1_card, g2_card
    ),
    map_card,
  ),
  about_card,
  textOutput("lastUpdated")

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
      min = 0, max = ceiling(data$Value / 100) * 100,
      label = NA,
      symbol = "cfs",
      sectors = gaugeSectors(success = c(mifs_today$sfj_limits$success_lo, ceiling(data$Value / 100) * 100),
                             warning = c(mifs_today$sfj_limits$warning_lo, mifs_today$sfj_limits$warning_hi),
                             danger = c(0,mifs_today$sfj_limits$danger_hi)
      )
    )
  })

  # render last recorded date.
  output$sfj_recorded <- renderText({
    req(flow_data())
    data <- flow_data()
    data <- data %>%
      filter(StationID == "SFJ")
    paste("Recorded:", data$DateTime)
  })

  output$sfj_mif <- renderText({
    paste("Minimum Instream Flow:", mifs_today$sfj_limits$mif, "cfs")
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
      sectors = gaugeSectors(success = c(mifs_today$sry_limits$success_lo, ceiling(data$Value / 100) * 100),
                             warning = c(mifs_today$sry_limits$warning_lo, mifs_today$sry_limits$warning_hi),
                             danger = c(0,mifs_today$sry_limits$danger_hi)
      )
    )
  })

  # render last recorded date.
  output$sry_recorded <- renderText({
    req(flow_data())
    data <- flow_data()
    data <- data %>%
      filter(StationID == "SRY")
    paste("Recorded:", data$DateTime)
  })

  output$sry_mif <- renderText({
    paste("Minimum Instream Flow:", mifs_today$sry_limits$mif, "cfs")
  })

  # Render leaflet map centered on Sacramento, CA.
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Esri.WorldTopoMap) %>%
      #     addTiles() %>%
      #add points for SFJ and SRY
      addCircleMarkers(group = "cdec-gages",
                       lng = -123.0150,
                       lat = 41.64069,
                       radius = 10,
                       color = "red",
                       fillOpacity = 1,
                       label = HTML("<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9263&end=&geom=small&interval=2' target='_blank'>SFJ</a>"),
                       labelOptions = labelOptions(noHide = TRUE,
                                                   interactive = TRUE,
                                                   direction = "bottom",
                                                   textsize = "15px")
      ) %>%
      addCircleMarkers(group = "cdec-gages",,
                       lng = -122.5956,
                       lat = 41.82292,
                       radius = 10,
                       color = "red",
                       fillOpacity = 1,
                       label = HTML("<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9254&end=&geom=small&interval=2' target='_blank'>SRY</a>"),
                       labelOptions = labelOptions(noHide = TRUE,
                                                   interactive = TRUE,
                                                   direction = "bottom",
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
