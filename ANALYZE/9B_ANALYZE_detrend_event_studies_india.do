
* Apply "rotation" adjustment to India event study results

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
* Adjust totals
******************************************************************

* Loop through phases
forvalues phase = 1(1)3 {
	
* Loop through specifications
foreach spec of numlist 1/3 6/10 {
use "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3.dta", clear

if !((`spec' == 9 | `spec' == 10) & `phase' == 3) {
di "------------------------------------------------------"
di "Phase: `phase'"
di "Spec: `spec'"
di "------------------------------------------------------"

* keep phase in question
keep if phase == `phase'

* keep specification in question
keep if spec == `spec'

* Convert estimates to event time such that t=0 is the release date
replace T = T - 100
count if T < 0 & !missing(T)
di "check 0"
assert r(N) == 30
di "check 1"
assert -30 <= T & T <= 30 if !missing(T) & ///
	`spec' != 9 & `spec' != 10
di "check 2"
assert T == . if total == 1
di "check 3"
assert T != . if total != 1

* Convert total effect to be in marginal terms
foreach var of varlist beta se ci90_hi ci90_lo ci95_hi ci95_lo {
	replace `var' = `var' / tot_migrants if missing(T)
}

reg beta T if T < 0 & !missing(T), noconstant
local theta = _b[T]
gen beta_adj = beta - (`theta' * (T + 1))
di "check 4"
assert -0.000000001 < beta_adj & beta_adj < 0.000000001 if ///
	T == -1

* Get the residual area under the post-release curve (t=0 onwards) for the total marginal effect of migrants on cases
count if T >= 0 & !missing(T)
di "check 5"
assert r(N) == 31 if `spec' != 9 & `spec' != 10
egen marginal_effect = total(beta_adj) if ///
	T >= 0 & !missing(T)
sort marginal_effect
replace marginal_effect = marginal_effect[1]
di "check 6"
assert !missing(marginal_effect)
sort T

count if missing(T)
di "check 7"
assert r(N) == 1
di "check 8"
assert beta_adj == . if missing(T)
replace beta_adj = marginal_effect if missing(T)
drop marginal_effect

* Rename old estimates unadjusted
foreach var of varlist beta ci95_lo ci95_hi ci90_lo ci90_hi {
	rename `var' `var'_unadj
}

* Generate adjusted CIs
// 95%
gen ci95_lo_adj = beta_adj - 1.96*se
gen ci95_hi_adj = beta_adj + 1.96*se
  
// 90%
gen ci90_lo_adj = beta_adj - 1.645*se
gen ci90_hi_adj = beta_adj + 1.645*se

if `spec' == 9 | `spec' == 10 {
	keep if missing(T)
}
} // end of if clause

* Temporarily save
save "$dirpath_int_temp/RESULTS_phase`phase'_spec`spec'_adj.dta", replace


} // end loop through specs
} // end loop through phases

* Append results
cd "$dirpath_int_temp"
clear

forvalues phase = 1(1)3 {
	foreach spec of numlist 1/3 6/10 {
		if !((`spec' == 9 | `spec' == 10) & `phase' == 3) {
			append using ///
				"RESULTS_phase`phase'_spec`spec'_adj.dta"
		}
	}
}
gduplicates drop

* Tidy
gsort spec depvar phase -total T
order tot_migrants description, last

* Save
compress *
save "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3_adj.dta", replace

******************************************************************
* Clear temporary directory
******************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"

foreach file of local files {
	erase `file'
}
