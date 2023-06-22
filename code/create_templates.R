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

header_style <- createStyle(
  border = "bottom",
  borderStyle = "medium",
  fgFill = "#E7E6E6",
  textDecoration = "bold"
)

header_numeric_style <- createStyle(
  halign = "right"
)

total_style <- createStyle(
  border = c("top", "bottom"),
  borderStyle = "thin",
  fgFill = "#E7E6E6"
)

separator_style <- createStyle(
  border = "right",
  borderStyle = "medium"
)

uptake_style <- createStyle(
  numFmt = "0.0"
)

### Step x : Load files ----

hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

lookup <- readWorkbook(lookup_fpath)

# assign order to qpis based on lookup
lookup <- lookup |> 
  group_by(cyear) |> 
  mutate(order = row_number()) |> 
  ungroup()

### Step x : locations ----


board_names <- hb_hosp_old |> 
  filter(Board_Hospital == "NHS Board",
         Cancer == tsg,
         Location != "Scotland") |>
  filter(Cyear == max(Cyear)) |> 
  select(Network, Location) |> 
  distinct()

### Get hospitals from most recent year in hb hosp
hosp_names <- hb_hosp_old |> 
  filter(Board_Hospital == "Hospital",
         Cancer == tsg) |>
  filter(Cyear == max(Cyear)) |> 
  select(Network, Location) |> 
  distinct()

### Step x : 

test <- make_template_df(lookup, "2021/22", "SCAN", board_names,
                         hosp_names)

test_nca <- make_template_df(lookup, "2021/22", "NCA", board_names,
                             hosp_names)
  
### Step x : Write to Excel ----

# create workbook
# use purrr write as many sheets as is requried for qpis
# write background info sheet using function

# write out


