
***** Combine district-wise cases and flows data

***** SETUP:
global dirpath_cases "$dirpath/data/generated/intermediate/Covid"
global dirpath_flows "$dirpath/data/Generated/Intermediate/remittances"
global dirpath_census "$dirpath/data/generated/intermediate/census"

**************************************************************************

* Load remittance remittance flows
use "$dirpath_flows/remittance_flows_from_mumbai.dta", clear
rename mumbai_flows remittance_flows

* Aggregate flows from states that got aggregated in the cases data
replace district = "TELANGANA" if state == "TELANGANA"
replace district = "ASSAM" if state == "ASSAM"
replace district = "GOA" if state == "GOA"
replace district = "MANIPUR" if state == "MANIPUR"
replace district = "DELHI" if state == "DELHI"
replace district = "SIKKIM" if state == "SIKKIM"

* Update state name for dadra and nagar haveli
replace state = "DAMAN & DIU" if state == "DADRA & NAGAR HAVE"
replace district = "DADRA & NAGAR HAVELI" if district == "DADRA & NAGAR HAVE"
drop if state == "ANDAMAN & NICOBAR"

collapse (sum) remittance_flows, by(state district)

* Temporarily save
tempfile flows
save `flows'

* Load cases
use "$dirpath_cases/covid19india_data_cleaned.dta", clear

* Add district-wise remittance flows
merge m:1 state district using `flows', nogen

* Non-matched remittance flows means that districts gets none
replace remittance_flows = 0 if missing(remittance_flows)

* Exclude Mumbai
drop if district == "MUMBAI"

* Keep necessary variables
keep state district date num_cases num_deaths num_tested_1wk num_tested ///
	remittance_flows 

* Create new district and state id's
egen state_id = group(state)
egen district_id = group(state district)

* Temporarily save
tempfile cases_remittance
save `cases_remittance'

* Load census data
use "$dirpath_census/census11_migrants_mumbai.dta", clear

* Split into 2 parts for merging: in Maha (district-wise) and not in Maha
* (state-wise)
preserve
keep if state == "MAHARASHTRA"
tempfile in_st
save `in_st'
restore

keep if state != "MAHARASHTRA"
tempfile out_st
save `out_st'

* Add 2 parts of census flows onto cases+remittance
use `cases_remittance', clear

* District-wise part
merge m:1 state district using `in_st', nogen

* Drop down in-state variables for palghar since it was formed after 2011
* and is therefore missing in the census
local varlist flows_birth_s in_state share_birth_d
foreach var of local varlist {
	replace `var' = `var'[_n-1] if ///
		district == "PALGHAR" & state == "MAHARASHTRA"
}

* Rename variables so variables for other states will be replaced
foreach var of local varlist {
	rename `var' `var'_maha
}

* State-wise part
merge m:1 state using `out_st', nogen

* Combine variables
foreach var of local varlist {
	replace `var' = `var'_maha if missing(`var')
	drop `var'_maha
}

* Add estimate of inter-state migrants that left Mumbai because of Covid
gen tot_5m = 5000000

* Indicator for phase 2 lockdown districts
gen phase2 = 0
replace phase2 = 1 if state == "MAHARASHTRA" & (district == "THANE" | ///
	district == "PALGHAR" | district == "RAIGARH")
	
sort state district date

save "$dirpath_cases/covid19india_data_cleaned_remittances.dta", replace

