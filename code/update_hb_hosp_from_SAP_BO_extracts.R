#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# update_hb_hosp_from_SAP_BO_extracts.R  ... replaces hb_hosp_qpi.R
# Run this script *after* prepping the extract using prep_SAP_BO_extracts.R. 
# Run this script instead of the original hb_hosp_qpi.R. 
# 
# Reads in the performance data extract generated using Business Objects, 
# which replaces the three old data submission templates,
# ie one Excel for Scotland (aka rectangular multi-QPI report)
# instead of three regional excel files,
# and preps them to be pasted into HB_Hosp_QPI.xlsx. 
# 
# R version 4.5.1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#### Step 0 : Housekeeping ----
# Calls housekeeping, which also calls functions, which also calls packages
library("here")
source(here("code", "housekeeping.R"))
if (length(new_years) > 1) {
  warning("More than one Cyear detected in housekeeping file. 
          This script is designed to process one year's data at a time.")
  }

#### Step 1 : Import data ----

extract_path <- here(data_folder, "data_extracts")

# Read in extract files. Assume one year's data. 
year_pattern <- str_replace(new_years[1], "/", "[-_]")
filenm_pattern <- str_c(".*", year_pattern, ".*\\.xlsx")
data_extract_files <- list.files(
  path = extract_path,
  pattern = filenm_pattern,
  full.names = TRUE,
  ignore.case = TRUE
)

# Read in extract for HOSPSURG. Assuming just one year's worth of data to read in. 
# Filename should contain <Cyear> + 'HOSPSURG' + .xlsx 
# Make it match eg 2023-24 or 2024_25

hospsurg_filenm_pattern <- str_c(year_pattern, ".*HOSPSURG.*", "\\.xlsx")
# hospsurg_extract_file <- list.files(
#   path = extract_path,
#   pattern = hospsurg_filenm_pattern,
#   full.names = TRUE,
#   ignore.case = TRUE
# )
if (length(hospsurg_extract_file) > 1) {
  message("More than one filename matches the criteria. Please make sure 
          only the desired HOSPSURG file matches the pattern: " )
  message(hospsurg_filenm_pattern) 
}




# Add the HB data as rows in new_data

# Calculate regional sub-totals, add as rows in new_data


# Add Scotland data as rows in new_data 


# Read in lookup. 
# new lookup
lookup <- import_lookup(lookup_fpath) |> 
  select(-SurgDiag)

# Add a column for numerator descriptions and denom descriptions based on lookup. 


# Calculate whether targets met or not met (ie RAG status) for each row 
new_data <-  set_rag_status(new_data)