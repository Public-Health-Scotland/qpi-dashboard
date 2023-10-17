# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# age_gender.R
# Angus Morton
# 2023-09-29
# 
# Update the background data age_gender excel file
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

sub_path <- paste0(data_folder, "data_submissions/")

new_data <- map(networks,
                import_age_gender,
                sub_path = sub_path,
                year_vals = new_years_vals,
                years = new_years) |>
  list_rbind()


#### Step x : Write to excel ----


