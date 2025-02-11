library(purrr)
library(cder)
library(dplyr)
library(readr)
library(glue)
library(stringr)
library(lubridate)
library(curl)

source("cdecFlowQuery.R")

sta_info <- read_csv("station-info.csv")[1:3, 1:3]


# Call the function
new_data <- pmap_df(.l = sta_info,
                    .f = cdecFlowQuery)

new_data2 <- sta_info %>% pmap_df(., cdecFlowQuery)

