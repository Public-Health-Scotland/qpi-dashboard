# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# housekeeping.R
# Angus Morton
# 2023-05-22
# 
# Contains the values which should be changed each run
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/packages.R")

# tsg = "Tumour Specific Group"
# The following are acceptable values
# "Acute Leukaemia" "Bladder"     "Breast"           "Cervical"
# "Colorectal"      "Endometrial" "Head and Neck"    "Lung"
# "Lymphoma"        "Melanoma"    "Ovarian"          "Prostate"
# "Renal"           "Testicular"  "Upper GI-Gastric" "Upper GI-Oesophageal"

tsg <- "Colorectal"

tsg_sex <- case_when(
  tsg %in% c("Breast", "Cervical", "Endometrial", "Ovarian") ~ "female",
  tsg %in% c("Prostate", "Testicular") ~ "male",
  TRUE ~ "both"
)

new_years <- c("2019/20", "2020/21", "2021/22")

date_start <- dmy("01-04-2019")

# measurability versions (one for each year)
meas_vers <- c("3.3", "3.3", "4.4")

## hospital names :
# Enter hospital names manually. If none supplied then the script will use
# the names from the most recent published year of QPIs for this TSG.
# To use existing names enter a NULL vector e.g. "nca_hosps <- c()"
nca_hosps <- c("hosp 1", "hosp 0")
sca_hosps <- c()
wos_hosps <- c()

# Filepaths

data_folder <- paste0("/conf/quality_indicators/Benchmarking/Cancer QPIs/",
                      "Data/new_process/colorectal_jun23_dev/")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# run get_hosp_names three times
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

hosp_vectors <- list(nca_hosps, sca_hosps, wos_hosps)
networks <- c("NCA", "SCAN", "WoSCAN")

hosp_names <- map2_dfr(hosp_vectors, networks, get_hosp_names, hb_hosp_old)
