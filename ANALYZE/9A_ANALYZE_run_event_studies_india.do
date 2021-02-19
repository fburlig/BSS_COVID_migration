
* Run event studies for mumbai specifications

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
* Get the number of migrants in each phase for different migrant specifications
****************************************************************

* Census only match to country reg, full sample (specs without testing control)
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear
// get migrant counts
gunique district_id
local unique_districts_all = r(unique)
duplicates drop state district, force
rename mig0to5yrs_dist num_migrants
collapse (sum) num_migrants, by(phase)
sort phase
local phase1_migrants_cns5yr_all = num_migrants[1]
local phase2_migrants_cns5yr_all = num_migrants[2]
local phase3_migrants_cns5yr_all = num_migrants[3]

* Census only match to country reg, full sample (specs without testing control)
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear
// drop units without testing data
bysort state district: ///
	gen obs_per_unit = _N
bysort state district: ///
	gen missing_1wk_tests = 1 if missing(num_tested_1wk)
by state district: ///
	egen tot_missing_tests = total(missing_1wk_tests)
drop if tot_missing_tests == obs_per_unit
assert state != "WEST BENGAL"
// get migrant counts
gunique district_id
local unique_districts_wtst = r(unique)
duplicates drop state district, force
rename mig0to5yrs_dist num_migrants
collapse (sum) num_migrants, by(phase)
sort phase
local phase1_migrants_cns5yr_wtst = num_migrants[1]
local phase2_migrants_cns5yr_wtst = num_migrants[2]
local phase3_migrants_cns5yr_wtst = num_migrants[3]

clear

* Release dates by phase
local phase1_release = date("2020/05/08", "YMD")
local phase2_release = date("2020/06/05", "YMD")
local phase3_release = date("2020/08/20", "YMD")


* Looping through phases
forvalues phase = 1(1)3 {
	
clear
	
* Create variables to store misc terms
gen feset = .
gen fe = ""
gen nobs = .
gen r2 = .
gen num_migrants = .
gen phase = .
set obs 200
local row = 1
	
* Create terms to store daily coefficients
forval t = 33/245 {
	gen beta_phase`phase'_`t' = .
	gen se_phase`phase'_`t' = .
}

* Create terms to store aggregated coefficients
gen beta_tot_phase`phase'_100 = .
gen se_tot_phase`phase'_100 = .

* Looping through regression specs 
foreach feset of numlist 1/3 6/10 {
if "`feset'" == "1" {
	replace fe = "cases, FE: district + day; controls = none; migrants: census last 5 years by pop; clustering: district + day" in `row'
}
if "`feset'" == "2" {
	replace fe = "cases, FE: district; controls = none; migrants: census last 5 years by pop; clustering: district + day" in `row'
}
if "`feset'" == "3" {
	replace fe = "cases, FE: district; controls = day + day^2; migrants: census last 5 years by pop; clustering: district + day" in `row'
}
if "`feset'" == "6" {
	replace fe = "cases, FE: district + day; controls = none; migrants: none; clustering: district + day" in `row'
}
if "`feset'" == "7" {
	replace fe = "cases, FE: district + day; controls = tests; migrants: census last 5 years by pop; clustering: district + day" in `row'
}
if "`feset'" == "8" {
	replace fe = "deaths; FE: district + day; controls = none; migrants: census last 5 years by pop; clustering: district + day" in `row'
}
if "`feset'" == "9" {
	replace fe = "cases, FE: district + day; controls = none; migrants: census last 5 years by pop; clustering: district + day, common endpoint" in `row'
}
if "`feset'" == "10" {
	replace fe = "deaths, FE: district + day; controls = none; migrants: census last 5 years by pop; clustering: district + day, common endpoint" in `row'
}

* Begin regressions
preserve
	
* Load data
use "$dirpath_final_reg_inputs/cleaned_countryreg_india_equiv_data.dta", clear

// spec with testing controls: drop regions that don't report tets
if "`feset'" == "7" {
	bysort state district: ///
		gen obs_per_unit = _N
	bysort state district: ///
		gen missing_1wk_tests = 1 if missing(num_tested_1wk)
	by state district: ///
		egen tot_missing_tests = total(missing_1wk_tests)
	drop if tot_missing_tests == obs_per_unit
	assert state != "WEST BENGAL"
}

rename mig0to5yrs_dist num_migrants
gen date_stata = date
replace date_stata = date_stata - 21976 + 1

* Create event study coefficients
// 1) create calendar day dummy
//  date_state = 1 first day of data, 68 on may 8: the day inter-state opened up
qui gen T = 100 + date_stata - 68
tab T, gen(T_)
// rename dummies to be centered on may8 = 100
forval i = 213(-1)1 {
	local j = `i' + (100 - 68)
	rename T_`i' T_`j'
}
// 2) multiply calendar dummy by the number of migrants
forval t = 33/245 {
	if "`feset'" != "6" { // migrants versions
		gen Tmig_phase`phase'_`t' = ///
			T_`t' * phase`phase' * num_migrants
	}
	if "`feset'" == "6" { // no migrants version
		gen Tmig_phase`phase'_`t' = ///
			T_`t' * phase`phase'
	}
		drop T_`t'
	}
	
* Prepare sample
if "`feset'" != "9" & "`feset'" != "10" {
if `phase' == 1 {
	// omit pre-release date (t=-1)
	order Tmig_phase1_99, last
	// drop coefficients for this phase outside the sample window
	foreach i of numlist 33/69 131/245 {
		drop Tmig_phase1_`i'
	}
}
if `phase' == 2 {
	order Tmig_phase2_127, last
	foreach i of numlist 33/97 159/245 {
		drop Tmig_phase2_`i' 
}
}
if `phase' == 3 {
	order Tmig_phase3_203, last
	foreach i of numlist 33/173 235/245 {
		drop Tmig_phase3_`i' 
	}
}
	
