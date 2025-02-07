library(purrr)
library(cder)
library(dplyr)
library(readr)
library(glue)
library(stringr)
library(lubridate)
library(curl)

source("cdecFlowQuery.R")

cdec_stations <- c("SFJ", # Scott R. near Fort Jones
                   "SRY", # Shasta R. at Yreka
                   "SRM")#, # Shasta R. near Montague
#                   "SPU"  # Shasta R. at Grenada Pump Plant
sensor <- 20
duration <- "E"
start_date <- as.Date(now()) - 1
end_date <- as.Date(now())

# Call the function
new_data <- map_df(cdec_stations,
                   cdecFlowQuery,
                   sensor = sensor,
                   duration = duration,
                   start_date = start_date,
                   end_date = end_date)

new_data2 <- cdecFlowQuery(station = cdec_stations, sensor = sensor, duration = duration, start_date = start_date, end_date = end_date)
