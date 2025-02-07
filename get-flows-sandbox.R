library(purrr)
library(cder)
library(dplyr)
library(readr)
library(glue)
library(stringr)
library(lubridate)
library(curl)

sta_info <- read_csv("station-info.csv")

source("cdecFlowQuery.R")


start_date <- as.Date(now()) - 1
end_date <- as.Date(now())

# Call the function
new_data <- pmap(.l = list(names(sta_info[1:3])),
                   .f = cdecFlowQuery)



new_data
