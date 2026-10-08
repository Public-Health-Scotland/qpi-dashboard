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
max(hb_hosp_old$Cyear)       # check 1 condensed hbhosp data in code writing BUT latest version in final code running
unique(hb_hosp_old$Cancer)   # check 2 condensed hbhosp data in code writing BUT latest version in final code running

# import lookup
lookup <- import_lookup(lookup_fpath) |> 
  select(-SurgDiag)

# Check that the lookup rows are for same tumour as set in housekeeping global variable 
if (any(!str_equal(lookup$cancer, tsg))){
 stop("Problem in lookup.xlsx: The tsg string value specified in 
      housekeeping.R (", tsg, ") is NOT matched in at least one of the values 
      in the Cancer column of lookup.xlsx: ", unique(lookup$cancer)) 
}


# Do the QPIs need to be split (due to a new report) ?
glimpse(lookup) # variable of interest is New.report.cf.previous.year

any(lookup$New.report.cf.previous.year == TRUE)# TRUE for ovarian 2023/24

lookup %>%
	filter(New.report.cf.previous.year %in% c(T, TRUE, "yes", "YES")) %>%
	count(qpi_label_short, New.report.cf.previous.year,cyear, qpi)

# new data
new_data <- import_extracts(data_folder, extracts_filenames) 
glimpse(new_data)
new_data %>% select_if(is.numeric) %>% summary()

# Shorten the QPI name column header to just 'QPI'. 
# The import functions already identified the first column 
# by matching search_string "QPI.*dashboard name", so we assume the column index
# is equal to 1, and do this step first, before any column re-ordering.  
names(new_data)[1] <- "QPI"

# Handle NAs in numeric columns only - convert to zeroes
new_data <- new_data |>
  mutate(
    across(
    where(is.numeric), ~ replace(.x, is.na(.x), 0)
    )
  )
         
# Get the tsg global variable
new_data <- new_data |>
  mutate(Cancer = tsg, 
         SurgDiag = "Not applicable")

# Add SCRIS-specific columns ie Board_Hospital and Comments #cft changed to HB_hosp version
new_data <- new_data |>
  mutate(Board_Hospital = "NHS Board") |> 
  mutate(HB_Comments = NA)


# Populate the Network column in Scotland rows
new_data <- new_data |>
  mutate(Network = if_else(
    str_detect(tolower(Location), "scotland"), 
    "Scotland", 
    NA_character_)) 

# Add Golden Jubilee (aka national facility) figures to Glasgow, then remove duplicate 'GG&C' rows 
# by adding figures in numerical variables to give 1 row. So number of obs will decrease. 
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


# Join to allocate rows to regional networks
table(HB_geo_groups$e_case_hb_name)
new_data <-  new_data |>
  mutate(Network = replace_values(
    Location, 
    from = HB_geo_groups$e_case_hb_name, 
    to = HB_geo_groups$Network))

table(new_data$Location,new_data$Network)

# Swap in the health board abbreviations used in the SCRIS Tableau dashboard
new_data <- new_data |>
  mutate(Location = replace_values(Location, 
                                   from = HB_geo_groups$e_case_hb_name, 
                                   to = HB_geo_groups$qpi_dashboard_hb_abbreviation)) 

table(new_data$Location,new_data$Network)
#### Step 2a: Create regional totals for new data's numerator, NR and denominator ----
# create subtotals & store into separate tibble
regional_rows <- new_data |>
  # Sum of performance is invalid, so firstly drop PerPerformance if it exists
  select(-any_of("PerPerformance")) |> 
  filter(!str_detect(tolower(Location), "scotland")) |>
           group_by(QPI, Network, Cyear) |>
           summarise(
             across(
              where(is.numeric), 
              ~ sum(.x, na.rm = TRUE)
              ) |> 
           ungroup()) |>
           mutate(Location = Network,
                  Board_Hospital = "NHS Board",
                  Cancer = tsg,
                  HB_Comments = NA      #cft change
                  ) 

#### cft 3/09 danger & workaround 1
# I dont know why code to make regional rows dropped "SurgDiag made in line 65, so am adding back in -----
  
regional_rows <- regional_rows %>%  mutate(SurgDiag = "Not applicable")

#### end temp workaround 1
new_data <- new_data |> 
  bind_rows(regional_rows)

#  cft there is an issue here due to regional_rows being a "grouped_df" "I know how sort -----

#### Step 2b: Build summary table for publications ----
scotland_rows <- new_data |> 
  filter(str_detect(tolower(Location), "scotland"))

scotland_minus_comments <- scotland_rows |>
  select(-any_of("HB_Comments"))   
write.xlsx(scotland_minus_comments, here("code", "for_summary_table", "Scotland_rows_no_comments.xlsx"))


#### Step 3 : Join lookup to new data ----

compare(names(new_data), names(lookup), max_diffs = Inf) # a check for upper/lowercase differences
new_data <- new_data |> 
  left_join(lookup, by = c("Cyear" = "cyear",
                           "Cancer" = "cancer",
                           "QPI" = "qpi"))

table(new_data$exclusions1)
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
    str_length(Cyear) == 4 ~ str_sub(Cyear, 1, 4),
    str_length(Cyear) == 7 ~ str_sub(Cyear, 3, 7)
  ))

