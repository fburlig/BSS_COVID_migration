clear all
version 16
set more off
macro drop _all

*********************************************************************************
*******************          MASTER PROJECT DO FILE           *******************
*********************************************************************************
/*

This script replicates Burlig, Sudarshan, and Schlauch (2021): 
   "The impact of domestic travel bans on COVID-19 cases is nonlinear in their duration"

All code and data can be found at our Github repository:
  https://github.com/fburlig/BSS_COVID_migration
  
Please contact Fiona Burlig (burlig@uchicago.edu) with questions.

*/


*********************************************************************************
*********************************************************************************

** This file has been validated to run using Stata 16 MP and R 4.02 as of Feb 18, 2021.

***** DEPENDENCIES:

** This .do file requires the following user-written packages:
* -- STATA: gsort, missings, reclink, strgroup, rangestat,
*	 dm88_1, gr0075, gtools, and reghdfe [all available from ssc]
* -- R: sf, plyr, tidyverse, nngeo, rlist, rjson, rmapshaper,
*	 grDevices, rgdal, extrafont, stringi, exactextractr, raster,
*    fasterize, maptools, and sp [all available from CRAN]
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
* global dirpath "[YOUR PROJECT DIRECTORY HERE]"
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

****   REPLICATORS SHOULD START AT STEP 8.

***
*** (Step 1: Build India district shapefile) 
***
{
*** 1.A: COMBINE MULTIPLE SHAPEFILES INTO ONE DISTRICT SHAPEFILE
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/1A_BUILD_district_shapefile_india.R"

*** 1.B: AGGREGATE DELHI AND MUMBAI INTO ONE DISTRICT EACH
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/1B_BUILD_agg_district_shapefile_india.R"

}

***
*** (Step 2: Extract populations from WorldPop rasters for each country) 
***
{
*** 2.A: EXTRACT POPULATIONS
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/2A_BUILD_extract_worldpop_rasters.R"

}

***
*** (Step 3: Clean/subset census migration data for each country) 
***
{
*** 3.A: GET MIGRATION STOCKS FOR CAPE TOWN, SOUTH AFRICA
do "$dirpath_code/build/3A_BUILD_clean_census_migration_za.do"

*** 3.B: GET MIGRATION STOCKS FOR NCR AND CEBU, PHILIPPINES
do "$dirpath_code/build/3B_BUILD_clean_census_migration_ph.do"

*** 3.C: GET MIGRATION STOCKS FOR NAIROBI AND MOMBASA, KENYA
do "$dirpath_code/build/3C_BUILD_clean_census_migration_ke.do"

*** 3.D: GET MIGRATION STOCKS FOR JAKARTA, INDONESIA
do "$dirpath_code/build/3D_BUILD_clean_census_migration_id.do"

*** 3.E: GET MIGRATION STOCKS FOR MUMBAI, INDIA
do "$dirpath_code/build/3E_BUILD_clean_census_migration_in.do"

*** 3.F: GET URBAN POPULATIONS FOR INDIAN DISTRICTS
do "$dirpath_code/build/3F_BUILD_get_tot_urban_pop_in.do"

}

***
*** (Step 4: Construct COVID data for India) 
***
{
*** 4.A: REFORMAT RAW COVID19INDIA.ORG CASE DATA
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/4A_BUILD_reformat_covid19india_raw.R"

*** 4.B: CONSTRUCT DISTRICT-WISE CUMULATIVE COVID CASE DATA
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/4B_BUILD_get_cumulative_cases_india.R"

*** 4.C: CLEAN COVID CASE DATA FOR INDIA
do "$dirpath_code/build/4C_BUILD_clean_covid_data_india.do"

*** 4.D: MERGE CLEANED INDIA COVID DATA WITH MIGRATION AND POPULATION DATA
do "$dirpath_code/merge/4D_MERGE_covid_mig_pop_data_india.do"

*** 4.E: PREP INDIA DATA FOR COUNTRY REGRESSIONS
do "$dirpath_code/build/4E_BUILD_prep_india_data_for_country_reg.do"

}

***
*** (Step 5: Clean COVID data for countries aside from India) 
***
{
*** 5.A: CLEAN COVID DATA AND MERGE IN POPULATIONS
do "$dirpath_code/build/5A_BUILD_clean_nonindia_data.do"

*** 5.B: INTERPOLATE DAILY CASES FOR KENYA DISTRICTS
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/5B_BUILD_interpolate_kenya_district_cases.R"

*** 5.C: ASSIGN MIGRANT COUNTS FOR ALL COUNTRIES ASIDE FROM INDIA
do "$dirpath_code/build/5C_BUILD_assign_migrants_nonindia.do"

}

