
library(ggplot2)
library(stringr)
library(purrr)
library(dplyr)

# Sample data frame
df <- list(
  a = 1:5,
  b = 6:10,
  c = 11:15
)

# Function to be applied to each row
row_function <- function(row) {
  a + b + c
}

# Apply the function to each row using pmap
results <- pmap(df, row_function)

# Print the results
print(results)

# Alternate method using an anonymous function for conciseness
results_alt <- pmap_dbl(df, ~ .x + .y + .z)
print(results_alt)

##################################################
make_chart <- function(data, x, y, xtitle) {
  ggplot(data, aes(x = as.factor(.data[[x]]), y = .data[[y]])) +
    geom_col() +
    ggtitle(paste0("Number of ", str_to_title(xtitle), " by MPG")) +
    xlab(xtitle)
}

x_variables <- c("cyl", "vs", "am", "gear", "carb")

pmap(
  list(
    x = x_variables,
    xtitle = x_variables,
    y = "mpg"
  ),
  make_chart,
  data = mtcars
)
