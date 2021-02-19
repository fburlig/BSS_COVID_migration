
***** Merge COVID, migration, and population data for India

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
* Prep cleaned covid19india data
****************************************************************

* Prep cleaned covid19india data
use "$dirpath_int_covid/covid19india_data_cleaned.dta", clear
// drop identifiers: will remake at end
drop state_id district_id
// clean names
foreach var of varlist state district {
	replace `var' = upper(`var')
	replace `var' = strtrim(`var')
	replace `var' = stritrim(`var')
}
// number of states to compare to state-wise migrant counts
gunique state
local num_states_covid = r(unique)

* temporarily save
gsort state district date
save "$dirpath_int_temp/covid19india_data_cleaned_temp.dta", replace

****************************************************************
* Prep worldpop data
****************************************************************

* Load data
use "$dirpath_int_worldpop/india_worldpop.dta", clear
// keep necessary variables
drop country_name
// rename variables
rename subregion1_name state
rename subregion2_name district
rename population worldpop2020
// clean names
foreach var of varlist state district {
	replace `var' = upper(`var')
	replace `var' = strtrim(`var')
	replace `var' = stritrim(`var')
}
// temporarily save
save "$dirpath_int_temp/india_worldpop_temp.dta", replace

****************************************************************
* Prep state-wise migrant counts in the last 4 years
****************************************************************

* Load data
use "$dirpath_int_census/interstate_migrant_counts_india.dta", clear
rename subregion1_name state
rename migrants mig0to4yrs_state
// check that the number of states is the same as in the covid data
gunique state
assert r(unique) == `num_states_covid'
// clean names
foreach var of varlist state {
	replace `var' = upper(`var')
	replace `var' = strtrim(`var')
	replace `var' = stritrim(`var')
}
// temporarily save
save "$dirpath_int_temp/interstate_migrant_counts_india_temp.dta", replace

****************************************************************
* Merge in worldpop and state-wise counts datasets
****************************************************************

* Load covid data
cd "$dirpath_int_temp"
use "covid19india_data_cleaned_temp.dta", clear

* Merge in worldpop 2020 population data
// obs before merging to check after merge
local obs_pre_merge = _N
// merge
merge m:1 state district using ///
	"india_worldpop_temp.dta"
// checks
assert _merge == 3
drop _merge
assert `obs_pre_merge' == _N
* output data for Mumbai for hotspot cases per capita figure and Mumbai case positivity rate figure
preserve
keep if district == "MUMBAI"
keep state district date num_cases num_tested worldpop2020
replace state = lower(state)
replace district = lower(district)
rename state subregion1_name
rename district subregion2_name
rename worldpop2020 population
gen country_name = "india"
compress *
save "$dirpath_int_covid/Mumbai_cleaned_case_timeseries.dta", replace
restore
// drop Mumbai
drop if district == "MUMBAI"

* Merge in state-wise migrant counts in the last 4 years
// obs before merging to check after merge
local obs_pre_merge = _N
// merge
merge m:1 state using ///
	"interstate_migrant_counts_india_temp.dta"
// checks
assert _merge == 3
drop _merge
assert `obs_pre_merge' == _N

****************************************************************
* Calculate migrant counts
****************************************************************

* Distribute counts within each state by population
preserve
// keep unique districts
keep state district worldpop2020 mig0to4yrs_state
gduplicates drop state district, force
// get population shares by state
bys state: egen tot_p = total(worldpop2020)
gen pop_share = worldpop2020 / tot_p
bys state: egen temp = total(pop_share)
assert 0.99 < temp & temp < 1.01
// get migrants in each district
gen mig0to4yrs_dist = pop_share * mig0to4yrs_state
// temporarily save
keep state district mig0to4yrs_dist
tempfile migs 
save `migs', replace
restore
// merge onto to master data
merge m:1 state district using `migs'
assert _merge == 3
drop _merge

* Create phase indicators
gen in_state = state == "MAHARASHTRA"
gen phase2 = (in_state == 1 & (district == "THANE" | ///
	district == "PALGHAR" | district == "RAIGARH"))
gen phase3 = in_state == 1 & phase2 == 0
gen phase = .
replace phase = 1 if in_state == 0
replace phase = 2 if phase2 == 1
replace phase = 3 if phase3 == 1
assert !missing(phase)

replace mig0to4yrs_dist = mig0to4yrs_dist * 1.25
rename mig0to4yrs_dist mig0to5yrs_dist
drop mig0to4yrs_state

****************************************************************
* Drop districts we exclude from the sample
****************************************************************

* Number of districts before dropping. There should be 14 less after these drops
gunique state district
local pre_drop_unique = r(unique)

* Outbreaks by may1 were in the 99th percentile
drop if (district == "PUNE" & state == "MAHARASHTRA") | ///
	(district == "AHMADABAD" & state == "GUJARAT") | ///
	(district == "INDORE" & state == "MADHYA PRADESH") | ///
	district == "DELHI"
	
* Urban pop >= 80% of total pop in 2011 census
drop if state == "PUDUCHERRY" & district == "MAHE"
drop if state == "PUDUCHERRY" & district == "YANAM"
drop if state == "TAMIL NADU" & district == "CHENNAI"
drop if state == "WEST BENGAL" & district == "KOLKATA"
drop if state == "CHANDIGARH" & district == "CHANDIGARH"
drop if state == "JAMMU & KASHMIR" & district == "SRINAGAR"
drop if state == "KARNATAKA" & district == "BANGALORE"
drop if state == "DAMAN & DIU" & district == "DAMAN"
drop if state == "MADHYA PRADESH" & district == "BHOPAL"
drop if state == "TAMIL NADU" & district == "KANNIYAKUMARI"

* Check the correct number of districts were dropped
gunique state district
assert r(unique) == (`pre_drop_unique' - 14)

****************************************************************
* Organize, check, and output
****************************************************************

* Sort
gsort state district date

* District and state identifiers
egen district_id = group(state district)
egen state_id = group(state)

* Date squarred
gen date2 = date^2

* Week
gen week = week(date)

* Phase 1 indicator
gen phase1 = phase == 1
drop in_state

* Check phase indicators
assert phase1 == 1 if phase == 1
assert phase1 == 1 if state != "MAHARASHTRA"
assert phase2 == 1 if phase == 2
assert phase2 == 1 if state == "MAHARASHTRA" & ///
	(district == "THANE" | district == "PALGHAR" | ///
	district == "RAIGARH")
assert phase3 == 1 if phase == 3
assert phase3 == 1 if state == "MAHARASHTRA" & ///
	!(district == "THANE" | district == "PALGHAR" | ///
	district == "RAIGARH")
assert !missing(phase1) & !missing(phase2) & !missing(phase3)

* Check district identifier
gunique state district
local nunique = r(unique)
gunique district_id
assert r(unique) == `nunique'

* Check each district has the same number of observations
gunique date
assert _N == `nunique' * r(unique)
	
* Tidy
order state state_id district district_id date date2 week ///
	num_cases num_deaths num_tested num_tested_1wk ///
	worldpop2020 mig0to5yrs_dist phase phase1 phase2 phase3
	
* Save
compress *
save "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", replace

