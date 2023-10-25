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

#### GENERAL ----

read_data_year <- function(year_val, cyear, network, sub_path) {
  sheet_name <- paste0("QPI Data Year ", as.character(year_val))
  
  network_year <- readWorkbook(paste0(sub_path, network, ".xlsx"),
                               sheet = sheet_name,
                               startRow = 5) |>
    mutate(
      cyear = cyear,
      Year = paste0("Year ", as.character(year_val)),
      .before = 1,
      Comments = as.character(Comments)
    )
  
  network_year
  
}

import_submission <- function(network, sub_path, year_vals, years) {
  
  network_sub <- map2(year_vals, years, read_data_year,
                     network = network,
                     sub_path = sub_path) |> 
    list_rbind() |> 
    rename(
      surg_diag = "Diagnosis/Surgery",
      board_hosp = "Board/Hospital",
      nr_numerator = "NR.Numerator",
      nr_exclusions = "NR.Exclusions",
      nr_denominator = "NR.Denominator"
    )
  
  network_sub
  
}

#### housekeeping.R ----

get_hosp_names <- function(ntwrk_hosps, ntwrk, hb_hosp_old) {
  
  if (is.null(ntwrk_hosps)) {
    
    hosps <- hb_hosp_old |> 
      filter(Cancer == tsg,
             Network == {{ ntwrk  }}) |>
      filter(Cyear == max(Cyear)) |> 
      filter(Board_Hospital == "Hospital") |> 
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

get_age_groups <- function(age_groups) {
  
  if (is.null(age_groups)) {
    
    age_groups <- c("Under 45",
                    "45-49",
                    "50-54",
                    "55-59",
                    "60-64",
                    "65-69",
                    "70-74",
                    "75-79",
                    "80-84",
                    "85+",
                    "Total")
    
  } else {
    
    age_groups <- age_groups |> append("Total")
    
  }
  
  age_groups
  
}

#### create_templates.R ----

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
    
    setColWidths(wb, sheet = sheet_name, widths = 3, cols = 1)
    setColWidths(wb, sheet = sheet_name, widths = "auto", cols = 3:7)
    setColWidths(wb, sheet = sheet_name, widths = 15.6, cols = 8:12)
    setColWidths(wb, sheet = sheet_name, widths = 68, cols = 13)
    
    showGridLines(wb, sheet = sheet_name, showGridLines = FALSE)
    
  }
  
  wb
  
}



