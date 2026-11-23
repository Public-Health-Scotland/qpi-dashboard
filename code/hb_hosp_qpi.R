# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hb_hosp_qpi.R
# 
# Update the hb_hosp_qpi.xlsx file with the new data. 
# Re-written in 2026 to use Business Objects extracts
# instead of the three regional submissions previously used. 
# 
# R version 4.5.1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----
warning("BEFORE RUNNING hb_hosp_qpi.R, MAKE SURE YOU HAVE RUN check_extracts.R 
	ON THIS DATA, AND LOOKED CAREFULLY AT ALL THE OUTPUT!")
# Please edit the housekeeping file to specify the tsg and year of diagnosis. 
# Calls housekeeping, which also calls functions, which also calls packages.
# And imports hb_hosp_old
source("code/housekeeping.R") 

# Check whether hb_hosp_old contains the expected range of years and tsg's. 
# These tests will make it obvious if the condensed hbhosp test file is being used.
max(hb_hosp_old$Cyear)      
unique(hb_hosp_old$Cancer)  
length(unique(hb_hosp_old$Cancer))

#### Step 1 : Import data ----
# Read in lookup file, and then extract(s). 
# Most TSGs will be two excel files, a hospsurg and diag, 
# whereas ac leuk and lymphoma have no hospsurg, so just one excel per year,
# while colorectal qpi 15 liver mets is a special additional report, 
# ie colorectal has three excel extract files for each year. 


# new lookup
lookup <- import_lookup(lookup_fpath) |> 
  select(-SurgDiag)

# Check that the lookup rows are for same tumour as set in housekeeping global variable 
if (any(!str_equal(lookup$cancer, tsg))){
 stop("Problem in lookup.xlsx: The tsg string value specified in 
      housekeeping.R (", tsg, ") is NOT matched in at least one of the values 
      in the Cancer column of lookup.xlsx: ", unique(lookup$cancer)) 
}

# Do the QPIs need to be split (due to a new report) ?
glimpse(lookup) # variable of interest is new_report formerly known as New.report.cf.previous.year

any(lookup$new_report == TRUE)# TRUE for ovarian 2023/24

if (any(lookup$new_report == TRUE)){
lookup |>
  filter(new_report %in% c(T, TRUE, "yes", "YES")) |>
  count(qpi_label_short, new_report, cyear, qpi)
}


# new data
new_data <- import_extracts(data_folder, extracts_filenames) 

#fix up common issues with names in new_data 
new_data <- new_data |>
	mutate(qpi = qpi|>
				 	                          str_remove_all("(\\r)|(\\n)") |> #new line characters
				 	                          str_remove_all(" $")) #spaces at end of string



# Handle NAs in numeric columns only - convert to zeroes
new_data <- new_data |>
  mutate(
    across(
    where(is.numeric), ~ replace(.x, is.na(.x), 0)
    )
  )
         
# If the network for Golden Jubilee is WoSCAN, then
# add Golden Jubilee (aka national facility) figures to Glasgow, then combine rows.
Jubilee_netwk <- HB_geo_groups |>
  filter(str_detect(e_case_hb_name, "NATIONAL FACILITY")) |>
  select(Network)      
if (length(Jubilee_netwk) >1) {
  stop("Problem: Found more than one row for NATIONAL FACILITY in regional lookup.") 
}
Jubilee_netwk <- Jubilee_netwk[[1]] # Just make sure it's just one element 
# Just make sure it's either Jubilee or WoSCAN
if (! str_detect(tolower(Jubilee_netwk), "jubilee|woscan")) {
  stop("Problem: Please check regional lookup - not clear how to process 
       national facility data. Expected string should contain either jubilee or 
       woscan, but instead found value of: ", Jubilee_netwk)
}
# Unnecessary
# if (str_detect(tolower(Jubilee_netwk), "jubilee")){
#   # Treat Golden Jubilee as a separate region on its own. Do nothing in code.
# }  else 
  if (str_detect(tolower(Jubilee_netwk), "woscan")){
  new_data <- new_data |>
    mutate(
      Location = if_else(str_detect(tolower(Location), "national facility"), 
                         "NHS GREATER GLASGOW & CLYDE",
                         Location) 
    ) |>
    summarise(
      across(where(is.numeric), sum),
      .by = !where(is.numeric)
    )
} 

# Temporary code for rest of the UK England etc and non-NHS 
new_data <-  new_data |>
  filter_out(str_detect(tolower(location), "england")) |>
  filter_out(str_detect(tolower(location), "non.*nhs")) 

# Join to allocate rows to regional networks
new_data <-  new_data |>
  mutate(network = replace_values(
    location, 
    from = HB_geo_groups$e_case_hb_name, 
    to = HB_geo_groups$Network))
    
# Swap in the health board abbreviations used in the SCRIS Tableau dashboard
new_data <- new_data |>
  mutate(location = replace_values(location, 
                                   from = HB_geo_groups$e_case_hb_name, 
                                   to = HB_geo_groups$qpi_dashboard_hb_abbreviation)) 


  

#### Step 2: Create regional totals for new data's numerator, NR and denominator ----

regional_rows <- new_data |>
  # Sum of performance is invalid, so firstly drop this column if it exists
  select(-any_of("PerPerformance")) |> 
  filter(!str_detect(tolower(location), "scotland")) |>
           group_by(qpi, network) |>
           summarise(
             across(
              where(is.numeric), 
              ~ sum(.x, na.rm = TRUE)
              ) |> 
           ungroup()) |>
           mutate(location = network) 

# Identify the HBs that should be summed to give Scotland total, 
# such as not to include non-NHS and NHS rest of the UK ie England, Wales, NI. 
# Not elegant, quick workaround. 
hbs_to_inc_in_scot_total <- HB_geo_groups |>
  filter(include_in_scot_nhs_total) |>
  pull(qpi_dashboard_hb_abbreviation)

## Calculate the Scotland rows 
scotland_rows_calcd <- new_data |>
  filter(location %in% hbs_to_inc_in_scot_total) |>
  group_by(qpi) |>
  summarise(
    across(
      where(is.numeric), 
      ~ sum(.x, na.rm = TRUE)
    ) |> 
      ungroup()) |>
  mutate(
   location = "Scotland", 
   network = "Scotland"
  )
  
# Bind the regional rows and Scotland rows onto new_data (already contains HB data)
new_data <- new_data |> 
  bind_rows(regional_rows, scotland_rows_calcd) 


# Populate constant fields
new_data <- new_data |>
  mutate(  cancer = tsg, 
           cyear = as.character(new_years[1]),
           surg_diag = "Not applicable",
           board_hosp = "NHS Board",
           hb_comments = NA)

#### Step 2b: Build summary table for publications ----
# scotland_rows <- new_data |> 
#   filter(str_detect(tolower(Location), "scotland"))
# 
# scotland_minus_comments <- scotland_rows |>
#   select(-any_of("HB_Comments")) 
# write.xlsx(scotland_minus_comments, here("code", "for_summary_table", "Scotland_rows_no_comments.xlsx"))


#### Step 3 : Join lookup to new data ----
# Clean up trailing carriage returns before join to lookup!

new_data <- new_data |> 
  left_join(lookup, by = c("cyear" = "cyear",
                           "cancer" = "cancer",
                           "qpi" = "qpi"))

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
  mutate(per_performance = (numerator/denominator)*100) |> 
	mutate(per_performance = round_half_up(per_performance, digits = 2)) |> 
  mutate(per_performance = if_else(is.na(per_performance), 0, per_performance))

if (any(new_data$per_performance > 100)){ 
	bad_performance <- new_data |>
		select(qpi, location, network, 
					 numerator, nr_for_numerator, denominator, per_performance) |>
		filter(per_performance > 100)
	print(bad_performance)
	stop("BAD DATA: Detected at least one performance value of over 100%, 
	suggesting numerator was greater than denominator. Check rows listed above!")
}

# QPI_order (does nothing. Leave for now?)
new_data <- new_data |> 
  mutate(qpi_order = as.numeric(qpi_order))

# Does nothing as well I think
new_data <- new_data |> 
  mutate(qpi_subtitle = as.character(qpi_subtitle))

# year_lk (same as cyear, but in tableau we use them each differently, 
# year_lk is a string in tableau cf cyear is a date field, both needed.)
new_data <- new_data |> 
  mutate(year_lk = Cyear)

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

# Populate the two numeric columns we no longer use with zeroes,  
# Not Recorded for denominator, and Not recorded for exclusion 
# This is just for Tableau ie fake data. Columns in eCASE will have some non-zeroes.
new_data <- new_data |>
		mutate(nr_denominator =0,
					 nr_exclusion =0 )

#### Step 5 : Comparisons for Quality Assurance ----


# check that 0 a reasonable value for new vars in new_data

head(hb_hosp_old |> count(nr_denominator)) # 0 is 56k
head(hb_hosp_old |> count(nr_exclusion)) # 0 is 62k

## Step 5.1 remove unwanted variables, add new one and adjust name of another ----
# from new_data:delete the additional variable & rename per_performance (check in main code where "_" came in) 
# add 2 new variables fake data as value 0 

new_data <-new_data |> select(-any_of("New.report.cf.previous.year")) 
new_data <-new_data |> select(-any_of("new_report")) 


# Check NR4D, NR4E, now that regional and Scotland sub-totals are included.  
new_data |> count(nr_denominator, nr_exclusion ) |> slice_head()


#### Step 6 : Change names for tableau ----
new_data <- new_data |> 
  rename(
    QPI = qpi, 
  	Board_Hospital = board_hosp,
    Cyear = cyear,
    SurgDiag = surg_diag,
    NRforDenominator = nr_denominator, 
    NRforExclusion = nr_exclusions, 
    NRforNumerator = nr_for_numerator,
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
    HB_Comments = hb_comments,
    Previous_Target = previous_target,
    QPI_Subtitle = qpi_subtitle, 
    Location = location,
    Network = network
  ) 

#### Step 7 : Bind together to make full hb_hosp_qpi ----

hb_hosp_old <- hb_hosp_old |>
  mutate(QPI_Subtitle = as.character(QPI_Subtitle))

hb_hosp_new <- bind_rows(hb_hosp_old, new_data)

#### Step 8 : Write to excel ----

write.xlsx(hb_hosp_new, hb_hosp_out_fpath, sheetName = "HB_Hosp_QPI")
