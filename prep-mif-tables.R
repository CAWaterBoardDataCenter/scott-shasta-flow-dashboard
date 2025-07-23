library(dplyr)
library(readr)
library(lubridate)

sfj <- read_csv(file = "mifs-sfj.csv",
                col_types = "cnnnnnnn") %>%
  mutate(across(
    .cols = (ncol(.) - 6):ncol(.),
    .fns = ~ as.integer(round(.))
  )) %>%
  mutate(day_month = mdy(day_month))

sry <- read_csv(file = "mifs-sry.csv",
                col_types = "cnnnnnnn") %>%
  mutate(across(
    .cols = (ncol(.) - 6):ncol(.),
    .fns = ~ as.integer(round(.))
  )) %>%
  mutate(day_month = mdy(day_month))

mifs <- list(sfj, sry)
names(mifs) <- c("sfj_limits", "sry_limits")

save(mifs, file = "data/mif-tables.RData")
