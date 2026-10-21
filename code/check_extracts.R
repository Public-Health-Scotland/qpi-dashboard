# check_extracts.R 
# Tests data extracts for new SCRIS QPIs dashboard updates. 
# Clare Taylor, October 2026

# Are all lookup qpis in new_data for a particular year (& vice versa)? -------
# Code in line 144 hb_hosp_qpi.R now redundant ("Identify rows where the QPI name in new_data was not matched with any in lookup"

source("code/housekeeping.R")

# get test : fake xlsx with pos & neg controls : lookup_cft_test.xlsx
# in lookup_test_cft edited "QPI 9: First-line Chemotherapy" to read "QPI 99: test qpi not in boxi"

test_data_folder <- here("/PHI_conf", "CancerGroup2", "Cancer_QPIs", "Data", 
												 "new_process", "testing", "TEST_updates", 
													"TEST_tsg_2026")

test_lookup_fpath <- here(test_data_folder, 
													"lookup", "lookup_cft_test.xlsx") 

# get test lookup
test_false_lookup <- import_lookup(test_lookup_fpath) |> 
	select(-SurgDiag)  # edited original from hb_hosp_qpi.R has 35 to 44

# get new_data by equivalent of running hb_hosp_qpi to line 83 170x10

# Check there is always just one year's worth of data to be read in. 
if (length(new_years) > 1) {
	stop("More than one Cyear detected in housekeeping file. 
          This script is designed to process one year's data at a time.")
}

# new real lookup
lookup <- import_lookup(lookup_fpath) |> 
	select(-SurgDiag) 

# new data
new_data <- import_extracts(data_folder, extracts_filenames) 

# exploration 
names(new_data)  #"QPI""Cyear" "Numerator""NRforNumerator" "Denominator" "Location" "Cancer"  "SurgDiag" "Board_Hospital" "HB_Comments"        
sort(unique(new_data$QPI)) 

# test 1 are all QPIs in lookup for a specific year in the new_data?

test_abbrev_lookup <-lookup %>% filter(cyear %in% new_years) 
sort(unique(test_abbrev_lookup$qpi))

names(lookup)  # cyear, qpi are lowercase
sort(unique(lookup$qpi))

compare(sort(unique(test_abbrev_lookup$qpi)),
				sort(unique(new_data$QPI))) # ✔ No differences

#now try with the lookup with fake data, need abbreviate it too 

test_false_lookup <-test_false_lookup %>% filter(cyear %in% new_years) #11 x 14
sort(unique(test_false_lookup$qpi)) # note qpi 9 is absent, qpi 99 is added

compare(sort(unique(test_false_lookup$qpi)),
				sort(unique(new_data$QPI)))  # result clearly shows difference in 2 qpis.

# check, need tidy 

test_a <- sort(unique(test_false_lookup$qpi))
test_b <- sort(unique(new_data$QPI))
test_a %in% test_b  # 1 false
test_a[!test_a %in% test_b ]  # "QPI 99: test qpi not in boxi"
test_b[!test_b %in% test_a ]  # "QPI 9: First-line Chemotherapy"

# Code below moved from hb_hosp_qpi.R sections 5.1 and 5.2 
test_a[!test_a %in% test_b]  # in a(hosp) but not new_data: nrfordenominator" "nrforexclusion"   "perperformance"  
# hence to do :add 2 & find out why perperformance not there (it was prior section 4)

test_b[!test_b %in% test_a] # in new_data but not hbhosp "new.report.cf.previous.year" "per_performance"
# hence remove 1st & rename 2nd

# check
# Below does not make sense
test_new_data_names2 <- new_data |> names()
compare(test_new_data_names,test_new_data_names2)

test_c <-str_to_lower(test_new_data_names2)  # 28

# check
test_c %in% test_b  # 3 false
test_c[c(23, 27:28)]  # as expected

sum(!test_a[!test_c %in% test_a])  # 0 

# investigate 
compare(test_hbhosp_names, names(new_data), max_diffs = Inf)

# investigate 
compare(test_hbhosp_names,names(new_data), max_diffs = Inf) # order correct, now only need case change


# end code -----





