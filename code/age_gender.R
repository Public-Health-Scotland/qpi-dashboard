# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# age_gender.R
# Angus Morton
# 2023-09-29
# 
# Update the background data age_gender excel file
# 
# R version 4.1.2 (2021-11-01)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Step 0 : Housekeeping ----

source("code/functions.R")
source("code/housekeeping.R")
source("code/packages.R")

#### Step 1 : Import data ----

# Background Age Gender file

age_gender <- readWorkbook(age_gender_in_fpath) |> 
  mutate(Location_C = str_replace(Location_C, "amp;", "")) |> 
  filter(!(Cancer_C == tsg & Year_C %in% new_years))

# Background tabs from submissions

sub_path <- paste0(data_folder, "data_submissions/")

new_data <- map(networks,
                import_age_gender,
                sub_path = sub_path,
                year_vals = new_years_vals,
                years = new_years) |>
  list_rbind()

#### Step 2 : Reformat data ----

new_data <- new_data |> 
  filter(Age.Range != "Total",
         Location != network) |> 
  mutate(value = replace_na(value, 0))

# Make totals
network_totals <- new_data |> 
  group_by(Age.Range, Sex, cyear, network) |>
  summarise(value = sum(value)) |> 
  ungroup() |> 
  mutate(Location = network)

scotland_totals <- new_data |> 
  group_by(Age.Range, Sex, cyear) |>
  summarise(value = sum(value)) |> 
  ungroup() |> 
  mutate(Location = "Scotland")

new_data <- bind_rows(new_data, network_totals, scotland_totals) |> 
  arrange(cyear, network, Location == network, Location, Age.Range,
          desc(Sex))

new_data <- new_data |> 
  mutate(Location = str_replace_all(Location, "\\." , " "),
         Gender = case_when(
           Sex == "F" ~ "Female",
           Sex == "M" ~ "Male"),
         Ord_Loc_C = as.integer(fct_inorder(Location))) |>
  mutate(Cancer_C = tsg) |> 
  select(Cancer_C,
         Year_C = cyear,
         Age_C = Age.Range,
         Location_C = Location,
         Ord_Loc_C,
         Gender,
         Total = value)

#### Step 3 : Combine existing and new data ----

age_gender_new <- bind_rows(age_gender, new_data)

#### Step 4 : Write to excel ----

write.xlsx(age_gender_new, age_gender_out_fpath,
           sheetName = "Background_Data_Age_Gender")