* Limit sample to +/- 30 days from release date
keep if date >= `phase`phase'_release' - 30 & ///
date <= `phase`phase'_release' + 30
gunique date
assert r(unique) == 61
}


if "`feset'" == "9" | "`feset'" == "10" {
if `phase' == 1 {
	// omit pre-release date (t=-1)
	order Tmig_phase1_99, last
	// drop coefficients for this phase outside the beginning of the sample window
	foreach i of numlist 33/69 154/245 {
		drop Tmig_phase1_`i'
	}
}
if `phase' == 2 {
	order Tmig_phase2_127, last
	foreach i of numlist 33/97 154/245 {
		drop Tmig_phase2_`i' 
}
}
if `phase' == 3 {
	di "skip"
}
	
* Limit sample to - 30 days from release date to jun 30
keep if date >= `phase`phase'_release' - 30 & ///
date <= date("2020/06/30", "YMD")
//gunique date
//assert r(unique) == 61
}


di "----------------------------------------------------------"
di "{bf:Phase: `phase'}"
di "{bf:Spec: `feset'}"
di "----------------------------------------------------------"

* Run regressions
if "`feset'" == "1" | "`feset'" == "6" {
count if state == "WEST BENGAL"
assert r(N) > 0
gunique district_id
assert r(unique) == `unique_districts_all'
reghdfe num_cases Tmig_phase`phase'*, ///
	absorb(district_id date) vce(cluster district_id date)
}
if "`feset'" == "2" {
count if state == "WEST BENGAL"
assert r(N) > 0
gunique district_id
assert r(unique) == `unique_districts_all'
reghdfe num_cases Tmig_phase`phase'*, ///
	absorb(district_id) vce(cluster district_id date)
}
if "`feset'" == "3" {
count if state == "WEST BENGAL"
assert r(N) > 0
gunique district_id
assert r(unique) == `unique_districts_all'
reghdfe num_cases Tmig_phase`phase'* date date2, ///
	absorb(district_id) vce(cluster district_id date)
}
if "`feset'" == "7" {
assert state != "WEST BENGAL"
gunique district_id
assert r(unique) == `unique_districts_wtst'
reghdfe num_cases Tmig_phase`phase'* num_tested_1wk, ///
	absorb(district_id date) vce(cluster district_id date)
}
if "`feset'" == "8" {
count if state == "WEST BENGAL"
assert r(N) > 0
gunique district_id
assert r(unique) == `unique_districts_all'
reghdfe num_deaths Tmig_phase`phase'*, ///
	absorb(district_id date) vce(cluster district_id date)
}
if "`feset'" == "9" {
if `phase' != 3 {
count if state == "WEST BENGAL"
assert r(N) > 0
gunique district_id
assert r(unique) == `unique_districts_all'
tab date
reghdfe num_cases Tmig_phase`phase'*, ///
	absorb(district_id date) vce(cluster district_id date)
}
if `phase' == 3 {
	di "skip"
}
}
if "`feset'" == "10" {
if `phase' != 3 {
count if state == "WEST BENGAL"
assert r(N) > 0
gunique district_id
assert r(unique) == `unique_districts_all'
tab date
reghdfe num_deaths Tmig_phase`phase'*, ///
	absorb(district_id date) vce(cluster district_id date)
}
if `phase' == 3 {
	di "skip"
}
}

