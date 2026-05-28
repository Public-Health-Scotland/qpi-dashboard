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
# Calls housekeeping, which calls functions, which calls packages
source(here("code", "housekeeping.R"))

#### Step 1 : Import data ----

extract_path <- here(data_folder, "data_extracts")

# Read in extract for HOSPSURG. Assuming just one year's worth of data to be read in. 
# Filename should contain <Cyear> + 'HOSPSURG' + .xlsx
hosp_surg_filenm_pattern <- str_c(new_years[0], ".*", "HOSPSURG", ".*", "\\.xlsx")
# data_extract_file <- list.files(
#   path = extract_path,
#   pattern = "daily.*\\.xlsx$",
#   full.names = TRUE
# )
if length(data_extract_file) > 1 {
  message("More than one filename matches the criteria. Please make sure only the desired HOSPSURG file matches the pattern: " )
  message(hosp_surg_filenm_pattern) 
}


# Read in non-surgical extract. Assume one year's data. 
 

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