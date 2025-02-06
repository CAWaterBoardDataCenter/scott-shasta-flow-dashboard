library(dplyr)
library(readr)
library(glue)
library(stringr)
library(lubridate)
library(curl)
#
# stations <- "SPU"
# sensors <- 20
# durations <- "E"
# start_date <- as.Date(now()) - 2
# end_date <- as.Date(now()) + 1
#
# single_query_url = "https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet"
# valid.durations = c("E", "H", "D", "W", "M", "Q", "Y")
# cdec.tz = "America/Los_Angeles"


cdecQuery <- function(stations,
                      sensors,
                      durations,
                      start_date,
                      end_date) {

  single_query_url<- "https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet"
  valid.durations <- c("E", "H", "D", "W", "M", "Q", "Y")


  if (missing(stations)) {
    stop("No stations provided.", call. = FALSE)
  } else {
    station.comp = glue("Stations={str_c(str_to_upper(stations), collapse = '%2C')}")
  }
  if (missing(sensors)) {
    sensor.comp = ""
  } else {
    sensor.comp = glue("&SensorNums={str_c(sensors, collapse = '%2C')}")
  }
  if (missing(durations)) {
    duration.comp = ""
  } else {
    durations = str_to_upper(str_sub(durations, 1, 1))
    if (!all(durations %in% valid.durations)) {
      stop("Invalid duration codes detected: ",
           paste(setdiff(durations, valid.durations), collapse = ", "))
    }
    duration.comp = glue("&dur_code={str_c(durations, collapse = '%2C')}")
  }
  if (missing(start_date)) {
    start.comp = ""
  } else {
    start_date = as_date(start_date)
    start.comp = glue("&Start={start_date}")
  }
  if (missing(end_date)) {
    end.comp = ""
  } else {
    end_date = as_date(end_date)
    end.comp = glue("&End={end_date}")
  }
  # query
  result <- basic_query(
    glue("{single_query_url}?",
         "{station.comp}", "{sensor.comp}", "{duration.comp}",
         "{start.comp}", "{end.comp}"),
    station.spec
  )
  result <- rename(result,
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
  return(result)
}

basic_query <- function(url, col.spec) {

  cdec.tz <- "America/Los_Angeles"

  result <- curl_fetch_memory(url, handle = cder_handle())
  if (result$status_code != 200L)
    stop("CDEC query failed with status ",
         parse_headers(result$headers)[1], "\n",
         parse(text = rawToChar(result$content)), "\n",
         "URL request: ", result$url,
         call. = FALSE)
  value = rawToChar(result$content)
  Encoding(value) = "UTF-8"
  result = read_csv(value, locale = locale(tz = cdec.tz),
                    na = c("---", "ART", "BRT"),
                    col_types = col.spec
  )
  if (nrow(problems(result)) > 0L) {
    problem_tf = tempfile(fileext = ".csv")
    problem_rows = str_split(value, "\r\n",
                             simplify = TRUE)[c(1, problems(result)$row)]
    writeLines(problem_rows, problem_tf)
    warning("Parsing problems detected. Output written to ",
            problem_tf, call. = FALSE)
  }

}

cder_handle = function() {
  h = new_handle()
  handle_setopt(h, connecttimeout = getOption("cder.timeout"))
  handle_setheaders(h, Accept = "application/json")
  h
}

station.spec = cols(
  STATION_ID = col_character(), DURATION = col_character(),
  SENSOR_NUMBER = col_integer(), SENSOR_TYPE = col_character(),
  `DATE TIME` = col_datetime(), `OBS DATE` = col_datetime(),
  VALUE = col_double(), DATA_FLAG = col_character(),
  UNITS = col_character())

