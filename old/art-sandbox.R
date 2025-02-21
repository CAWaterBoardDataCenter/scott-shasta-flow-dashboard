library(shiny)
library(flexdashboard)
library(bslib)
library(dplyr)

#testing variables.
df1 <- tibble(StationID = "SPU",
             DateTime = as.POSIXct("2025-02-13 10:45:00"),
              Value = "238",
              rt_ul = 288
              )

df2 <- tibble(StationID = "SPU",
              DateTime = as.POSIXct("2025-02-13 10:45:00"),
              Value = "ART",
              rt_ul = 288
)

# Create card
card(
  card_header(
    class = "bg-blue",
    paste("Station ID:", df1$StationID, "    Last Update:", df1$DateTime)),
  card_body(
    flexdashboard::gauge(
      value = as.numeric(df1$Value),
      min = 0,
      max = df1$rt_ul,
      symbol = "cfs",
      label = "Flow Rate"
    )
  )
)

# Use df2 instead of df1 for condition check
display_value <- ifelse(df2$Value == "ART", paste0(">", df2$rt_ul), as.numeric(df2$Value))

# Create card
card(
  card_header(
    class = "bg-blue",
    paste("Station ID:", df2$StationID, "    Last Update:", df2$DateTime)
  ),
  card_body(
    flexdashboard::gauge(
      value = display_value,
      min = 0,
      max = df2$rt_ul,
      symbol = "cfs",
      label = "Flow Rate"
    )
  )
)

#####################

# Determine gauge numeric value
gauge_value <- ifelse(df2$Value == "ART", df2$rt_ul, as.numeric(df2$Value))

# Determine gauge symbol
gauge_symbol <- ifelse(df2$Value == "ART", "ART", "cfs")

# Create card
card(
  max_height = "220px",
  full_screen = FALSE,
  card_header(
    class = "bg-blue",
    paste("Station ID:", df2$StationID, "    Last Update:", df2$DateTime)
  ),
  card_body(
    flexdashboard::gauge(
      value = gauge_value,
      min = 0,
      max = df2$rt_ul,
      symbol = gauge_symbol,  # Dynamically set symbol
      label = "Flow Rate"
    ),
    # Add a note below the gauge if ART is detected
    if (df2$Value == "ART") {
      div(style = "color: red; font-weight: bold; text-align: center; margin-top: 10px;",
          "Gauge is reading above the rating table.")
    }
  )
)