restore



* Store daily coefficients and se
if "`feset'" != "9" & "`feset'" != "10" {
if `phase' == 1 {
	forval t = 70/130 {
		replace beta_phase1_`t' = _b[Tmig_phase1_`t'] in `row'
		replace se_phase1_`t' = _se[Tmig_phase1_`t'] in `row'
	}
}
if `phase' == 2 {
	forval t = 98/158 {
		replace beta_phase2_`t' = _b[Tmig_phase2_`t'] in `row'
		replace se_phase2_`t' = _se[Tmig_phase2_`t'] in `row'
	}
}
if `phase' == 3 {
	forval t = 174/234 {
		replace beta_phase3_`t' = _b[Tmig_phase3_`t'] in `row'
		replace se_phase3_`t' = _se[Tmig_phase3_`t'] in `row'
	}
}
}

if "`feset'" == "9" | "`feset'" == "10" {
if `phase' == 1 {
	forval t = 70/153 {
		replace beta_phase1_`t' = _b[Tmig_phase1_`t'] in `row'
		replace se_phase1_`t' = _se[Tmig_phase1_`t'] in `row'
	}
}
if `phase' == 2 {
	forval t = 98/153 {
		replace beta_phase2_`t' = _b[Tmig_phase2_`t'] in `row'
		replace se_phase2_`t' = _se[Tmig_phase2_`t'] in `row'
	}
}

if `phase' == 3 {
	di "skip"
}
}

* Store the phase number
replace phase = `phase' in `row'

* Store the number of migrants in a phase
if "`feset'" != "6" & "`feset'" != "7" { // with migrants
local phase`phase'_migrants = `phase`phase'_migrants_cns5yr_all'
replace num_migrants = `phase`phase'_migrants' in `row'
}
if "`feset'" == "6" { // no migrants, just multiply by 1
local phase`phase'_migrants = 1
replace num_migrants = 1 in `row'
}
if "`feset'" == "7" { // with migrants, only regions with tests
local phase`phase'_migrants = `phase`phase'_migrants_cns5yr_wtst'
replace num_migrants = `phase`phase'_migrants' in `row'
}
di `phase`phase'_migrants'
	
* Aggregate coefficients = sum(post release) * num_migrants = total excess cases
if "`feset'" != "9" & "`feset'" != "10" {
if `phase' == 1 {
	lincom((Tmig_phase1_100 + Tmig_phase1_101 + Tmig_phase1_102 + Tmig_phase1_103 + Tmig_phase1_104 + Tmig_phase1_105 + Tmig_phase1_106 + Tmig_phase1_107 + Tmig_phase1_108 + Tmig_phase1_109 + Tmig_phase1_110 + Tmig_phase1_111 + Tmig_phase1_112 + Tmig_phase1_113 + Tmig_phase1_114 + Tmig_phase1_115 + Tmig_phase1_116 + Tmig_phase1_117 + Tmig_phase1_118 + Tmig_phase1_119 + Tmig_phase1_120 + Tmig_phase1_121 + Tmig_phase1_122 + Tmig_phase1_123 + Tmig_phase1_124 + Tmig_phase1_125 + Tmig_phase1_126 + Tmig_phase1_127 + Tmig_phase1_128 + Tmig_phase1_129 + Tmig_phase1_130)*`phase1_migrants')

	qui replace beta_tot_phase1_100 = r(estimate) in `row'
	qui replace se_tot_phase1_100 = r(se) in `row'
}

