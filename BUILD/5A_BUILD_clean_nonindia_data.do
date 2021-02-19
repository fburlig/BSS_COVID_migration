
* Clean COVID data for countries aside from India

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
* Load and subset data
******************************************************************

* Load data
import delimited "$dirpath_raw_covid/main.csv", clear

* Keep countries and aggregation levels in question
keep if country_name == "Indonesia" | ///
	country_name == "South Africa" | ///
	country_name == "Kenya" | ///
	country_name == "Philippines" | ///
	country_name == "China"
	
* Drop levels of aggregation beyond Admin 2
drop if aggregation_level > 2

* Keep necessary variables
keep key date country_name subregion1_code subregion1_name subregion2_code subregion2_name aggregation_level new_confirmed new_deceased new_tested population

* Rename variables
rename new_confirmed num_cases
rename new_deceased num_deaths
rename new_tested num_tested

* Make stata date
gen date_stata = date(date, "YMD")
format date_stata %td
drop date
rename date_stata date
order date

* Replace names to lower case
foreach var of varlist country_name subregion1_name subregion2_name {
	replace `var' = lower(`var')
}

* Keep dates through September
drop if date > date("2020/09/30", "YMD")
	
drop num_deaths population

* Use aggregate cases for NCR in the philippines. these are later dropped
drop if country_name == "philippines" & ///
	!missing(subregion2_code) & ///
	subregion1_name == "national capital region"
	
replace subregion2_name = "national capital region" if ///
	subregion1_name == "national capital region" & ///
	country_name == "philippines"
	
replace subregion2_code = "NCR_agg" if ///
	subregion1_name == "national capital region" & ///
	country_name == "philippines"
	
replace aggregation_level = 2 if subregion2_code == "NCR_agg"
	
******************************************************************
* Subset
******************************************************************

* Keep most granular level of aggregation for each country
drop if (country_name == "philippines" & aggregation_level != 2) | ///
	(country_name == "south africa" & aggregation_level != 2) | ///
	(country_name == "indonesia" & aggregation_level != 1) | ///
	(country_name == "kenya" & aggregation_level != 1) | ///
	(country_name == "china" & aggregation_level != 1)
	******************************************************************
* Limit sample to +/- 30 days of travel release
******************************************************************

gen travel_rls = 0
replace travel_rls = 1 if ///
	(country_name == "south africa" & date > date("2020/04/30", "YMD")) | ///
	(country_name == "kenya" & date > date("2020/07/06", "YMD")) | ///
	(country_name == "indonesia" & date > date("2020/05/06", "YMD")) | ///
	(country_name == "philippines" & date > date("2020/05/29", "YMD")) | ///
	(country_name == "china" & date > date("2020/04/07", "YMD"))

levelsof country_name, local(levels) 
foreach c of local levels {
	qui sum date if travel_rls == 1 & country_name == "`c'"
	local event_date = r(min)
	drop if country_name == "`c'" & ///
		(date < `=`event_date'-30' | ///
		date > `=`event_date'+30')
}

******************************************************************
* Backfill negative cases over previous reporting periods
******************************************************************

* Set missing cases to 0
replace num_cases = 0 if missing(num_cases)

* Backfill negative cases evenly across all preceding days with positive cases
bysort country_name subregion1_code subregion2_code (date): ///
	egen pre_tot_cases = total(num_cases)
	
preserve
	
* Keep only observations with a nonmissing, nonzero entry
keep if num_cases != 0 & !missing(num_cases)

* Initialize a variable equal to the value of cases/deaths/tests if negative and 0 otherwise
gen neg_cases = 0
replace neg_cases = num_cases if num_cases < 0
gen neg_flag = 0
replace neg_flag = 1 if neg_cases < 0
	
* Drop places that have no negative entries
bysort country_name subregion1_code subregion2_code (date): ///
	egen tot_neg = total(neg_flag)
drop if tot_neg == 0

* By admin unit date, get the number of previous obs that are NOT negative for each negative entry
gen pos_cases = 0
replace pos_cases = 1 if neg_flag == 0
by country_name subregion1_code subregion2_code (date): ///
	gen num_prev_pos_cases = sum(pos_cases)
		
* By admin unit date, drop if the first observation is negative	
by country_name subregion1_code subregion2_code (date): ///
	drop if num_cases < 0 & _n == 1
	
* Average the negative values by those obs numbers. If the negative occurs before any positives, it will be divided by 0  and coded as missing
by country_name subregion1_code subregion2_code (date): ///
	replace neg_cases = neg_cases / num_prev_pos_cases

* For each admin unit, evenly back fill the negatives. If two negatives overlap, sum them
gsort country_name subregion1_code subregion2_code -date
by country_name subregion1_code subregion2_code: ///
	replace neg_cases = neg_cases[_n] + neg_cases[_n - 1] if _n > 1
	
* Recode formerly negative entires to missing
replace neg_cases = . if neg_flag == 1
	
* Take off the distributed negative entries from the original,  positive ones. Any originally negative entries are turned to missing
replace num_cases = num_cases + neg_cases

