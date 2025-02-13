library(purrr)
library(cder)
library(dplyr)
library(readr)
library(glue)
library(stringr)
library(lubridate)
library(curl)

#testing variables.
station <- "SPU"
sensor <- 20
duration <- "E"
start_date <- as.Date(now()) - 1
end_date <- as.Date(now()) + 1

source("cdecFlowQuery.R")

sta_info <- read_csv("station-info.csv")

# Call the function

new_data <- sta_info[, 1:3] %>%
 pmap_dfr(., cdecFlowQuery) %>%
  mutate(
    Date = as.Date(DateTime, tz = "America/Los_Angeles"),
    Time = format(as.POSIXct(DateTime, tz = "America/Los_Angeles"), "%H:%M:%S")
  )
new_data_t <- new_data %>%
  mutate(Value = ifelse(Value == "ART", format(rt_ul, ">"), Value))

spu <- read_csv("https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet?Stations=SPU&SensorNums=20&dur_code=E&Start=2025-02-11&End=2025-02-13")
sfj <- read_csv("https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet?Stations=SFJ&SensorNums=20&dur_code=E&Start=2025-02-11&End=2025-02-12")


x2 <- 62
x2f <- format(x2, ">")
