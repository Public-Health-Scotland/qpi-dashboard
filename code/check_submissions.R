# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_submissions.R
# Angus Morton
# 2023-05-22
# 
# Checks for the data submissions by the three networks to make sure
# all data is valid
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Select which templates to check. Put the names of the files in this vector
to_check <- c("NCA", "SCAN", "WoSCAN")

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import Submissions ----

# Bring all submissions in and combine into one dataframe

sub_path <- paste0(data_folder, "data_submissions/")

new_data <- map(to_check, import_submission,
                sub_path = sub_path,
                year_vals = new_years_vals,
                years = new_years) |> 
  list_rbind()


#### Step 2: Basic checks for data completeness ---- 

basic_checks_results <- basic_data_checks(new_data)
write.csv(basic_checks_results[1], here(data_folder, "tally_table_by_network.csv"))
write.csv(basic_checks_results[2], here(data_folder, "tally_table_by_qpi.csv"))
write.csv(basic_checks_results[3], here(data_folder, "tally_table_by_location.csv"))


#### Step 3 : Check Board Totals Match Network ----
# The total of the numbers for all boards must match the quoted network total
# Should probably do this 'summarise_if(is.numeric,sum)'

z_board_totals <- check_totals(new_data, "Board")


#### Step 4 : Check Hospital Totals Match Network ----
# The total of the numbers for all hospitals must match the quoted network total

z_hospital_totals <- check_totals(new_data, "Hospital")

# Print the results of the check_totals functions to the console
# print_error_report(z_board_totals, z_hospital_totals)



