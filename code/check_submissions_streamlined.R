# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_submissions_streamlined.R
# Pauline Ward
# 2025-04-02
# 
# Checks for the data submissions by the three networks to make sure
# all data is valid
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Select which templates to check. Put the names of the files in this vector
to_check <- c("NCA", "SCAN", "WoSCAN")

#### Step 0 : Housekeeping ----

source("code/functions.R")
# source("code/housekeeping.R")
source("code/packages.R")

data_folder <- str_c("/conf/quality_indicators/Benchmarking/Cancer_QPIs/",
  "Data/new_process/testing/test_code_toenails_the_new_process/toenails_july24/head_and_neck_april_2025_just_fr_test/pauline_test/")

# Create a folder for output
quality_checking_folder <- sub("/$", "", data_folder)
quality_checking_folder  <-  here(quality_checking_folder, "quality_checking")
dir.create(quality_checking_folder)

#### Step 1 : Import Submissions ----

# Bring all submissions in and combine into one dataframe

sub_path <- paste0(data_folder, "data_submissions/")

new_years <- c("2021/22", "2022/23", "2023/24")
new_years_vals <- c(8, 9, 10)


new_data <- map(to_check, import_submission,
                sub_path = sub_path,
                year_vals = new_years_vals,
                years = new_years) |> 
  list_rbind()


#### Step 2: Basic checks for data completeness ---- 

basic_checks_results <- basic_data_checks(new_data)
write.csv(basic_checks_results[1], here(quality_checking_folder, "tally_table_by_network.csv"))
write.csv(basic_checks_results[2], here(quality_checking_folder, "tally_table_by_qpi.csv"))
write.csv(basic_checks_results[3], here(quality_checking_folder, "tally_table_by_location.csv"))
message("Counting done, tally tables saved to quality_checking folder. 
INSTRUCTION: Now do the manual step: look at the tally tables, 
to check that numbers of rows per network etc are consistent and in-the-right-ballpark!")

#### Step 3 : Check Board Totals Match Network ----
# The total of the numbers for all boards must match the quoted network total
# Should probably do this 'summarise_if(is.numeric,sum)'

z_board_totals <- check_totals(new_data, "Board")
if (nrow(z_board_totals) > 0) {
  message("ISSUE FOUND: There are ", nrow(z_board_totals), 
          " network totals that do not match the sum of the health board rows. 
          See quality_checking/ folder, non_matching_board_totals.csv. ")
  write_csv(z_board_totals, file = here(quality_checking_folder, "non_matching_board_totals.csv"))
}


#### Step 4 : Check Hospital Totals Match Network ----
# The total of the numbers for all hospitals must match the quoted network total

z_hospital_totals <- check_totals(new_data, "Hospital")
if (nrow(z_hospital_totals) > 0) { 
  message("ISSUE FOUND: There are ", nrow(z_hospital_totals), 
          " hospital totals that do not match the sum of the rows. 
          See quality_checking/ folder, non_matching_hospital_totals.csv. 
          This issue may be caused by rows for hospitals being listed after network sub-total rows(?).")
  
  write_csv(z_hospital_totals, file = here(quality_checking_folder, "non_matching_hospital_totals.csv"))
}

# Print the results of the check_totals functions to the console
print_error_report(z_board_totals, z_hospital_totals)


# Generate a report listing the size of differences for hospitals
hosp_diffs_tbl <- hosp_differences_report(new_data)
write_csv(hosp_diffs_tbl, file = here(quality_checking_folder, "hospital_differences_amounts.csv"))