* Keep necessary variables for merging back
keep country_name subregion1_code subregion2_code date num_cases
rename num_cases num_cases_fxd

* Save fixes
tempfile tmpfile
save `tmpfile', replace

* Reload original dataset
restore
	
* Add backfilled estimates back on
merge 1:1 country_name subregion1_code subregion2_code date using ///
	`tmpfile'

* Use fixed estimates
replace num_cases = num_cases_fxd if _merge == 3
drop _merge num_cases_fxd

// Check that post-replacement total cases equal pre-replacement total cases
bysort country_name subregion1_code subregion2_code (date): ///
	egen post_tot_cases = total(num_cases)
assert pre_tot_cases == post_tot_cases
drop pre_tot_cases post_tot_cases
	
* Recode remaining negatives to 0: all orig negatives have already been  accounted for, and any remaining negatives had more than their previous count subtracted off, eg 1 - 1.14
replace num_cases = 0 if num_cases < 0 & !missing(num_cases)

******************************************************************
* Merge in populations form worldpop
******************************************************************

* Create id variables
egen covid_id = group(key)

* Temporarily save
tempfile full_covid_data
save `full_covid_data'

* Load WP data to pre-clean names
use "$dirpath_int_worldpop/non_india_worldpop.dta", clear

// Convert Indonesian names to english
replace subregion1_name = "southeast sulawesi" if ///
	subregion1_name == "sulawesi tenggara"

replace subregion1_name = ///
	subinstr(subregion1_name, "kepulauan", "islands", .) if ///
	country_name == "indonesia"
replace subregion1_name = ///
	subinstr(subregion1_name, "utara", "north", .) if ///
	country_name == "indonesia"
replace subregion1_name = ///
	subinstr(subregion1_name, "barat", "west", .) if ///
	country_name == "indonesia"
replace subregion1_name = ///
	subinstr(subregion1_name, "tengah", "central", .) if ///
	country_name == "indonesia"
replace subregion1_name = ///
	subinstr(subregion1_name, "timur", "east", .) if ///
	country_name == "indonesia"
replace subregion1_name = ///
	subinstr(subregion1_name, "selatan", "south", .) if ///
	country_name == "indonesia"
	
// Use philippines admin 1 region names instead of numbers
replace subregion1_name = "ilocos region" if ///
	subregion1_name == "region i" & ///
	country_name == "philippines"
replace subregion1_name = "cagayan valley" if ///
	subregion1_name == "region ii" & ///
	country_name == "philippines"
replace subregion1_name = "central luzon" if ///
	subregion1_name == "region iii" & ///
	country_name == "philippines"
replace subregion1_name = "calabarazon" if ///
	subregion1_name == "region iv-a" & ///
	country_name == "philippines"
replace subregion1_name = "bicol region" if ///
	subregion1_name == "region v" & ///
	country_name == "philippines"
replace subregion1_name = "western visayas" if ///
	subregion1_name == "region vi" & ///
	country_name == "philippines"
replace subregion1_name = "central visayas" if ///
	subregion1_name == "region vii" & ///
	country_name == "philippines"
replace subregion1_name = "eastern visayas" if ///
	subregion1_name == "region viii" & ///
	country_name == "philippines"
replace subregion1_name = "zamboanga oeninsula" if ///
	subregion1_name == "region ix" & ///
	country_name == "philippines"
replace subregion1_name = "northern mindanao" if ///
	subregion1_name == "region x" & ///
	country_name == "philippines"
replace subregion1_name = "davao region" if ///
	subregion1_name == "region xi" & ///
	country_name == "philippines"
replace subregion1_name = "soccsksargen" if ///
	subregion1_name == "region xii" & ///
	country_name == "philippines"
replace subregion1_name = "caraga" if ///
	subregion1_name == "region xiii" & ///
	country_name == "philippines"
replace subregion1_name = "mimaropa" if ///
	subregion1_name == "region iv-b" & ///
	country_name == "philippines"

replace subregion2_name = "davao de oro" if ///
	subregion2_name == "compostela valley" & ///
	country_name == "philippines"

// south africa
replace subregion2_name = "buffalo city metropolitan municipality" if ///
	subregion2_name == "buffalo city" & ///
	country_name == "south africa"
replace subregion2_name = "or tambo" if ///
	subregion2_name == "o.r.tambo" & ///
	country_name == "south africa"
replace subregion2_name = "nelson mandela bay metropolitan municipality" if ///
	subregion2_name == "nelson mandela bay" & ///
	country_name == "south africa"
replace subregion2_name = "sarah baartman" if ///
	subregion2_name == "cacadu" & ///
	country_name == "south africa"
replace subregion2_name = "ethekwini metropolitan municipality" if ///
	subregion2_name == "ethekwini" & ///
	country_name == "south africa"
replace subregion2_name = "king cetshwayo" if ///
	subregion2_name == "uthungulu" & ///
	country_name == "south africa"
replace subregion2_name = "garden route" if ///
	subregion2_name == "eden" & ///
	country_name == "south africa"
	
// china
replace subregion1_name = "guangdong" if ///
	subregion1_name == "guangdong province" & ///
	country_name == "china"
replace subregion1_name = "guangxi" if ///
	subregion1_name == "guangxi zhuang autonomous region" & ///
	country_name == "china"
replace subregion1_name = ///
	subinstr(subregion1_name, " province", "", .) if ///
	country_name == "china"

tempfile wp
save `wp'

