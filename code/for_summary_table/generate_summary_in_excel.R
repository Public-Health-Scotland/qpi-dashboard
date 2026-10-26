# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# generate_summary_in_excel.R
# R version: 4.4.2
# Description: Takes the QPI performance data for Scotland, 
#  and saves to a table in a formatted Excel file,
#  suitable for inclusion as a download file with a publication. 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#setup ----
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



# Make the summary table ----
scotland_rows <- filter_hbhosp_for_summary(
	"/PHI_conf/CancerGroup2/Cancer_QPIs/Data/new_process/lymphoma_2026/2022-23/HB_Hosp_updated/HB_Hosp_QPI.xlsx"
	)

perf_summary_tbl <- make_summary_table(scotland_rows) |> #see functions.R for what this does
	arrange(parse_number(QPI))



#set up openxlsx workbook ----
wb_qpi_summary = createWorkbook()
addWorksheet(wb_qpi_summary, "Table_1_summary_data")

writeDataTable(wb_qpi_summary, 
							 sheet = "Table_1_summary_data", 
							 x = perf_summary_tbl, 
							 startCol = 1, 
							 startRow = 1, 
							 #tableStyle = "TableStyleLight1"
							 )




#widths + styles ----
setColWidths(wb_qpi_summary, 
						 sheet = "Table_1_summary_data", 
						 cols = 1:length(names(perf_summary_tbl)), 
						 widths = c(48, 7.5, rep(c(14, 10), (length(names(perf_summary_tbl)) -2)/2 )))

addStyle(wb_qpi_summary, 
				 sheet = "Table_1_summary_data", 
				 style = createStyle(wrapText = TRUE, 
				 										 valign = "center",
				 										border = "bottom",
				 										borderColour = phs_colors("phs-purple")),
				 cols = 1:length(names(perf_summary_tbl)),
				 rows = 2:length(perf_summary_tbl$QPI)+1,
				 gridExpand = TRUE)

addStyle(wb_qpi_summary, 
				 sheet = "Table_1_summary_data", 
				 style = createStyle(numFmt = "0.0%", 
				 										border = "left",
				 										borderColour = phs_colors("phs-purple")),
				 cols = (1:(length(names(perf_summary_tbl))/2) * 2) + 1,
				 rows = 2:length(perf_summary_tbl$QPI)+1,
				 gridExpand = TRUE,
				 stack = TRUE)




##top row styles----
addStyle(wb_qpi_summary, 
				 sheet = "Table_1_summary_data", 
				 style = createStyle(wrapText = TRUE, 
				 										valign = "center",
				 										fgFill = phs_colors("phs-purple"),
				 										fontColour = "#FFFFFF"),
				 cols = 1:length(names(perf_summary_tbl)),
				 rows = 1,
				 stack = TRUE)

addStyle(wb_qpi_summary, 
				 sheet = "Table_1_summary_data", 
				 style = createStyle(numFmt = "0.0%", 
				 										border = "left",
				 										borderColour = "#FFFFFF"),
				 cols = (1:(length(names(perf_summary_tbl))/2) * 2) + 1,
				 rows = 1,
				 stack = TRUE)




#conditional formatting ----
conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:length(names(perf_summary_tbl)),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Target met"', 
                      style = success_style)

conditionalFormatting(wb_qpi_summary,
											"Table_1_summary_data",
											cols = 1:length(names(perf_summary_tbl)),
											rows = 1:length(perf_summary_tbl$QPI)+1,
											rule = '=B2="Target met"', 
											style = success_style)


conditionalFormatting(wb_qpi_summary,
                      "Table_1_summary_data",
                      cols = 1:length(names(scotland_rows)),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Not met"',
                      style = target_not_met_style)

conditionalFormatting(wb_qpi_summary,
											"Table_1_summary_data",
											cols = 1:length(names(scotland_rows)),
											rows = 1:length(perf_summary_tbl$QPI)+1,
											rule = '=B2="Not met"',
											style = target_not_met_style)




#save! ----
tsg <- scotland_rows$Cancer[1] |> str_to_lower() |> str_replace_all("\\W", "_")

years <- distinct(scotland_rows, Cyear)$Cyear |> str_flatten("_") |> str_replace_all("\\W", "-")

saveWorkbook(wb_qpi_summary, here(summary_data_path, 
																	paste0("qpi_summary_table_", 
																				 tsg, 
																				 "_",
																				 years,
																				 ".xlsx")),
						 overwrite = TRUE)
