library(readxl)

sfj <- read_xlsx("mifs-sfj.xlsx")
sry <- read_xlsx("mifs-sry.xlsx")

mifs <- list("sfj" = sfj,
             "sry" = sry)

save(mifs, file = "data/mif-tables.RData")