* Subset covid data for matching
use `full_covid_data', clear
duplicates drop covid_id, force
keep country_name subregion1_name subregion2_name covid_id

* Fuzzy join worldpop populations onto covid dataset// get pre-merge observations to check they are the same
local pre_merge_obs = _N

// fuzzy join
reclink country_name subregion1_name subregion2_name ///
	using `wp', idmaster(covid_id) idusing(wp_id) gen(reclinkscore)
	
// check count of post-merge observations are unchanged
assert _N == `pre_merge_obs'

* Keep necessary variables for matching back
keep covid_id population

* Join back onto full cases data
merge 1:m covid_id using `full_covid_data', nogen
drop covid_id

*****************************************************************
* Clean names to match with census migration data
*****************************************************************

***************************** Philippines
tempfile full_data
save `full_data', replace
keep if country_name == "philippines"
* Aggregate necessary provinces
replace subregion2_name = "cagayan, batanes" if ///
	subregion2_name == "cagayan" | subregion2_name == "batanes"
replace subregion2_name = "iloilo, guimaras" if ///
	subregion2_name == "iloilo" | subregion2_name == "guimaras"
replace subregion2_name = "leyte, biliran" if ///
	subregion2_name == "leyte" | subregion2_name == "biliran"
replace subregion2_name = "south cotabato, sarangani" if ///
	subregion2_name == "south cotabato" | ///
	subregion2_name == "sarangani"
replace subregion2_name = "kalinga-apayao" if ///
	subregion2_name == "kalinga" | subregion2_name == "apayao"
replace subregion2_name = ///
	"surigao del norte, dinagat islands" if ///
		subregion2_name == "surigao del norte" | ///
		subregion2_name == "dinagat islands"
replace subregion2_name = ///
	"zamboanga del sur, zamboanga sibugay" if ///
		subregion2_name == "zamboanga del sur" | ///
		subregion2_name == "zamboanga sibugay"
replace subregion2_name = "davao de oro, davao del norte" if ///
	subregion2_name == "davao de oro" | ///
	subregion2_name == "davao del norte"
replace subregion2_name = "davao del sur" if ///
	subregion2_name == "davao occidental"
tempfile ph
save `ph', replace
* Append back to full data
use `full_data', clear
drop if country_name == "philippines"
append using `ph'

***************************** Indonesia
tempfile full_data
save `full_data', replace
keep if country_name == "indonesia"
* reorder directions and names
local names northwest northeast southwest southeast north south east west islands
foreach name of local names {
	gen temp = strpos(subregion1_name, "`name' ")
	replace subregion1_name = ///
		subinstr(subregion1_name, "`name' ", "", .) if ///
			temp > 0
	replace subregion1_name = subregion1_name + " `name'" ///
		if temp > 0
	drop temp
}
* Aggregate/replace names
replace subregion1_name = "sulawesi south" if ///
	subregion1_name == "sulawesi southeast"
replace subregion1_name = "kalimantan east" if ///
	subregion1_name == "kalimantan north"
replace subregion1_name = "gorontalo, sulawesi north" if ///
	subregion1_name == "gorontalo" | ///
	subregion1_name == "sulawesi north"
replace subregion1_name = "maluku, maluku north" if ///
	subregion1_name == "maluku" | ///
	subregion1_name == "maluku north"
replace subregion1_name = "papua, papua west" if ///
	subregion1_name == "papua" | ///
	subregion1_name == "papua west"
replace subregion1_name = "sulawesi west, sulawesi south" if ///
	subregion1_name == "sulawesi west" | ///
	subregion1_name == "sulawesi south"
replace subregion1_name = "bangka belitung, sumatera south" if ///
	subregion1_name == "bangka belitung islands" | ///
	subregion1_name == "sumatra south"
replace subregion1_name = "banten, jawa west" if ///
	subregion1_name == "banten" | ///
	subregion1_name == "java west"
replace subregion1_name = "islands riau, riau" if ///
	subregion1_name == "riau islands" | ///
	subregion1_name == "riau"
tempfile id
save `id', replace
* Append back to full data
use `full_data', clear
drop if country_name == "indonesia"
append using `id'


* Collapse combined units
collapse (sum) num_cases population, ///
	by(country_name subregion1_name subregion2_name travel_rls date)

* Check that each unit has the same number of observations
bysort country_name subregion1_name subregion2_name: ///
	gen obs = _N
assert obs == 1 + 30 + 30
drop obs

******************************************************************
* Output
******************************************************************

compress *
sort country_name subregion1_name subregion2_name date
save "$dirpath_int_covid/cleaned_non_india_covid_data.dta", replace


******************************************************************
* Clear temporary directory
******************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"

foreach file of local files {
	erase `file'
}
