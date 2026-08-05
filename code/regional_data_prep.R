#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# 
# Data prep - regional QPI data for public dashboard
#
#
#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Lots of manual steps to start with. 
# See README file: 
# \Cancer_QPIs\Data\new_process\regional_data\nov_2025_dashboard_data

library(here) 
library(tidyverse)
library(arrow)

# Folder
data_folder <- here("/PHI_conf", "CancerGroup2", "Cancer_QPIs",
                    "Data", "public_dashboard_qpis", "historic_regional_data",
                    "nov_2025_dashboard_data")

# Import the three CSV files for performance, age and case ascertainment
historic_performance <- read_csv(here(data_folder, "HB_Hosp_QPI_regional.csv"))

# Save as parquet eg
# #write parquet file to shiny app data folder
# write_parquet(regional_dataset, "shiny_app/data/regional_dataset", compression = "zstd")
write_parquet(historic_performance, here(data_folder, "HB_Hosp_QPI_regional.parquet"))
