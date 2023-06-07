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

source("code/packages.R")

# tsg = "Tumour Specific Group"
# The following are acceptable values
# "Acute Leukaemia" "Bladder"     "Breast"           "Cervical"
# "Colorectal"      "Endometrial" "Head and Neck"    "Lung"
# "Lymphoma"        "Melanoma"    "Ovarian"          "Prostate"
# "Renal"           "Testicular"  "Upper GI-Gastric" "Upper GI-Oesophageal"
tsg <- "Colorectal"

new_years <- c("2019/20", "2020/21", "2021/22")

# Filepaths

data_folder <- paste0("/conf/quality_indicators/Benchmarking/Cancer QPIs/",
                      "Data/new_process/colorectal_jun23_dev/")

#########################################

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

# output files

hb_hosp_out_fpath <- paste0(data_folder,
                           "excels_for_tableau/output/",
                           "hb_hosp_qpi.xlsx")