***
*** (Step 6: Create datasets for permutation inference test) 
***
{
*** 6.A: MERGE DISTRICT-WISE CASES AND MIGRATION DATA
do "$dirpath_code/build/6A_BUILD_permutation_inference_datasets.do"

}

***
*** (Step 7: Data preparation for migrant map) 
***
{
*** 7.A: CONSTRUCT BINS FOR MIGRANT MAP
do "$dirpath_code/build/7A_BUILD_migrant_map_bins_india.do"

*** 7.B: CONSTRUCT SHAPEFILE FOR MIGRANT MAP
shell "${R_exe_path}" --vanilla <"$dirpath_code/build/7B_BUILD_migration_shapefile_india.R"

}

*********************************************************************************
*********************************************************************************

**** NOTE: THE REMAINING STEPS CONDUCT ANALYSIS AND GENERATE FIGURES AND TABLES.

***
*** (Step 8: Generate SEIR model predictions) 
***
{
*** 8.A: GENERATE SEIR MODEL PREDICTIONS
shell "${R_exe_path}" --vanilla <"$dirpath_code/analyze/8A_ANALYZE_SEIR_model_predictions.R"
}

***
*** (Step 9: Estimate empirical model for India) 
***
{
*** 9.A: ESTIMATE REGRESSION MODEL FOR INDIA
do "$dirpath_code/analyze/9A_ANALYZE_run_event_studies_india.do"

*** 9.B: PERFORM "ROTATION" ADJUSTMENT FOR INDIA
do "$dirpath_code/analyze/9B_ANALYZE_detrend_event_studies_india.do"

*** 9.C: RUN PERMUTATION INFERENCE TEST FOR INDIA
* NOTE: This takes a long time (>2h)
do "$dirpath_code/analyze/9C_ANALYZE_permutation_inference_test_india.do"
}

***
*** (Step 10: Estimate empirical model for cross-country comparison) 
***
{
*** 10.A: ESTIMATE REGRESSION MODEL FOR CROSS-COUNTRY COMPARISON
do "$dirpath_code/analyze/10A_ANALYZE_run_event_studies_countries.do"

*** 10.B: PERFORM "ROTATION" ADJUSTMENT FOR CROSS-COUNTRY COMPARISON
do "$dirpath_code/analyze/10B_ANALYZE_detrend_event_studies_countries.do"

}

***
*** (Step 11: Produce outputs) 
***
{
*** 11.A: PRODUCE MAIN TEXT FIGURE 1: SEIR MODEL PREDICTIONS
do "$dirpath_code/po/11A_PO_Figure_SEIR_model.do"

*** 11.B: PRODUCE MAIN TEXT FIGURE 2, PANEL A: SEIR MODEL PREDICTIONS
do "$dirpath_code/po/11B_PO_Figure_mumbai_case_pos_rate.do"

*** 11.C: PRODUCE MAIN TEXT FIGURE 2, PANEL B: MIGRANT MAP
shell "${R_exe_path}" --vanilla <"$dirpath_code/po/11C_PO_Map_mumbai_migrants.R"

*** 11.D: PRODUCE MAIN TEXT FIGURE 2, PANEL C: EVENT STUDIES
do "$dirpath_code/po/11D_PO_Figure_event_studies_india.do"

*** 11.E: PRODUCE MAIN TEXT FIGURE 2, PANELS D AND E, AND EXTENDED DATA FIGURE 1: INDIA EMPIRICAL ESTIMATES
do "$dirpath_code/po/11E_PO_Figure_main_estimates_india.do"

*** 11.F: PRODUCE MAIN TEXT FIGURE 3, PANELS A AND B, AND EXTENDED DATA FIGURE 3: CROSS-COUNTRY COMPARISONS
do "$dirpath_code/po/11F_PO_Figure_countries.do"

*** 11.G: PRODUCE EXTENDED DATA FIGURE 2: INDIA EMPIRICAL ROBUSTNESS
do "$dirpath_code/po/11G_PO_Figure_robustness_india.do"

*** 11.H: PRODUCE EXTENDED DATA FIGURE 3: PERMUTATION INFERENCE TEST
do "$dirpath_code/po/11H_PO_Figure_permutation_inference.do"

*** 11.I: PRODUCE SUPPLEMENTARY TABLES 1--3
do "$dirpath_code/po/11I_PO_Tables.do"

}

