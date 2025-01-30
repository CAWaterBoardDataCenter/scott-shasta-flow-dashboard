# Load necessary packages
library(dplyr)
library(cder)
library(lubridate)
library(purrr)

cdec_stations <- c("SJF", # Scott R. near Fort Jones
                   "SRM", # Shasta R. near Montague
                   "SRY"  # Shasta R. at Yreka
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

# Call the function
flow_values <- map_df(.x = cdec_stations,
                      .f = get_sensor20_flows)
