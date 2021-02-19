
* Assign migrant counts to countries aside from India

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
* Load master data
******************************************************************

use "$dirpath_int_covid/cleaned_non_india_covid_data.dta", clear
cd "$dirpath_int_temp"

******************************************************************
* South Africa
******************************************************************

* Save full data
save "full_data.dta", replace

* Keep south africa
keep if country_name == "south africa"

* Drop hotspot: cape town
drop if subregion2_name == "city of cape town metropolitan municipality"

* Create id for fuzzy join
egen covid_id = group(subregion2_name)

* Keep only unique observations for merging
tempfile south africa
save `south africa', replace
keep subregion2_name covid_id
duplicates drop subregion2_name, force

* counts from hotspots --> non-hotspots
local filename = "$dirpath_int_census/za_hotspot_to_nonhotspot_migrants.dta"

* Fuzzy join
local count_premerge = _N
reclink subregion2_name using "`filename'", ///
	idmaster(covid_id) idusing(census_id) gen(reclinkscore)
assert _N == `count_premerge'
assert !missing(subregion2_name) & !missing(Usubregion2_name)
unique subregion2_name
assert r(unique) == _N
unique Usubregion2_name
assert r(unique) == _N
keep covid_id migrants

// merge back onto south africa data
merge 1:m covid_id using `south africa'
assert _merge == 3
drop _merge
drop covid_id

* Temporarily save
save "south africa.dta", replace

* Append back onto full data
use "full_data.dta", clear
drop if country_name == "south africa"
append using "south africa.dta"

******************************************************************
* Kenya
******************************************************************

* Hotspot/travel restrict regions: nairobi and mombasa

* Use at interpolated district level
tempfile full_data
save "full_data.dta", replace

use "$dirpath_int_covid/cleaned_kenya_covid_data.dta", clear
assert !missing(migrants)
gunique date
bysort subregion2_name: gen obs = _N
assert obs == r(unique)
drop obs
gen date_stata = date(date, "YMD")
format date_stata %td
drop date
rename date_stata date
tempfile kenya
save `kenya'

use "full_data.dta", clear
drop if country_name == "kenya"
append using `kenya'

******************************************************************************
* China
******************************************************************************

* Hotspot/travel restrict region: hubei

* Save previous data
save "full_data.dta", replace

* Keep china
keep if country_name == "china"
drop migrants

* total interprovincial migrants in china
local migrants_china = 54.9 * 10^6

* get migrants from hubei using a pop share
// population of hubei
preserve
keep if subregion1_name == "hubei"
local pop = population[1]
restore
// population of china
preserve
gduplicates drop subregion1_name, force
collapse (sum) population
local tot_p = population[1]
restore
// share of china pop that is in hubei
local pop_share = `pop' / `tot_p'
// migrants coming from hubei based on that pop share
local migrants_hubei = `pop_share' * `migrants_china'

* Temporarily save
save "china_full.dta", replace

* Drop hubei, distribute its migrants across other provinces
drop if subregion1_name == "hubei"
gduplicates drop subregion1_name, force
egen tot_p = total(population)
gen pop_share = population / tot_p
egen test = total(pop_share)
assert test > 0.999 & test < 1.001
drop test
gen migrants = `migrants_hubei' * pop_share
keep subregion1_name migrants

* check migrant count assigned correctly
preserve
drop if subregion1_name == "hubei"
gduplicates drop subregion1_name, force
collapse (sum) migrants
assert migrants > `=`migrants_hubei'-100' & ///
	migrants < `=`migrants_hubei'+100'
restore

* Temporarily save
keep subregion1_name migrants
save "china_migrants.dta", replace

* Merge back onto china data
use "china_full.dta", clear
merge m:1 subregion1_name using "china_migrants.dta"
assert _merge == 3 if subregion1_name != "hubei"
drop _merge

* Temporarily save
save "china_migrants.dta", replace

* Append to full data
use "full_data.dta", clear
drop if country_name == "china"
append using "china_migrants.dta"

* Check hotspot regions are not in the data
drop if subregion1_name == "hubei"

******************************************************************************
* Indonesia
******************************************************************************

* Hotspot/travel restrict region: jakarta

* Save previous data
save "full_data.dta", replace

* Keep indonesia
keep if country_name == "indonesia"
drop migrants

* Drop hotspot: jakarta
drop if subregion1_name == "jakarta"

* Create id for fuzzy join
egen covid_id = group(subregion1_name)

* Keep only unique observations for merging
tempfile indonesia
save `indonesia', replace
keep subregion1_name covid_id
duplicates drop subregion1_name, force

* V1: counts from hotspots --> non-hotspots
local filename = "$dirpath_int_census/indonesia_hotspot_to_nonhotspot_migrants.dta"

