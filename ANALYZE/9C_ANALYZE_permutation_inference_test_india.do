
* Run permutation inference test for India

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

****************************************************************
* Macros for release dates and the number of iterations
****************************************************************

* Release date and range macros
local phase1_release = 100
local phase1_range = "70/130"
local phase2_release = 128
local phase2_range = "98/158"
local phase3_release = 204
local phase3_range = "174/234"

* Macro for number of permutation iterations
local num_permutations = 10000

****************************************************************
* Get the number of migrants in each phase. This will be used to get total case estimates later
****************************************************************

* Census only match to country reg, full sample (specs without testing control)
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear
gunique district_id
local unique_districts_all = r(unique)
duplicates drop state district, force
rename mig0to5yrs_dist num_migrants
collapse (sum) num_migrants, by(phase)
sort phase
local phase1_migrants = num_migrants[1]
local phase2_migrants = num_migrants[2]
local phase3_migrants = num_migrants[3]

******************************************************************
* Phase 1
******************************************************************

************************************ Non-permuted

di "Phase 1: non-permuted regression"

qui {
	
* Load data
use "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase1.dta", clear

* Run regression
areg num_cases Tmig_phase1* i.date, ///
	absorb(district_id)

* Prep dataset to store results
clear
set obs 61
gen T = .
gen beta_unadj = .

* Store daily coefficients
local obs = 1
forval t = `phase1_range' {
	qui replace T = `t' - `phase1_release' if _n == `obs'
	qui replace beta_unadj = _b[Tmig_phase1_`t'] if _n == `obs'
	local obs = `obs' + 1
}

* Note phase
gen phase = 1
gen seed = .

* Output
save "$dirpath_int_temp/RESULTS_phase1_eventstudy_unadjusted.dta", replace
}

************************************ Permuted

* Loop through number of permutations
forval i = 1(1)`num_permutations' {
	
* Monitor loop
di "Phase 1: permuted regression"
di "   Iteration number: `i' / `num_permutations'"
	
qui {
	
* Load data
use "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase1.dta", clear

* Assign a random number to eacah district
keep num_cases date district_id
set seed `i'
gen random_num = runiform()
gsort district_id date
by district_id (date): replace random_num = random_num[1]

* Assign a new district id to each district based on this number
preserve
keep district_id random_num
gduplicates drop
gsort random_num
gen new_district_id = _n
tempfile new_dist_id
save `new_dist_id', replace
restore

* Replace the old district id with new one in cases timeseries
qui merge m:1 district_id using `new_dist_id'
assert _merge == 3
drop _merge district_id random_num
rename new_district_id district_id
rename num_cases new_num_cases

* Join onto event study dataframe, keeping only the dates that match since dates outside event windows were dropped
qui merge 1:1 district_id date using "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase1.dta"
assert _merge == 3
drop _merge
	
* Replace the original cases time series with one from another randomly assigned district
drop num_cases
rename new_num_cases num_cases

* Run regression
areg num_cases Tmig_phase1* i.date, ///
	absorb(district_id)

* Prep dataset to store results
clear
set obs 61
gen T = .
gen beta_unadj = .

local obs = 1
forval t = `phase1_range' {
	qui replace T = `t' - `phase1_release' if _n == `obs'
	qui replace beta_unadj = _b[Tmig_phase1_`t'] if _n == `obs'
	local obs = `obs' + 1
}

* Note phase
gen phase = 1
gen seed = `i'

* Output
save "$dirpath_int_temp/RESULTS_phase1_eventstudy_unadjusted_seed`i'.dta", replace
}
}


******************************************************************
* Phase 2
******************************************************************

************************************ Non-permuted

di "Phase 2: non-permuted regression"

qui {
	
* Load data
use "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase2.dta", clear

* Run regression
areg num_cases Tmig_phase2* i.date, ///
	absorb(district_id)

* Prep dataset to store results
clear
set obs 61
gen T = .
gen beta_unadj = .

* Store daily coefficients
local obs = 1
forval t = `phase2_range' {
	qui replace T = `t' - `phase2_release' if _n == `obs'
	qui replace beta_unadj = _b[Tmig_phase2_`t'] if _n == `obs'
	local obs = `obs' + 1
}

* Note phase
gen phase = 2
gen seed = .

* Output
save "$dirpath_int_temp/RESULTS_phase2_eventstudy_unadjusted.dta", replace
}

************************************ Permuted

* Loop through number of permutations
forval i = 1(1)`num_permutations' {
	
* Monitor loop
di "Phase 2: permuted regression"
di "   Iteration number: `i' / `num_permutations'"
	
qui {
	
* Load data
use "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase2.dta", clear

* Assign a random number to eacah district
keep num_cases date district_id
set seed `i'
gen random_num = runiform()
gsort district_id date
by district_id (date): replace random_num = random_num[1]

* Assign a new district id to each district based on this number
preserve
keep district_id random_num
gduplicates drop
gsort random_num
gen new_district_id = _n
tempfile new_dist_id
save `new_dist_id', replace
restore

* Replace the old district id with new one in cases timeseries
qui merge m:1 district_id using `new_dist_id'
assert _merge == 3
drop _merge district_id random_num
rename new_district_id district_id
rename num_cases new_num_cases

* Join onto event study dataframe, keeping only the dates that match since dates outside event windows were dropped
qui merge 1:1 district_id date using "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase2.dta"
assert _merge == 3
drop _merge
	
* Replace the original cases time series with one from another randomly assigned district
drop num_cases
rename new_num_cases num_cases

* Run regression
areg num_cases Tmig_phase2* i.date, ///
	absorb(district_id)

* Prep dataset to store results
clear
set obs 61
gen T = .
gen beta_unadj = .

local obs = 1
forval t = `phase2_range' {
	qui replace T = `t' - `phase2_release' if _n == `obs'
	qui replace beta_unadj = _b[Tmig_phase2_`t'] if _n == `obs'
	local obs = `obs' + 1
}

* Note phase
gen phase = 2
gen seed = `i'

* Output
save "$dirpath_int_temp/RESULTS_phase2_eventstudy_unadjusted_seed`i'.dta", replace
}
}


******************************************************************
* Phase 3
******************************************************************

************************************ Non-permuted

di "Phase 3: mon-permuted regression"

qui {
	
* Load data
use "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase3.dta", clear

* Run regression
areg num_cases Tmig_phase3* i.date, ///
	absorb(district_id)

* Prep dataset to store results
clear
set obs 61
gen T = .
gen beta_unadj = .

* Store daily coefficients
local obs = 1
forval t = `phase3_range' {
	qui replace T = `t' - `phase3_release' if _n == `obs'
	qui replace beta_unadj = _b[Tmig_phase3_`t'] if _n == `obs'
	local obs = `obs' + 1
}

* Note phase
gen phase = 3
gen seed = .

* Output
save "$dirpath_int_temp/RESULTS_phase3_eventstudy_unadjusted.dta", replace
}

************************************ Permuted

* Loop through number of permutations
forval i = 1(1)`num_permutations' {
	
* Monitor loop
di "Phase 3"
di "   Iteration number: `i' / `num_permutations'"
	
qui {
	
* Load data
use "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase3.dta", clear

* Assign a random number to eacah district
keep num_cases date district_id
set seed `i'
gen random_num = runiform()
gsort district_id date
by district_id (date): replace random_num = random_num[1]

* Assign a new district id to each district based on this number
preserve
keep district_id random_num
gduplicates drop
gsort random_num
gen new_district_id = _n
tempfile new_dist_id
save `new_dist_id', replace
restore

* Replace the old district id with new one in cases timeseries
qui merge m:1 district_id using `new_dist_id'
assert _merge == 3
drop _merge district_id random_num
rename new_district_id district_id
rename num_cases new_num_cases

* Join onto event study dataframe, keeping only the dates that match since dates outside event windows were dropped
qui merge 1:1 district_id date using "$dirpath_final_reg_inputs/event_study_dataset_permtest_phase3.dta"
assert _merge == 3
drop _merge
	
* Replace the original cases time series with one from another randomly assigned district
drop num_cases
rename new_num_cases num_cases

* Run regression
areg num_cases Tmig_phase3* i.date, ///
	absorb(district_id)

* Prep dataset to store results
clear
set obs 61
gen T = .
gen beta_unadj = .

local obs = 1
forval t = `phase3_range' {
	qui replace T = `t' - `phase3_release' if _n == `obs'
	qui replace beta_unadj = _b[Tmig_phase3_`t'] if _n == `obs'
	local obs = `obs' + 1
}

* Note phase
gen phase = 3
gen seed = `i'

* Output
save "$dirpath_int_temp/RESULTS_phase3_eventstudy_unadjusted_seed`i'.dta", replace
}
}

******************************************************************
* Append unadjusted results
******************************************************************

di "Append unadjusted results"

qui {
* Load non-randomized results
cd "$dirpath_int_temp"
use "RESULTS_phase1_eventstudy_unadjusted.dta", clear
append using "RESULTS_phase2_eventstudy_unadjusted.dta"
append using "RESULTS_phase3_eventstudy_unadjusted.dta"

* Append permuted results
forvalues phase = 1(1)3 {
	forvalues i = 1(1) `num_permutations' {
		append using ///
		"RESULTS_phase`phase'_eventstudy_unadjusted_seed`i'.dta"
	}
}


* Set the seed in non-randomized regressions to 0 for looping purposes. This will be set back to missing at the end
count if missing(seed) 
assert r(N) == 61 * 3
replace seed = 0 if missing(seed)

* Save results
save "RESULTS_phases123_eventstudy_unadjusted.dta", replace
}

******************************************************************
* Adjust estimates for pre-release linear counterfactual
******************************************************************

di "Adjusting results for pre-release linear counterfactual"


* Loop through phases
forvalues phase = 1(1)3 {

* Loop through permutations
forvalues perm = 0(1)`num_permutations' {

* Monitor loop
di "Adjustment"
di "   Phase `phase'"
di "      Iteration: `perm' / `num_permutations'"

qui {
	
* Load results
use "RESULTS_phases123_eventstudy_unadjusted.dta", clear

* Keep phase in question
keep if phase == `phase'

* Keep permutation in question
keep if seed == `perm'

* Check that there are only t=-30 through t=30 observations
assert _N == 61
assert T >= -30 & T <= 30
assert !missing(T)

* Fit linear function to pre-release coefficients
count if T < 0
assert r(N) == 30
reg beta T if T < 0, noconstant
local theta = _b[T]
gen beta_adj = beta - (`theta' * (T + 1))
assert -0.000000001 < beta_adj & beta_adj < 0.000000001 if ///
	T == -1

* Get aggregate residual marginal cases: adjusted and unadjusted
keep if T >= 0
assert _N == 31
collapse (sum) beta_unadj beta_adj, by(phase seed)
assert _N == 1

* Save
if `perm' == 0 {
	replace seed = .
	save ///
		"RESULTS_phase`phase'_eventstudy_adjusted.dta", ///
		replace
}
else {
	save ///
	"RESULTS_phase`phase'_eventstudy_adjusted_seed`perm'.dta", ///
	replace
}

} // end quietly

} // end loop through permutations
} // end loop through phases

******************************************************************
* Append adjusted results
******************************************************************

* Load non-randomized results
cd "$dirpath_int_temp"
use "RESULTS_phase1_eventstudy_adjusted.dta", clear
append using "RESULTS_phase2_eventstudy_adjusted.dta"
append using "RESULTS_phase3_eventstudy_adjusted.dta"
* Append permuted results
forvalues phase = 1(1)3 {
	forvalues i = 1(1)`num_permutations' {
		append using ///
		"RESULTS_phase`phase'_eventstudy_adjusted_seed`i'.dta"
	}
}

* Check total observations
assert _N == (`num_permutations' * 3) + 3

******************************************************************
* Tidy and output
******************************************************************

gsort phase seed

compress *
save "$dirpath_final_results/RESULTS_permutation_inference_test_phases123.dta", replace

******************************************************************
* Clear temporary directory
******************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"

foreach file of local files {
	erase `file'
}
