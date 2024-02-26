# *qpi-dashboard*
*Repository to update the Scottish Cancer QPIs Dashboard*

### Directories
  * `code` - R scripts required for project
    + `housekeeping.R` - contains all values which need to be changed each time
    + `functions.R` - functions sourced and used in the other script(s)
    + `packages.R` - list of packages sourced and used in the other script(s) 
    + `create_lookup.R` 
    + `create_templates.R` 
    + `check_submissions.R` 
    + `hb_hosp_qpi.R` 
    + `age_gender.R` 
    + `case_asc.R`
    + `change_qpi_names.R`
    + `change_hospital_names.R`
    + `late_lookup_edits.R`
  * `renv` - Required for renv. Don't need to interact directly 
  * /docs - documentation

### Files
  * `renv.lock` - List of packages for use with renv
  * `.Rprofile` - R profile settings
  * `.gitignore` - tells git what files and folders *not* to track or upload to GitHub
  * `README.md` - this page
  * `QPI-dashboard.Proj` - R project
  
## How to use
Please see the SOP in the /docs folder. 
