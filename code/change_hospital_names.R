# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change_hospital_names.R
# Angus Morton
# 2023-11-14
# 
# When hospital names need changed. Run this script to pull in changes file
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
                        "excels_for_tableau/hospital_name_changes/input/",
                        "HB_Hosp_QPI.xlsx")

hb_hosp_qpi <- readWorkbook(hb_hosp_fpath)

hosp_name_changes_path <- paste0(data_folder,
                                 "lookup/hospital_name_changes.xlsx")

hosp_name_changes <- readWorkbook(hosp_name_changes_path)

#### Step 2 : Make QPI name changes ----

# reformat name changes table to have one row per QPI-cyear pair

# Need a vector of all years in this tsg
all_years <- hb_hosp_qpi |>
  filter(Cancer == tsg) |>
  count(Cyear) |>
  select(Cyear)

hosp_name_changes <- hosp_name_changes |> 
  mutate(Cancer = tsg) |> 
  select(Cancer, old_hospital_name, new_hospital_name)

# 

hb_hosp_qpi <- hb_hosp_qpi |> 
  left_join(hosp_name_changes, by = c("Location" = "old_hospital_name",
                                      "Cancer" = "Cancer")) |> 
  mutate(Location = case_when(
    !is.na(new_hospital_name) ~ new_hospital_name,
    TRUE ~ Location
  )) |> 
  select(-new_hospital_name)

#### Step 3 : Write to excel ----

out_path <- paste0(data_folder,
                   "excels_for_tableau/hospital_name_changes/output/",
                   "HB_Hosp_QPI.xlsx")

write.xlsx(hb_hosp_qpi, out_path, sheetName = "HB_Hosp_QPI")

