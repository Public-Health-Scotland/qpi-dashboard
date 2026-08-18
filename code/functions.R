# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# functions.R
# 
# Define functions used in other scripts. 
# 
# R version 4.5.1
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

# import_extracts replaces import_submission, below
import_extracts <- function(data_folder, extracts_filenames) {
  # Read in extract files. Assume one year's data. 
  # Usually will find hospsurg file and non-surgical file. 
   
  message(c("Path to your input data: ", extract_path))
  filenm_pattern <- str_c(".*\\.xlsx") 
  data_folder_files <- list.files(
    path = extract_path,
    pattern = filenm_pattern,
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  message("Please check that each of the extract files is named in housekeeping.R, 
  and is also detected in the data folder...")
  message("Housekeeping.R: ", extracts_filenames)
  message("Files detected in data folder: ", data_folder_files) 
  message("WARNING: The script assumes the following:
          the Multi-QPI Scotland performance data has 'Scot' in the worksheet name, and 
          the MultiQPI health board level performance data has 'HB' in the worksheet name. ")

  new_data <- tibble() 
  for (one_filename in extracts_filenames) {
    # for testing   #  one_filename <- extracts_filenames[1]
    extract_file <- here(extract_path, one_filename) 
    
    # Identify the Scotland and HB tabs respectively, in a typo-tolerant way
    tab_names <- getSheetNames(extract_file)
    scot_sheet_name <- tab_names[str_detect(tab_names, regex("Scot", ignore_case = TRUE))][1]
    scot_raw_tab <- readWorkbook(extract_file, sheet = scot_sheet_name, colNames = FALSE)
    
    table_start_position <- find_table_start(scot_raw_tab)

    scot_new_data <- readWorkbook(extract_file, 
                               sheet = scot_sheet_name, 
                               colNames = TRUE, 
                               skipEmptyCols = TRUE, 
                               skipEmptyRows = TRUE,
                               # Not sure why, but offset of 2 is required
                               startRow = as.integer(table_start_position["start_row"]) + 2
    )  |> 
      mutate(PerPerformance = as.double(PerPerformance), 
             Location = "Scotland")

    hb_sheet_name <- tab_names[str_detect(tab_names, regex("HB", ignore_case = TRUE))][1]
    hb_raw_tab <- readWorkbook(extract_file, sheet = hb_sheet_name, colNames = FALSE) 
    hb_table_start_position <- find_table_start(hb_raw_tab)
    hb_new_data  <- readWorkbook(extract_file, 
                              sheet = hb_sheet_name, 
                              colNames = TRUE, 
                              skipEmptyCols = TRUE, 
                              skipEmptyRows = TRUE,
                              startRow = as.integer(hb_table_start_position["start_row"]) + 2
    ) |> 
      mutate(PerPerformance = as.double(PerPerformance)) 
    
    # Rename the column containing health board name 
    if (any(str_detect(tolower(hb_new_data[ ,2]), "glasgow"))) {
      # print("found Glasgow, phew.") # Just checking this is the health board column
     names(hb_new_data)[2] <- "Location"
    }
    new_data <-  bind_rows(new_data, scot_new_data, hb_new_data)
  }
  
  return(new_data)
  
} 

find_table_start <- function(raw_worksheet){
  
  search_string <- "QPI.*dashboard name" 
  
  # Create named vector, for returning the result 
  start_positions <- c(start_row = 0, start_col = 0)
  max_cols_to_search <- 7
  max_rows_to_search <- 12
  current_row_checking <- 1
  while (current_row_checking < max_rows_to_search) { 
    current_col_checking <- 1
    while (current_col_checking < max_cols_to_search) {
      if (  str_detect(
        raw_worksheet[current_row_checking, current_col_checking], 
        search_string) |>
        coalesce(FALSE) # treat NA values as false
      ){
        start_positions["start_row"] <- current_row_checking
        start_positions["start_col"] <- current_col_checking 
      }
      current_col_checking <- current_col_checking + 1
    }
    
    current_row_checking <- current_row_checking + 1 
  }
  return(start_positions) 
}

# Should be called passing in the following arguments: 
#  - new_years_vals, as defined in housekeeping, in to year_vals parameter
#    (year_vals are usually integers stored as numerics representing the year 
#    of the improvement programme eg c(7,8,9)), 
#    but may be strings eg "7 to 9". 
#    They need to match the tabs in Excel submission files. 
#
#  - new_years, as defined in housekeeping, in to the years parameter
#    (such as "2017/18" ie the strings that ultimately go into the column Cyear in the output.)
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
    ) |> 
    replace_na(list(Numerator = 0,
                    Denominator = 0,
                    nr_numerator = 0, 
                    nr_exclusions = 0, 
                    nr_denominator = 0))
    
  
  network_sub
  
}

import_lookup <- function(lookup_fpath) {
  
  lookup <- readWorkbook(lookup_fpath) |> 
    mutate(across(c("cyear", "cancer", "qpi",
                    "numerator1", "denominator1", "exclusions1",
                    "target_label", "direction", "qpi_label_short",
                    "qpi_subtitle",
                    "SurgDiag"), as.character)) |> 
    mutate(across(c("qpi_order", "previous_target",
                    "current_target"), as.numeric))
  
  lookup
  
}

#### housekeeping.R ----

get_hosp_names <- function(ntwrk_hosps, ntwrk, hb_hosp_old) {
  
  # Convert Cyear into a numeric value, so we can make use of a range of years
  hb_hosp_old <- hb_hosp_old |> 
    mutate(start_year = as.numeric(substr(Cyear, 1, 4)))
    
    
  if (is.null(ntwrk_hosps)) {
    
    hosps <- hb_hosp_old |> 
      filter(Cancer == tsg,
             Network == {{ ntwrk  }}) |>
      filter(start_year >= (max(start_year) - 5) ) |> 
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
    
    # date_end is start_date plus one year minus one day
    date_end_date <- date_start -1
    date_end_str <- date_end_date %m+% years(i) |> 
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
  
  # Calculate date end string as date_start plus one year, minus one day, in two steps
  date_end_date <- date_start -1
  date_end_str <- date_end_date %m+% years(length(new_years)) |> 
    format("%d/%m/%Y")
  
  
 # date_end_str <- as.Date(date_end_plus_one_day_str) -1 |> 
  #  format("%d/%m/%Y")
  
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
    
    if (tsg_sex == "both") {
      
      for (j in 1:(nrow(age_sex_df)/2)) {
        
        mergeCells(wb, "BackgroundInfo", cols = 2,
                   rows = ((title_row+3+(2*(j-1))):(title_row+3+(2*(j-1)+1))))
        
      }
      
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

set_RAG_status <- function(new_data) {
  # RAG status
  new_data <- new_data |> 
    mutate(rag_status = case_when(
      direction == "H" & (per_performance >= current_target) ~ "1",
      direction == "H" & per_performance > 0 & (per_performance < current_target) ~ "2",
      direction == "H" & per_performance == 0  & Denominator <= 0 ~ "3",
      direction == "H" & per_performance == 0 & Denominator > 0 ~ "2",
      direction == "L" & per_performance > 0 & per_performance <= current_target ~ "1",
      direction == "L" & per_performance > current_target ~ "2",
      direction == "L" & per_performance == 0 & Denominator <= 0 ~ "3",
      direction == "L" & per_performance == 0 & Denominator > 0 ~ "1",
      TRUE ~ "unknown"))
}

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

make_summary_table <- function(summary_data_path) {
  # Import the summary data 
  # from the separate file containing rows from HB_hosp where Location is Scotland 
  scotland_performance_all_qpis <- readWorkbook(here(summary_data_path, "Scotland_rows_no_comments.xlsx"))
  
  # Add target status column called Result
  scotland_performance_all_qpis <- scotland_performance_all_qpis |>
    mutate(Result = ifelse(RAG_Status == 1, "Target met", "Target not met")) |> 
    mutate("Performance (%)" = str_c(format(round_half_up(PerPerformance, digits = 1), nsmall=1), "%")) |> 
    rename("Target" = Target_Label)
  
  # Use pivot_wider to create columns for the years
  # Needs more work, to appent "%" in the cells so its more obvious they're percentages. 
  performance_by_year <- scotland_performance_all_qpis |>
    pivot_wider(names_from = Cyear, 
                values_from = c("Performance (%)", Result),
                id_cols = c(QPI,Target), 
                names_sep = " ",
                names_vary = "slowest"
    ) 
  
  return(performance_by_year)
}

# Identify what HBs belong to what regions, dependent on the TSG
# since some HBs differ for brain & CNS, lymphoma and ac leuk
set_up_regions <- function() { 
  # Read the data from: 
  # H:\Cancer_QPIs\Data\qpi_lookups\regional_geography
  # "lookup_health_board_by_cancer_hb_14_hb19_RegionalCancerNetwork.xlsx" 
  # This reference file should be kept in Excel format to allow
  # colour highlighting for human readability
  # NB eCASE raw health board names need parsing to NHS opendata format 
  # here, because they are upper case with ampersands instead of "and"(!).
  # Could use new eCASE_name column in the lookup to match. 
  regions_lookup <- readWorkbook(here(regional_networks_folder, 
                                      "lookup_health_board_by_cancer_hb_14_hb19_RegionalCancerNetwork.xlsx")) |>
    clean_names()
  
  if (str_equal(tsg, "Acute Leukaemia")){
    tsg_specific_regions_lookup <- tsg_specific_regions_lookup |> 
      mutate(Network = rcn_for_acute_leukaemia)
  } else if(str_equal(tsg, "Lymphoma")) {
    tsg_specific_regions_lookup <- tsg_specific_regions_lookup |> 
      mutate(Network = rcn_for_lymphoma)
  } else if(str_equal(tsg, "Brain and CNS")){
    tsg_specific_regions_lookup <- tsg_specific_regions_lookup |>
      mutate(Network = rcn_for_brain_and_cns_cancer)
  } else {
    tsg_specific_regions_lookup <- tsg_specific_regions_lookup |>
      mutate(Network = default_regional_cancer_network)
  }
  return(tsg_specific_regions_lookup)
}

#### check_submissions.R ----

basic_data_checks <- function(new_data) {
  
  basic_checks_output <- "# Basic checks output \n"
  # Add date and time into output
  basic_checks_output <- str_c(basic_checks_output, "Timestamp - Checking started at: ", Sys.time(), "\n")

  # Delete the comments column
  new_data_to_check <- as_tibble(new_data)
  new_data_to_check <- select(new_data_to_check, -Comments)
  
  # For the new data, provide a count of records for each regional network, 
  # for each year, 
  # for each QPI. 
  # Are there rows for each Health Board for each QPI for each year? 
  # Are any cells empty that we would expect to be populated? 
  # Are the numbers of patients in a sensible range ie what ballpark are they in? 
  basic_checks_output <- str_c(basic_checks_output, "ADD CHECK RESULTS HERE!" , "\n")
  
  tally_table_by_network <- new_data_to_check |> 
    count(cyear, Year, Network)
  
  tally_table_by_QPI <- new_data_to_check |> 
    count(QPI, board_hosp) 
  
  tally_table_by_location <- new_data_to_check |> 
    group_by(Network) |> 
    count(cyear, Location)
  
  return(basic_checks_list <- list(netwk = tally_table_by_network, qpis = tally_table_by_QPI, locn = tally_table_by_location))
  
}


check_totals <- function(df, board_or_hosp) {
  
  message(str_c("Checking sub-totals for: ", board_or_hosp)) 
  
  if (board_or_hosp == "Hospital") {
    
    df <- df |> 
      filter(surg_diag == "Surgery",
             board_hosp %in% c("Network", "Hospital"))
    
  }
  
  check <- df |> 
    select(-Comments) |>
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
  
  message("tibble: check; column: Numerator:  ")
  message(toString(check$Numerator))
  
  totals <- df |> 
    filter(board_hosp == "Network") |> 
    select(
      Year, Location, QPI, Numerator, Denominator, nr_numerator,
      nr_exclusions, nr_denominator
    ) |> 
    rename(Network = Location)
  
  message("tibble: totals; column: Numerator: ")
  message(toString(totals$Numerator))
  
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
    ungroup() |> 
    pivot_longer(cols = c(Numerator:nr_denominator)) |> 
    filter(value == FALSE) |> 
    select(-value)
  
  
  message("tibble diffs: ")
  message(toString(diffs))
  
  diffs
  
}

hosp_differences_report <- function(new_data) {
  # Create tibble, to contain the delta  
  # not working - will need some trial and error
  # still need to filter to hospital 
  # and sum the hosps only 
  # and compare to network only
  # Will calculate the delta ie the differences for any non-matching sub-totals
  # and will store and write the amount and direction of the differences
  # to help troubleshooting by helping us identify eg where there are reciprocal differences, 
  # that show data has been swapped between the expected locations etc. 
  diffs_deltas <- new_data |> 
    group_by(Year, Network, QPI) |> 
    summarise(
    summarised_Numerator = Numerator
  )
}

print_error_report <- function(z_board_totals, z_hospital_totals) {
  
  # Prints the outcome of all checks to the terminal
  
  message("ERROR REPORT \n")

  if (nrow(z_board_totals) == 0) {
    message("PASS. All board totals match network figures")
  } else {
    message("ERROR. The following board totals don't match the network figure")
    message("       View `z_board_totals` for full dataframe")
    z_board_totals 
  }
  
  if (nrow(z_hospital_totals) == 0) {
    message("PASS. All hospital totals match network figures")
  } else {
    message("ERROR. The following hospital totals don't match the network figure")
    message("       View `z_hospital_totals` for full dataframe")
    z_hospital_totals
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

