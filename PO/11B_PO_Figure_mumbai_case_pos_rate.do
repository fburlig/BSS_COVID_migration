
* Plot Mumbai case positivity rate

**** Setup
clear all
macro drop _all

global dirpath_data "$dirpath/data"
global dirpath_raw "$dirpath_data/raw"
global dirpath_raw_census "$dirpath_raw/census"
global dirpath_raw_covid "$dirpath_raw/covid"
global dirpath_raw_misc "$dirpath_raw/misc"
global dirpath_gen "$dirpath_data/generated"
global dirpath_int "$dirpath_gen/intermediate"
global dirpath_int_census "$dirpath_int/census"
global dirpath_int_covid "$dirpath_int/covid"
global dirpath_int_map "$dirpath_int/map"
global dirpath_int_temp "$dirpath_int/temp"
global dirpath_int_worldpop "$dirpath_int/World pop"
global dirpath_int_shapefiles "$dirpath_int/shapefiles"
global dirpath_final "$dirpath_gen/final"
global dirpath_final_reg_inputs "$dirpath_final/Regression inputs"
global dirpath_final_results "$dirpath_final/results"
global dirpath_outputs "$dirpath/outputs"
global dirpath_outputs_figs "$dirpath_outputs/figures"
global dirpath_outputs_tables "$dirpath_outputs/tables"

set scheme fb2, perm

local phase1_color = "midblue*1.5"
local phase2_color = "midblue*0.75"
local phase3_color = "79 41 132"

******************************************************************* Prep data
******************************************************************
	
* Get cases and deaths in mumbai around ban lift
use "$dirpath_int_covid/Mumbai_cleaned_case_timeseries.dta", clear
sort date
replace num_cases = 0 if missing(num_cases)
gen cum_cases_past7days = num_cases[_n-7] + ///
	num_cases[_n-6] + num_cases[_n-5] + num_cases[_n-4] + ///
	num_cases[_n-3] + num_cases[_n-2] + num_cases[_n-1] + ///
	num_cases[_n]
gen cum_tests_past7days = num_tested[_n-7] + ///
	num_tested[_n-6] + num_tested[_n-5] + num_tested[_n-4] + ///
	num_tested[_n-3] + num_tested[_n-2] + num_tested[_n-1] + ///
	num_tested[_n]
gen pos_rate = cum_cases_past7days / cum_tests_past7days
keep subregion2_name date pos_rate
keep if date("2020/05/08", "YMD") - 7 <= date & ///
	date <= date("2020/08/20", "YMD") + 7

local may1 = date("2020/05/01", "YMD")
local may8 = date("2020/05/08", "YMD")
local jun1 = date("2020/06/01", "YMD")
local jun5 = date("2020/06/05", "YMD")
local jul1 = date("2020/07/01", "YMD")
local aug1 = date("2020/08/01", "YMD")
local aug20 = date("2020/08/20", "YMD")
local sep1 = date("2020/09/01", "YMD")
local tick_axis_thick = 0.3

* Plot
twoway ///
	(line pos_rate date, ///
		lc(gs10) lp(solid) lw(0.65)) ///
	(scatter pos_rate date if ///
		date == `may8', ///
		mlcolor("`phase1_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	(scatter pos_rate date if ///
		date == `jun5', ///
		mlcolor("`phase2_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	(scatter pos_rate date if ///
		date == `aug20', ///
		mlcolor("`phase3_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	, ///
		legend(off) ///
		xtitle("") ///
		ytitle("Mumbai COVID-19 positivity rate", ///
			size(large)) ///
		xsc(lw(`tick_axis_thick') r(`=`may1'-3' `=`sep1'+2')) ///
		ysc(lw(`tick_axis_thick')) ///
		ylab(, labsize(large) tlwidth(`tick_axis_thick')) ///
		xlab(`may1' "May 1" `jun1' "Jun 1" `jul1' "Jul 1" ///
			`aug1' "Aug 1" `sep1' "Sep 1", ///
				labsize(large) tlwidth(`tick_axis_thick')) ///
		xsize(2.4) /// default is 5.5
		ysize(2.6565) /// old: 2 default is 4
		title("{bf: {fontface Arial: a}}", pos(10) size(vhuge))

graph export "$dirpath_outputs_figs/Figure_india_mumbai_cases_last7days_timeseries.pdf", replace

