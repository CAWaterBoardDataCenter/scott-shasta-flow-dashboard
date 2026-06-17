# 1. Load libraries. ----
library(aws.s3)
library(shiny)
library(flexdashboard)
library(htmlwidgets)
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
library(sf)

# 2. Set application state for AWS (development or production). ----
Sys.setenv(R_CONFIG_ACTIVE = yaml::read_yaml("config.yml")$active_env)

## Read AWS config data from config.yml.
config_data <- config::get()

## Set AWS credentials and region as environment variables.
Sys.setenv(
  "AWS_BUCKET" = config_data$aws$bucket,
  "AWS_ACCESS_KEY_ID" = config_data$aws$access_key,
  "AWS_SECRET_ACCESS_KEY" = config_data$aws$secret_key,
  "AWS_DEFAULT_REGION" = config_data$aws$region
)

# 3. Load data. ----

## Station information. ----
sta_info <- read_csv("data/station-info.csv")

## Minimum instream flow lookup tables. ----
load("data/mif-tables.RData")

## Load POD data. ----
## Fetches the POD object from S3 and returns the POD data frame (with plot
## colors mapped) along with its prep date. Defined as a function so the app
## can re-fetch fresh data via the refresh button without restarting.
loadPods <- function() {
  obj <- get_object(
    object = "scott-shasta-monitoring-pods",
    bucket = Sys.getenv("AWS_BUCKET"),
    as = "raw"
  )

  raw_conn <- rawConnection(obj)
  load(raw_conn) # loads `pods` and `prep_date`
  close(raw_conn)

  ### Map POD plot color to curtailment status.
  pods <- pods %>%
    mutate(
      color = case_when(
        curtail_status == "Not Curtailed" ~ "green",
        curtail_status == "Conditionally Suspended" ~ "chartreuse",
        curtail_status == "Conditionally Curtailed" ~ "yellow",
        curtail_status == "Curtailed" ~ "red",
        TRUE ~ "gray"
      )
    )

  list(pods = pods, prep_date = prep_date)
}

### Initial POD load at startup.
initial_pods <- loadPods()
pods <- initial_pods$pods
prep_date <- initial_pods$prep_date

## Load watershed boundaries for the map. ----
watershedBoundaries <- sf::st_read(
  "./data/scott-shasta-huc8s/scott-shasta-huc8s.shp"
) %>%
  sf::st_transform("+proj=longlat +datum=WGS84")

## Load stream lines for the map. ----
stream_lines <- sf::st_read(
  "./data/scott-shasta-rivers/scott-shasta-rivers.shp"
) %>%
  sf::st_transform("+proj=longlat +datum=WGS84") %>%
  st_zm()

# 4. Define support functions. ----

col_spec <- cols(
  VALUE = col_character(),
  DATA_FLAG = col_character(),
  UNITS = col_character()
)

cder_handle <- function() {
  h <- new_handle()
  handle_setopt(h, connecttimeout = getOption("cder.timeout"))
  handle_setheaders(h, Accept = "application/json")
  h
}

basic_query <- function(url, col_spec) {
  cdec_tz <- "America/Los_Angeles"

  result <- curl_fetch_memory(url, handle = cder_handle())
  if (result$status_code != 200L) {
    stop(
      "CDEC query failed with status ",
      parse_headers(result$headers)[1],
      "\n",
      parse(text = rawToChar(result$content)),
      "\n",
      "URL request: ",
      result$url,
      call. = FALSE
    )
  }

  value <- rawToChar(result$content)
  Encoding(value) <- "UTF-8"

  result <- read_csv(
    I(value),
    locale = locale(tz = cdec_tz),
    na = "---",
    col_types = col_spec
  )

  if (nrow(problems(result)) > 0L) {
    problem_tf <- tempfile(fileext = ".csv")
    problem_rows <- str_split(value, "\r\n", simplify = TRUE)[c(
      1,
      problems(result)$row
    )]
    writeLines(problem_rows, problem_tf)
    warning(
      "Parsing problems detected. Output written to ",
      problem_tf,
      call. = FALSE
    )
  }

  result
}

