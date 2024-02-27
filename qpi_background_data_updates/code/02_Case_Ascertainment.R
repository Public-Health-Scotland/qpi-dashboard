##########################################################
# Original author(s): Paulius Leniauskas
# First draft created: 20-04-2022
# Description of content: Extract Case Ascertainment Data
##########################################################

### 1 - Preliminaries ----

####### Things to edit before running the code #####------
cancer <- "Upper GI"
total_years <- 1
which_years <- c("2022")
##########################################################

#   Loading required libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(readxl, writexl, glue)

### 2 - Extract Case Ascertainment Data ----

# Import data
path_bdc <- glue("\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/Tableau/Tableau Dashboard 2017/Data/Background_Data_Case.xlsx")
bdc <- read_xlsx(path = path_bdc, guess_max = 1048576)

# Create template
template <- bdc[1:(total_years*18),]                       # 18 Locations
template$Cancer_D <- cancer                                # type of cancer
template$Year_D <- rep(rev(which_years), each = 18)        # required years
template[,4:6] <- NA                                       # columns 4 to 6 left empty
write_xlsx(template, "\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/Tableau/Age Group & Case Asc/data/output/case_asc_template.xlsx") # export the new template

################### Run below after filling in data ###############################################
# Import updated template
updated_template <- read_xlsx("\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/Tableau/Age Group & Case Asc/data/output/case_asc_template.xlsx")


# Determine where the new data will be attached
where <- match(cancer, bdc$Cancer_D)-1

# Insert new data
bdc <- rbind(bdc[1:where,],updated_template,bdc[-(1:where),])

# Save updated_templated dataset into Background_Data_Case file
write_xlsx(list(Background_Data_Case = bdc), path = path_bdc)
# write_xlsx(list(Background_Data_Case = bdc), "data/output/test_bdc.xlsx")


