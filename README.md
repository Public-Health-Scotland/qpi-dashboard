# *qpi-dashboard*
*Repository to update the Scottish Cancer QPIs Dashboard (Tableau)*

### Directories
  * /code - R scripts required for project
    + `housekeeping.R` - contains all values which need to be changed each time
    + `functions.R` - functions sourced and used in the other script(s)
    + `packages.R` - list of packages sourced and used in the other script(s) 
    + `create_lookup.R` - compile the list of QPI names and targets
    + `create_templates.R` 
    + `check_submissions.R` 
    + `hb_hosp_qpi.R` - updates the Excel file containing the data, for feeding into Tableau
    + `age_gender.R` - process the demographic data
    + `case_asc.R` - process the case ascertainment data
    + `change_qpi_names.R`
    + `change_hospital_names.R`
    + `late_lookup_edits.R`
  * /renv - Required for renv. Don't need to interact directly 
  * /docs - documentation
  * /for_summary_table - script, input and templates to generate table for summary publication
    + `generate_summary_in_excel.R` - pivots the rows to show perf by year
    + `Scotland_rows_no_comments.xlsx` - input, containing Scotland-level performance data
    + `qpi_summary_table_plain.xlsx` - pivoted qpi table with no highlighting
    + `qpi_summary_table.xlsx` - pivoted table with 'target met' column and colour highlighting
  * /qpi_background_data_updates - for automatically collating demographic data for dashboard 'Background' tab

### Files
  * `renv.lock` - List of packages for use with renv
  * `.Rprofile` - R profile settings
  * `.gitignore` - tells git what files and folders *not* to track or upload to GitHub
  * `README.md` - this page
  * `QPI-dashboard.Proj` - R project
  
## How to use
Please see the SOP in the /docs folder. 
