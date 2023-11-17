# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change_qpi_names.R
# Angus Morton
# 2023-09-06
# 
# When QPI names need changed. Run this script to pull in changes file
# and update hb_hosp_qpi
#
# This script can only be run after hb_hosp_qpi.R has updated the
# hb_hosp_qpi.xlsx file
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# hb hosp


hb_hosp_fpath <- paste0(data_folder,
                        "excels_for_tableau/qpi_name_changes/input/",
                        "HB_Hosp_QPI.xlsx")

hb_hosp_qpi <- readWorkbook(hb_hosp_fpath)

qpi_name_changes_path <- paste0(data_folder, "lookup/qpi_name_changes.xlsx")

qpi_name_changes <- readWorkbook(qpi_name_changes_path)

#### Step 2 : Make QPI name changes ----

# reformat name changes table to have one row per QPI-cyear pair

# Need a vector of all years in this tsg
all_years <- hb_hosp_qpi |>
  filter(Cancer == tsg) |>
  count(Cyear) |>
  select(Cyear)

qpi_name_changes <- qpi_name_changes |> 
  cross_join(all_years) |> 
  filter(between(Cyear, first_cyear, last_cyear)) |> 
  mutate(Cancer = tsg) |> 
  select(Cancer, old_qpi_name, new_qpi_name, Cyear)

# 

hb_hosp_qpi <- hb_hosp_qpi |> 
  left_join(qpi_name_changes, by = c("QPI" = "old_qpi_name",
                                     "Cyear" = "Cyear",
                                     "Cancer" = "Cancer")) |> 
  mutate(QPI = case_when(
    !is.na(new_qpi_name) ~ new_qpi_name,
    TRUE ~ QPI
  )) |> 
  select(-new_qpi_name)

#### Step 3 : Write to excel ----

out_path <- paste0(data_folder,
                   "excels_for_tableau/qpi_name_changes/output/",
                   "HB_Hosp_QPI.xlsx")

write.xlsx(hb_hosp_qpi, out_path, sheetName = "HB_Hosp_QPI")
