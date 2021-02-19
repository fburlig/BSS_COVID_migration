
* Create datasets for permutation inference test

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

******************************************************************
* Prep data to run regressions
******************************************************************

* Load data
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear

* Rename migrant variable
rename mig0to5yrs_dist num_migrants

* Create new data variable
gen date_stata = date
replace date_stata = date_stata - 21976 + 1

* Create time dummies
qui gen T = 100 + date_stata - 68
tab T, gen(T_)
forval i = 213(-1)1 {
	local j = `i' + (100 - 68)
	rename T_`i' T_`j'
}

* Multiply time dummies by the number of migrants in each phase
forval t = 33/245 {
	forvalues phase = 1(1)3 {
		gen Tmig_phase`phase'_`t' = ///
			T_`t' * phase`phase' * num_migrants
	}
	drop T_`t'
}

* Run checks
forvalues i = 33(1)245 {
	assert Tmig_phase1_`i' == 0 if phase == 2 | phase == 3
	assert Tmig_phase2_`i' == 0 if phase == 1 | phase == 3
	assert Tmig_phase3_`i' == 0 if phase == 1 | phase == 2
	assert !missing(Tmig_phase1_`i') & ///
		!missing(Tmig_phase1_`i') & !missing(Tmig_phase1_`i')
}

******************************************************************
* Phase 1
******************************************************************

preserve

* Order pre-release coefficient last to be omitted
local phase1_release = date("2020/05/08", "YMD")
assert Tmig_phase1_100 != 0 if date == `phase1_release' & ///
	phase == 1
order Tmig_phase1_99, last

* Drop other Tmig terms
drop Tmig_phase2* Tmig_phase3*

* Drop Tmig terms outside sample window
foreach i of numlist 33/69 131/245 {
	drop Tmig_phase1_`i'
}

* Keep dates in sample window
keep if date >= `phase1_release' - 30 & ///
date <= `phase1_release' + 30

* Run checks
gunique date
assert r(unique) == 61
assert date[31] == `phase1_release'

* Keep necessary variables to save space
keep state state_id district district_id date ///
	num_cases Tmig* phase

* Output
compress *
save "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase1.dta", replace

restore

******************************************************************
* Phase 2
******************************************************************

preserve

* Order pre-release coefficient last to be omitted
local phase2_release = date("2020/06/05", "YMD")
assert Tmig_phase2_128 != 0 if date == `phase2_release' & ///
	phase == 2
order Tmig_phase2_127, last

* Drop other Tmig terms
drop Tmig_phase1* Tmig_phase3*

* Drop Tmig terms outside sample window
foreach i of numlist 33/97 159/245 {
		drop Tmig_phase2_`i' 
}

* Keep dates in sample window
keep if date >= `phase2_release' - 30 & ///
date <= `phase2_release' + 30

* Run checks
gunique date
assert r(unique) == 61
assert date[31] == `phase2_release'

* Keep necessary variables to save space
keep state state_id district district_id date ///
	num_cases Tmig* phase

* Output
compress *
save "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase2.dta", replace

restore

******************************************************************
* Phase 3
******************************************************************

* Order pre-release coefficient last to be omitted
local phase3_release = date("2020/08/20", "YMD")
assert Tmig_phase3_204 != 0 if date == `phase3_release' & ///
	phase == 3
order Tmig_phase3_203, last

* Drop other Tmig terms
drop Tmig_phase1* Tmig_phase2*

* Drop Tmig terms outside sample window
foreach i of numlist 33/173 235/245 {
		drop Tmig_phase3_`i' 
}

* Keep dates in sample window
keep if date >= `phase3_release' - 30 & ///
date <= `phase3_release' + 30

* Run checks
gunique date
assert r(unique) == 61
assert date[31] == `phase3_release'

* Keep necessary variables to save space
keep state state_id district district_id date ///
	num_cases Tmig* phase

* Output
compress *
save "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase3.dta", replace

