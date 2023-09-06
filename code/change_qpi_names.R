# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change_qpi_names.R
# Angus Morton
# 2023-09-06
# 
# When QPI names need changed. Run this script to pull in changes file
# and update hb_hosp_qpi
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# hb hosp

hb_hosp_qpi <- readWorkbook(hb_hosp_out_fpath)

qpi_name_changes_path <- paste0(data_folder, "lookup/qpi_name_changes.xlsx")

qpi_name_changes <- readWorkbook(qpi_name_changes_path)

#### Step 2 : Make QPI name changes ----


#### Step 3 : Write to excel ----

wb <- createWorkbook(hb_hosp_qpi)

saveWorkbook(wb, hb_hosp_out_fpath)


