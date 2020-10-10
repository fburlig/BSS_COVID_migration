

***** Get migration estimates using the census only

***** SETUP:
global dirpath_cases "$dirpath/data/generated/intermediate/covid"
global dirpath_flows "$dirpath/data/Generated/Intermediate/census"
global dirpath_out "$dirpath/data/generated/final/regression_inputs"

*****************************************************************************
*****************************************************************************

* Load census district-wise flows in maha/state-wise flows outside maha
* from birth
use "$dirpath_flows/census11_migrants_mumbai.dta", clear

keep state district flows_birth_s in_state share_birth_d

* Get Mumbai migrant state-wise share from birth
preserve
duplicates drop state, force
egen tot_birth_s = total(flows_birth_s)
gen tshare_birth_s = flows_birth_s / tot_birth_s
keep state tshare_birth_s
tempfile shares
save `shares', replace
restore

merge m:1 state using `shares', nogen
drop flows_birth_s

* Have to merge separately for district-wise (which is only for Maharashtra) 
* and state-wise
preserve
keep if in_state == 1
drop tshare_birth_s
tempfile census_flows_dw
save `census_flows_dw'
restore

duplicates drop state, force
drop district
tempfile census_flows_sw
save `census_flows_sw'

* Load population-cases data
use "$dirpath_cases/covid19india_data_cleaned_remittances_pops.dta", clear

* Combine thane and palghar since the latter was formed after 2011. If a
* given district-date observation is missing for one, it is missing for both
* in the aggregation
replace district = "THANE" if district == "PALGHAR" & state == "MAHARASHTRA"
egen group = group(state district date)
local varlist num_cases num_deaths num_tested num_tested_1wk ///
	remittance_flows
foreach var of local varlist {
	bysort group: gen `var'_missing = missing(`var')
	gsort group -`var'_missing
	by group: replace `var'_missing = `var'_missing[1]
	by group: egen `var'_agg = total(`var')
	replace `var'_agg = . if `var'_missing == 1
	drop `var' `var'_missing	
	rename `var'_agg `var'
}

duplicates drop group, force
drop group district_id
egen district_id = group(state district)

* Correct thane's population
replace population = 11060148 if district == "THANE" & state == "MAHARASHTRA"

* Merge in-state shares
merge m:1 state district using `census_flows_dw', nogen

* Merge state-wise shares
merge m:1 state using `census_flows_sw', nogen

* Get within state district-wise population shares
preserve
duplicates drop state district, force
keep state district in_state population
bysort state: egen tot_p_s = total(population)
gen pop_share_s_d = population / tot_p_s 
keep state district pop_share_s_d
tempfile pop_shares
save `pop_shares'
restore

merge m:1 state district using `pop_shares', nogen

* Number of inter-state migrants who left mumbai
gen T5m = 5*10^6

* Migration flows
*  = 3m * state-wise-share from birth * within-state district-wise share
* (the latter is given in the in-state data and is obtained from a 
* population weight for out of state)
gen T5m_TSsbth_DScns = T5m * tshare_birth_s * pop_share_s_d if ///
	in_state == 0
replace T5m_TSsbth_DScns = T5m * tshare_birth_s * share_birth_d if ///
	in_state == 1

* Scale these counts such that there are 5 million out of staters
preserve
duplicates drop state district, force
collapse (sum) T5m_TSsbth_DScns, by(in_state)
local reweight = 5000000 / T5m_TSsbth_DScns[1]
restore

replace T5m_TSsbth_DScns = T5m_TSsbth_DScns * `reweight'
	
* Make new date variable = 1 for the first date in the sample
gen date_stata = date
replace date_stata = date_stata - 21976 + 1

* Add week
gen week = week(date) - 8 //  minus 8 so 1st week of the sample = week 1
gen week2 = week^2

* Keep necessary variables
keep state state_id district district_id date date date_stata ///
	num_cases num_deaths num_tested num_tested_1wk population in_state ///
	phase2 T5m_TSsbth_DScns week week2

gen phase3 = 0
replace phase3 = 1 if in_state == 1 & phase2 == 0

drop if (district == "PUNE" & state == "MAHARASHTRA") | ///
	(district == "BOTAD_COMB" & state == "GUJARAT") | ///
	(district == "INDORE" & state == "MADHYA PRADESH") | ///
	district == "DELHI"
	
* Create control group for all remaining inter-state migrants, 
* taking their average daily cases weighted by the number of migrants estimated
* in each district
preserve
keep if in_state == 0
replace T5m_TSsbth_DScns = round(T5m_TSsbth_DScns)
collapse (mean) num_cases [fweight=T5m_TSsbth_DScns], by(date)
rename num_cases num_cases_date_control
tempfile control_cases
save `control_cases'
restore

* Add daily average for control cases (out of state) back to overall dataset
merge m:1 date using `control_cases', nogen
drop if in_state == 0

* Sort data
sort state district date


save "$dirpath_out/covid19india_migrants_census_only.dta", replace



