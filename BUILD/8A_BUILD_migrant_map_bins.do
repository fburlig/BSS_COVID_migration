
* Initialize categories for migrant map


* Set paths
global dirpath_covid "$dirpath/data/generated/intermediate/covid"
global dirpath_migrant_counts "$dirpath/data/generated/final/regression_inputs"
global dirpath_out "$dirpath/data/generated/intermediate/map"


* Full list of district names, use for adding 0 flow districts
use "$dirpath_covid/covid19india_data_cleaned.dta", clear
duplicates drop state district, force
drop if district == "MUMBAI" | ///
	(district == "PUNE" & state == "MAHARASHTRA") | ///
	(district == "AHMADABAD" & state == "GUJARAT") | ///
	(district == "INDORE" & state == "MADHYA PRADESH") | ///
	district == "DELHI"
keep state district
tempfile all_districts
save `all_districts'


* Compute percentiles among districts receiving flows so places without
* flows are coded to 0
use "$dirpath_migrant_counts/covid19india_migrants_remittance.dta", clear

duplicates drop state district, force
keep state district T5m_Dremittance

* Assign migrant quintiles
xtile qT5m_Dremittance = T5m_Dremittance, n(5)

* Get quantile values
egen p20 = pctile(T5m_Dremittance), p(20)
egen p40 = pctile(T5m_Dremittance), p(40)
egen p60 = pctile(T5m_Dremittance), p(60)
egen p80 = pctile(T5m_Dremittance), p(80)

local p20_rounded : di `=round(p20, 10)'
local p40_rounded : di `=round(p40, 10)'
local p60_rounded : di %5.0fc `=round(p60, 10)'
local p80_rounded : di %5.0fc `=round(p80, 10)'

gen qval = ""
replace qval = "<`p20_rounded'" if qT5m_Dremittance == 1
replace qval = "`p20_rounded'-`p40_rounded'" if qT5m_Dremittance == 2
replace qval = "`p40_rounded'-`p60_rounded'" if qT5m_Dremittance == 3
replace qval = "`p60_rounded'-`p80_rounded'" if qT5m_Dremittance == 4
replace qval = ">`p80_rounded'" if qT5m_Dremittance == 5

* Add in districts with 0 flows
merge 1:1 state district using `all_districts', nogen
replace qval = "0" if missing(qval)
replace qT5m_Dremittance = 0 if missing(qT5m_Dremittance)

* Shorten names
rename qT5m_Dremittance qT5m_Drmt
 
* Output
keep state district qT5m_Drmt qval
save  "$dirpath_out/covid19india_migrants_map_initialization.dta", replace

