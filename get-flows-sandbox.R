library(dplyr)
library(purrr)
library(cder)
library(lubridate)

cdec_stations <- c("SRM", # Shasta R. near Montague
                   "SRY", # Shasta R. at Yreka
                   "SJF" # Scott R. near Fort Jones"
)

cdec_sensor <- 20 # Sensor ID


# Define the function to get the latest row of data
getCdecFlows <- function(station = "SJF", sensor = 20) {
  # Retrieve the data from the CDER API
  data <- cder::cdec_query(station = station, sensor = sensor)

  # Check if data is retrieved
  if (nrow(data) == 0) {
    stop("No data available for the specified station and sensor.")
  }

  # Filter for the latest row
  latest_data <- data %>%
    arrange(desc(datetime)) %>%
    slice(1)

  return(latest_data)
}

# Call the function
latest_flow <- getCdecFlows()
print(latest_flow)