# per_performance  # cft this should be PerPerformance
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

# Recode board_hospital
new_data <- new_data |> 
  mutate(Board_Hospital = case_when(
  	Board_Hospital %in% c("Board","Network") ~ "NHS Board",
    TRUE ~ Board_Hospital
  ))

#### Step 5 : Change names for tableau ----

test_hbhosp_names <- readWorkbook(hb_hosp_in_fpath) %>% names()
test_new_data_names <- new_data %>% names()

compare(length(test_hbhosp_names),length(test_new_data_names)) # hbhosp has 28, newdata has 27 
compare(test_hbhosp_names,test_new_data_names, max_diffs = Inf)  # obv case issues etc
# Q1 what are those variables in one dataset & not the other? 

test_a <-str_to_lower(test_hbhosp_names)    # 28
test_b <-str_to_lower(test_new_data_names)  # 27

test_a %in% test_b # 3 false ie in hosp-qpi but not new_data
sum(!test_a %in% test_b) # 3

test_b %in% test_a  # 2 false
sum(!test_b %in% test_a )  #2

test_a[!test_a %in% test_b]  # in a(hosp) but not new_data: nrfordenominator" "nrforexclusion"   "perperformance"  
# hence to do :add 2 & find out why perperformance not there (it was prior section 4)

test_b[!test_b %in% test_a] # in new_data but not hbhosp "new.report.cf.previous.year" "per_performance"
# hence remove 1st & rename 2nd

# check that 0 a reasonable value for new vars in new_data

head(hb_hosp_old %>% count(NRforDenominator)) # 0 is 56k
head(hb_hosp_old %>% count(NRforExclusion)) # 0 is 62k

# 5.1 removal unwanted variables, addition new variables and adjust name of 1 varin  new_data ----
# from new_data:delete the additional variable & rename per_performance (check in main code where "_" came in) 
# add 2 new variables fake data as value 0 

new_data <-new_data %>% select(-New.report.cf.previous.year) %>% 
	rename(PerPerformance = per_performance) %>% 
	mutate(NRforDenominator =0,
				 NRforExclusion =0 ) 

# include NR4D, NR4E here pro tem but should be at import rather than above-----

new_data %>% count(NRforDenominator,NRforExclusion ) %>% slice_head()

# check

test_new_data_names2 <- new_data %>% names()
compare(test_new_data_names,test_new_data_names2)

test_c <-str_to_lower(test_new_data_names2)  # 28

# check
test_c %in% test_b  # 3 false
test_c[c(23, 27:28)]  # as expected

sum(!test_a[!test_c %in% test_a])  # 0

# 5.2 piecemeal reordering of new_data, make iterative -----

new_data <- new_data %>% select(test_hbhosp_names[1:10], everything())

new_data <- new_data %>% select(
	test_hbhosp_names[1:11],
	PerPerformance, cyear_abr, year_lk, qpi_order:target_label,
	everything()
)
# investigate 
compare(test_hbhosp_names, names(new_data), max_diffs = Inf)

new_data <- new_data %>% select(
	Board_Hospital:target_label,
	direction, qpi_label_short, Network,
	direction_text, rag_status, HB_Comments,
	previous_target, qpi_subtitle
)

# investigate 
compare(test_hbhosp_names,names(new_data), max_diffs = Inf) # order correct, now only need case change

# 5.3 final case change etc so new_data like hb_hosp -----
new_data <- new_data |> 
	rename( 
		Cyear_Abr = cyear_abr  ,
		Year_Lk  = year_lk ,
		QPI_Order = qpi_order      ,
		Numerator1  =numerator1   ,
		Denominator1 = denominator1   ,
		Exclusions1 = exclusions1   ,
		Current_Target = current_target  ,
		Target_Label = target_label   ,
		Direction = direction    ,
		QPI_Label_Short = qpi_label_short ,
		Direction_Text = direction_text ,
		RAG_Status = rag_status     ,
		Previous_Target = previous_target ,
		QPI_Subtitle = qpi_subtitle  )

# final check 

compare(test_hbhosp_names,names(new_data), max_diffs = Inf)		# ✔ No differences	

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


