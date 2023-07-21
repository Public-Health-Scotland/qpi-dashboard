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
# They will need edited for each new dashbaord update.

# tsg = "Tumour Specific Group"
# The following are acceptable values
# "Acute Leukaemia" "Bladder"     "Breast"           "Cervical"
# "Colorectal"      "Endometrial" "Head and Neck"    "Lung"
# "Lymphoma"        "Melanoma"    "Ovarian"          "Prostate"
# "Renal"           "Testicular"  "Upper GI-Gastric" "Upper GI-Oesophageal"

tsg <- "Lymphoma"

new_years <- c("2019/20", "2020/21", "2021/22")
new_years_vals <- c(7,8,9)

# Date of the start of the first new reporting year
date_start <- dmy("01-10-2019")

# measurability versions (one for each year)
meas_vers <- c("3.3", "3.3", "4.4")

## hospital names :
# Enter hospital names manually. If none supplied then the script will use
# the names from the most recent published year of QPIs for this TSG.
# To use existing names enter a NULL vector e.g. "nca_hosps <- c()"
nca_hosps <- c()
sca_hosps <- c()
wos_hosps <- c()

## age groups for template :
# Enter age groups for background info manually. If none supplied then the
# script will use the most common set of (<45, 45-49 ... 80-84, >85)
# To use default age groups enter a NULL vector e.g. "nca_hosps <- c()"
age_groups <- c("Under 16",
                "16-19",
                "20-24",
                "25-29",
                "30-34",
                "35-39",
                "40-44",
                "45-49",
                "50-54",
                "55-59",
                "60-64",
                "65-69",
                "70-74",
                "75-79",
                "80-84",
                "85+")

# Folder
data_folder <- paste0("/conf/quality_indicators/Benchmarking/Cancer QPIs/",
                      "Data/new_process/lymphoma_jul23/")

#~~~~~~~~~~~~~~~~~ Nothing below this line needs edited ~~~~~~~~~~~~~~

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
                           "excels_for_tableau/input/",
                           "HB_Hosp_QPI.xlsx")

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
                          "tempates/")

# output files

hb_hosp_out_fpath <- paste0(data_folder,
                           "excels_for_tableau/output/",
                           "hb_hosp_qpi.xlsx")

### hospital names
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

hosp_vectors <- list(nca_hosps, sca_hosps, wos_hosps)
networks <- c("NCA", "SCAN", "WoSCAN")

hosp_names <- map2_dfr(hosp_vectors, networks, get_hosp_names, hb_hosp_old)

### board names
board_names <- hb_hosp_old |> 
  filter(Board_Hospital == "NHS Board",
         Cancer == tsg,
         Location != "Scotland") |>
  filter(Cyear == max(Cyear)) |> 
  select(Network, Location) |> 
  distinct()

### age groups

age_groups <- get_age_groups(age_groups)
