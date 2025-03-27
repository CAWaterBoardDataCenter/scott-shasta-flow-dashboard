library(aws.s3)
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

# Set application state (development or production). ----
Sys.setenv(R_CONFIG_ACTIVE = "production")

# Load data. ----
# Station information.
sta_info <- read_csv("data/station-info.csv")

# Minimum instream flow time series.
load("data/mif-tables.RData")

# # Load and prepare POD data set. ----

# Load config data.
config_data <- config::get()

# Set AWS credentials and region as environment variables
Sys.setenv(
  "AWS_BUCKET" = config_data$aws$bucket,
  "AWS_ACCESS_KEY_ID" = config_data$aws$access_key,
  "AWS_SECRET_ACCESS_KEY" = config_data$aws$secret_key,
  "AWS_DEFAULT_REGION" = config_data$aws$region
)

# Load data.
obj <- get_object(
  object = "scott-shasta-monitoring-pods",
  bucket = Sys.getenv("AWS_BUCKET"),
  as = "raw")

# Convert raw object to R readable format.
raw_conn <- rawConnection(obj)
load(raw_conn)
close(raw_conn)

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

# Define expected order of curtailment statuses.
expected_levels <- c("Not Curtailed", "Curtailed")

# Extract actual levels present in the dataset while preserving expected order
actual_levels <- expected_levels[expected_levels %in% unique(pods$curtail_status)]

# Convert to factor using expected order to maintain color consistency.
pods <- pods %>%
  mutate(curtail_status = factor(curtail_status, levels = expected_levels))

# Create a color palette ensuring "Not Curtailed" is green & "Curtailed" is red.
pal <- colorFactor(palette = c("red", "green"), domain = expected_levels)

# Define cards. ----

## Define Gauge 1 card. ----
g1_card <- card(
  card_header(HTML("Scott R. at Fort Jones (SFJ)")),
  card_body(
    textOutput("sfj_recorded"),
    gaugeOutput("gauge_sfj"),
    textOutput("sfj_mif")
  )
)

## Define Gauge 2 card. ----
g2_card <- card(
  card_header(HTML("Shasta R. at Yreka (SRY)")),
  card_body(
    textOutput("sry_recorded"),
    gaugeOutput("gauge_sry"),
    textOutput("sry_mif")
  )
)

## Define Map card. ----
map_card <- card(
  full_screen = TRUE,
  card_header("Point of Diversion Curtailment Status Map"),
  card_body(
    leafletOutput("map", height = "100%")
  )
)

## Define About card. ----
about_card <- card(
 #  height = "10vh",
 # fillable = TRUE,
 # fill = TRUE,
  card_header("About The Dashboard"),
  card_body(
    div(class = "card-body",
        p("This application serves as a centralized dashboard for monitoring stream flow in the Shasta and Scott Rivers. Flow data is retrieved from the Dept. of Water Resources' ",
          tags$a(href = "https://cdec.water.ca.gov/", "California Data Exchange Center (CDEC)", target = "_blank"),
          " at 15-minute intervals. The dashboard also includes a map showing the curtailment status of points of diversion (PODs) along the rivers."),
        tags$ul(

          tags$li("Click the Station links on the map to view CDEC's plots of recent flows. Click on the PODs to view their water right information."),
          tags$li(
            "Link to Scott River Curtailment Webpage: ",
            tags$a(href = "https://www.waterboards.ca.gov/drought/scott_shasta_rivers/scott_2024addendums.html", "Scott River Watershed Curtailment Orders and Addendums", target = "_blank")
          ),
          tags$li(
            "Link to Shasta River Curtailment Webpage: ",
            tags$a(href = "https://waterboards.ca.gov", "Shasta River Watershed Curtailment Orders and Addendums", target = "_blank")
          )
        )
    )
  )
)


# Define UI. --------

ui <- page_fillable(
  theme = bslib::bs_theme(preset = "litera"),

  # Load CSS styles for the dashboard.
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),

  # Modified titlePanel with logo
  div(
    class = "title-container",
    img(src = "enf-logo.png", class = "logo"),
    h1("Scott and Shasta Rivers Flow Monitoring Dashboard")
  ),

  layout_column_wrap(
    width = NULL,
    height = 510,
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

  # Last updated text.
  div(class = "last-updated-container",
      div(class = "left-updated", textOutput("gaugeLastUpdated")),
      div(class = "right-updated", textOutput("podLastUpdated"))
  )

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

  # Render SFJ gauge. ----
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

  # Render SRY gauge. ----
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

  # Render leaflet map. ----
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Esri.WorldTopoMap) %>%
      #     addTiles() %>%

      # Add guage points for SFJ and SRY/
      addCircleMarkers(group = "cdec-gages",
                       lng = -123.0150,
                       lat = 41.64069,
                       radius = 10,
                       color = "blue",
                       fillOpacity = 1,
                       label = HTML("<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9263&end=&geom=small&interval=2' target='_blank'>SFJ</a>"),
                       labelOptions = labelOptions(noHide = TRUE,
                                                   interactive = TRUE,
                                                   direction = "bottom",
                                                   textsize = "15px")
      ) %>%
      addCircleMarkers(group = "cdec-gages",
                       lng = -122.5956,
                       lat = 41.82292,
                       radius = 10,
                       color = "blue",
                       fillOpacity = 1,
                       label = HTML("<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9254&end=&geom=small&interval=2' target='_blank'>SRY</a>"),
                       labelOptions = labelOptions(noHide = TRUE,
                                                   interactive = TRUE,
                                                   direction = "bottom",
                                                   textsize = "15px")) %>%

      # Add pod_curtailment_status points.
      addCircleMarkers(
        group = "pods",
        data = pods,
        lng = ~lon,
        lat = ~lat,
        popup = ~paste("WR ID:", wr_id, "<br>Owner:", owner, "<br>Status:", curtail_status),
        radius = 6,
        color = ~pal(curtail_status),  # Now correctly mapped
        stroke = TRUE,
        weight = 1.0,
        fillOpacity = 0.5
      ) %>%

      # Add legend for curtailment status.
      addLegend(
        group = "pods",
        data = pods,
        position = "bottomright",
        pal = pal,
        values = ~curtail_status,
        title = "Curtailment Status",
        opacity = 1
      )
  })

  # # Render time gauge data was last retrieved.
  # output$lastUpdated <- renderText({
  #   paste0("Gauge data last retrieved: ", format(last_update(), "%Y-%m-%d %H:%M:%S"), ".      ",
  #         "POD curtailment data last updated:", format(prep_date, "%Y-%m-%d")
  #         )
  # })

  # Render time gauge data was last retrieved.
  output$gaugeLastUpdated <- renderText({
    paste("Gauge data last retrieved:", format(last_update(), "%Y-%m-%d %H:%M:%S"))
  })

  # Render time POD data was last updated.
  output$podLastUpdated <- renderText({
    paste("POD curtailment data last updated:", format(prep_date, "%Y-%m-%d"))  # Customize as needed
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
