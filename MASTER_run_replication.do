clear all
version 16
set more off
macro drop _all

*********************************************************************************
**************          MASTER PAPER REPLICATION DO FILE           **************
*********************************************************************************
/*

This script replicates Burlig, Sudarshan, and Schlauch (2020): 
   "Quantifying the effect of domestic travel bans on COVID-19 infections,"
   starting from publicly available data.

All code and publicly-available data can be found at our Github repository:
  https://github.com/fburlig/BSS_COVID_migration
  
Please contact Fiona Burlig (burlig@uchicago.edu) with questions.

*/


*********************************************************************************
*********************************************************************************

** This file has been validated to run using Stata 16 and R 4.02 as of Oct 10, 2020.

***** DEPENDENCIES:

** This .do file requires the following user-written packages:
* -- STATA: gsort, missings, reclink, strgroup, rangestat, dm88_1 [all available from ssc]
* -- R: sf, dplyr, haven, plyr, tidyverse, readxl, readr, stringr, tidyr, nngeo, rlist, rjson, jsonlite,
*   lubridate, rmapshaper, grDevices, rgdal, sp [all available from CRAN]
* -- R: covoid [available from Github using the following code: 
/*
# if necessary, install devtools:
install.packages("devtools")
# install covoid:
devtools::install_github("cbdrh/covoid",build_vignettes = TRUE)]
*/ 

*********************************************************************************
*********************************************************************************

***** SETUP

**** Set data paths
* global dirpath "[YOUR DATA DIRECTORY HERE]"
* global dirpath_code "[YOUR CODE DIRECTORY HERE]"

**** This .do file calls R files. Set this path to your installation of R.
* global R_exe_path "[YOUR R INSTALLATION HERE]"

** For Mac users, this will look something like: "/Library/Frameworks/R.framework/Resources/bin/R"
** For PC users, this will look something like: "C:/PROGRA~1/MIE74D~1/ROPEN~1/bin/x64/R"

** NOTE: Due to the clunky nature of calling R within Stata,
**   replicators will need to change the --setwd()-- to their own path in each .R
**   file individually before running this script.

** For figures to appear as in the main paper, use the included scheme-fb2.scheme:
set scheme fb2

*********************************************************************************
*********************************************************************************
*** Project code must be run in the below order. If you wish to run any single file,
**   you must first add the line `global dirpath "[YOUR DIRECTORY PATH]"'.


**** NOTE: STEPS 1-8 RELY ON CONFIDENTIAL DATA THAT WE ARE PREVENTED FROM SHARING
****   DUE TO THE NATURE OF OUR DUA. THEY CAN BE FOUND IN MASTER_run_full_project.do.
****   REPLICATORS SHOULD START AT STEP 9.


*********************************************************************************
*********************************************************************************

**** NOTE: THE REMAINING STEPS CONDUCT ANALYSIS AND GENERATE FIGURES. WE PROVIDE
****   ALL DATA FOR THESE STEPS IN THE PUBLIC REPOSITORY. REPLICATORS SHOULD START HERE.


***
*** (Step 9: Generate SEIR predictions) 
***
{
*** 9.A: GENERATE SEIR MODEL PREDICTIONS
shell "${R_exe_path}" --vanilla <"$dirpath_code/analyze/9A_ANALYZE_SEIR_model_predictions.R"
}


***
*** (Step 10: Estimate empirical model) 
***
{
*** 10.A: ESTIMATE REGRESSION MODEL
do "$dirpath_code/analyze/10A_ANALYZE_run_event_studies.do"

*** 10.B: RUN PERMUTATION INFERENCE TEST
* NOTE: This takes a long time (>24h)
do "$dirpath_code/analyze/10B_ANALYZE_permutation_inference_test.do"
}

***
*** (Step 11: Produce outputs) 
***
{
*** 11.A: PRODUCE MAIN TEXT FIGURE 1, PANEL A: MIGRANT MAP
* Note: The final production figure has been modified using Adobe Illustrator.
shell "${R_exe_path}" --vanilla <"$dirpath_code/po/11A_PO_Map_mumbai_migrants.R"

*** 11.B: PRODUCE MAIN TEXT FIGURE 1, PANEL B: DAILY REMITTANCE TRANSACTION VOLUME
do "$dirpath_code/po/11B_PO_Figure_mumbai_transaction_volume.do"

*** 11.C: PRODUCE MAIN TEXT FIGURE 1, PANEL C: MUMBAI COVID CASES
do "$dirpath_code/po/11C_PO_Figure_mumbai_cases_timeseries.do"

*** 11.D: PRODUCE MAIN TEXT FIGURE 2, PANEL A: SEIR PREDICTIONS
* Note: The final production figure has been modified using Adobe Illustrator.
do "$dirpath_code/po/11D_PO_Figure_SEIR_model.do"

*** 11.E: PRODUCE MAIN TEXT FIGURE 2, PANEL B: REGRESSION ESTIMATES
***   ALSO PRODUCES: SI FIGURE S1 AND SI FIGURE S2, ALL PANELS
* Note: The final production figure has been modified using Adobe Illustrator.
do "$dirpath_code/po/11D_PO_Figure_SEIR_model.do"

*** 11.F: PRODUCE SI FIGURE S3: ECONOMETRIC ROBUSTNESS
do "$dirpath_code/po/11F_PO_Figure_robustness_cases.do.do"

*** 11.G: PRODUCE SI FIGURE S4: PERMUTATION INFERENCE
do "$dirpath_code/po/11G_PO_Figure_permutation_inference.do"

*** 11.H: PRODUCE SI TABLE S1: SEIR PARAMETERS
do "$dirpath_code/po/11H_PO_Table_SEIR_parameters.do"
}

