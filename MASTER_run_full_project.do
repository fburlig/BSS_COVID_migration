clear all
version 16
set more off
macro drop _all

*********************************************************************************
*******************          MASTER PROJECT DO FILE           *******************
*********************************************************************************
/*

This script replicates Burlig, Sudarshan, and Schlauch (2020): 
   "Quantifying the effect of domestic travel bans on COVID-19 infections"

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
****   DUE TO THE NATURE OF OUR DUA. CONTACT US FOR FURTHER DETAILS.
****   REPLICATORS SHOULD START AT STEP 9.



***
*** (Step 1: Build shape files) 
***
{
*** 1.A: COMBINE MULTIPLE SHAPEFILES INTO ONE DISTRICT SHAPEFILE
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/1A_BUILD_district_shapefile.R"

*** 1.B: AGGREGATE DELHI AND MUMBAI INTO ONE DISTRICT EACH
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/1B_BUILD_aggregate_district_shapefile_delhi_mumbai.R"

*** 1.C: COMBINE VILLAGE SHAPEFILES INTO ONE MASTER SHAPEFILE
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/1C_BUILD_village_shapefile.R"

}

***
*** (Step 2: Geocode bank branches) 
***
{
*** 2.A: CLEAN BANK CODES
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/2A_BUILD_clean_bank_codes.R"

*** 2.B: UPDATE REMITTANCE DATA WITH CLEANED BANK CODES
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/2B_BUILD_update_bank_codes.R"

*** 2.C: GEOCODE BANK CODES IN REMITTANCE DATA
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/2C_BUILD_geocode_bank_codes.R"

}


***
*** (Step 3: Construct remittances data) 
***
{
*** 3.A: GENERATE GEOCODED SENDER-RECEIVER REMITTANCE PAIRS
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/3A_BUILD_remit_send_rec_pairswise.R"

*** 3.B: FILTER REMITTANCE FLOWS TO MUMBAI-ORIGIN ONLY
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/3B_BUILD_filter_mumbai_remittance_flows.R"

}

***
*** (Step 4: Construct COVID data) 
***
{
*** 4.A: REFORMAT RAW COVID19INDIA.ORG CASE DATA
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/4A_BUILD_reformat_covid19india_raw.R"

*** 4.B: CONSTRUCT DISTRICT-WISE CUMULATIVE COVID CASE DATA
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/4B_BUILD_cumulative_cases.R"

*** 4.C: CLEAN COVID CASE DATA
do "$dirpath_code/build/4C_BUILD_clean_covid19india_cases.do"
}

***
*** (Step 5: Construct Census data) 
***
{
*** 5.A: BUILD CENSUS MIGRANT FLOWS
do "$dirpath_code/build/5A_BUILD_census_flows_mumbai.do"

*** 5.B: BUILD CENSUS DISTRICT POPULATIONS
do "$dirpath_code/build/5B_BUILD_district_wise_populations.do"

}

***
*** (Step 6: Combine COVID and migration data) 
***
{
*** 6.A: MERGE DISTRICT-WISE CASES AND MIGRATION DATA
do "$dirpath_code/merge/6A_MERGE_cases_flows.do"

*** 6.B: MERGE DISTRICT POPULATIONS WITH DISTRICT CASE/MIGRATION DATA
do "$dirpath_code/merge/6B_MERGE_cases_flows_pops.do"

}


***
*** (Step 7: Produce final regression inputs) 
***
{
*** 7.A: GENERATE MIGRATION FLOWS USING CENSUS DATA ONLY
do "$dirpath_code/build/7A_BUILD_census_only_migration_flows.do"

*** 7.B: GENERATE MIGRATION FLOWS USING REMITTANCE DATA ONLY
do "$dirpath_code/build/7B_BUILD_migrant_counts_remittances_only_2011_pop.do"

*** 7.C: COMPUTE STATE-WISE AND DISTRICT-WISE MIGRANT SHARES
do "$dirpath_code/build/7C_BUILD_migration_totals_shares.do"

*** 7.D: COMPUTE DISTRICT-WISE MIGRATION COUNTS; COMBINE REMITTANCE & CENSUS
do "$dirpath_code/build/7D_BUILD_migration_estimates.do"

*** 7.E: BUILD REGRESSION TREATMENT VARIABLES & PREP PERMUTATION TEST
do "$dirpath_code/build/7E_BUILD_perm_test_dataset_eventstudy.do"
}


***
*** (Step 8: Miscellaneous data preparation for figures) 
***
{
*** 8.A: CONSTRUCT BINS FOR MIGRANT MAP
do "$dirpath_code/build/8A_BUILD_migrant_map_bins.do"

*** 8.B: CLEAN MUMBAI MONTHLY REMITTANCE TRANSACTION VOLUME
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/8B_BUILD_clean_monthly_volume_mumbai.R"

*** 8.C: CLEAN DAILY REMITTANCE TRANSACTION VOLUME
do "$dirpath_code/build/8C_BUILD_clean_daily_transaction_volume.do"

*** 8.D: PREPARE DISTRICT-LEVEL SHAPEFILE FOR DEPARTING MIGRANT HEATMAP
shell "${R_exe_path}" --vanilla <"$dirpath_code/merge/8D_MERGE_migration_flows_shapefile.R"

*** 8.E: MERGE DAILY AND MONTHLY REMITTANCE VOLUME; SCALE DAILY BY MUMBAI SHARE
do "$dirpath_code/merge/8E_MERGE_daily_monthly_remittance_volume.do"
}

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