cdecQuery <- function(station, sensor, duration, start_date, end_date) {
  cdec_url <- "https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet"
  valid_durations <- c("E", "H", "D", "W", "M", "Q", "Y")

  if (missing(station)) {
    stop("No station provided.", call. = FALSE)
  } else {
    station_comp <- glue(
      "Stations={str_c(str_to_upper(station), collapse = '%2C')}"
    )
  }

  sensor_comp <- if (missing(sensor)) {
    ""
  } else {
    glue("&SensorNums={str_c(sensor, collapse = '%2C')}")
  }

  if (missing(duration)) {
    duration_comp <- ""
  } else {
    duration <- str_to_upper(str_sub(duration, 1, 1))
    if (!all(duration %in% valid_durations)) {
      stop(
        "Invalid duration codes detected: ",
        paste(setdiff(duration, valid_durations), collapse = ", ")
      )
    }
    duration_comp <- glue("&dur_code={str_c(duration, collapse = '%2C')}")
  }

  start_comp <- if (missing(start_date)) {
    ""
  } else {
    glue("&Start={as_date(start_date)}")
  }
  end_comp <- if (missing(end_date)) "" else glue("&End={as_date(end_date)}")

  url <- glue(
    "{cdec_url}?{station_comp}{sensor_comp}{duration_comp}{start_comp}{end_comp}"
  )

  basic_query(url, col_spec) %>%
    rename(
      StationID = "STATION_ID",
      DateTime = "DATE TIME",
      SensorType = "SENSOR_TYPE",
      Value = "VALUE",
      DataFlag = "DATA_FLAG",
      SensorUnits = "UNITS",
      SensorNumber = "SENSOR_NUMBER",
      Duration = "DURATION",
      ObsDate = "OBS DATE"
    )
}

cdecFlowQuery <- function(station, sensor, duration) {
  x <- cdecQuery(
    station,
    sensor,
    duration,
    as.Date(now()) - 1,
    as.Date(now()) + 1
  )

  if (nrow(x) == 0) {
    stop("No data available for the specified station and sensor.")
  }

  x %>%
    filter(!is.na(Value)) %>%
    arrange(desc(DateTime)) %>%
    slice(1)
}

roundUpAuto <- function(x) {
  vapply(x, FUN.VALUE = numeric(1), FUN = function(xi) {
    if (xi < 10) {
      return(10)
    }
    e <- floor(log10(xi))
    base <- 10^e
    base * ceiling(xi / base)
  })
}

sameMonthDay <- function(date1, date2) {
  d1 <- ymd(date1)
  d2 <- ymd(date2)
  identical(month(d1), month(d2)) && identical(day(d1), day(d2))
}

# 5. Pull today's minimum instream flow values. ----

mifs_today <- map(
  mifs,
  ~ filter(.x, map_lgl(day_month, ~ sameMonthDay(.x, Sys.Date())))
)

# 6. Define cards. ----

## Gauge 1 card. ----
g1_card <- card(
  card_header(HTML("Scott R. at Fort Jones (SFJ)")),
  card_body(
    textOutput("sfj_recorded"),
    gaugeOutput("gauge_sfj"),
    textOutput("sfj_mif")
  )
)

## Gauge 2 card. ----
g2_card <- card(
  card_header(HTML("Shasta R. at Yreka (SRY)")),
  card_body(
    textOutput("sry_recorded"),
    gaugeOutput("gauge_sry"),
    textOutput("sry_mif")
  )
)

## Map card. ----
map_card <- card(
  full_screen = TRUE,
  card_header("Point of Diversion Curtailment Status Map"),
  card_body(
    leafletOutput("map", height = "100%")
  )
)