if `phase' == 2 {
	lincom((Tmig_phase2_128 + Tmig_phase2_129 + Tmig_phase2_130 + Tmig_phase2_131 + Tmig_phase2_132 + Tmig_phase2_133 + Tmig_phase2_134 + Tmig_phase2_135 + Tmig_phase2_136 + Tmig_phase2_137 + Tmig_phase2_138 + Tmig_phase2_139 + Tmig_phase2_140 + Tmig_phase2_141 + Tmig_phase2_142 + Tmig_phase2_143 + Tmig_phase2_144 + Tmig_phase2_145 + Tmig_phase2_146 + Tmig_phase2_147 + Tmig_phase2_148 + Tmig_phase2_149 + Tmig_phase2_150 + Tmig_phase2_151 + Tmig_phase2_152 + Tmig_phase2_153 + Tmig_phase2_154 + Tmig_phase2_155 + Tmig_phase2_156 + Tmig_phase2_157 + Tmig_phase2_158)*`phase2_migrants')
	
	qui replace beta_tot_phase2_100 = r(estimate) in `row'
	qui replace se_tot_phase2_100 = r(se) in `row'
}
	
if `phase' == 3 {
	lincom((Tmig_phase3_204 + Tmig_phase3_205 + Tmig_phase3_206 + Tmig_phase3_207 + Tmig_phase3_208 + Tmig_phase3_209 + Tmig_phase3_210 + Tmig_phase3_211 + Tmig_phase3_212 + Tmig_phase3_213 + Tmig_phase3_214 + Tmig_phase3_215 + Tmig_phase3_216 + Tmig_phase3_217 + Tmig_phase3_218 + Tmig_phase3_219 + Tmig_phase3_220 + Tmig_phase3_221 + Tmig_phase3_222 + Tmig_phase3_223 + Tmig_phase3_224 + Tmig_phase3_225 + Tmig_phase3_226 + Tmig_phase3_227 + Tmig_phase3_228 + Tmig_phase3_229 + Tmig_phase3_230 + Tmig_phase3_231 + Tmig_phase3_232 + Tmig_phase3_233 + Tmig_phase3_234)*`phase3_migrants')

	qui replace beta_tot_phase3_100 = r(estimate) in `row'
	qui replace se_tot_phase3_100 = r(se) in `row'
}
}

if "`feset'" == "9" | "`feset'" == "10" {
if `phase' == 1 {
	lincom((Tmig_phase1_100 + Tmig_phase1_101 + Tmig_phase1_102 + Tmig_phase1_103 + Tmig_phase1_104 + Tmig_phase1_105 + Tmig_phase1_106 + Tmig_phase1_107 + Tmig_phase1_108 + Tmig_phase1_109 + Tmig_phase1_110 + Tmig_phase1_111 + Tmig_phase1_112 + Tmig_phase1_113 + Tmig_phase1_114 + Tmig_phase1_115 + Tmig_phase1_116 + Tmig_phase1_117 + Tmig_phase1_118 + Tmig_phase1_119 + Tmig_phase1_120 + Tmig_phase1_121 + Tmig_phase1_122 + Tmig_phase1_123 + Tmig_phase1_124 + Tmig_phase1_125 + Tmig_phase1_126 + Tmig_phase1_127 + Tmig_phase1_128 + Tmig_phase1_129 + Tmig_phase1_130 + Tmig_phase1_131 + Tmig_phase1_132 + Tmig_phase1_133 + Tmig_phase1_134 + Tmig_phase1_135 + Tmig_phase1_136 + Tmig_phase1_137 + Tmig_phase1_138 + Tmig_phase1_139 + Tmig_phase1_140 + Tmig_phase1_141 + Tmig_phase1_142 + Tmig_phase1_143 + Tmig_phase1_144 + Tmig_phase1_145 + Tmig_phase1_146 + Tmig_phase1_147 + Tmig_phase1_148 + Tmig_phase1_149 + Tmig_phase1_150 + Tmig_phase1_151 + Tmig_phase1_152 + Tmig_phase1_153)*`phase1_migrants')

	qui replace beta_tot_phase1_100 = r(estimate) in `row'
	qui replace se_tot_phase1_100 = r(se) in `row'
}

