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

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

