# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hb_hosp_qpi.R
# 
# Update the hb_hosp_qpi.xlsx file with the new data. 
# Re-written in 2026 to use Business Objects extracts
# instead of the regional submissions previously used. 
# 
# R version 4.5.1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----
# Please edit the housekeeping file to specify the tsg and year of diagnosis. 
# Calls housekeeping, which also calls functions, which also calls packages. 
source("code/housekeeping.R") 

# Check there is always just one year's worth of data to be read in. 
if (length(new_years) > 1) {
  stop("More than one Cyear detected in housekeeping file. 
          This script is designed to process one year's data at a time.")
}

#### Step 1 : Import data ----
# Read in extract(s). 
# Most TSGs will be two excel files, a hospsurg and non-surg, 
# whereas ac leuk and lymphoma no hospsurg, 
# while colorectal qpi 15 liver mets is a special additional report, 
# ie colorectal has three excel extract files for each year. 


# old hb_hosp_qpi
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

# new lookup
lookup <- import_lookup(lookup_fpath) |> 
  select(-SurgDiag)

# Check that the lookup rows are for same tumour as set in housekeeping global variable 
if (any(!str_equal(lookup$cancer, tsg))){
 stop("Problem in lookup.xlsx: The tsg string value specified in 
      housekeeping.R (", tsg, ") is NOT matched in at least one of the values 
      in the Cancer column of lookup.xlsx: ", unique(lookup$cancer)) 
}

# new data
new_data <- import_extracts(data_folder, extracts_filenames) 

# Shorten the QPI name column header to just 'QPI'. 
# The import functions already identified the first column 
# by matching search_string "QPI.*dashboard name", so we assume the column index
# is equal to 1, and do this step first, before any column re-ordering.  
names(new_data)[1] <- "QPI"



# Add Board_Hospital (constant) and Cancer from tsg global variable
new_data <- new_data |>
  mutate(Board_Hospital = "NHS Board") |> 
  mutate(Cancer = tsg)


# Populate the Network column in Scotland rows
new_data <- new_data |>
  mutate(Network = if_else(
    str_detect(tolower(Location), "scotland"), 
    "Scotland", 
    NA_character_)) 

# Join to allocate rows to regional networks
new_data <-  new_data |>
  mutate(Network = replace_values(
    Location, 
    from = HB_geo_groups$e_case_hb_name, 
    to = HB_geo_groups$Network))
    
# Swap in the health board abbreviations used in the SCRIS Tableau dashboard
new_data <- new_data |>
  mutate(Location = replace_values(Location, 
                                   from = HB_geo_groups$e_case_hb_name, 
                                   to = HB_geo_groups$qpi_dashboard_hb_abbreviation)) 

# Add figures from Golden Jubilee to Greater Glasgow & Clyde

#new_data <- new_data |>
  

#### Step 2 : Create Scotland totals for new data (to be changed to create regional rows instead) ----

regional_rows <- new_data |>
  filter(!str_detect(tolower(Location), "scotland")) |>
           group_by(QPI, Network) |>
           summarise(
             across(
              where(is.numeric), 
              ~ sum(.x, na.rm = TRUE)
              ) |> 
           ungroup()) |>
           mutate(Location = Network,
                  Board_Hospital = "NHS Board",
                  Cancer = tsg,
                  Comments = NA)


scotland_rows <- new_data %>% 
  filter(Location %in% c("NCA", "SCAN", "WoSCAN")) %>% 
  group_by(QPI, cyear, Year, surg_diag) %>% 
  summarise_if(is.numeric,sum) %>%
  ungroup() %>% 
  mutate(board_hosp = "NHS Board",
         Cancer = tsg,
         Location = "Scotland",
         Network = "Scotland",
         Comments = NA)

scotland_minus_comments <- scotland_rows |>
  select(!Comments)
write.xlsx(scotland_minus_comments, here("code", "for_summary_table", "Scotland_rows_no_comments.xlsx"))

new_data <- new_data |> 
  bind_rows(scotland_rows)

#### Step 3 : Join lookup to new data ----

new_data <- new_data |> 
  left_join(lookup, by = c("cyear" = "cyear",
                           "Cancer" = "cancer",
                           "QPI" = "qpi"))

# Identify rows where the QPI name in new_data was not matched with any in lookup. 
# Sometimes happens because of a typo in the QPI name. 
# Checking Numerator1 column as a proxy for the whole row in lookup
rows_with_missing_values <- new_data |> 
  filter(is.na(numerator1) ) # needs testing

if (nrow(rows_with_missing_values) > 0 ) {
  message("ISSUE DETECTED: POSSIBLE UN-MATCHED ROWS.\n")
  message("The Numerator1 column is empty in some rows, indicating possible mis-match between data submissions and lookup, see missing_data.csv.\n")
 write.csv(rows_with_missing_values, file = here(data_folder, "missing_data.csv"))
}

#### Step 4 : create derived variables ----
## There are a series of variables which Tableau requires which are 
## derived from the data submissions and the lookups.
## Some of them aren't used anymore but for now they are all required

## cyear_abr
new_data <- new_data |>
  mutate(cyear_abr = case_when(
    str_length(cyear) == 4 ~ str_sub(cyear, 1, 4),
    str_length(cyear) == 7 ~ str_sub(cyear, 3, 7)
  ))

# per_performance
new_data <- new_data |> 
  mutate(per_performance = (Numerator/Denominator)*100) |> 
  mutate(per_performance = if_else(is.na(per_performance), 0, per_performance))

# QPI_order (does nothing. Leave for now?)
new_data <- new_data |> 
  mutate(qpi_order = as.numeric(qpi_order))

# Does nothing as well I think
new_data <- new_data |> 
  mutate(qpi_subtitle = as.character(qpi_subtitle))

# year_lk (same as cyear?)
new_data <- new_data |> 
  mutate(year_lk = cyear)

# direction_text
new_data <- new_data |> 
  mutate(direction_text = case_when(
    direction == "H" ~ "High rates/ratio desired",
    direction == "L" ~ "Low rates/ratio desired",
    TRUE ~ "unknown"))

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

# target_label
new_data <- new_data |> 
  mutate(target_label = case_when(
    direction == "H" ~ paste0(current_target, "%"),
    direction == "L" ~ paste0("<", current_target, "%")
  ))

# Recode board_hospital
new_data <- new_data |> 
  mutate(board_hosp = case_when(
    board_hosp %in% c("Board","Network") ~ "NHS Board",
    TRUE ~ board_hosp
  ))

#### Step 5 : Change names for tableau ----

new_data <- new_data |> 
  rename(
    Board_Hospital = board_hosp,
    Cyear = cyear,
    SurgDiag = surg_diag,
    NRforDenominator = nr_denominator,
    NRforExclusion = nr_exclusions,
    NRforNumerator = nr_numerator,
    PerPerformance = per_performance,
    Cyear_Abr = cyear_abr,
    Year_Lk = year_lk,
    QPI_Order = qpi_order,
    Numerator1 = numerator1,
    Denominator1 = denominator1,
    Exclusions1 = exclusions1,
    Current_Target = current_target,
    Target_Label = target_label,
    Direction = direction,
    QPI_Label_Short = qpi_label_short,
    Direction_Text = direction_text,
    RAG_Status = rag_status,
    HB_Comments = Comments,
    Previous_Target = previous_target,
    QPI_Subtitle = qpi_subtitle
  ) |> 
  select(-Year)

#### Step 6 : Bind together to make full hb_hosp_qpi ----

hb_hosp_no_tsg <- hb_hosp_old |> 
  filter(Cancer != tsg)

old_tsg_data <- hb_hosp_old |> 
  filter(Cancer == tsg)

# Replace " - " and " – " in old QPI names with ": "
# This step can be removed once all updates are done or another solution made
old_tsg_data <- old_tsg_data |> 
  mutate(QPI = str_replace(QPI, " – ", ": "),
         QPI = str_replace(QPI, " - ", ": "),
         QPI = str_replace(QPI, "QPI \\d+ ", reformat_qpi_number))

hb_hosp_new <- bind_rows(hb_hosp_no_tsg, old_tsg_data, new_data) |> 
  arrange()

#### Step 7 : Write to excel ----

write.xlsx(hb_hosp_new, hb_hosp_out_fpath, sheetName = "HB_Hosp_QPI")


