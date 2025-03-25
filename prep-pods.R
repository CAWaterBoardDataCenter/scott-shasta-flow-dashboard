library(tidyr)
library(dplyr)
library(readxl)
library(aws.s3)

# Load data sets.
shasta_pods <- read_xlsx("./aws-data/ShastaPBI.xlsx")
scott_pods <- read_xlsx("./aws-data/ScottPBI.xlsx")

# Process data.
pods <- bind_rows(shasta_pods, scott_pods) %>%
  select(wr_id = `Application Number`,
         owner = `Primary Owner`,
         lat = Latitude,
         lon = Longitude,
         curtail_status = `Curtailment Status`) %>%
  mutate(curtail_status = trimws(as.character(curtail_status)))  # Remove spaces

prep_date <- Sys.time()

# Save pods and prep_date in a .RData file.
save(pods, prep_date, file = "pods.RData")

# Upload the .RData file to "dwr-shiny-apps" AWS S3 bucket.
put_object(
  file = "pods.RData",
  object = "scott-shasta-monitoring-pods",
  bucket = "dwr-shiny-apps"
)


