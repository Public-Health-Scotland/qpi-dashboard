# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# housekeeping.R
# Angus Morton
# 2023-05-22
# 
# Contains the values which should be changed each run
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source("code/functions.R")
source("code/packages.R")

#### Edit Variables ----
# The below variables vary depending on the the nature of the update.
# They will need edited for each new dashboard update.

# tsg = "Tumour Specific Group"
# The following are acceptable values
# "Acute Leukaemia" "Bladder"     "Breast"           "Cervical"
# "Colorectal"      "Endometrial" "Head and Neck"    "Lung"
# "Lymphoma"        "Melanoma"    "Ovarian"          "Prostate"
# "Renal"           "Testicular"  "Upper GI-Gastric" "Upper GI-Oesophageal"

# In development values for tsg
# "Brain and CNS" "HPB" 

tsg <- "Bladder"

new_years <- c("2020/21", "2021/22", "2022/23")
new_years_vals <- c(7, 8, 9)

# Date of the start of the first new reporting year
date_start <- dmy("01-04-2020")

# measurability versions (one for each year)
meas_vers <- c("3.2", "4.2", "4.2")

## hospital names :
# Enter hospital names manually. If none supplied then the script will use
# the names from the most recent published four years of QPIs for this TSG.
# To use existing names enter a NULL vector e.g. "nca_hosps <- c()"
nca_hosps <- c("Aberdeen RI","Albyn","Balfour Hosp","Belford Hosp",
               "Caithness General","Dr Grays Hosp","Gilbert Bain Hosp",
               "Lorn Islands Hosp","Ninewells Hosp","Perth Royal Inf",
               "Raigmore Hosp","Stracathro Hosp","Western Isles Hosp")
sca_hosps <- c("Borders General Hosp","QMH Fife","Royal Inf Edinburgh",
               "Victoria Hosp Fife","Western General Hosp")
wos_hosps <- c("Ayr", "Dumfries & Galloway RI", "Forth Valley Royal", 
               "Gartnavel","Glasgow Royal Inf", "Hairmyres","Inverclyde Royal",
               "Monklands","Queen Elizabeth Hosp","Royal Alexandra","Stobhill",
               "Victoria Glasgow","Wishaw")

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

# Folder
data_folder <- paste0("/conf/quality_indicators/Benchmarking/Cancer QPIs/",
                      "Data/new_process/bladder_nov_24/")

# Folder containing lookup info on HBs by network
regional_networks_folder <- here("/conf/quality_indicators/Benchmarking/Cancer QPIs/Data/new_process/regional_cancer_networks")


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

hb_hosp_in_fpath <- paste0(data_folder,
                           "excels_for_tableau/initial_run/input/",
                           "HB_Hosp_QPI.xlsx")

age_gender_in_fpath <- paste0(data_folder,
                              "excels_for_tableau/initial_run/input/",
                              "Background_Data_Age_Gender.xlsx")

case_asc_in_fpath <- paste0(data_folder,
                            "excels_for_tableau/initial_run/input/",
                            "Background_Data_Case.xlsx")

sca_fpath <- paste0(data_folder,
                    "data_submissions/scan.xlsx")

nca_fpath <- paste0(data_folder,
                    "data_submissions/nca.xlsx")

wos_fpath <- paste0(data_folder,
                    "data_submissions/woscan.xlsx")

# lookup

lookup_fpath <- paste0(data_folder,
                       "lookup/lookup.xlsx")

# templates

templates_fpath <- paste0(data_folder,
                          "templates/")

# output files

hb_hosp_out_fpath <- paste0(data_folder,
                           "excels_for_tableau/initial_run/output/",
                           "HB_Hosp_QPI.xlsx")

age_gender_out_fpath <- paste0(data_folder,
                               "excels_for_tableau/initial_run/output/",
                               "Background_Data_Age_Gender.xlsx")

case_asc_out_fpath <- paste0(data_folder,
                             "excels_for_tableau/initial_run/output/",
                             "Background_Data_Case.xlsx")

### hospital names
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

hosp_vectors <- list(nca_hosps, sca_hosps, wos_hosps)
networks <- c("NCA", "SCAN", "WoSCAN")

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

