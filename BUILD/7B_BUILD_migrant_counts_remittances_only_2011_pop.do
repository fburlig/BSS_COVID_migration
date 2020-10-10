
***** Get migration estimates for remittances only using 2011 boundaries
* for the pop weight


***** SETUP:
global dirpath_cases "$dirpath/data/generated/intermediate/covid"
global dirpath_census "$dirpath/data/generated/intermediate/census"
global dirpath_out "$dirpath/data/generated/final/regression_inputs/"

******************************************************************************
******************************************************************************

* Load census data
use "$dirpath_cases/covid19india_data_cleaned_remittances_pops.dta", clear


* Calculate remittance district-wise distribution across states
preserve
duplicates drop state district, force
egen tot_remittanceflows = total(remittance_flows)
gen dshare_remittance = remittance_flows / tot_remittanceflows
keep state district dshare_remittance
tempfile shares
save `shares'
restore

merge m:1 state district using `shares', nogen
tempfile main
save `main'

* Scale remittance-only shares by 5 million
gen T5m_Dremittance = 5*10^6 * dshare_remittance

* Scale migrant counts such that there are 5 million out of state migrants
preserve
duplicates drop state district, force
collapse (sum) T5m_Dremittance, by(in_state)
local reweight = 5000000 / T5m_Dremittance[1]
restore
replace T5m_Dremittance = T5m_Dremittance * `reweight'

* Drop places with early outbreaks
drop if (district == "PUNE" & state == "MAHARASHTRA") | ///
	(district == "BOTAD_COMB" & state == "GUJARAT") | ///
	(district == "INDORE" & state == "MADHYA PRADESH") | ///
	district == "DELHI"

* Calculate cases in control districts: those that do not get remittance flows
* with the rural filter
preserve
collapse (mean) num_cases_date_control = num_cases if remittance_flows == 0, by(date)
tempfile control_cases
save `control_cases'
restore

* Add dately average for control casess back to overall dataset
merge m:1 date using `control_cases', nogen

* Drop control districts
drop if remittance_flows == 0

* Make new date variable = 1 for the first date in the sample
gen date_stata = date
replace date_stata = date_stata - 21976 + 1

* Add week
gen week = week(date) - 8 //  minus 8 so 1st week of the sample = week 1
gen week2 = week^2

* Indicator for in-state non-MMR
gen phase3 = 0
replace phase3 = 1 if in_state == 1 & phase2 == 0


save "$dirpath_out/covid19india_migrants_remittance_2011_pop.dta", replace


