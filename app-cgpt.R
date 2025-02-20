library(shiny)
library(bslib)
library(leaflet)
library(shinydashboardPlus)  # For better card UI
library(shinyWidgets)  # For gauge UI

# Define UI
ui <- fluidPage(
  theme = bs_theme(bootswatch = "flatly"),

  # Custom CSS for proper height alignment
  tags$head(tags$style(HTML("
    .row-height {
      display: flex;
      height: 75vh;  /* Ensure full height for main section */
    }
    .left-column, .right-column {
      display: flex;
      flex-direction: column;
      height: 100%;
    }
    .fixed-card {
      height: 45%;  /* Adjust to control Card 1 height */
    }
    .flex-grow-card {
      flex-grow: 1;  /* Makes Card 2 take remaining space */
    }
  "))),

  titlePanel("Scott and Shasta Rivers Flow Monitoring Dashboard - Concept"),

  fluidRow(
    class = "row-height",  # Ensures row items align properly
    column(
      width = 3,  # 25% width
      div(class = "left-column",
          div(class = "fixed-card mb-3",
              card(
                card_header("Gauge 1", class = "gray-400"),
                card_body(
                  gaugeOutput("gauge1") # Content for Gauge 1
                )
              )
          ),
          div(class = "flex-grow-card",
              card(
                card_header("Gauge 2", class = "gray-400"),
                card_body(
                  gaugeOutput("gauge2") # Content for Gauge 2
                )
              )
          )
      )
    ),
    column(
      width = 9,  # 75% width
      div(class = "right-column",
          div(class = "flex-grow-card",  # Ensures Map grows like Gauge 2
              card(
                full_screen = TRUE,
                card_header("Map", class = "gray-400"),
                card_body(
                  leafletOutput("map") # Content for map.
                )
              )
          )
      )
    )
  ),

  fluidRow(
    column(
      width = 12,  # Full width for second row
      card(
        full_screen = TRUE,
        card_header("About The Dashboard", class = "gray-400"),
        card_body(
          p("This dashboard is a concept for monitoring the flow of the Scott and Shasta Rivers. It includes gauges and a map to visualize the data.")
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {

  # Render Leaflet Map centered at Sacramento, CA
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -121.4944, lat = 38.5816, zoom = 7) # Sacramento, CA
  })

  # Render Gauges with Random Values
  output$gauge1 <- renderGauge({
    gauge(sample(1:100, 1), min = 0, max = 100, symbol = "%", sectors = gaugeSectors(
      success = c(75, 100), warning = c(40, 74), danger = c(0, 39)
    ))
  })

  output$gauge2 <- renderGauge({
    gauge(sample(1:100, 1), min = 0, max = 100, symbol = "%", sectors = gaugeSectors(
      success = c(75, 100), warning = c(40, 74), danger = c(0, 39)
    ))
  })
}

# Run App
shinyApp(ui, server)