## About card. ----
about_card <- card(
  card_header("About The Dashboard"),
  card_body(
    div(
      class = "card-body",
      actionButton(
        "refresh_pods",
        "Refresh POD Data",
        icon = icon("rotate"),
        class = "btn-primary btn-sm"
      ),
      p(
        "This application serves as a centralized dashboard for monitoring stream flow in the Shasta and Scott Rivers. Flow data is retrieved from the Dept. of Water Resources' ",
        tags$a(
          href = "https://cdec.water.ca.gov/",
          "California Data Exchange Center (CDEC)",
          target = "_blank"
        ),
        " at 15-minute intervals. The dashboard also includes a map showing the curtailment status of points of diversion (PODs) along the rivers."
      ),
      tags$ul(
        tags$li(
          "Click the Station links on the map to view CDEC's plots of recent flows. Click on the PODs to view their water right information."
        ),
        tags$li(
          "Link to Scott River Curtailment Webpage: ",
          tags$a(
            href = "https://www.waterboards.ca.gov/drought/scott_shasta_rivers/scott_2024addendums.html",
            "Scott River Watershed Curtailment Orders and Addendums",
            target = "_blank"
          )
        ),
        tags$li(
          "Link to Shasta River Curtailment Webpage: ",
          tags$a(
            href = "https://www.waterboards.ca.gov/drought/scott_shasta_rivers/shasta_2024addendums.html",
            "Shasta River Watershed Curtailment Orders and Addendums",
            target = "_blank"
          )
        )
      )
    )
  )
)

# 7. Define UI. ----

ui <- page_fillable(
  theme = bslib::bs_theme(preset = "litera"),

  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),

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
      g1_card,
      g2_card
    ),
    map_card
  ),
  about_card,

  div(
    class = "last-updated-container",
    div(class = "left-updated", textOutput("gaugeLastUpdated")),
    div(class = "center-updated", textOutput("appEnvironment")),
    div(class = "right-updated", textOutput("podLastUpdated"))
  )
)

# 8. Define server. ----

