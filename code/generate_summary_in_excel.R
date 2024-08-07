# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# generate_summary_in_excel.R
# Author: Pauline Ward
# Date: August 2024
# Written on: Posit Workbench RStudio
# R version: 4.1.2
# Description: Takes the QPI performance data for Scotland, 
#  and saves to a table in a formatted Excel file,
#  suitable for inclusion as a download file with a publication. 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source("code/functions.R")
source("code/packages.R")

library(phsstyles)

success_style <- createStyle(
  bgFill = phs_colors("phs-green-50")
)

target_not_met_style <- createStyle(
  bgFill = phs_colors("phs-magenta-50")
)

perf_summary_tbl <- make_summary_table()

write.xlsx(perf_summary_tbl, file = here("for_summary_table", "qpi_summary_table.xlsx"))
