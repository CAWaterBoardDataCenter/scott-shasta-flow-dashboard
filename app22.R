library(shiny)
library(bslib)
library(shinydashboard)
library(shinydashboardPlus)
library(leaflet)
library(flexdashboard)  # For gauge function


page_fillable(
  theme = bs_theme(version = 5),

  # Title Bar with Navy Blue Background
  div(
    style = "background-color: #001F3F; color: white; text-align: center;
             font-size: 24px; font-weight: bold; padding: 15px; width: 100%;",
    "Scott and Shasta Rivers Flow Monitoring Dashboard"
  ),

  # Use layout_columns() to properly align Notes (1/4) and Map (3/4)
  layout_columns(
    col_widths = c(3, 9),  # 1/4 and 3/4 of the screen width
    heights_equal = "row",  # Ensures Notes and Map stay the same height
    style = "height: 75vh;",  # Makes this row 75% of the screen height

    card(
      width = 3,  # 1/4 of a 12-column grid
      full_screen = TRUE,
      header = "Notes",
      textAreaInput("notes", label = NULL, placeholder = "Enter notes here...",
                    width = "100%", height = "400px")
    ),

    card(
      width = 9,  # 3/4 of a 12-column grid
      full_screen = TRUE,
      header = "Map",
      leafletOutput("map", height = "100%")
    )
  )
)

