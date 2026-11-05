#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Troubleshooting ingest of manually created extract file. 
# Error in find table. 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

source("code/housekeeping.R") 
# For troubleshooting when files cannot be read in, 
# check each one for error messages, separately
file1_new_data <- import_extracts(data_folder, extracts_filenames[1]) # should be OK but doesn't work!
file2_new_data <- import_extracts(data_folder, extracts_filenames[2]) # problem
file3_new_data <- import_extracts(data_folder, extracts_filenames[3]) # workaround

