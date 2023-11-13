# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# case_asc.R
# Angus Morton
# 2023-09-29
# 
# Update case ascertainment file
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# Background Case Ascertainment file

case_asc <- readWorkbook(case_asc_in_fpath) |> 
  mutate(Location_D = str_replace(Location_D, "amp;", ""))

#### Step x : Create template ----

case_asc_temp <- case_asc |> 
  filter(Cancer_D == tsg) |>
  filter(Year_D == max(Year_D)) |> 
  select(-Year_D)

case_asc_temp <- data.frame(Year_D = new_years) |> 
  cross_join(case_asc_temp) |> 
  mutate(Audit_Cases = as.numeric(NA),
         Cancer_Reg_Avg = as.numeric(NA),
         Per_Case_Ascertainment = as.numeric(NA)) |>
  select(Cancer_D, Year_D, everything()) |> 
  arrange(desc(Year_D))

#### Step x : Export template ----

case_asc_temp_fpath <- paste0(templates_fpath, "Case_Asc_Template.xlsx")

write.xlsx(case_asc_temp, case_asc_temp_fpath,
           sheetName = "Background_Data_Case")

## Now fill in this template and place in:
## "excels_for_tableau/input/Case_Asc_Template_Completed.xlsx"

#### Step x : Import completed template ----

case_asc_comp_fpath <- paste0(data_folder,
                              "excels_for_tableau/input/",
                              "Case_Asc_Template.xlsx")

case_asc_comp <- readWorkbook(case_asc_comp_fpath)

#### Step 3 : Combine existing and new data ----

case_asc_new <- bind_rows(case_asc, case_asc_comp) |> 
  arrange(Cancer_D, desc(Year_D))

#### Step 4 : Write to excel ----

write.xlsx(case_asc_new, case_asc_out_fpath,
           sheetName = "Background_Data_Case")
