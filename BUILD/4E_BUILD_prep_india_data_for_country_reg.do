
* Prepare India COVID data for cross-country comparison

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
* Load and subset data
******************************************************************

* Load data
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear

* Make names lowercase
replace state = lower(state)
replace district = lower(district)

* Rename variables to match non-india data
rename district subregion2_name
rename district_id subregion2_code
rename state subregion1_name
rename state_id subregion1_code

* Country name
gen country_name = "india"

******************************************************************
* Get total phase 1 migrants
******************************************************************

gen temp = 1
preserve
drop if subregion1_name == "maharashtra"
gduplicates drop subregion1_name subregion2_name, force
egen tot_migrants = total(mig0to5yrs_dist)
keep temp tot_migrants
gduplicates drop
tempfile migs
save `migs', replace
restore
merge m:1 temp using `migs'
assert _merge == 3
drop _merge

******************************************************************
* Tidy and output
******************************************************************

rename mig0to5yrs_dist migrants

gen travel_rls = 0
replace travel_rls = 1 if date >= date("2020/05/08", "YMD")

gen date_stata = date - date("2020/03/01", "YMD")
drop date_stata

assert !missing(migrants)
assert !missing(tot_migrants)
assert !missing(country_name)
assert !missing(subregion1_name)
assert !missing(subregion2_name)
assert !missing(date)

egen region_code = group(subregion1_name subregion2_name)

* Set phase 2 and phase 3 migrants to 0
replace migrants = 0 if phase1 == 0
assert !missing(migrants)
assert migrants > 0 if phase1 == 1

* Keep dates within 30 days of phase 1 release
keep if date("2020/05/08", "YMD") - 30 <= date & ///
	date <= date("2020/05/08", "YMD") + 30
gunique(date)
assert r(unique) == 61

* Tidy
order subregion1_name subregion1_code subregion2_name ///
	subregion2_code region_code date date2 ///
	num_cases num_deaths num_tested num_tested_1wk ///
	worldpop2020 migrants phase phase1 phase2 phase3

* Output
compress *
save "$dirpath_final_reg_inputs/cleaned_india_covid_data_for_country_regs.dta", replace
