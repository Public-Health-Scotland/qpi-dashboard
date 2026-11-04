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
	"/PHI_conf/CancerGroup2/Cancer_QPIs/Data/HB_Hosp_new/HB_Hosp_current/HB_Hosp_QPI.xlsx"
	)

perf_summary_tbl <- make_summary_table(scotland_rows) |> #see functions.R for what this does
	arrange(parse_number(QPI), str_extract(QPI, "\\([xvi]*\\)"))




#this block of code replaces the "Years x:y" text within QPI names with "(20XX criteria)"
#feel free to skip if if this is not wanted/needed
perf_summary_tbl <- perf_summary_tbl |>
	mutate(temp = "", .after = QPI)

for(i in names(perf_summary_tbl)){
	if(str_detect(i, "^Performance")){
		col_year = str_extract(i, "\\d*/\\d*")
		perf_summary_tbl <- perf_summary_tbl |>
			mutate(temp = if_else(!is.na(perf_summary_tbl[[i]]),
														paste(temp, col_year, sep = " & "),
														temp))
	}
}

perf_summary_tbl <- perf_summary_tbl |>
	mutate(temp = str_remove(temp, "^ & "))

perf_summary_tbl <- perf_summary_tbl |>
	mutate(QPI = str_replace(QPI, "(\\.)? Years \\d*:\\d*", paste0(" (", temp, " criteria)"))) |>
	select(-temp)






#set up openxlsx workbook ----
wb_qpi_summary = createWorkbook()
addWorksheet(wb_qpi_summary, "summary_data")

writeDataTable(wb_qpi_summary, 
							 sheet = "summary_data", 
							 x = perf_summary_tbl)




#widths + styles ----
setColWidths(wb_qpi_summary, 
						 sheet = "summary_data", 
						 cols = 1:length(perf_summary_tbl), 
						 widths = c(48, 7.5, rep(c(14, 10), (length(perf_summary_tbl) -2)/2 )))

addStyle(wb_qpi_summary, 
				 sheet = "summary_data", 
				 style = createStyle(wrapText = TRUE, 
				 										 valign = "center",
				 										border = "bottom",
				 										borderColour = phs_colors("phs-purple")),
				 cols = 1:length(perf_summary_tbl),
				 rows = 1:length(perf_summary_tbl$QPI)+1,
				 gridExpand = TRUE)

addStyle(wb_qpi_summary, 
				 sheet = "summary_data", 
				 style = createStyle(numFmt = "0.0%", 
				 										border = "left",
				 										borderColour = phs_colors("phs-purple")),
				 cols = (1:(length(perf_summary_tbl)/2) * 2) + 1,
				 rows = 1:length(perf_summary_tbl$QPI)+1,
				 gridExpand = TRUE,
				 stack = TRUE)




##top row styles----
addStyle(wb_qpi_summary, 
				 sheet = "summary_data", 
				 style = createStyle(wrapText = TRUE, 
				 										valign = "center",
				 										fgFill = phs_colors("phs-purple"),
				 										fontColour = "#FFFFFF"),
				 cols = 1:length(perf_summary_tbl),
				 rows = 1,
				 stack = TRUE)

addStyle(wb_qpi_summary, 
				 sheet = "summary_data", 
				 style = createStyle(numFmt = "0.0%", 
				 										border = "left",
				 										borderColour = "#FFFFFF"),
				 cols = (1:(length(perf_summary_tbl)/2) * 2) + 1,
				 rows = 1,
				 stack = TRUE)




#conditional formatting ----
conditionalFormatting(wb_qpi_summary,
                      "summary_data",
                      cols = 1:length(perf_summary_tbl),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Target met"', 
                      style = success_style)

conditionalFormatting(wb_qpi_summary,
											"summary_data",
											cols = 1:length(perf_summary_tbl),
											rows = 1:length(perf_summary_tbl$QPI)+1,
											rule = '=B2="Target met"', 
											style = success_style)


conditionalFormatting(wb_qpi_summary,
                      "summary_data",
                      cols = 1:length(perf_summary_tbl),
                      rows = 1:length(perf_summary_tbl$QPI)+1,
                      rule = '="Not met"',
                      style = target_not_met_style)

conditionalFormatting(wb_qpi_summary,
											"summary_data",
											cols = 1:length(perf_summary_tbl),
											rows = 1:length(perf_summary_tbl$QPI)+1,
											rule = '=B2="Not met"',
											style = target_not_met_style)




#save! ----
tsg <- scotland_rows$Cancer[1] |> str_to_lower() |> str_replace_all("\\W", "_")

years <- distinct(scotland_rows, Cyear)$Cyear |> str_flatten("_") |> str_replace_all("\\W", "-")

saveWorkbook(wb_qpi_summary, here(summary_data_path, 
																	paste0(tsg, 
																				 "_",
																				 years,
																				 "_QPI_summary_table.xlsx")),
						 overwrite = TRUE)




#.----
#concise version----
simple_summary_table <- perf_summary_tbl
names(simple_summary_table) <- names(perf_summary_tbl) |> str_remove_all("Performance \\(%\\) ")

removeTable(wb_qpi_summary,
						"summary_data",
						getTables(wb_qpi_summary,
											"summary_data"))

writeDataTable(wb_qpi_summary,
					"summary_data",
					x = simple_summary_table)

addStyle(wb_qpi_summary,
				 "summary_data",
				 cols = 1:length(perf_summary_tbl),
				 rows = 1,
				 style = createStyle(textDecoration = "bold"),
				 stack = TRUE)

setColWidths(wb_qpi_summary,
						 "summary_data",
						 cols = 1:length(perf_summary_tbl), 
						 widths = c(64, 7.5, rep(c(8.5, 10), (length(perf_summary_tbl) -2)/2 )),
						 hidden = c(F,F, rep(c(F,T), (length(perf_summary_tbl)-2)/2)))

addStyle(wb_qpi_summary,
					"summary_data",
					cols = 1:length(perf_summary_tbl),
					rows = 1:length(perf_summary_tbl$QPI) + 1,
					style = createStyle(border = "TopBottomLeftRight"),
					gridExpand = TRUE,
					stack = TRUE)

addStyle(wb_qpi_summary, 
				 sheet = "summary_data", 
				 style = createStyle(border = "TopBottomLeftRight"),
				 cols = 1:length(perf_summary_tbl),
				 rows = 1,
				 stack = TRUE)



saveWorkbook(wb_qpi_summary, here(summary_data_path, 
																	paste0(tsg, 
																				 "_",
																				 years,
																				 "_QPI_summary_table_concise.xlsx")),
						 overwrite = TRUE)


