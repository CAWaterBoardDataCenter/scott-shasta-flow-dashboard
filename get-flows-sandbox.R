library(dplyr)
library(purrr)
library(cder)
library(lubridate)

cdec_stations <- c("SRM", # Shasta R. near Montague
                   "SRY", # Shasta R. at Yreka
                   "SJF" # Scott R. near Fort Jones"
)

sensor <- 20 # Sensor ID



# Define the function to get the latest row of data
getCdecFlow <- function(station = station, sensor = sensor) {

  # Retrieve the data from the CDER API
  x <- cder::cdec_query(station = station, sensor = sensor)

  # Check if data is retrieved
  if (nrow(x) == 0) {
    stop("No data available for the specified station and sensor.")
  }

  # Filter for the latest row
  x <- x %>%
    filter(!is.na(Value)) %>%
    arrange(desc(DateTime)) %>%
    slice(1)

  return(latest_data)
}




# Call the function
latest_flow <- getCdecFlow()
print(latest_flow)
