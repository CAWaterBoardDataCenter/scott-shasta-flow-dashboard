# Define the function to get the latest row of data
cdecFlowQuery <- function(station, sensor, duration) {

  start_date <- as.Date(now()) - 1
  end_date <- as.Date(now()) + 1

  # Retrieve the data from the CDER API
  x <- cdecQuery(station,
                 sensor,
                 duration,
                 start_date,
                 end_date)

  # Check if data is retrieved
  if (nrow(x) == 0) {
    stop("No data available for the specified station and sensor.")
  }

  # Filter for the latest row
  x <- x %>%
    filter(!is.na(Value)) %>%
     arrange(desc(DateTime)) %>%
    slice(1)

  return(x)
}


cdecQuery <- function(station,
                      sensor,
                      duration,
                      start_date,
                      end_date) {

  cdec_url <- "https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet"
  valid_durations <- c("E", "H", "D", "W", "M", "Q", "Y")


  if (missing(station)) {
    stop("No station provided.", call. = FALSE)
  } else {
    station_comp = glue("Stations={str_c(str_to_upper(station), collapse = '%2C')}")
  }
  if (missing(sensor)) {
    sensor_comp = ""
  } else {
    sensor_comp = glue("&SensorNums={str_c(sensor, collapse = '%2C')}")
  }
  if (missing(duration)) {
    duration_comp = ""
  } else {
    duration = str_to_upper(str_sub(duration, 1, 1))
    if (!all(duration %in% valid_durations)) {
      stop("Invalid duration codes detected: ",
           paste(setdiff(duration, valid_durations), collapse = ", "))
    }
    duration_comp = glue("&dur_code={str_c(duration, collapse = '%2C')}")
  }
  if (missing(start_date)) {
    start_comp = ""
  } else {
    start_date = as_date(start_date)
    start_comp = glue("&Start={start_date}")
  }
  if (missing(end_date)) {
    end_comp = ""
  } else {
    end_date = as_date(end_date)
    end_comp = glue("&End={end_date}")
  }

  url <- glue("{cdec_url}?",
                    "{station_comp}", "{sensor_comp}", "{duration_comp}",
                    "{start_comp}", "{end_comp}")

  result <- basic_query(url, col_spec)

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

basic_query <- function(url, col_spec) {

  cdec_tz <- "America/Los_Angeles"

  result <- curl_fetch_memory(url, handle = cder_handle())
  if (result$status_code != 200L)
    stop("CDEC query failed with status ",
         parse_headers(result$headers)[1], "\n",
         parse(text = rawToChar(result$content)), "\n",
         "URL request: ", result$url,
         call. = FALSE)
  value = rawToChar(result$content)
  Encoding(value) = "UTF-8"

    result = read_csv(value, locale = locale(tz = cdec_tz),
                    na = "---",
                    col_types = col_spec)

    if (nrow(problems(result)) > 0L) {
    problem_tf = tempfile(fileext = ".csv")
    problem_rows = str_split(value, "\r\n",
                             simplify = TRUE)[c(1, problems(result)$row)]
    writeLines(problem_rows, problem_tf)
    warning("Parsing problems detected. Output written to ",
            problem_tf, call. = FALSE)
  }
  return(result)

}

cder_handle = function() {
  h = new_handle()
  handle_setopt(h, connecttimeout = getOption("cder.timeout"))
  handle_setheaders(h, Accept = "application/json")
  h
}

col_spec = cols(
  VALUE = col_character(),
  DATA_FLAG = col_character(),
  UNITS = col_character()
  )

