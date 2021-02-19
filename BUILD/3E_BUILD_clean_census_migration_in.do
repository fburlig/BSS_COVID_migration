
* Clean census data for India

***** SETUP:
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

***************************************************************

*** V1: just mumbai
//import excel using "`f'", firstrow clear
import excel using "$dirpath_raw_census/india/d2/DS-2700-D02-MDDS.XLSX", clear

* Keep total people in destination/enumerated and origin state
keep if F == "Total" & G == "Total"

* Keep necessary variables
keep D E K N
	
* Rename variables
rename D enumerated_area
rename E origin_state
rename K migrants_0_1_yrs
rename N migrants_1_4_yrs

* Make lower case
replace enumerated_area = lower(enumerated_area)
replace origin_state = lower(origin_state)
	
* Keep those enumerated in mumbai + mumbai suburban
keep if enumerated_area == "mumbai suburban" | ///
	enumerated_area == "mumbai"
	
* Keep destination states
keep if origin_state == "jammu & kashmir" | ///
	origin_state == "himachal pradesh" | ///
	origin_state == "punjab" | ///
	origin_state == "chandigarh" | ///
	origin_state == "uttarakhand" | ///
	origin_state == "haryana" | ///
	origin_state == "nct of delhi" | ///
	origin_state == "rajasthan" | ///
	origin_state == "uttar pradesh" | ///
	origin_state == "bihar" | ///
	origin_state == "sikkim" | ///
	origin_state == "arunachal pradesh" | ///
	origin_state == "nagaland" | ///
	origin_state == "manipur" | ///
	origin_state == "mizoram" | ///
	origin_state == "tripura" | ///
	origin_state == "meghalaya" | ///
	origin_state == "assam" | ///
	origin_state == "west bengal" | ///
	origin_state == "jharkhand" | ///
	origin_state == "odisha" | ///
	origin_state == "chhattisgarh" | ///
	origin_state == "madhya pradesh" | ///
	origin_state == "gujarat" | ///
	origin_state == "daman & diu" | ///
	origin_state == "dadra & nagar haveli" | ///
	origin_state == "andhra pradesh" | ///
	origin_state == "karnataka" | ///
	origin_state == "goa" | ///
	origin_state == "kerala" | ///
	origin_state == "tamil nadu" | ///
	origin_state == "puducherry" | ///
	origin_state == "in other districts of the state of enumeration"
	
// note that from the d1 birth-migration data, there is no mumbai<-->mumbai suburban migration listed
replace origin_state = "maharashtra" if origin_state == "in other districts of the state of enumeration"

* Get total migrants 0_4 years
destring migrants_0_1_yrs migrants_1_4_yrs, replace
assert !missing(migrants_0_1_yrs) & !missing(migrants_1_4_yrs)
gen migrants_0_4_yrs = migrants_0_1_yrs + migrants_1_4_yrs
drop migrants_0_1_yrs migrants_1_4_yrs

* Combine mumbai and mumbai suburban
collapse (sum) migrants_0_4_yrs, by(origin_state)

* Split andhra pradesh and telangana by population
// add observation for telangana
local extra_obs = _N + 1
set obs `extra_obs'
replace origin_state = "telangana" if _n == `extra_obs'
// get migrants in AP
preserve
keep if origin_state == "andhra pradesh"
local migrant_count = migrants_0_4_yrs[1]
restore
// replace AP and TG counts with a pop weight of AP's migrants
local pop_TG_outof_AP = 0.4262 //0.416
replace migrants_0_4_yrs = ///
	`pop_TG_outof_AP' * `migrant_count' if ///
	origin_state == "telangana"
replace migrants_0_4_yrs = ///
	(1 - `pop_TG_outof_AP') * `migrant_count' if ///
	origin_state == "andhra pradesh"
	
* Above for Jammu & kashmir and Ladakh
// add observation for ladakh
local extra_obs = _N + 1
set obs `extra_obs'
replace origin_state = "ladakh" if _n == `extra_obs'
// get migrants in AP
preserve
keep if origin_state == "jammu & kashmir"
local migrant_count = migrants_0_4_yrs[1]
restore
// replace AP and TG counts with a pop weight of AP's migrants
local pop_LD_outof_JK = .0199 //.0219
replace migrants_0_4_yrs = ///
	`pop_LD_outof_JK' * `migrant_count' if ///
	origin_state == "ladakh"
replace migrants_0_4_yrs = ///
	(1 - `pop_LD_outof_JK') * `migrant_count' if ///
	origin_state == "jammu & kashmir"

* Combine dadra and nagar haveli with daman and diu
replace origin_state = "daman & diu" if ///
	origin_state == "dadra & nagar haveli"

* Collapse again with above changes
collapse (sum) migrants_0_4_yrs, by(origin_state)

* Rename delhi
replace origin_state = "delhi" if origin_state == "nct of delhi"

* Prepare for output
rename origin_state subregion1_name
rename migrants_0_4_yrs migrants

* Output
save "$dirpath_int_census/interstate_migrant_counts_india.dta", replace

