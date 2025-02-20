library(shiny)
library(flexdashboard)  # Using flexdashboard for gauges
library(leaflet)
library(bslib)

# Define cards. ----

# Define Gauge 1 card.
g1_card <- card(
  card_header("Gauge 1"),
  card_body(
    gaugeOutput("gauge1")  # flexdashboard gaugeOutput
  )
)

# Define Gauge 2 card.
g2_card <- card(
  card_header("Gauge 2"),
  card_body(
    gaugeOutput("gauge2")  # flexdashboard gaugeOutput
  )
)

#Define Map card.
map_card <- card(
  full_screen = TRUE,
  card_header("Map"),
  card_body(
     leafletOutput("map", height = "100%")
    )
  )

# Define About card.
about_card <- card(
  height = "25vh",
#  full_screen = TRUE,
  card_header("About The Dashboard"),
  card_body(
    p("This dashboard is a concept for monitoring the flow of the Scott and Shasta Rivers.")
  )
)

# Define UI. ----

ui <- page_fillable(
  theme = bslib::bs_theme(preset = "litera"),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard"),

  layout_column_wrap(
    width = NULL,
    height = 700,
    fill = FALSE,
    style = css(grid_template_columns = "1fr 3fr"),
    layout_column_wrap(
      width = 1,
      heights_equal = "row",
      g1_card, g2_card
    ),
     map_card,
  ),
  about_card
)

# Define Server. ----
server <- function(input, output, session) {

  # Render Leaflet Map centered at Sacramento, CA
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -121.4944, lat = 38.5816, zoom = 7) # Sacramento, CA
  })

  # Force Leaflet to redraw after rendering
  observe({
    session$sendCustomMessage("redrawMap", list())
  })

  # Render Gauges using flexdashboard
  output$gauge1 <- renderGauge({
    gauge(
      value = sample(1:100, 1),
      min = 0,
      max = 100,
      symbol = "%",
      label = "Gauge 1"
    )
  })

  output$gauge2 <- renderGauge({
    gauge(
      value = sample(1:100, 1),
      min = 0,
      max = 100,
      symbol = "%",
      label = "Gauge 2"
    )
  })
}

# Run App
shinyApp(ui, server)
