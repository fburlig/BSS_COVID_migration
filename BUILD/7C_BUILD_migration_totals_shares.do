******************************************************************************
******************************************************************************

***** Calculate migration state-wise and district-wise shares

******************************************************************************
******************************************************************************

***** SETUP:
global dirpath "/Users/garyschlauch/desktop/covid_india_migrants"
global dirpath_cases "$dirpath/data/generated/intermediate/covid"


******************************************************************************
******************************************************************************

* Load data
use "$dirpath_cases/covid19india_data_cleaned_remittances.dta", clear

* Create new state and district indentifiers
drop district_id state_id
egen district_id = group(state district)
egen state_id = group(state)


* Across states, calculate the remittance flow district-wise distribution
preserve
duplicates drop state district, force
egen tot_remittance_flows = total(remittance_flows)
gen dshare_remittance = remittance_flows / tot_remittance_flows
replace dshare_remittance = 0 if missing(dshare_remittance)
keep state district dshare_remittance
tempfile share
save `share', replace
restore

merge m:1 state district using `share', nogen


* Find the within state, district-wise remittances distribution
preserve 
duplicates drop state district, force
bysort state: egen tot_remittance_flows_s = total(remittance_flows)
gen dshare_remittance_s = remittance_flows / tot_remittance_flows_s
replace dshare_remittance_s = 0 if missing(dshare_remittance_s)
keep state district dshare_remittance_s
tempfile share
save `share', replace
restore

merge m:1 state district using `share', nogen


* State-level indicator for receives remittance flows
preserve
duplicates drop state district, force
bysort state: egen rec_remittance_flows = total(dshare_remittance_s)
duplicates drop state, force
keep state rec_remittance_flows
tempfile share
save `share', replace
restore

merge m:1 state using `share', nogen


* Calculate Census flows from birth for each state
gen dummy_id = 1
preserve
duplicates drop state, force
egen tot_birth_s = total(flows_birth_s) if rec_remittance_flows == 1
sort tot_birth_s
replace tot_birth_s = tot_birth_s[1] // fill in missings
duplicates drop dummy_id, force
keep dummy_id tot_birth_s
tempfile totals
save `totals'
restore

merge m:1 dummy_id using `totals', nogen
drop dummy_id


* Calculate Census state-wise shares from birth among districts that receive
* remittance flows
preserve
duplicates drop state, force
gen tshare_birth_s = flows_birth_s / tot_birth_s if rec_remittance_flows == 1
keep state tshare_birth_s
tempfile share
save `share', replace
restore

merge m:1 state using `share', nogen

* Keep necessary variables
drop flows_birth_s rec_remittance_flows tot_birth_s
	
* Sort dataset
sort state district date

* Reorder dataset
order state state_id district district_id date ///
	num_cases num_deaths num_tested num_tested_1wk ///
	tot_5m tshare_birth_s dshare_remittance
	
* Rename variables
rename tot_5m T5m
rename tshare_birth_s TSsbth
rename dshare_remittance_s DSsremittance
rename dshare_remittance Dremittance

* Output
save "$dirpath_cases/covid19india_totals_shares.dta", replace
