# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create_lookup.R
# Angus Morton
# 2023-10-17
# 
# Read in HB_Hosp_QPI file and create lookup based on this for the current tsg
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# old hb_hosp_qpi
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

#### Step 2 : Create lookup ----

lookup <- hb_hosp_old |> 
  filter(Cancer == tsg) |> 
  select(cyear = Cyear,
         cancer = Cancer,
         qpi = QPI,
         qpi_order = QPI_Order,
         numerator1 = Numerator1,
         denominator1 = Denominator1,
         exclusions1 = Exclusions1,
         current_target = Current_Target,
         target_label = Target_Label,
         direction = Direction,
         qpi_label_short = QPI_Label_Short,
         
         previous_target = QPI_Label_Short, # not used
         # The previous_target variable is not needed, but will not be removed 
         # in case doing so would disrupt downstream processes eg in Tableau. 
         qpi_subtitle = QPI_Subtitle,
         SurgDiag) |> 
  distinct() |> 
  arrange(cyear, qpi_order)


#### Step 3 : Write to excel ----

write.xlsx(lookup, lookup_fpath, sheetName = "qpi_information")

