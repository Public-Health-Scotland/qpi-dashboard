# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# housekeeping.R
# 
# Contains the values which should be changed each run
# 
# R version 4.5
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source("code/functions.R")

#### Edit Variables ----
# The below variables vary depending on the the nature of the update.
# They will need edited for each new dashboard update.

# tsg = "Tumour Specific Group"
# The following are acceptable values
# "Acute Leukaemia" "Bladder"     "Breast"           "Cervical"
# "Colorectal"      "Endometrial" "Head and Neck"    "Lung"
# "Lymphoma"        "Melanoma"    "Ovarian"          "Prostate"
# "Renal"           "Testicular"  "Upper GI-Gastric" "Upper GI-Oesophageal"
# "Brain and CNS" "HPB" "Sarcoma"
# 
# In development values for tsg
# "Mesothelioma" "Thyroid"

tsg <- "Bladder"

# For the BO input, important to specify just one Cyear at a time 
# (eg "2023" or "2023/24")
# Colorectal April to March, 2023/4 then 2024/25 update running summer 2026.
new_years <- c("2023/24")
# new_years_vals is the Year X year number eg most cancers started QPI data 
# collection in 2014 so Year 1 was 2014 or 2014/15. Colorectal Year 11 is 2023/24. 
new_years_vals <- c(10)

# Date of the start of the first new reporting year
date_start <- dmy("01-04-2023")

# measurability versions (one for each year, usually "5.x")
meas_vers <- c("4.x")

# Workaround to avoid error - create hospital vectors. 
# This is just backwards compatibility with the submission / templates approach.
nca_hosps <- c()
sca_hosps <- c()
wos_hosps <- c()

## age groups for template :
# Enter age groups for background info manually. If none supplied then the
# script will use the most common set of (<45, 45-49 ... 80-84, >85)
# To use default age groups enter a NULL vector e.g. "age_groups <- c()"
age_groups <- c("85+",
                "80-84", 
                "75-79", 
                "70-74", 
                "65-69", 
                "60-64", 
                "55-59", 
                "50-54", 
                "45-49", 
                "0-44")

# Data Folder
# The lookup folder and extracts folder will be derived from this path 
# ie they're sub-folders of the data folder BOXI_extracts/ and lookup/. 
data_folder <- here("/PHI_conf", "CancerGroup2", "Cancer_QPIs",
                      "Data", "new_process", "bladder_2026") 

# Extracts filenames
# List each extract file. 
# This is flexible because for some tumours there are additional reports, 
# not just HOSPSURG and the main QPI eg QPI 12 of testis is separate. 
# eg c("2024_25_Rectangular_QPI_Colorectal_v4_non-surgical.xlsx", 
# "2024_25_Rectangular_QPI_Colorectal_HOSPSURG_v4.xlsx",
# "2024-25 Rectangular_QPI_Colorectal_LiverDiagDate.xlsx")
extracts_filenames <- c("2023-2024 Rectglr_QPI_Bladder_v4_non-surgical_-_Archived_-_diag_before_31_mar_2024_only.xlsx")

# Folder containing lookup info on HBs by network
regional_networks_folder <- here("/PHI_conf", "CancerGroup2", "Cancer_QPIs", 
                            "Data", "qpi_lookups", "regional_geography")


#~~~~~~~~~~~~~~~~~ Nothing below this line should need edited ~~~~~~~~~~~~~~

#### Derived Variables ----
# All these variables are automatically generated from input files and
# the values provided above

# Sex value to handle sex specific cancers
tsg_sex <- case_when(
  tsg %in% c("Breast", "Cervical", "Endometrial", "Ovarian") ~ "female",
  tsg %in% c("Prostate", "Testicular") ~ "male",
  TRUE ~ "both"
)

# input files

hb_hosp_in_fpath <- here(data_folder,
                         "excels_for_tableau/initial_run/input/",
                         "HB_Hosp_QPI.xlsx")

age_gender_in_fpath <- paste0(data_folder,
                              "excels_for_tableau/initial_run/input/",
                              "Background_Data_Age_Gender.xlsx")

case_asc_in_fpath <- paste0(data_folder,
                            "excels_for_tableau/initial_run/input/",
                            "Background_Data_Case.xlsx")

# sca_fpath <- paste0(data_folder,
#                     "data_submissions/scan.xlsx")
# 
# nca_fpath <- paste0(data_folder,
#                     "data_submissions/nca.xlsx")
# 
# wos_fpath <- paste0(data_folder,
#                     "data_submissions/woscan.xlsx")

# lookup

lookup_fpath <- here(data_folder,
                       "lookup", "lookup.xlsx")

# templates

#templates_fpath <- paste0(data_folder,
#                          "templates/")

# output files

hb_hosp_out_fpath <- here(data_folder,
                           "HB_Hosp_updated",
                           "HB_Hosp_QPI.xlsx")

age_gender_out_fpath <- paste0(data_folder,
                               "excels_for_tableau/initial_run/output/",
                               "Background_Data_Age_Gender.xlsx")

case_asc_out_fpath <- paste0(data_folder,
                             "excels_for_tableau/initial_run/output/",
                             "Background_Data_Case.xlsx")


# Read in the previous data
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

### hospital names

# hosp_vectors OBSOLETE but bug when deleted because of hospsurg processing
hosp_vectors <- list(nca_hosps, sca_hosps, wos_hosps) 
networks <- c("NCA", "SCAN", "WoSCAN")

# Optional: check tsg is a match by counting rows
# nrow(hb_hosp_old |> filter(Cancer == tsg)) 
# If nrow is zero, then max(Cyear) in next line will error, cos no arguments.

if ((hb_hosp_old |>
    filter(Cancer == tsg) |>
    filter(Cyear == max(Cyear)) |>
    filter(Board_Hospital == "Hospital") |> 
    nrow() != 0) |
    every(hosp_vectors, is.null) == FALSE) {
  
  any_hosp_qpis <- 1
  
} else {
  
  any_hosp_qpis <- 0
  
}


if (any_hosp_qpis == 1) {
  
  hosp_names <- map2_dfr(hosp_vectors, networks, get_hosp_names, hb_hosp_old)
  
} else {
  
  message("TSG has no surgical QPIs")
  
  hosp_names <- hb_hosp_old |> 
    filter(Board_Hospital == "Hospital",
           Cancer == tsg)
  
}

### board names
### Creates a data frame, listing the boards belonging to each network, 
### for the present tsg, based on the last dataset 
### For tsg with no pre-existing list, need to add that. 
board_names <- hb_hosp_old |> 
  filter(Board_Hospital == "NHS Board",
         Cancer == tsg,
         Location != "Scotland") |>
  filter(Cyear == max(Cyear)) |> 
  select(Network, Location) |>
  arrange(Network, Network == Location) |> 
  distinct()

# If board_names is empty / null 
# read in the file "health_boards_to_default_RegionalCancerNetworks.csv" 
# into df new_tsg_board_names

if ( nrow(board_names) < 1 ) {
    board_names <- read.csv(file = here(regional_networks_folder,"health_boards_to_default_RegionalCancerNetworks.csv"))
} 

# If tsg is brain, overwrite board_names
if ( str_detect(tsg, "^Brain and CNS$" ) ) { 
    # read in the brain / CNS networks memberships
    board_names <- read.csv(file = here(regional_networks_folder, "brain_cns_health_boards_to_RegionalCancerNetworks.csv"))
  } 


### age groups

age_groups <- get_age_groups(age_groups)

