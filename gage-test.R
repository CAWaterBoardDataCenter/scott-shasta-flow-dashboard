library(flexdashboard)

gauge(value = 51,
      min = 0,
      max = 100,
      symbol = 'cfs',
      sectors = gaugeSectors(
        success = c(61, 100),
        warning = c(60, 51),
        danger = c(0, 50)
      )
)
