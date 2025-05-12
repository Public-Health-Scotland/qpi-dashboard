# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hb_hosp_qpi.R
# Angus Morton
# 2023-05-22
# 
# Update the hb_hosp_qpi.xlsx file with the new data
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# old hb_hosp_qpi
hb_hosp_old <- readWorkbook(hb_hosp_in_fpath)

# new lookup
lookup <- import_lookup(lookup_fpath) |> 
  select(-SurgDiag)

# new data
sub_path <- paste0(data_folder, "data_submissions/")

new_data <- map(networks,
                import_submission,
                sub_path = sub_path,
                year_vals = new_years_vals,
                years = new_years) |>
  list_rbind() |>
  mutate(
    Year = as.character(Year),
    Network = as.character(Network),
    Location = as.character(Location),
    QPI = as.character(QPI),
    surg_diag = as.character(surg_diag),
    board_hosp = as.character(board_hosp),
    Cancer = as.character(Cancer),
    Numerator = as.numeric(Numerator),
    Denominator = as.numeric(Denominator),
    nr_numerator = as.numeric(nr_numerator),
    nr_exclusions = as.numeric(nr_exclusions),
    nr_denominator = as.numeric(nr_denominator),
    Comments = as.character(Comments)
  )


#### Step x : Create Scotland totals for new data ----

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
write.xlsx(scotland_minus_comments, here("for_summary_table", "Scotland_rows_no_comments.xlsx"))

new_data <- new_data |> 
  bind_rows(scotland_rows)

#### Step x : Join lookup to new data ----

new_data <- new_data |> 
  left_join(lookup, by = c("cyear" = "cyear",
                           "Cancer" = "cancer",
                           "QPI" = "qpi"))

# Identify rows where the QPI name in new_data was not matched with any in lookup. 
# Sometimes happens because of a typo in the QPI name. 
# Checking Numerator1 column as a proxy for the whole row in lookup
rows_with_missing_values <- new_data |> 
  filter(str_equal(numerator1, "") )

if (nrow(rows_with_missing_values) > 0 ) {
  message("ISSUE DETECTED: POSSIBLE UN-MATCHED ROWS.\n")
  message("The Numerator1 column is empty in some rows, indicating possible mis-match between data submissions and lookup, see missing_data.csv.\n")
 write.csv(rows_with_missing_values, file = here(data_folder, "missing_data.csv"))
}

#### Step x : create derived variables ----
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

#### Step x : Change names for tableau ----

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

#### Step x : Bind together to make full hb_hosp_qpi ----

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

#### Step x : Write to excel ----

write.xlsx(hb_hosp_new, hb_hosp_out_fpath, sheetName = "HB_Hosp_QPI")