make_background_tab <- function(wb, tsg, network, new_years, new_years_vals,
                                date_start, tsg_sex, board_names,
                                styles) {
  
  title_cell <- paste0(tsg, " QPIs: Background Data")
  
  date_start_str <- date_start |> format("%d/%m/%Y")
  
  date_end_str <- date_start %m+% years(length(new_years)) |> 
    format("%d/%m/%Y")
  
  subtitle_cell <- paste0("Cohort: Patients Diagnosed with ",
                          tsg,
                          " Cancer Between ",
                          date_start_str,
                          " and ",
                          date_end_str
  )
  
  addWorksheet(wb, sheetName = "BackgroundInfo")
  
  writeData(wb, sheet = "BackgroundInfo",
            title_cell, startRow = 1, startCol = 2)
  writeData(wb, sheet = "BackgroundInfo",
            subtitle_cell, startRow = 2, startCol = 2)
  
  addStyle(wb, sheet = "BackgroundInfo", style = styles$title,
           rows = 1, cols = 2)
  
  num_cases_df <- board_names |>
    filter(Network == network) |>
    select(Location) |>
    mutate(Measure = "No. Of Cases",
           `No. Of Patients` = NA)
  
  num_boards <- board_names |> 
    filter(Network == network) |> 
    select(Location) |> 
    pull() |> 
    length()
  
  ntwk_boards <- board_names |> 
    filter(Network == network) |> 
    filter(Location != network)
  
  
  if (tsg_sex == "female") {
    
    age_sex_df <- data.frame(
      `Age Range` = age_groups,
      Sex = "F",
      dummy = NA
    ) |> 
      cross_join(ntwk_boards) |> 
      pivot_wider(names_from = "Location", values_from = dummy) |> 
      select(-Network) |> 
      mutate("{network}" := NA)
    
  } else if (tsg_sex == "male") {
    
    age_sex_df <- data.frame(
      `Age Range` = age_groups,
      Sex = "M",
      dummy = NA
    ) |> 
      cross_join(ntwk_boards) |> 
      pivot_wider(names_from = "Location", values_from = dummy) |> 
      select(-Network) |> 
      mutate("{network}" := NA)
    
  } else {
    
    age_sex_df <- data.frame(
      `Age Range` = age_groups) |>
      cross_join(data.frame(Sex = c("M","F"))) |> 
      cross_join(ntwk_boards) |> 
      mutate(dummy = NA) |> 
      pivot_wider(names_from = "Location", values_from = dummy) |> 
      select(-Network) |> 
      mutate("{network}" := NA)
    
  }
  
  age_sex_start_row <- 5 + length(new_years)*(num_boards+4)
  
  for (i in 1:length(new_years)) {
    
    title_row <- (5 + (i-1)*(num_boards + 4))
    
    table_rows <- (title_row+3):(title_row + num_boards + 2)
    
    network_row <- (title_row + num_boards + 2)
    
    # Number of cases tables
    
    title <- paste0("Number of Cases (Year ",
                    new_years_vals[i],
                    " - ",
                    new_years[i],
                    ")")
    
    writeData(wb, sheet = "BackgroundInfo",
              title,
              startRow = title_row,
              startCol = 2)
    
    writeData(wb, sheet = "BackgroundInfo",
              num_cases_df,
              startRow = (title_row + 2),
              startCol = 2)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$title,
             rows = title_row, cols = 2)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$header,
             rows = (title_row + 2), cols = 2:4, gridExpand = TRUE,
             stack = TRUE)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$table,
             rows = table_rows, cols = 2:4, gridExpand = TRUE,
             stack = TRUE)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$total,
             rows = network_row, cols = 2, gridExpand = TRUE,
             stack = TRUE)
    
    
    # age gender tables
    
    title_row <- age_sex_start_row + (i-1)*(nrow(age_sex_df)+4)
    
    table_rows <- (title_row+3):(title_row + nrow(age_sex_df) + 2)
    
    table_cols <- 2:(length(age_sex_df)+1)
    
    title <- paste0("Age Gender (Year ",
                    new_years_vals[i],
                    " - ",
                    new_years[i],
                    ")")
    
    writeData(wb, sheet = "BackgroundInfo",
              title,
              startRow = title_row,
              startCol = 2)
    writeData(wb, sheet = "BackgroundInfo",
              age_sex_df,
              startRow = (title_row + 2),
              startCol = 2)
    createNamedRegion(wb, "BackgroundInfo",
                      cols = 2:(ncol(age_sex_df)+1),
                      rows = (title_row+2):(title_row+3+nrow(age_sex_df)),
                      name = paste0("ag", as.character(new_years_vals[i])))
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$title,
             rows = title_row, cols = 2)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$header,
             rows = (title_row + 2), cols = 2:(length(age_sex_df)+1),
             gridExpand = TRUE, stack = TRUE)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$table,
             rows = table_rows, cols = table_cols, gridExpand = TRUE,
             stack = TRUE)
    
    addStyle(wb, sheet = "BackgroundInfo", style = styles$age_sex_table,
             rows = table_rows, cols = table_cols, gridExpand = TRUE,
             stack = TRUE)
    
    for (j in 1:(nrow(age_sex_df)/2)) {
      
      mergeCells(wb, "BackgroundInfo", cols = 2,
                 rows = ((title_row+3+(2*(j-1))):(title_row+3+(2*(j-1)+1))))
      
    }
    
  }
  

  setColWidths(wb, sheet = "BackgroundInfo", widths = 25.3, cols = 2)
  setColWidths(wb, sheet = "BackgroundInfo", widths = 10.5, cols = 3)
  setColWidths(wb, sheet = "BackgroundInfo", widths = 23,
               cols = 4:(length(age_sex_df)+1))
  
  showGridLines(wb, sheet = "BackgroundInfo", showGridLines = FALSE)
  
  wb
  
}


