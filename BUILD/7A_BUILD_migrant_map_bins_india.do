
* Get migration deciles for Mumbai migrant map

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
* Create migrant deciles and labels
******************************************************************

* Compute percentiles among non-excluded districts
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear

duplicates drop state district, force
keep state district mig0to5yrs_dist
rename mig0to5yrs_dist migrants

* Assign migrant quintiles
xtile q_migrants = migrants, n(10)

* Get quantile values

forvalues j = 1(1)8 {
	local i = `j' * 10
	egen p`i' = pctile(migrants), p(`i')
	replace p`i' = 50 if p`i' < 25
	replace q_migrants = 1 if migrants < 25
	replace p`i' = round(p`i', 50)
	local p`i'_rounded = string(p`i', "%10.0fc")
	di "Group: `i'"
	di "`p`i'_rounded'"
}
egen p90 = pctile(migrants), p(90)
replace p90 = round(p90, 50)
local p90_rounded = string(p90, "%10.0fc")
di "`p90_rounded'"

* Fix migrant counts to fit in rounded bins
sort migrants
replace q_migrants = 1 if migrants < p10
replace q_migrants = 2 if p10 <= migrants & migrants < p20
replace q_migrants = 3 if p20 <= migrants & migrants < p30
replace q_migrants = 4 if p30 <= migrants & migrants < p40
replace q_migrants = 5 if p40 <= migrants & migrants < p50
replace q_migrants = 6 if p50 <= migrants & migrants < p60
replace q_migrants = 7 if p60 <= migrants & migrants < p70
replace q_migrants = 8 if p70 <= migrants & migrants < p80
replace q_migrants = 9 if p80 <= migrants & migrants <= p90
replace q_migrants = 10 if p90 < migrants

* Labels
gen qval = ""
replace qval = "<`p10_rounded'" if q_migrants == 1
replace qval = ">`p90_rounded'" if q_migrants == 10
forvalues i = 1(1)8 {
	local first_num = `i' * 10
	//local first_name = 
	local second_num = `=`i'+1' * 10
	replace qval = ///
		"`p`first_num'_rounded'-`p`second_num'_rounded'" if ///
		q_migrants == `=`i'+1'
}
assert !missing(qval)
unique qval
assert r(unique) == 10

******************************************************************
* Tidy and output
******************************************************************

* Shorten names for shapefile driver
rename q_migrants q_mig
rename migrants mig_tc
rename state stname
rename district dtname

* Output
keep stname dtname q_mig qval mig_tc
compress *
save "$dirpath_int_map/covid19india_migrants_map_initialization.dta", replace