* Fuzzy join
local count_premerge = _N
reclink subregion1_name using "`filename'", ///
	idmaster(covid_id) idusing(census_id) gen(reclinkscore)
assert _N == `count_premerge'
assert !missing(subregion1_name) & !missing(Usubregion1_name)
unique subregion1_name
assert r(unique) == _N
unique Usubregion1_name
assert r(unique) == _N
keep covid_id migrants

// merge back onto indonesia data
merge 1:m covid_id using `indonesia'
assert _merge == 3
drop _merge
drop covid_id

* Temporarily save
save "indonesia.dta", replace

* Append back onto full data
use "full_data.dta", clear
drop if country_name == "indonesia"
append using "indonesia.dta"

******************************************************************
* Philippines
******************************************************************

* Hotspot/travel restrict region: national capital region and cebu

* Save previous data
save "full_data.dta", replace

* Keep philippines
keep if country_name == "philippines"
drop migrants

* Drop hotspot: national capital region
drop if subregion2_name == "national capital region" | ///
	subregion2_name == "cebu"

* Create id for fuzzy join
egen covid_id = group(subregion2_name)

* Keep only unique observations for merging
tempfile philippines
save `philippines', replace
keep subregion2_name covid_id
duplicates drop subregion2_name, force

* V1: counts from hotspots --> non-hotspots
local filename = "$dirpath_int_census/philippines_hotspot_to_nonhotspot_migrants.dta"

* Fuzzy join
local count_premerge = _N
reclink subregion2_name using "`filename'", ///
	idmaster(covid_id) idusing(census_id) gen(reclinkscore)
assert _N == `count_premerge'
assert !missing(subregion2_name) & !missing(Usubregion2_name)
unique subregion2_name
assert r(unique) == _N
unique Usubregion2_name
assert r(unique) == _N
keep covid_id migrants

// merge back onto philippines data
merge 1:m covid_id using `philippines'
assert _merge == 3
drop _merge
drop covid_id

* Temporarily save
save "philippines.dta", replace

* Append back onto full data
use "full_data.dta", clear
drop if country_name == "philippines"
append using "philippines.dta"

******************************************************************
* Total migrants in each country, adjusting migrant numbers to be of equal time spans
******************************************************************

* Temporarily save
save "full_data.dta", replace

* Keep unique admin units in each country
gduplicates drop country_name subregion1_name subregion2_name, force

* Collapse to country level to sum migrants
collapse (sum) tot_migrants = migrants, by(country_name)

* Temporarily save
save "migrants_countries.dta", replace

* Merge back onto Full data
use "full_data.dta", clear
merge m:1 country_name using "migrants_countries.dta"
assert _merge == 3
drop _merge

// kenya reports based on past year, so multiply by 5
foreach var of varlist migrants tot_migrants {
	replace `var' = `var' * 5 if country_name == "kenya"
}

******************************************************************************
* Misc vars and checks
******************************************************************************

* Gen date^2 of sample
gen date2 = date^2

* Per capita cases
gen num_cases_pcap = num_cases / population

* Checks
assert !missing(migrants)
assert !missing(tot_migrants)
assert !missing(country_name)
assert !missing(subregion1_name)
assert !missing(date)

* Check again that hotspot regions are gone
assert subregion2_name != "national capital region" & ///
	subregion2_name != "cebu"
assert subregion1_name != "jakarta"
assert subregion1_name != "hubei"
assert subregion1_name != "nairobi"
assert subregion1_name != "mombasa"
assert subregion1_name != "city of cape town metropolitan municipality"

* Remake region identifiers
unique subregion1_name subregion2_name
local unique_pre = r(unique)
replace subregion2_name = ///
	subregion1_name if missing(subregion2_name)
unique subregion1_name subregion2_name
assert r(unique) == `unique_pre'
egen region_code = ///
	group(country_name subregion1_name subregion2_name)

* Sort and order
sort country_name subregion1_name subregion2_name date
order country_name region_code subregion1_name population date num_cases travel_rls

* Check that each unit has the same number of observations
bysort country_name subregion1_name subregion2_name: ///
	gen obs = _N
assert obs == 1 + 30 + 30 
drop obs

* Total migrants
drop tot_migrants
preserve
gduplicates drop country_name subregion1_name subregion2_name, force
bysort country_name: egen tot_migrants = total(migrants)
keep country_name tot_migrants
duplicates drop country_name, force
assert _N == 5
tempfile totals
save `totals'
restore
merge m:1 country_name using `totals'
assert _merge == 3
drop _merge

* Output
compress *
save "$dirpath_final_reg_inputs/cleaned_non_india_covid_data_migrants.dta", replace

******************************************************************************
* Delete files in temporary directory
******************************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"
foreach f in `files' {
	erase "`f'"
}