server <- function(input, output, session) {
  flow_data <- reactiveVal(NULL)
  last_update <- reactiveVal(Sys.time())

  # POD data reactives (refreshable from AWS via the refresh button). ----
  pod_data <- reactiveVal(pods)
  pod_prep_date <- reactiveVal(prep_date)

  observeEvent(input$refresh_pods, {
    tryCatch(
      {
        refreshed <- loadPods()
        pod_data(refreshed$pods)
        pod_prep_date(refreshed$prep_date)
        showNotification("POD data refreshed from AWS.", type = "message")
      },
      error = function(e) {
        showNotification(
          paste("Failed to refresh POD data:", conditionMessage(e)),
          type = "error",
          duration = NULL
        )
      }
    )
  })

  update_data <- function() {
    new_data <- sta_info[, 1:3] %>%
      pmap_dfr(cdecFlowQuery) %>%
      mutate(
        Date = as.Date(DateTime, tz = "America/Los_Angeles"),
        Time = format(
          as.POSIXct(DateTime, tz = "America/Los_Angeles"),
          "%H:%M:%S"
        ),
        Value = as.numeric(Value)
      )
    flow_data(new_data)
    last_update(Sys.time())
  }

  observe({
    invalidateLater(15 * 60 * 1000, session)
    update_data()
  })

  # Render SFJ gauge. ----
  output$gauge_sfj <- renderGauge({
    req(flow_data())
    data <- flow_data() %>% filter(StationID == "SFJ")
    gauge(
      value = data$Value,
      min = 0,
      max = roundUpAuto(data$Value),
      label = NA,
      symbol = "cfs",
      sectors = gaugeSectors(
        success = c(mifs_today$sfj_limits$success_lo, roundUpAuto(data$Value)),
        warning = c(
          mifs_today$sfj_limits$warning_lo,
          mifs_today$sfj_limits$warning_hi
        ),
        danger = c(0, mifs_today$sfj_limits$danger_hi)
      )
    )
  })

  output$sfj_recorded <- renderText({
    req(flow_data())
    paste(
      "Recorded:",
      flow_data() %>% filter(StationID == "SFJ") %>% pull(DateTime)
    )
  })

  output$sfj_mif <- renderText({
    paste("Minimum Instream Flow:", mifs_today$sfj_limits$mif, "cfs")
  })

  # Render SRY gauge. ----
  output$gauge_sry <- renderGauge({
    req(flow_data())
    data <- flow_data() %>% filter(StationID == "SRY")
    gauge(
      value = data$Value,
      min = 0,
      max = roundUpAuto(data$Value),
      label = NA,
      symbol = "cfs",
      sectors = gaugeSectors(
        success = c(mifs_today$sry_limits$success_lo, roundUpAuto(data$Value)),
        warning = c(
          mifs_today$sry_limits$warning_lo,
          mifs_today$sry_limits$warning_hi
        ),
        danger = c(0, mifs_today$sry_limits$danger_hi)
      )
    )
  })

  output$sry_recorded <- renderText({
    req(flow_data())
    paste(
      "Recorded:",
      flow_data() %>% filter(StationID == "SRY") %>% pull(DateTime)
    )
  })

  output$sry_mif <- renderText({
    paste("Minimum Instream Flow:", mifs_today$sry_limits$mif, "cfs")
  })

  # Render leaflet map. ----
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Esri.WorldStreetMap, group = "Street") %>%
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Topographic") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial") %>%
      addLayersControl(
        baseGroups = c("Street", "Topographic", "Aerial"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addCircleMarkers(
        group = "cdec-gages",
        lng = -123.0150,
        lat = 41.64069,
        radius = 7,
        color = "blue",
        fillOpacity = 1,
        label = HTML(
          "<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9263&end=&geom=small&interval=2' target='_blank'>SFJ</a>"
        ),
        labelOptions = labelOptions(
          noHide = TRUE,
          interactive = TRUE,
          direction = "bottom",
          textsize = "15px"
        )
      ) %>%
      addCircleMarkers(
        group = "cdec-gages",
        lng = -122.5956,
        lat = 41.82292,
        radius = 7,
        color = "blue",
        fillOpacity = 1,
        label = HTML(
          "<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9254&end=&geom=small&interval=2' target='_blank'>SRY</a>"
        ),
        labelOptions = labelOptions(
          noHide = TRUE,
          interactive = TRUE,
          direction = "bottom",
          textsize = "15px"
        )
      ) %>%
      addCircleMarkers(
        group = "PODs",
        data = isolate(pod_data()),
        lng = ~lon,
        lat = ~lat,
        radius = 4,
        color = ~color,
        stroke = TRUE,
        weight = 1,
        fillOpacity = 0.6,
        popup = ~ paste(
          "WR ID:",
          wr_id,
          "<br>Owner:",
          owner,
          "<br>Status:",
          curtail_status
        )
      ) %>%
      addPolylines(
        data = stream_lines,
        group = "streams",
        color = "blue",
        weight = 2.0,
        opacity = 1.0
      ) %>%
      addLegend(
        position = "bottomright",
        colors = c("green", "chartreuse", "yellow", "red"),
        labels = c(
          "Not Curtailed",
          "Conditionally Suspended",
          "Conditionally Curtailed",
          "Curtailed"
        ),
        title = "Curtailment Status",
        opacity = 1
      )
  })

  # Update watershed boundary color when base map changes. ----
  observe({
    req(input$map_groups)
    color <- if ("Aerial" %in% input$map_groups) "white" else "black"
    leafletProxy("map") %>%
      clearGroup("watershedGroup") %>%
      addPolygons(
        data = watershedBoundaries,
        color = color,
        weight = 2,
        fill = FALSE,
        group = "watershedGroup"
      )
  })

  # Redraw POD markers when the data is refreshed (without resetting the map). ----
  observeEvent(pod_data(), ignoreInit = TRUE, {
    leafletProxy("map") %>%
      clearGroup("PODs") %>%
      addCircleMarkers(
        group = "PODs",
        data = pod_data(),
        lng = ~lon,
        lat = ~lat,
        radius = 4,
        color = ~color,
        stroke = TRUE,
        weight = 1,
        fillOpacity = 0.6,
        popup = ~ paste(
          "WR ID:",
          wr_id,
          "<br>Owner:",
          owner,
          "<br>Status:",
          curtail_status
        )
      )
  })

  # Render footer outputs. ----
  output$appEnvironment <- renderText({
    label <- if (Sys.getenv("R_CONFIG_ACTIVE") == "production") {
      "Production"
    } else {
      "Development"
    }
    paste("Environment:", label)
  })

  output$gaugeLastUpdated <- renderText({
    paste(
      "Gauge data last retrieved:",
      format(last_update(), "%Y-%m-%d %H:%M:%S %Z", tz = "America/Los_Angeles")
    )
  })

  output$podLastUpdated <- renderText({
    paste(
      "POD curtailment data last updated:",
      format(pod_prep_date(), "%Y-%m-%d")
    )
  })

  output$flow_table <- renderDT({
    req(flow_data())
    datatable(flow_data(), rownames = FALSE)
  })
}

# 9. Run app. ----
shinyApp(ui, server)
