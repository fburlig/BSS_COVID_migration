
* Apply "rotation" adjustment to cross-country comparison event study results

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

* Loop through specs
forval spec = 1/3 {

* Loop through countries
foreach feset of numlist 1/6 {
use "$dirpath_final_results/RESULTS_event_studies_countries.dta", clear

* Keep spec in question
keep if spec == `spec'

* keep country number in question
keep if feset == `feset'

* Convert estimates to event time such that t=0 is the release date
replace T = T - 100
count if T < 0 & !missing(T)
assert r(N) == 30
assert -30 <= T & T <= 30 if !missing(T)
assert T == . if tot_cases == 1
assert T != . if tot_cases != 1

reg beta T if T < 0 & !missing(T), noconstant
local theta = _b[T]
gen beta_adj = beta - (`theta' * (T + 1))
assert -0.000000001 < beta_adj & beta_adj < 0.000000001 if ///
	T == -1

* Get the residual area under the post-release curve (t=0 onwards) for the total marginal effect of migrants on cases
count if T >= 0 & !missing(T)
assert r(N) == 31
egen marginal_effect = total(beta_adj) if ///
	T >= 0 & !missing(T)
sort marginal_effect
replace marginal_effect = marginal_effect[1]
assert !missing(marginal_effect)
sort T

* Get total marginal effect
count if missing(T)
assert r(N) == 1
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

* Temporarily save
save "$dirpath_int_temp/RESULTS_country`feset'_spec`spec'_adj.dta", replace

} // end loop through countries
} // end loop through specs

* Append results
cd "$dirpath_int_temp"
clear
forval spec = 1/3 {
	foreach feset of numlist 1/6 {
		append using "RESULTS_country`feset'_spec`spec'_adj.dta"
	}
}

* Keep totals
keep if tot_cases == 1
drop T

* Tidy
gsort spec feset
order spec country_name feset se *_unadj *_adj tot_cases ban_duration tot_migrants

* Save
compress *
save "$dirpath_final_results/RESULTS_event_studies_countries_adj.dta", replace


******************************************************************
* Clear temporary directory
******************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"

foreach file of local files {
	erase `file'
}
