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

# new_years
# new_years_vals
vars <- list(years, networks)

dfs_sca <- map(new_years, make_template_df,
                network = "SCAN",
                lookup = lookup,
                board_names = board_names,
                hosp_names = hosp_names)

dfs_wos <- map(new_years, make_template_df,
               network = "WoSCAN",
               lookup = lookup,
               board_names = board_names,
               hosp_names = hosp_names)

dfs_nca <- map(new_years, make_template_df,
               network = "NCA",
               lookup = lookup,
               board_names = board_names,
               hosp_names = hosp_names)

### Step x : Write to Excel ----

# create workbook
wb <- createWorkbook()

# write QPIs tabs
wb <- make_qpis_tabs(dfs_scan, year_nums, years, meas_vers,
                     wb, date_start, styles)

# write background info tabs

wb <- make_background_tab(wb, tsg, "SCAN", new_years,
                          date_start, tsg_sex)

temp_path <- paste0(data_folder, "temp/scan_test.xlsx")

saveWorkbook(wb, temp_path)

# write background info sheet using function

# write out


