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
  bgFill = phs_colors("phs-magenta-30")
)

# This colour appears to not work, openxlsx uses a blue heading style
# But colour can be manually set to PHS Table Head style after pasting anyway. 
#headerStyle <- createStyle(
#  bgFill = phs_colors("phs-purple")
#)

# The make_summary_table function reads in "Scotland_rows_no_comments.xlsx" 
# from the /for_summary_table folder
perf_summary_tbl <- make_summary_table()

wb_qpi_summary = createWorkbook()
addWorksheet(wb_qpi_summary, "Table_1_summary_data")

writeDataTable(wb_qpi_summary, "Table_1_summary_data", perf_summary_tbl, startCol = 1, startRow = 1)

conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:14,
                      rows = 1:50,
                      rule = '="Target met"', 
                      style = success_style
                      )

conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:14,
                      rows = 1:50,
                      rule = '="Target not met"',
                      style = target_not_met_style
                      )



saveWorkbook(wb_qpi_summary, here("for_summary_table", "Table_1_QPIs_summary.xlsx"))

# Optional - just write the data to file, for manual formatting
write.xlsx(perf_summary_tbl, file = here("for_summary_table", "qpi_summary_table_plain.xlsx"))

