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
lookup <- readWorkbook(lookup_fpath)

# new data
nca <- read_qpi_data(nca_fpath, "NCA", new_years)
sca <- read_qpi_data(sca_fpath, "SCAN", new_years)
wos <- read_qpi_data(wos_fpath, "WoSCAN", new_years)

new_data <- bind_rows(nca, sca, wos) %>% 
  rename(
    SurgDiag = "Diagnosis/Surgery",
    Board_Hospital = "Board/Hospital",
    NRforNumerator = "NR.Numerator",
    NRforExclusion = "NR.Exclusion",
    NRforDenominator = "NR.Denominator",
    HB_Comments = "Comments"
  )

#### Step x : Create Scotland totals ----

scotland_rows <- new_data %>% 
  filter(Location %in% c("NCA", "SCAN", "WoSCAN")) %>% 
  group_by(QPI, Cyear) %>% 
  summarise_if(is.numeric,sum) %>%
  ungroup() %>% 
  mutate(Board_Hospital = "NHS Board",
         Cancer = tsg,
         Location = "Scotland",
         Network = "Scotland",
         HB_Comments = "")

new_data <- new_data %>% 
  bind_rows(scotland_rows) %>%
  group_by(Cancer, QPI, Cyear) %>% 
  mutate(SurgDiag = case_when(
    Location == "Scotland" ~ ,
    TRUE ~ SurgDiag
  ))
  

### Step x : create derived variables


mutate(board_hospital_v2 = case_when(
  board_hospital == "Board" ~ "NHS Board",
  board_hospital == "Network" ~ "NHS Board",
  board_hospital == "Hospital" ~ "Hospital",
  TRUE ~ "unknown"))

#### Step x : Write to excel ----
write.xlsx(hb_hosp_new, hb_hosp_out_fpath)


