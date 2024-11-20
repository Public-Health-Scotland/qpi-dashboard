# QPI summary table tidying steps

Steps to carry out after using the generate_summary_in_excel.R script to create the Excel file. 

## For the download file 

* Remove filters.
* Expand QPI name column A.
* Save as ... "for_pasting_YYYY_MM_DD_<tsg>_summary_table.xlsx"
* If applicable, append "%" symbol in the percentage value cells, so it's more obvious it's a percentage value. Planning to code to do this automatically. 
* If applicable, manually adjust the order of the cols to be in QPI number order rather than alphabetical eg so that QPI 10 etc all appear after QPI 9. 
* Adjust Performance columns to width of 'Performance', wrapping the rest. 
* Double-click Target column B, to fit to width.
* Likewise for the Results columns. 
* Optionally: Copy the fill colour into the cells containing the performance numbers.
 - not met: #E39C8C
 - target met: #C1DD93

* If necessary, manually adjust to get 1 decimal place on every performance figure (even on whole numbers). 
* Save this as the download version for users. 

## For the publication version

* Change "Target not met" to just "Not met". 
* Save as ... "YYYY_MM_DD_<tsg eg bladder>_cancer_qpi_summary_table.xlsx"
* Change column heading from Performance etc to the year eg 2022/23, by deleting "Performance (%) ". 
* Change Result column headings to just "Result", and a space or two to make each column different, to prevent Excel numbering them. 
* Colour the table borders - maybe dark purple everywhere, and white lines between the years, but not between the performance column and the result column. 
* Copy and paste into Word template draft summary report. 
* Set style of the table text to "Table body". 
* Set style of number columns to "Table body right aligned for numbers only".
* Select heading row, and set style to "Table head".
* Adjust column widths. If edges are beyond the margin, try selecting the table and select 'Autofit: Fit to Window'. 

