# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# generate_summary_in_excel.R
# R version: 4.4.2
# Description: Takes the QPI performance data for Scotland, 
#  and saves to a table in a formatted Excel file,
#  suitable for inclusion as a download file with a publication. 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source("code/packages.R") 
source("code/functions.R")

library(phsstyles)

summary_data_path <- here("code", "for_summary_table")

success_style <- createStyle(
  bgFill = phs_colors("phs-green-50")
)

target_not_met_style <- createStyle(
  bgFill = phs_colors("phs-magenta-30")
)


# The make_summary_table function reads in "Scotland_rows_no_comments.xlsx" 
# from the for_summary_table/ folder
scotland_rows <- filter_hbhosp_for_summary(
	"/PHI_conf/CancerGroup2/Cancer_QPIs/Data/HB_Hosp_new/HB_Hosp_current/HB_Hosp_QPI.xlsx"
	)

perf_summary_tbl <- make_summary_table(scotland_rows)

wb_qpi_summary = createWorkbook()
addWorksheet(wb_qpi_summary, "Table_1_summary_data")

writeDataTable(wb_qpi_summary, "Table_1_summary_data", perf_summary_tbl, startCol = 1, startRow = 1)

setColWidths(wb_qpi_summary, "Table_1_summary_data", cols = 1:length(names(perf_summary_tbl)), widths = "auto")

conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:length(names(perf_summary_tbl)),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Target met"', 
                      style = success_style
                      )

conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:length(names(scotland_rows)),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Target not met"',
                      style = target_not_met_style
                      )

# The below is activated when we manually edit the cells to "Not met" 
# to make a narrower table for pasting into the draft publication. 
conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:length(names(scotland_rows)),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Not met"',
                      style = target_not_met_style
)

tsg <- scotland_rows$Cancer[1] |> str_to_lower() |> str_replace_all("\\W", "_")

years <- distinct(scotland_rows, Cyear)$Cyear |> str_flatten("_") |> str_replace_all("\\W", "\\.")

saveWorkbook(wb_qpi_summary, here(summary_data_path, 
																	paste0("qpi_summary_table_", 
																				 tsg, 
																				 "_",
																				 years,
																				 ".xlsx")),
						 overwrite = TRUE)
