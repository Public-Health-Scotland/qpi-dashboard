# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# late_lookup_edits.R
# Angus Morton
# 2023-09-06
# 
# Sometimes there are definition corrections/changes. Join an updated 
# version of the lookup onto hb_hosp_qpi for all years of a tsg.
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Note ####

# This script assumes that the changes being made are only to
# numerator1, denominator1 or exclusions1.
# Changes to qpi names should be made by running change_qpi_names.R
# Changes to other variables in the lookup will need to be made by
# running hb_hosp_qpi.R again.

##############

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# old hb_hosp_qpi
hb_hosp_qpi <- readWorkbook(hb_hosp_in_fpath)

# new lookup
lookup <- readWorkbook(lookup_fpath) |>
  select(Cyear = cyear,
         Cancer = cancer,
         QPI = qpi,
         Numerator1 = numerator1,
         Denominator1 = denominator1,
         Exclusions1 = exclusions1)

#### Step 2 : Add new lookup data ----

tsg_all <- hb_hosp_qpi |> 
  filter(Cancer == tsg) |> 
  select(-c("Numerator1", "Denominator1", "Exclusions1"))

hb_hosp_no_tsg <- hb_hosp_qpi |> 
  filter(Cancer != tsg)

tsg_all <- tsg_all |> 
  left_join(lookup, by = c("Cyear", "Cancer", "QPI"))

hb_hosp_qpi <- bind_rows(hb_hosp_no_tsg, tsg_all)

#### Step 3 : Write to excel ----

out_path <- paste0(data_folder, "excels_for_tableau/output/name_changes/",
                   "HB_Hosp_QPI.xlsx")

write.xlsx(hb_hosp_qpi, out_path, sheetName = "HB_Hosp_QPI")