if `phase' == 2 {
	lincom((Tmig_phase2_128 + Tmig_phase2_129 + Tmig_phase2_130 + Tmig_phase2_131 + Tmig_phase2_132 + Tmig_phase2_133 + Tmig_phase2_134 + Tmig_phase2_135 + Tmig_phase2_136 + Tmig_phase2_137 + Tmig_phase2_138 + Tmig_phase2_139 + Tmig_phase2_140 + Tmig_phase2_141 + Tmig_phase2_142 + Tmig_phase2_143 + Tmig_phase2_144 + Tmig_phase2_145 + Tmig_phase2_146 + Tmig_phase2_147 + Tmig_phase2_148 + Tmig_phase2_149 + Tmig_phase2_150 + Tmig_phase2_151 + Tmig_phase2_152 + Tmig_phase2_153)*`phase2_migrants')
	
	qui replace beta_tot_phase2_100 = r(estimate) in `row'
	qui replace se_tot_phase2_100 = r(se) in `row'
}
if `phase' == 3 {
	di "skip"
}
}

* Store specification number
qui replace feset = `feset' in `row'

* Store N observations
qui replace nobs = e(N)  in `row'

* Store R^2
qui replace r2 = e(r2) in `row'

* Iterate row number by 1
local row = `row' + 1

} // end spec loop

* Make dataset long
drop nobs r2
drop if fe == ""
greshape long beta se, by(fe feset) keys(T) string
drop if missing(beta)

* Identify aggregated estimates
gen total = substr(T, 2, 10) == "tot_phase`phase'"

* Indicate depvar
gen depvar = "num_cases"
replace depvar = "num_deaths" if feset == 8 | feset == 10

* Destring daily coefficients
replace T = substr(T, -3, 3) 
replace T = substr(T, -2, 2) if substr(T, 1, 1) == "_"
destring T, replace
	
* 95% confidence intervals
gen ci95_lo = beta - 1.96*se
gen ci95_hi = beta + 1.96*se
  
* 90% confidence intervals
gen ci90_lo = beta - 1.645*se
gen ci90_hi = beta + 1.645*se 

* Temporarily save results for each phase
save "$dirpath_int_temp/RESULTS_event_study_phase`phase'.dta", replace

} // end phase loop


* Append results for each phase
use "$dirpath_int_temp/RESULTS_event_study_phase1.dta", clear
append using "$dirpath_int_temp/RESULTS_event_study_phase2.dta"
append using "$dirpath_int_temp/RESULTS_event_study_phase3.dta"

* Run checks on the data
gunique phase
assert r(unique) == 3
bys feset phase: gen count = _N
assert count == 62 if feset != 9 & feset != 10
drop count
assert beta == 0 if T == 99 & phase == 1
assert beta == 0 if T == 127 & phase == 2
assert beta == 0 if T == 203 & phase == 3
foreach var of varlist * {
	assert !missing(`var')
}

* Standardize T's such that the release date is T = 100
replace T = . if total == 1
replace T = T - 28 if phase == 2 & total == 0
replace T = T - 104 if phase == 3 & total == 0
assert 70 <= T & T <= 130 if total == 0 & feset != 9 & feset != 10
assert phase != 3 if feset == 9 | feset == 10

* Tidy output
rename num_migrants tot_migrants
gsort feset depvar phase -total T
order feset depvar phase total T beta se ci95_lo ci95_hi ci90_lo ci90_hi tot_migrants fe
rename feset spec
rename fe description

* Output
compress *
save "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3.dta", replace

******************************************************************
* Clear temporary directory
******************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"

foreach file of local files {
	erase `file'
}
