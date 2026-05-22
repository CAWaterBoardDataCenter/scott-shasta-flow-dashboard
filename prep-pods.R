library(tidyr)
library(dplyr)
library(readxl)
library(aws.s3)

save_s3 <- TRUE

# Set application state (development or production). ----
Sys.setenv(R_CONFIG_ACTIVE = "production")

# Load AWS S3 credentials.
config_data <- config::get()

# Set AWS credentials and region as environment variables
Sys.setenv(
  "AWS_BUCKET" = config_data$aws$bucket,
  "AWS_ACCESS_KEY_ID" = config_data$aws$access_key,
  "AWS_SECRET_ACCESS_KEY" = config_data$aws$secret_key,
  "AWS_DEFAULT_REGION" = config_data$aws$region
)

# Load curtailment status data sets.
scott <- list.files("./aws-data", pattern = "^ScottPBI-\\d{8}\\.xlsx$", full.names = TRUE) %>%
  sort() %>%
  last() %>%
  read_xlsx() %>%
  rename(`Application Number` = `Application Number/Diversion Number`)

shasta <- list.files("./aws-data", pattern = "^ShastaPBI-\\d{8}\\.xlsx$", full.names = TRUE) %>%
  sort() %>%
  last() %>%
  read_xlsx()

# Find the common column names between the two data frames
common_cols <- intersect(names(scott), names(shasta))

# Select only the common columns and combine the data frames using bind_rows
pods <- bind_rows(
  scott %>% select(all_of(common_cols)),
  shasta %>% select(all_of(common_cols))
) %>%
  select(wr_id = `Application Number`,
         owner = `Primary Owner`,
         lat = Latitude,
         lon = Longitude,
         curtail_status = `Curtailment Status`) %>%
  mutate(curtail_status = trimws(as.character(curtail_status)))

# Get the current date and time.
prep_date <- Sys.time()

# Save pods and prep_date in a .RData file.
save(pods, prep_date, file = "pods.RData")

if (save_s3) {
  # Upload the .RData file to "dwr-shiny-apps" AWS S3 bucket.
res <-   put_object(
    file = "pods.RData",
    object = "scott-shasta-monitoring-pods",
    bucket = config_data$aws$bucket
  )
}

