#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prep_SAP_BO_extracts.R
# 
# Reads in the performance data extract generated using Business Objects, 
# which replaces the three old data submission templates,
# ie one Excel for Scotland (aka rectangular multi-QPI report)
# instead of three regional excel files,
# and preps them to be pasted into HB_Hosp_QPI.xlsx. 
# 
# R version 4.5.1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Not sure need to call housekeeping
#### Step 0 : Housekeeping ----
#  source("code/housekeeping.R")

# Read in extract

# Read in lookup. 

# Add a column for numerator descriptions and denom descriptions based on lookup. 

# Calculate regional sub-totals