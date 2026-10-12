# check_extracts.R

# are all lookup qpis in new_data for a particular year (& vice versa)? -------
# code in line 144 hb_hosp_qpi.R now redundant ("Identify rows where the QPI name in new_data was not matched with any in lookup"

# get test : fake xlsx with pos & neg controls : lookup_cft_test.xlsx
# in lookup_test_cft edited "QPI 9: First-line Chemotherapy" to read "QPI 99: test qpi not in boxi"

test_lookup_fpath <- here(data_folder,
													"lookup", "lookup_cft_test.xlsx") # original from housekeeping.R line 122 

# get test lookup
test_false_lookup <- import_lookup(test_lookup_fpath) |> 
	select(-SurgDiag)  # edited original from hb_hosp_qpi.R has 35 to 44

# get new_data by run hb_hosp_qpi to line 83 170x10

# exploration 
names(new_data)  #"QPI""Cyear" "Numerator""NRforNumerator" "Denominator" "Location" "Cancer"  "SurgDiag" "Board_Hospital" "HB_Comments"        
sort(unique(new_data$QPI)) 

# test 1 are all QPIs in lookup for a specific year in the new_data?

test_abbrev_lookup <-lookup %>% filter(cyear %in% new_years) #11 x 14
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

# end code -----





