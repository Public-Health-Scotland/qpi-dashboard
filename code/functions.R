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

# housekeeping

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

# create_templates.R


make_template_df <- function(year, network, lookup, board_names,
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


# can't think of a way of doing this without a for loop.
# If openxlsx allowed you to combine workbook objects then you could do it
make_qpis_tabs <- function(dfs, year_nums, years, meas_vers,
                          wb, date_start, styles) {
  
  tsg <- dfs[[1]] |> 
    select(Cancer) |> 
    distinct() |> 
    pull()
  
  for (i in 1:length(year_nums)) {
  
    # define sheet name and cell values
    
    sheet_name <- paste0("QPI Data Year ", year_nums[i])
    
    title_cell <- paste0(tsg,
                         " Cancer QPIs (Year ",
                         year_nums[i],
                         " - ",
                         years[i],
                         ")")
    
    date_start_str <- date_start %m+% years(i-1) |> 
      format("%d/%m/%Y")
    
    date_end_str <- date_start %m+% years(i) |> 
      format("%d/%m/%Y")
    
    subtitle_cell <- paste0("Cohort: Patients Diagnosed with ",
                            tsg,
                            " Cancer Between ",
                            date_start_str,
                            " and ",
                            date_end_str
    )
    
    meas_cell <- paste0("Measurability of Quality Performance Indicators ",
                        "Version ",
                        meas_vers[i])
    
    # populate workbook
    
    addWorksheet(wb, sheetName = sheet_name)
    
    writeData(wb, sheet = sheet_name, title_cell, startRow = 1, startCol = 2)
    writeData(wb, sheet = sheet_name, subtitle_cell, startRow = 2, startCol = 2)
    writeData(wb, sheet = sheet_name, meas_cell, startRow = 3, startCol = 2)
    
    writeData(wb, sheet = sheet_name, dfs[[i]], startRow = 5, startCol = 2,
              colNames = TRUE)
    
    # apply styles
    
    ntwrk_rows <- which(dfs[[i]]$Network == dfs[[i]]$Location)+5
    
    data_size <- nrow(dfs[[i]])+1
    
    addStyle(wb, sheet = sheet_name, style = styles$title,
             rows = 1, cols = 2)
    
    addStyle(wb, sheet = sheet_name, style = styles$table,
             rows = 6:(data_size+4), cols = 2:13, gridExpand = TRUE)
    
    addStyle(wb, sheet = sheet_name, style = styles$header,
             rows = 5, cols = 2:13, stack = TRUE)
    
    addStyle(wb, sheet = sheet_name, style = styles$ntwrk_row,
             rows = ntwrk_rows, cols = 2:13, gridExpand = TRUE,  stack = TRUE)
    
    addStyle(wb, sheet = sheet_name, style = styles$total,
             rows = ntwrk_rows, cols = c(3,8:12), gridExpand = TRUE,
             stack = TRUE)
    
    setColWidths(wb, sheet = sheet_name, widths = "auto", cols = 3:7)
    setColWidths(wb, sheet = sheet_name, widths = 15.6, cols = 8:12)
    setColWidths(wb, sheet = sheet_name, widths = 68, cols = 13)
    
    showGridLines(wb, sheet = sheet_name, showGridLines = FALSE)
    
  }
  
  wb
  
}


make_background_tab <- function(wb, tsg, network, new_years,
                                date_start, tsg_sex) {
  
  
  
  title_cell <- paste0(tsg,
                       " QPIs: Background Data (",
                       month_start,
                       " to ",
                       month_end,
                       ")")
  
  addWorksheet(wb, sheetName = "BackgroundInfo")
  
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

