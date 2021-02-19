clear all
version 16
set more off
macro drop _all

*********************************************************************************
**************          MASTER PAPER REPLICATION DO FILE           **************
*********************************************************************************
/*

This script replicates Burlig, Sudarshan, and Schlauch (2021): 
   "The impact of domestic travel bans on COVID-19 cases is nonlinear in their duration"
   starting from the final analysis.

All code and data can be found at our Github repository:
  https://github.com/fburlig/BSS_COVID_migration
  
Please contact Fiona Burlig (burlig@uchicago.edu) with questions.

*/


*********************************************************************************
*********************************************************************************

** This file has been validated to run using Stata 16 and R 4.02 as of Feb 18, 2021.

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


**** NOTE: THE FILE RUNS ALL CODE USED CONDUCT ANALYSIS AND GENERATE FIGURES AND TABLES. TO REPRODUCE THE ENTIRE PROJECT INCLUDING CLEANING STEPS, SEE 'MASTER_run_full_project.do'


*********************************************************************************
*********************************************************************************

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

