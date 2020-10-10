******************************************************************************
******************************************************************************

***** Calculate district-wise migration counts with remittances only and
* combining remittances and census data

******************************************************************************
******************************************************************************

***** SETUP:
global dirpath_in "$dirpath/data/generated/intermediate/covid"
global dirpath_out "$dirpath/data/generated/final/regression_inputs"

******************************************************************************
******************************************************************************

* Load data
use "$dirpath_in/covid19india_totals_shares.dta", clear


**** Calculate district-wise migration flows
* Remittances only
gen T5m_Dremittance  = T5m * Dremittance

* Remittances + census
gen T5m_TSsbth_DSsremittance = T5m * TSsbth * DSsremittance


* Rescale migrant counts such that there are 5 million out of staters
preserve
duplicates drop state district, force
collapse (sum) T5m_Dremittance, by(in_state)
local reweight = 5000000 / T5m_Dremittance[1]
restore
replace T5m_Dremittance = T5m_Dremittance * `reweight'

preserve
duplicates drop state district, force
collapse (sum) T5m_TSsbth_DSsremittance, by(in_state)
local reweight = 5000000 / T5m_TSsbth_DSsremittance[1]
restore
replace T5m_TSsbth_DSsremittance = T5m_TSsbth_DSsremittance * `reweight'
	
	
* Drop districts whose outbreaks by may1 (day trains started) were in the 
* 99th percentile
drop if (district == "PUNE" & state == "MAHARASHTRA") | ///
	(district == "AHMADABAD" & state == "GUJARAT") | ///
	(district == "INDORE" & state == "MADHYA PRADESH") | ///
	district == "DELHI"

	
* Take average daily cases for control districts (not receiving remittance flows)
preserve
collapse (mean) num_cases if remittance_flows == 0, by (date)
rename num_cases num_cases_date_control
tempfile control_cases
save `control_cases'
restore

merge m:1 date using `control_cases', nogen


* Drop control districts
drop if remittance_flows == 0


* Make new date variable = 1 for the first date in the sample
gen date_stata = date
replace date_stata = date_stata - 21976 + 1


* Add week
gen week = week(date) - 8 //  minus 8 so 1st week of the sample = week 1
gen week2 = week^2


**** Clean up and output
* Reorder dataset
order state state_id district district_id date date_stata week in_state ///
	num_cases num_deaths num_tested num_tested_1wk ///
	num_cases_date_control

* Keep necessary variables
	
* Organize data
sort state district date

* Create new district and state identifiers
drop district_id state_id
egen district_id = group(state district)
egen state_id = group(state)

* Indicator for phase 3 districts
gen phase3 = 0
replace phase3 = 1 if in_state == 1 & phase2 == 0

* Output
save "$dirpath_out/covid19india_migrants_remittance.dta", replace

