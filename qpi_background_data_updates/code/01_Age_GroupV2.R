##########################################################
# Original author(s): Paulius Leniauskas
# First version was started on: 15-04-2022
# Description of content: Extract Age Group data 
##########################################################

### 1 - Preliminaries ----

####### Things to edit before running the code #####------
cancer <- "Brain and CNS"
total_years <- 3
which_years <- c("2020", "2021", "2022")

NCA_submission_location <- "\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/new_process/brain_mar24/data_submissions/NCA.xlsx"
# Below is cells in which data is located, each year's data separated by comma
NCA <- c("B7:D14", "B18:D25", "B29:D36")  

SCA_submission_location <- "\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/new_process/brain_mar24/data_submissions/SCAN.xlsx"
SCA <- c("B7:D13", "B17:D23", "B27:D33")

WOS_submission_location <- "\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/new_process/brain_mar24/data_submissions/WoSCAN.xlsx"
WOS <- c("B7:D11", "B15:D19", "B23:D27")
##########################################################

# Loading required libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, readxl, writexl, glue, stringr, here)

# Correct location names in correct order
loc_order <- c("Grampian", "Highland",	"Orkney",	"Shetland",	"Tayside", "Western Isles",
               "NCA", "Borders",	"Dumfries & Galloway", "Fife",	"Lothian",
               "SCAN",	"Ayrshire & Arran",	"Forth Valley",	"Greater Glasgow & Clyde",
               "Lanarkshire",	"WoSCAN")

### 2 - Extract Age Group Data ----

### Import latest Background_Data_Age_Gender.xlsx ###----
age_gender <- read_xlsx(path = "\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/Tableau/Tableau Dashboard 2017/Data/Background_Data_Age_Gender.xlsx", guess_max = 1048576)

# Variables to store datasets for each year
Age <- list()
Year <- list()

for (i in 1:total_years) {
  # Import networks' submissions separately
  NCA_subm <- as.data.frame(read_xlsx(NCA_submission_location, 
                                      range = paste("BackgroundInfo!", NCA[i], sep = "")))
  
  SCA_subm <- as.data.frame(read_xlsx(SCA_submission_location,
                                      range = paste("BackgroundInfo!", SCA[i], sep = "")))
  
  WOS_subm <- as.data.frame(read_xlsx(WOS_submission_location, 
                                      range = paste("BackgroundInfo!", WOS[i], sep = "")))
  
  # bind all networks together into one year submission
  age <- bind_cols(NCA_subm, SCA_subm[,-(1:2)], WOS_subm[,-(1:2)])
  # Rename first two columns appropriately
  colnames(age)[1:2] <- c("Age", "Gender")
  
  # If second row first column is empty, fix it
  if (is.na(age[2,1]) == TRUE){
    age$Age[is.na(age$Age) == TRUE] <- age$Age[is.na(age$Age) == FALSE]
  }
  
  # Save it to list object
  Age[[i]] <- age
  
  # Remove unnecessary "Totals" row(s)
  Age[[i]] <- Age[[i]][Age[[i]]$Age != "Total", ]
  
  # Change "F" to "Female" and "M" to "Male"
  Age[[i]][Age[[i]] == "F"] <- "Female"
  Age[[i]][Age[[i]] == "M"] <- "Male"
  
  # Make sure the order and names of the columns are correct
  Age[[i]][,3:8] <- Age[[i]][,3:8] %>% select(sort(current_vars()))
  Age[[i]][,10:13] <- Age[[i]][,10:13] %>% select(sort(current_vars()))
  Age[[i]][,15:18] <- Age[[i]][,15:18] %>% select(sort(current_vars()))
  colnames(Age[[i]])[3:19] <- loc_order
  
  # Replace word "Under" with "0-"
  Age[[i]]$Age[grep("nder", Age[[i]]$Age)] <- paste0("0-",as.numeric(str_sub(Age[[i]]$Age[1], start= -2))-1)
  
  # Add Scotland's totals = NCA + SCAN + WoSCAN for each age group
  Age[[i]]$Scotland <- Age[[i]][,9] + Age[[i]][,14] + Age[[i]][,19]
  
  # Create table for each year in Background_Data_Age_Gender.xlsx style
  Year[[i]] <- setNames(data.frame(matrix(ncol = 7, nrow = nrow(Age[[i]])*(ncol(Age[[i]])-2))), colnames(age_gender))
  Year[[i]]$Cancer_C <- cancer
  Year[[i]]$Year_C <- which_years[i]
  Year[[i]]$Age_C <-rep(Age[[i]]$Age, nrow(Year[[i]])/nrow(Age[[i]]))
  Year[[i]]$Location_C <- rep(colnames(Age[[i]])[-c(1,2)], rep(nrow(Age[[i]]),length(colnames(Age[[i]])[-c(1,2)])))
  Year[[i]]$Ord_Loc_C <- rep(1:18, rep(nrow(Age[[i]]),18))
  Year[[i]]$Gender <- rep(Age[[i]]$Gender,nrow(Year[[i]])/nrow(Age[[i]]))
  Year[[i]]$Total <- stack(Age[[i]][,-c(1,2)])[,"values",drop=FALSE][,1]
}

# Combine all years into one
tumour_age <- bind_rows(Year)

# Insert new data to age_gender dataset
where <- nrow(age_gender) - match(cancer, rev(age_gender$Cancer_C)) + 1
age_gender <- rbind(age_gender[1:where,],tumour_age,age_gender[-(1:where),])

# Export updated age_gender (=Background_Data_Age_Gender.xslx)
write_xlsx(list(Background_Data_Age_Gender = age_gender), path = "\\\\Isdsf00d03/quality_indicators/Benchmarking/Cancer QPIs/Data/Tableau/Tableau Dashboard 2017/Data/Background_Data_Age_Gender.xlsx")
# write_xlsx(list(Background_Data_Age_Gender = age_gender), path = "data/output/Background_Data_Age_Gender.xlsx")



