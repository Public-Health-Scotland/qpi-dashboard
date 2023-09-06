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

old_tsg_data <- hb_hosp_old |> 
  filter(Cancer == tsg)



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
  mutate(per_performance = (numerator/denominator)*100)

# QPI_order (does nothing. Leave for now?)

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
    direction == "H" & per_performance == 0  & denominator <= 0 ~ "3",
    direction == "H" & per_performance == 0 & denominator > 0 ~ "2",
    direction == "L" & per_performance > 0 & per_performance <= current_target ~ "1",
    direction == "L" & per_performance > current_target ~ "2",
    direction == "L" & per_performance == 0 & denominator <= 0 ~ "3",
    direction == "L" & per_performance == 0 & denominator > 0 ~ "1",
    TRUE ~ "unknown"))


#### Step x : bind together to make full hb_hosp_qpi ----

hb_hosp_no_tsg <- hb_hosp_old |> 
  filter(Cancer != tsg)

hb_hosp_new <- bind_rows(hb_hosp_no_tsg, old_tsg_data, new_data) |> 
  arrange()

#### Step x : Write to excel ----
write.xlsx(hb_hosp_new, hb_hosp_out_fpath)


