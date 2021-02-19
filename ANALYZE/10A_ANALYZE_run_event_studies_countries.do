
* Run event studies for cross-country comparison

******************************************************************
* Initialize directory paths 
******************************************************************

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
* Release date macros
******************************************************************

local release_ke = date("2020/07/07", "YMD")
local release_id = date("2020/05/07", "YMD")
local release_ph = date("2020/05/30", "YMD")
local release_za = date("2020/05/01", "YMD")
local release_in_p1 = date("2020/05/08", "YMD")
local release_cn = date("2020/04/08", "YMD")

******************************************************************
* Initialize dataset for storing results
******************************************************************

gen beta_tot_100 = .
gen se_tot_100 = .
local min_coef = 70
local max_coef = 130
local date_window = 30
forvalues t = `min_coef'/`max_coef' {
	gen beta_`t' = .
	gen se_`t' = .
}
gen feset = .
gen fe = ""
gen nobs = .
gen r2 = .
set obs 200
local row = 1
gen tot_migrants = .
gen spec = .

compress *
save "$dirpath_int_temp/country_regs_store_results.dta", replace

******************************************************************
* Iterate through specifications
******************************************************************

forvalues spec = 1/3 {

* Load dataset to store results
use "$dirpath_int_temp/country_regs_store_results.dta", clear
	
* Label regression versions
forvalues feset = 1/6 {
		  
if "`feset'" == "1" {
	replace fe = "kenya, admin1, admin unit FE" in `row'
}
if "`feset'" == "2" {
	replace fe = "indonesia, admin1, admin unit FE" in `row'
}
if "`feset'" == "3" {
	replace fe = "philippines, admin2, admin unit FE" in `row'
}
if "`feset'" == "4" {
	replace fe = "south africa, admin1, admin unit FE" in `row'
}
if "`feset'" == "5" {
	replace fe = "india, admin1, admin unit FE" in `row'
}
if "`feset'" == "6" {
	replace fe = "china, admin1, admin unit FE" in `row'
}

di "`row'"

* Load data
preserve

* Load non-india data
use "$dirpath_final_reg_inputs/cleaned_non_india_covid_data_migrants.dta", clear

* Append India data
append using "$dirpath_final_reg_inputs/cleaned_india_covid_data_for_country_regs.dta"

* keep desired country
if "`feset'" == "1" {
	keep if country_name == "kenya"
	assert !missing(migrants)
	local tot_migrants = tot_migrants[1]
	assert (`release_ke' - `date_window' <= date) & ///
		(date <= `release_ke' + `date_window')
	gunique date
	assert r(unique) == (`date_window' * 2) + 1
}
if "`feset'" == "2" {
	keep if country_name == "indonesia"
	assert !missing(migrants)
	local tot_migrants = tot_migrants[1]
	assert (`release_id' - `date_window' <= date) & ///
		(date <= `release_id' + `date_window')
	gunique date
	assert r(unique) == (`date_window' * 2) + 1
}
if "`feset'" == "3" {
	keep if country_name == "philippines"
	assert !missing(migrants)
	local tot_migrants = tot_migrants[1]
	assert (`release_ph' - `date_window' <= date) & ///
		(date <= `release_ph' + `date_window')
	gunique date
	assert r(unique) == (`date_window' * 2) + 1
}
if "`feset'" == "4" {
	keep if country_name == "south africa"
	assert !missing(migrants)
	local tot_migrants = tot_migrants[1]
	assert (`release_za' - `date_window' <= date) & ///
		(date <= `release_za' + `date_window')
	gunique date
	assert r(unique) == (`date_window' * 2) + 1
}
if "`feset'" == "5" {
	keep if country_name == "india"
	assert !missing(migrants)
	assert migrants == 0 if phase1 == 0
	local tot_migrants = tot_migrants[1]
	assert (`release_in_p1' - `date_window' <= date) & ///
		(date <= `release_in_p1' + `date_window')
	gunique date
	assert r(unique) == (`date_window' * 2) + 1
}
if "`feset'" == "6" {
	keep if country_name == "china"
	assert !missing(migrants)
	local tot_migrants = tot_migrants[1]
	assert (`release_cn' - `date_window' <= date) & ///
		(date <= `release_cn' + `date_window')
	gunique date
	assert r(unique) == (`date_window' * 2) + 1
}

* Create date counter starting from 1
bysort region_code (date): ///
	gen date_stata = _n 
	
// get number of admin units
unique region_code
local num_regions = r(unique)

// 1) Create calendar day dummies centered at event date == 100
qui gen T = 100 + date_stata - 31
assert T <= 130 & T >= 70
assert !missing(T)
tab T, gen(T_)

* Rename variables to be centered at event date
unique T
local max_counter = r(unique)
forvalues i = `max_counter'(-1)1 {
	rename T_`i' T_`=`i'+69'
}

// migrant event study coefficients
forval t = `min_coef'(1)`max_coef' {
	gen Tmig_`t' = T_`t' * migrants
	drop T_`t'
}

* Omit the day before travel bans were ended
order Tmig_99, last

* Run main event study regression
di "--------------------------------------------------"
di "Spec number: `spec'"
di "Country number: `feset'"
di "--------------------------------------------------"

* Main spec, with and without migrants
if `spec' == 1 {
reghdfe num_cases Tmig_*, ///
	absorb(region_code date) vce(cluster region_code date)
}
* Main spec without date FE
if `spec' == 2 {
reghdfe num_cases Tmig_*, ///
	absorb(region_code) vce(cluster region_code date)
}
* Main spec without date FE, with date + date^2 polynomial
if `spec' == 3 {
reghdfe num_cases Tmig_* date date2, ///
	absorb(region_code) vce(cluster region_code date)
}

restore

forvalues t = `min_coef'/`max_coef' {
	qui replace beta_`t' = _b[Tmig_`t'] in `row'
	qui replace se_`t' = _se[Tmig_`t'] in `row'
}

* Aggregate post-period coefficients
lincom(((Tmig_130 + Tmig_129 + Tmig_128 + Tmig_127 + Tmig_126 + Tmig_125 + Tmig_124 + Tmig_123 + Tmig_122 + Tmig_121 + Tmig_120 + Tmig_119 + Tmig_118 + Tmig_117 + Tmig_116 + Tmig_115 + Tmig_114 + Tmig_113 + Tmig_112 + Tmig_111 + Tmig_110 + Tmig_109 + Tmig_108 + Tmig_107 + Tmig_106 + Tmig_105 + Tmig_104 + Tmig_103 + Tmig_102 + Tmig_101 + Tmig_100)))

qui replace beta_tot_100 = r(estimate) in `row'
qui replace se_tot_100 = r(se) in `row'

* Total migrants
replace tot_migrants = `tot_migrants' in `row'

* Grab misc info
qui replace feset = `feset' in `row'
qui replace nobs = e(N)  in `row'
qui replace r2 = e(r2) in `row'
local row = `row' + 1
 
} // end loop through countries

* Make dataset long
drop nobs r2
drop if fe == ""
greshape long beta se, by(fe feset) keys(T) string
drop if missing(beta)

* Country
gen country_name = ""
replace country_name = "kenya" if feset == 1
replace country_name = "indonesia" if feset == 2
replace country_name = "philippines" if feset == 3
replace country_name = "south africa" if feset == 4
replace country_name = "india" if feset == 5
replace country_name = "china" if feset == 6
assert country_name != ""

* Duration of travel restrictions
gen ban_duration = .
replace ban_duration = ///
	`release_ke' - date("2020/04/06", "YMD") if ///
	feset == 1
replace ban_duration = ///
	`release_id' - date("2020/04/24", "YMD") if ///
	feset == 2
replace ban_duration = ///
	`release_ph' - date("2020/03/15", "YMD") if ///
	feset == 3
replace ban_duration = ///
	`release_za' - date("2020/03/26", "YMD") ///
	if feset == 4
replace ban_duration = ///
	`release_in_p1' - date("2020/03/25", "YMD") if ///
	feset == 5
replace ban_duration = ///
	`release_cn' - date("2020/01/23", "YMD") if ///
	feset == 6
assert !missing(ban_duration)

* Destring daily coefficients
gen tot_cases = 0
replace tot_cases = 1 if substr(T, 2, 3) == "tot"
replace T = substr(T, -3, 3)
replace T = substr(T, -2, 2) if substr(T, 1, 1) == "_"
destring T, replace
replace T = . if tot_cases == 1

* 95% confidence intervals
gen ci95_lo = beta - 1.96*se
gen ci95_hi = beta + 1.96*se
  
* 90% confidence intervals
gen ci90_lo = beta - 1.645*se
gen ci90_hi = beta + 1.645*se 

* Mark the spec
replace spec = `spec'

* Save
save "$dirpath_int_temp/RESULTS_country_event_studies_spec`spec'.dta", replace

} // end loop through specifications

* Stack specs
clear
cd "$dirpath_int_temp"
forvalues spec = 1/3 {
	append using "RESULTS_country_event_studies_spec`spec'.dta"
}

* Tidy
sort spec feset T
drop fe
order spec country_name feset T beta se ci95_lo ci95_hi ///
	ci90_lo ci90_hi tot_cases tot_migrants ban_duration 

* Output
compress *
save "$dirpath_final_results/RESULTS_event_studies_countries.dta", replace

