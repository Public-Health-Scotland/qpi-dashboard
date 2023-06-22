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

get_hosp_names <- function(ntwrk_hosps, ntwrk, hb_hosp_old) {
  
  if (is.null(ntwrk_hosps)) {
    
    hosps <- hb_hosp_old |> 
      filter(Board_Hospital == "Hospital",
             Cancer == tsg,
             Network == {{ ntwrk  }}) |>
      filter(Cyear == max(Cyear)) |> 
      select(Network, Location) |> 
      distinct()
    
  } else {
    
    hosps <- data.frame(Location = ntwrk_hosps) |> 
      mutate(Network = {{  ntwrk  }}) |> 
      select(Network, Location) |> 
      arrange(Location)
    
  }
  
  hosps
  
}


make_template_df <- function(lookup, year, network, board_names,
                             hosp_names) {
  
  boards_ntwrk <- board_names |> 
    filter(Network == {{  network  }})
  
  hosps_ntwrk <- hosp_names |> 
    filter(Network == {{  network  }})
  
  board_qpis <- lookup |> 
    filter(cyear == {{  year  }}) |> 
    cross_join(boards_ntwrk) |> 
    mutate(board_hosp = if_else(Location != {{  network  }}, 1, 2))
  
  hosp_qpis <- lookup |> 
    filter(cyear == {{  year  }},
           SurgDiag == "Surgery") |> 
    cross_join(hosps_ntwrk) |> 
    mutate(board_hosp = 3)
  
  qpis <- bind_rows(board_qpis,
                    hosp_qpis) |> 
    arrange(order, board_hosp) |> 
    mutate(board_hosp = case_when(
      board_hosp == 1 ~ "Board",
      board_hosp == 2 ~ "Network",
      board_hosp == 3 ~ "Hospital"
    )) |> 
    select(Network, Location, qpi, SurgDiag, board_hosp, cancer) |> 
    rename(QPI = qpi,
           "Diagnosis/Surgery" = SurgDiag,
           "Board/Hospital" = board_hosp,
           Cancer = cancer) |> 
    mutate(Numerator = NA,
           Denominator = NA,
           "NR Numerator" = NA,
           "NR Exclusions" = NA,
           "NR Denominator" = NA,
           Comments = NA)
  
  qpis
  
}



make_qpis_tab <- function(wb, df, styles) {
  
  addWorksheet(wb, sheetName = "data")
  
  writeData(wb, sheet = 1, data, startRow = 1, startCol = 1, colNames = TRUE)
  
  wb
  
}


make_background_tab <- function(wb, cancer, network, new_years,
                                date_start, tsg_sex) {
  
  addWorksheet(wb, sheetName = "data")
  
  writeData(wb, sheet = 1, data, startRow = 1, startCol = 1, colNames = TRUE)
  
  wb
  
}


read_qpi_data <- function(fpath, network_name, year_names) {
  
  # Reads in a QPI data submission template from a network
  
  template <- loadWorkbook(fpath)
  
  years_num <- length(year_names)
  
  dat <- data.frame()
  
  for (year in 1:years_num) {
    
    rows <- readWorkbook(template, sheet = year, startRow = 5,
                         colNames = TRUE, cols = 2) %>%
      filter(Network == network_name) %>% 
      count(Network) %>% 
      select(n) %>% 
      pull()
    
    year_dat <- readWorkbook(template, sheet = year, startRow = 5, 
                             rows = c(5:(rows+5)),
                             cols = c(2:13)) %>% 
      mutate(Comments = as.character(Comments),
             Cyear = year_names[year])
    
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

