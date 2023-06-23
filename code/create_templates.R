# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create_templates.R
# Angus Morton
# 2023-06-08
# 
# Script pulls in lookup and housekeeping info and makes blank excel templates
# for the networks to fill in
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

### Step x : Create styles ----

title <- createStyle(
  textDecoration = "bold",
  fontSize = 12
)

table <- createStyle(
  border = c("top", "bottom", "left", "right"),
  borderStyle = "thin",
  fontSize = 10
)

header <- createStyle(
  border = c("top", "bottom", "left", "right"),
  borderStyle = "thin",
  textDecoration = "bold",
  fgFill = "#B8CCE4",
  halign = "center"
)

ntwrk_row <- createStyle(
  fgFill = "#DCE6F1"
)

total <- createStyle(
  textDecoration = "bold"
)

styles <- c("title" = title,
            "table" = table,
            "header" = header, 
            "ntwrk_row" = ntwrk_row,
            "total" = total)

### Step x : Load files ----

hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

lookup <- readWorkbook(lookup_fpath)

# assign order to qpis based on lookup
lookup <- lookup |> 
  group_by(cyear) |> 
  mutate(order = row_number()) |> 
  ungroup()


### Step x : 

year_nums <- c(7,8,9)
years <- c("2019/20", "2020/21", "2021/22")
vars <- list(years, networks)

dfs <- pmap(vars, make_template_df,
            lookup = lookup,
            board_names = board_names,
            hosp_names = hosp_names)

### Step x : Write to Excel ----

wb <- createWorkbook()

wb <- make_qpis_tab(dfs, year_nums, years, meas_vers, wb, date_start, styles)

vars <- list(dfs, year_nums, years, meas_vers)
wb <- pmap(vars, make_qpis_tab, wb = wb, date_start = date_start,
           styles = styles)

wb2 <- createWorkbook()

wb2 <- make_qpis_tab(wb, test, 8, "2019/20",
                    date_start, 3.3, tsg, styles)

w

temp_path <- paste0(data_folder, "temp/test.xlsx")

saveWorkbook(wb, temp_path)

# create workbook
# use purrr write as many sheets as is required for QPIs

wb <- pmap()

# write background info sheet using function

# write out


