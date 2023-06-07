# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# functions.R
# Angus Morton
# 2023-06-07
# 
# Define functions used in other scripts
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source("code/packages.R")

# read in and tidy qpi info from template

read_qpi_data <- function(fpath) {
  
  # Reads in a QPI data submission template from a network
  
  template <- loadWorkbook(fpath)
  
  years_num <- length(names(template))-1
  
  dat <- data.frame()
  
  for (year in 1:years_num) {
    
    rows <- readWorkbook(wos, sheet = year, startRow = 5, colNames = TRUE,
                         cols = 2) %>%
      filter(Network == "WoSCAN") %>% 
      count(Network) %>% 
      select(n) %>% 
      pull()
    
    year_dat <- readWorkbook(template, sheet = year, startRow = 5, 
                             rows = c(5:(rows+5)),
                             cols = c(2:13)) %>% 
      mutate(Comments = as.character(Comments),
             cyear = year)
    
    dat <- bind_rows(dat, year_dat)
    
  }
  
  dat
  
}

# read in and tidy qpi info from template

read_background_data <- function(fpath) {
  
  # Reads in a QPI data submission template from a network
  
  template <- loadWorkbook(fpath)

  
  data
  
}


# Check totals match

# check for novel hospital names

# reformat comments

# 

