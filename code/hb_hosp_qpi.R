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
lookup <- readWorkbook(lookup_fpath) |> 
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

#### Step x : Modify old data for tsg ----

# Sometimes changes need to be made in the old data.
# Name/definition changes etc.
# Make these in the lookup then it'll be joined back on

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
         Comments = "")

new_data <- new_data |> 
  bind_rows(scotland_rows)

#### Step x : Join lookup to new data ----

new_data <- new_data |> 
  left_join(lookup, by = c("cyear" = "cyear",
                           "Cancer" = "cancer",
                           "QPI" = "qpi"))

#### Step x : create derived variables ----


mutate(board_hospital_v2 = case_when(
  board_hospital == "Board" ~ "NHS Board",
  board_hospital == "Network" ~ "NHS Board",
  board_hospital == "Hospital" ~ "Hospital",
  TRUE ~ "unknown"))

#### Step x : bind together to make full hb_hosp_qpi ----

#### Step x : Write to excel ----
write.xlsx(hb_hosp_new, hb_hosp_out_fpath)


