# QPI summary table tidying steps

## The script this document shares a folder with will do the following:

-   Reads in the version of HB_Hosp stored in the folder *CancerGroup2/Cancer_QPIs/Data/HB_Hosp_new/HB_Hosp_current*
-   Filters the rows in HB_Hosp to only include Scotland level data for the tumour group and years you select (please be aware that the code on row 31 of this script will ask for input to determine which tumour group and which years to filter for, so trying to run code after that and before providing this input will result in the later code not running).
-   Pivots the data into the tabular format required for the summary publications.
-   Saves this table into a spreadsheet named like *[tumourgroup]\_[years]\_QPI_summary_table.xlsx*. This will be the spreadsheet which is provided alongside the summary report to aid accessibility.
-   Saves a second more concise spreadsheet named *[tumourgroup]\_[years]\_QPI_summary_table_concise.xlsx*. This concise version formats the table in several ways which allow it to fit inside the report document - the "Results" columns are hidden, the names of the "Performance" columns are shortened to just be the year the column is relevant to, and the column widths are adjusted.

## For the publication summary report

Although the script automates most of the formatting required for this table to appear in the summary report, a few small changes need to be made after copying it into the document, since the text options in the document are locked and so some of the table's text formatting does not copy across. Please follow the following steps to account for this:

-   Copy and paste the table from the second spreadsheet (the one who's name ends with "\_concise") into the Word template draft summary report.
-   In the word document, select the title row from the table you've just pasted. Go into the dropdown list of pre-set styles for the document and select "Table Head"
-   Select all fields containing numbers (not including the "Target" column). Go into the dropdown list of pre-set styles for the document and select "Table body right aligned (for numbers only)"
-   Lastly, take a look at the table and check everything looks right.
