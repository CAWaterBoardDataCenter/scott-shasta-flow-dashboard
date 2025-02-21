library(shiny)
library(flexdashboard)
library(bslib)
library(dplyr)

# Sample Data (Can be updated dynamically)
df <- tibble(
  StationID = "SPU",
  DateTime = as.POSIXct("2025-02-13 10:45:00"),
  Value = "ART",  # Change to a numeric value to test different cases
  rt_ul = 288
)

# UI
ui <- page_fluid(
  theme = bs_theme(bootswatch = "flatly"),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard"),

  layout_columns(

    ### Column and row sizes
    col_widths = c(4, 8, 12),
    row_heights = c(1, 4),

    card(
      # max_height = "220px",
      # full_screen = FALSE,
      card_header(
        class = "bg-blue",
        textOutput("header_text")
      ),
      card_body(
        flexdashboard::gaugeOutput("gauge_plot"),
        uiOutput("art_warning")  # Dynamic warning message
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  output$header_text <- renderText({
    paste("Station ID:", df$StationID, "    Last Update:", df$DateTime)
  })

  output$gauge_plot <- renderGauge({
    # Determine gauge numeric value
    gauge_value <- ifelse(df$Value == "ART", df$rt_ul, as.numeric(df$Value))

    # Determine gauge symbol
    gauge_symbol <- ifelse(df$Value == "ART", "ART", "cfs")

    # Render gauge
    flexdashboard::gauge(
      value = gauge_value,
      min = 0,
      max = df$rt_ul,
      symbol = gauge_symbol,
      label = "Flow Rate"
    )
  })

  output$art_warning <- renderUI({
    if (df$Value == "ART") {
      div(style = "color: red; font-weight: bold; text-align: center; margin-top: 10px;",
          "Gauge is reading above the rating table.")
    }
  })
}

# Run App
shinyApp(ui, server)
