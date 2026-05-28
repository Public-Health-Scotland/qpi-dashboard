#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prep_SAP_BO_extracts.R
# 
# Reads in the performance data extract generated using Business Objects, 
# which replaces the three old data submission templates,
# ie one Excel for Scotland (aka rectangular multi-QPI report)
# instead of three regional excel files,
# and preps them to be pasted into HB_Hosp_QPI.xlsx. 
# After running this script, 
# next step is to run update_hb_hosp_from_SAP_BO_extracts.R. 
# 
# R version 4.5.1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Not sure need to call housekeeping
#### Step 0 : Housekeeping ----
#  source("code/housekeeping.R")

# Read in extract. Assuming just one year's worth of data to be read in. 



