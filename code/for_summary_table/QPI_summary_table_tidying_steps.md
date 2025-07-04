# QPI summary table tidying steps

Steps to carry out after using the generate_summary_in_excel.R script to create the Excel file. 

## For the download file 

* Remove filters.
* Expand QPI name column A.
* Save as ... 
"YYYY_MM_DD_<tsg eg bladder>_cancer_qpi_summary_table.xlsx"
* If applicable, manually adjust the order of the rows to be in true QPI number order rather than alphabetical eg so that QPI 10 etc all appear after QPI 9. But beware, try to avoid some rows ending up outside the Excel 'Table', because then Excel won't sort them together with the other rows properly. So follow these steps (if QPI 11 etc is at the top of the table): 
   - select the rows for QPIs 1, 2, 3, 4 to 9 etc (that are incorrectly at the foot of the table). 
   - cut them
   - select the first row of the table ie row 2
   - right-click and select "Insert cut cells", so the rows are inserted and all rows remain within the Excel table. 
* Adjust Performance columns to width of 'Performance', wrapping the rest. 
* Double-click Target column B, to fit to width.
* Likewise for the Results columns.
* Clear any warnings (usually highlighted as a green triangle in the corner of a cell) on the Target column cells stating 'number stored as text' or equivalent - open and click 'ignore error'. Or select area containing all the errors, go into Error Checking Options, and uncheck 'Numbers displayed as text", or just deactivate background error checking, to clear all errors at once. 
* Optionally: Copy the fill colour into the cells containing the performance numbers.
 - not met: #E1C7DF (ie phs-magenta-30)
 - target met: #C1DD93 (ie phs-green-50)
* Optionally: Right-align the data cells in the columns containing percentages ie Column B (Target) and Performance. 
* Save this for checking, ie as the download version for users. 

## For the publication version

* Change "Target not met" to just "Not met". 
* Save as ... "for_pasting_YYYY_MM_DD_<tsg>_qpi_summary_table.xlsx"
* Change column heading from Performance etc to the year eg 2022/23, by deleting "Performance (%) ". 
* Change Result column headings to just "Result", and a space or two to make each column different, to prevent Excel numbering them. 
* Colour the table borders - maybe dark purple everywhere, and white lines between the years, but not between the performance column and the result column. 
* Copy and paste into Word template draft summary report. 
* Set style of the table text to "Table body". 
* Set style of number columns to "Table body right aligned for numbers only".
* Select heading row, and set style to "Table head".
* Adjust column widths. If edges are beyond the margin, try selecting the table and select 'Autofit: Fit to Window'. 

