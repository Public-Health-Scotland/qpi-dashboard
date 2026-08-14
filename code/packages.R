# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# packages.R
# 
# Import packages required for the project
# 
# R version 4.5 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(tidyverse)
library(openxlsx)
# Warning: deliberate decision to NOT update to openxlsx2, firstly because it 
# stupidly has a different name, and secondly because it stupidly renames 
# the readWorkbook function ie breaks this code in multiple places, 
# so would require a non-trivial amount of migration work and testing. 
library(here)
library(janitor)