export_template <- function(df, network, new_years_vals, new_years, meas_vers,
                            date_start, styles) {
  
  # create workbook
  wb <- createWorkbook()
  
  # write QPIs tabs
  wb <- make_qpis_tabs(df, new_years_vals, new_years, meas_vers,
                       wb, date_start, styles)
  
  # write background tab
  wb <- make_background_tab(wb, tsg, network, new_years, new_years_vals,
                            date_start, tsg_sex, board_names, styles)
  
  # write out
  
  output_path <- paste0(data_folder, "templates/",
                        network,
                        "_",
                        tsg,
                        "_QPIs_template.xlsx")
  
  saveWorkbook(wb, output_path)
  
}


#### hb_hosp_qpi.R ----

# MIGHT BE DEPRECATING THIS
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

reformat_qpi_number <- function(x) {
  
  num <- str_match(x, "\\d+")
  
  qpi_number <- paste0("QPI ", num)
  
  qpi_number
  
}

#### check_submissions.R ----


check_totals <- function(df, board_or_hosp) {
  
  check <- new_data |> 
    filter(board_hosp == {{  board_or_hosp  }}) |>
    group_by(Year, Network, QPI) |> 
    summarise(
      Numerator = sum(Numerator),
      Denominator = sum(Denominator),
      nr_numerator = sum(nr_numerator),
      nr_exclusions = sum(nr_exclusions),
      nr_denominator = sum(nr_denominator)
    ) |> 
    ungroup()
  
  totals <- new_data |> 
    filter(board_hosp == "Network") |> 
    select(
      Year, Location, QPI, Numerator, Denominator, nr_numerator,
      nr_exclusions, nr_denominator
    ) |> 
    rename(Network = Location)
  
  diffs <- check |> 
    bind_rows(totals) |> 
    group_by(Year, Network, QPI) |> 
    summarise(
      Numerator = isTRUE(var(Numerator) == 0),
      Denominator = isTRUE(var(Denominator) == 0),
      nr_numerator = isTRUE(var(nr_numerator) == 0),
      nr_exclusions = isTRUE(var(nr_exclusions) == 0),
      nr_denominator = isTRUE(var(nr_denominator) == 0)
    ) |> 
    ungroup()
  
  diffs <- diffs |> 
    filter(Numerator == FALSE |
             Denominator == FALSE |
             nr_numerator == FALSE |
             nr_exclusions == FALSE |
             nr_denominator == FALSE)
  
  diffs
  
}

print_error_report <- function(z_board_totals, z_hospital_totals) {
  
  # Prints the outcome of all checks to the terminal
  
  message("ERROR REPORT \n")
  
  if (nrow(z_board_totals) == 0) {
    message("PASS. All board totals match network figures")
  } else {
    message("ERROR. The following board totals don't match the network figure")
    message("       View `z` for full dataframe")
    z
  }
  
  if (nrow(z_board_totals) == 0) {
    message("PASS. All board totals match network figures")
  } else {
    message("ERROR. The following board totals don't match the network figure")
    message("       View `z` for full dataframe")
    z
  }
}

#### case_asc.R ----

read_case_asc_data <- function(fpath) {
  
  # Reads in a QPI data submission template from a network
  
  template <- loadWorkbook(fpath)

  
  data
  
}

#### age_gender.R ----


read_ag_year <- function(year_val, cyear, network, sub_path) {
  
  network_year <- loadWorkbook(paste0(sub_path, network, ".xlsx")) |> 
    readWorkbook(namedRegion = paste0("ag", year_val)) |>
    pivot_longer(cols = 3:last_col()) |> 
    mutate(cyear = cyear,
           network = network) |> 
    rename(Location = name)
  
  network_year
  
}

import_age_gender <- function(network, sub_path, year_vals, years) {
  
  network_sub <- map2(year_vals, years, read_ag_year,
                      network = network,
                      sub_path = sub_path) |> 
    list_rbind()
  
  network_sub
  
}


## Potential checks
# Check totals match

# check for novel hospital names

# reformat comments

# 

