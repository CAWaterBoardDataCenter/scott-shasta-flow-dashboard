library(shiny)
library(bslib)

# UI ----
ui <- page_fillable(

  titlePanel("My App"),
  theme = bs_theme(version = 5),

  layout_column_wrap(
    card(
      card_header("Inputs"),
      "No Sidebar"
    ),

    card(
      card_header("Single Year Plot"),

      "Main Content"

    )
  ),

  card(
    card_header("All Data"),
    "All Data"
  )
)


# SERVER ----
server <- function(input, output, session) {


}


# APP ----
shinyApp(ui = ui, server = server)
