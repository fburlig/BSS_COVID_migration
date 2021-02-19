
* Clean COVID data for India

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
* Prep covid data for merge with shapefile names
******************************************************************

* Load data from covid19india json api
import delimited "$dirpath_int_covid/covid19india_api.csv", clear

* Create a data-formatted date variable
gen date_stata = date(date, "YMD")
format date_stata %dM_d,_CY
drop date
rename date_stata date

* Keep days prior to September 30th, 2020
keep if date <= date("2020/09/30", "YMD")

* Drop duplicate reports for Tripura
duplicates drop state district date num_cases num_deaths num_tested if ///
	state == "TRIPURA", force

* Make sure there is no extra whitespace in state/district names
replace district = strtrim(district)
replace state = strtrim(state)

* Drop unclassified observations
drop if district == "OTHER STATE" | district == "OTHERS" | ///
	district == "RAILWAY QUARANTINE" | district == "OTHER REGION" | ///
	district == "AIRPORT QUARANTINE" | district == "ITALIANS" | ///
	district == "FOREIGN EVACUEES" | district == "BSF CAMP" | ///
	district == "EVACUEES" | district == "CAPF PERSONNEL" | ///
	district == "STATE POOL"

* Fix names to better match shapefile
replace district = "PASHCHIM CHAMPARAN" if district == "WEST CHAMPARAN"
replace district = "PURBA CHAMPARAN" if district == "EAST CHAMPARAN"
replace district = "PURBI SINGHBHUM" if district == "EAST SINGHBHUM"
replace district = "PASHCHIMI SINGHBHUM" if district == "WEST SINGHBHUM"
replace district = "SAHIBZADA AJIT SINGH NAG*" if district == "S.A.S. NAGAR"
replace district = "Y.S.R." if district == "KADAPA"
replace district = "DOHAD" if district == "DAHOD"
replace district = "BID" if district == "BEED"
replace district = "WEST NIMAR" if district == "KHARGONE"
replace district = "EAST NIMAR" if district == "KHANDWA"
replace district = "SRI POTTI SRIRAMULU NELL*" if district == "S.P.S. NELLORE"
replace district = "KACHCHH" if district == "KUTCH"
replace district = "KHERI" if district == "LAKHIMPUR KHERI" & ///
	state == "UTTAR PRADESH"
replace district = "FAIZABAD" if district == "AYODHYA" & ///
	state == "UTTAR PRADESH"
replace district = "BALESHWAR" if district == "BALASORE" & ///
	state == "ODISHA"
replace district = "PASCHIM MEDINIPUR" if district == "MEDINIPUR WEST"
replace district = "KRA DAADI" if district == "KRA-DAADI"
replace district = "UPPER DIBANG VALLEY" if district == "DIBANG VALLEY"

* Aggregate Gaurella-Pendra-Marwahi into Bilaspur since formed in 2020,
* newer than the shapefile and therefore can't get any flows
replace district = "BILASPUR" if district == "GAURELA PENDRA MARWAHI"

* Drop island UT andaman and nicobar (lakasashweep already not present in data)
drop if state == "ANDAMAN & NICOBAR"

* Aggregate districts
collapse (sum) num_cases num_deaths num_tested, by(state district date)

* Make district id for matching to shapefile and linking back to 
* full time series
egen case_id = group(state district)

* Fix negative reported tests that clearly originate from a surrounding day
replace num_tested = 222267 - 221755 if district == "UDHAM SINGH NAGAR" & ///
	num_tested == 222267
replace num_tested = . if district == "UDHAM SINGH NAGAR" & /// 
	num_tested == -221755
	
replace num_tested = 910000 - 906671 if district == "GHAZIPUR" & ///
	num_tested == 910000
replace num_tested = . if district == "GHAZIPUR" & ///
	num_tested == -906671
	
replace num_tested = 621244 - 618806 if district == "PURI" & ///
	num_tested == 621244
replace num_tested = . if district == "PURI" & ///
	num_tested == -618806
	
replace num_tested = 610748 - 608779 if district == "CHANDRAPUR" & ///
	num_tested == 610748
replace num_tested = . if district == "CHANDRAPUR" & ///
	num_tested == -608779
replace num_tested = 30935 - 29065 if district == "CHANDRAPUR" & ///
	num_tested == 30935
replace num_tested = . if district == "CHANDRAPUR" & ///
	num_tested == -29065
	
replace num_tested = 179745 - 157341 if district == "VARANASI" & ///
	num_tested == 179745
replace num_tested = . if district == "VARANASI" & ///
	num_tested == -157341
	
replace num_tested = 120819 - 117157 if district == "SAMBHAL" & ///
	num_tested == 120819
replace num_tested = . if district == "SAMBHAL" & ///
	num_tested == -117157
	
replace num_tested = 100761 - 95044 if district == "BUXAR" & ///
	num_tested == 100761
replace num_tested = . if district == "BUXAR" & ///
	num_tested == -95044
	
replace num_tested = 92160 - 90647 if district == "KAIMUR" & ///
	num_tested == 92160
replace num_tested = . if district == "KAIMUR" & ///
	num_tested == -90647
	
replace num_tested = 65156 - 60617 if district == "GWALIOR" & ///
	num_tested == 65156
replace num_tested = . if district == "GWALIOR" & ///
	num_tested == -60617
	
replace num_tested = 63469 - 56680 if district == "NAGPUR" & ///
	num_tested == 63469
replace num_tested = . if district == "NAGPUR" & ///
	num_tested == -56680
	
replace num_tested = 186550 - 166309 if district == "GANJAM" & ///
	num_tested == 186550
replace num_tested = . if district == "GANJAM" & ///
	num_tested == -166309
	
replace num_tested = 55625 - 45489 if district == "GHAZIABAD" & ///
	num_tested == 55625
replace num_tested = . if district == "GHAZIABAD" & ///
	num_tested == -45489
	
replace num_tested = 41832 - 41432 if district == "PATHANKOT" & ///
	num_tested == 41832
replace num_tested = . if district == "PATHANKOT" & ///
	num_tested == -41432
	
replace num_tested = 39090 - 35097 if district == "PUDUCHERRY" & ///
	num_tested == 39090
replace num_tested = . if district == "PUDUCHERRY" & ///
	num_tested == -35097
	
replace num_tested = 39034 - 32034 if district == "BANDA" & ///
	num_tested == 39034
replace num_tested = . if district == "BANDA" & ///
	num_tested == -32034
	
replace num_tested = 37995 - 31395 if district == "BHAGALPUR" & ///
	num_tested == 37995
replace num_tested = . if district == "BHAGALPUR" & ///
	num_tested == -31395
	

replace num_tested = 34823 - 26127 if district == "RAE BARELI" & ///
	num_tested == 34823
replace num_tested = . if district == "RAE BARELI" & ///
	num_tested == -26127
	
replace num_tested = 23127 - 20648 if district == "HARDOI" & ///
	num_tested == 23127
replace num_tested = . if district == "HARDOI" & ///
	num_tested == -20648
	
replace num_tested = 20442 - 17930 if district == "SITAPUR" & ///
	num_tested == 20442
replace num_tested = . if district == "SITAPUR" & ///
	num_tested == -17930
	
replace num_tested = 13878 - 10325 if district == "KISHANGANJ" & ///
	num_tested == 13878
replace num_tested = . if district == "KISHANGANJ" & ///
	num_tested == -10325
	
replace num_tested = 6998 - 5794 if district == "CHIKKABALLAPURA" & ///
	num_tested == 6998
replace num_tested = . if district == "CHIKKABALLAPURA" & ///
	num_tested == -5794
	
replace num_tested = 5801 - 5422 if district == "KARAIKAL" & ///
	num_tested == 5801
replace num_tested = . if district == "KARAIKAL" & ///
	num_tested == -5422
	
replace num_tested = 8415 - 3755 if district == "SIDHI" & ///
	num_tested == 8415
replace num_tested = . if district == "SIDHI" & ///
	num_tested == -3755
	
replace num_tested = 2834 - 2674 if district == "YANAM" & ///
	num_tested == 2834
replace num_tested = . if district == "YANAM" & ///
	num_tested == -2674
	
replace num_tested = 6139 - (2628/2) if district == "SHIVPURI" & ///
	num_tested == 6139
replace num_tested = 3403 - (2628/2) if district == "SHIVPURI" & ///
	num_tested == 3403
replace num_tested = . if district == "SHIVPURI" & ///
	num_tested == -2628
	
replace num_tested = 3436 - 2499 if district == "HOSHANGABAD" & ///
	num_tested == 3436
replace num_tested = . if district == "HOSHANGABAD" & ///
	num_tested == -2499

replace num_tested = 2935 - 2322 if district == "ASHOKNAGAR" & ///
	num_tested == 2935
replace num_tested = . if district == "ASHOKNAGAR" & ///
	num_tested == -2322
	
replace num_tested = 3463 - 2183 if district == "SIPAHIJALA" & ///
	num_tested == 3463
replace num_tested = . if district == "SIPAHIJALA" & ///
	num_tested == -2183
	
replace num_tested = 2192 - 2126 if district == "GARIABAND" & ///
	num_tested == 2192
replace num_tested = . if district == "GARIABAND" & ///
	num_tested == -2126
	
replace num_tested = 3393 - 2100 if district == "WARDHA" & ///
	num_tested == 3393
replace num_tested = . if district == "WARDHA" & ///
	num_tested == -2100
	
replace num_tested = 2024 - 1936 if district == "DHALAI" & ///
	num_tested == 2024
replace num_tested = . if district == "DHALAI" & ///
	num_tested == -1936

replace num_tested = 2344 - 1520 if district == "NASHIK" & ///
	num_tested == 2344
replace num_tested = . if district == "NASHIK" & ///
	num_tested == -1520
	
replace num_tested = 1628 - 1423 if district == "MAHE" & ///
	num_tested == 1628
replace num_tested = . if district == "MAHE" & ///
	num_tested == -1423
	
replace num_tested = 2634 - 1285 if district == "KANNAUJ" & ///
	num_tested == 2634
replace num_tested = . if district == "KANNAUJ" & ///
	num_tested == -1285
	
replace num_tested = 58163 - 38191 if district == "MADHUBANI" & ///
	num_tested == 58163
replace num_tested = . if district == "MADHUBANI" & ///
	num_tested == -38191
	
replace num_tested = 34858 - 29213 if district == "KUSHINAGAR" & ///
	num_tested == 34858
replace num_tested = . if district == "KUSHINAGAR" & ///
	num_tested == -29213
	
replace num_tested = 21348 - 17517 if district == "CHANDAULI" & ///
	num_tested == 21348
replace num_tested = . if district == "CHANDAULI" & ///
	num_tested == -17517

replace num_tested = 8040 - 7199 if district == "SAGAR" & ///
	num_tested == 8040
replace num_tested = . if district == "SAGAR" & ///
	num_tested == -7199
	
replace num_tested = 6580 - 6501 if district == "KINNAUR" & ///
	num_tested == 6580
replace num_tested = . if district == "KINNAUR" & ///
	num_tested == -6501
	
replace num_tested = 1271 - 914 if district == "BHANDARA" & ///
	num_tested == 1271
replace num_tested = . if district == "BHANDARA" & ///
	num_tested == -914
	
replace num_tested = 965 - 905 if district == "SHAHDOL" & ///
	num_tested == 965
replace num_tested = . if district == "SHAHDOL" & ///
	num_tested == -905
	
* Evenly take from the surrounding ones since the one immediately before 
* would go negative (all 3---negative and the 2 positives---are an order
* of magnitude larger than surrounding values)
replace num_tested = 26314 - (29635/2) if district == "PATIALA" & ///
	num_tested == 26314
replace num_tested = 36840 - (29635/2) if district == "PATIALA" & ///
	num_tested == 36840
replace num_tested = . if district == "PATIALA" & ///
	num_tested == -29635
	
replace num_tested = 13225 - (12377/2) if district == "SANGRUR" & ///
	num_tested == 13225
replace num_tested = 13742 - (12377/2) if district == "SANGRUR" & ///
	num_tested == 13742
replace num_tested = . if district == "SANGRUR" & ///
	num_tested == -12377
	
replace num_tested = 7119 - (3623/2) if ///
	district == "SHAHID BHAGAT SINGH NAGAR" & ///
	num_tested == 7119
replace num_tested = 4310 - (3623/2) if ///
	district == "SHAHID BHAGAT SINGH NAGAR" & ///
	num_tested == 4310
replace num_tested = . if district == "SHAHID BHAGAT SINGH NAGAR" & ///
	num_tested == -3623

* Code two observations to missing that are unusually large negatives
* and do not have a surrounding positive testing value to couteract them
replace num_tested = . if num_tested == -7851 & district == "ANUPPUR"
replace num_tested = . if num_tested == -28381 & district == "UJJAIN"

* Save full series to match back later
tempfile cases_full
save `cases_full'

* Keep only necessary variables/observations for matching to shapefile
duplicates drop state district, force
keep state district case_id
tempfile cases_matching
save `cases_matching'

******************************************************************
* Prep shapefile
******************************************************************

* Load names from district shapefile
use "$dirpath_int_shapefiles/districts/aggregated/districts_delhiagg.dta", clear

* Rename variables
rename stname state
rename dtname district
drop JID

* Aggregate states missing district-wise information (Delhi is already aggregated)
replace district = "TELANGANA" if state == "TELANGANA"
replace district = "ASSAM" if state == "ASSAM"
replace district = "GOA" if state == "GOA"
replace district = "MANIPUR" if state == "MANIPUR"
replace district = "SIKKIM" if state == "SIKKIM"

* Recode Dadra and Nagar Haveli to be in the state of Daman and Diu to match
* the cases data
replace state = "DAMAN & DIU" if state == "DADRA & NAGAR HAVE"
replace district = "DADRA & NAGAR HAVELI" if district == "DADRA & NAGAR HAVE"

* Drop island UTs
drop if state == "LAKSHADWEEP"
drop if state == "ANDAMAN & NICOBAR"

* Delete districts that aren't considered part of India anymore
drop if district == "MUZAFFARABAD" & state == "JAMMU & KASHMIR"
drop if district == "MIRPUR" & state == "JAMMU & KASHMIR"

* Create dataset for matching
duplicates drop state district, force
egen JID = group(state district)

******************************************************************
* Fuzzy merge shapefile names and covid data
******************************************************************

* Fuzzy join shapefile and cases time series
reclink state district using `cases_matching', idmaster(JID) idusing(case_id) gen(reclinkscore)

* Keep necessary variables
keep state district case_id

* Rename districts
rename state state_shp
rename district district_shp

* Join back onto full cases data
merge 1:m case_id using `cases_full', nogen
drop case_id

* Use district shapefile names
drop district state
rename district_shp district
rename state_shp state
duplicates drop state district date, force

* Create unique district ids
egen district_id = group(state district)

* Temporarily save
tempfile cases_cleaned
save `cases_cleaned'

******************************************************************
* Fill in the full time series from march 2nd through sep 30 for each district
******************************************************************

* Get max date
sum date
local max_date = r(max)

* Get number of unique districts
duplicates drop state district, force
local num_districts = _N

* Fill in missing date observations by creating a complete timeseries for each district and merging
clear
local obs_num = `max_date' - mdy(3,2,2020) //march 2nd is start of series
set obs `=`obs_num' + 1'
gen date = mdy(3,1,2020) + _n
format date %dM_d,_CY
gen district_id = 1

tempfile dateseries
save `dateseries'

tempfile dateseries_cum
save `dateseries_cum'

clear

foreach i of numlist 2/`num_districts' {
	use `dateseries'
	replace district_id = `i'
	append using `dateseries_cum'
	save `dateseries_cum', replace
}

merge m:1 date district_id using `cases_cleaned', nogen

* Fill in missing variables
bysort district_id (state district): replace state = state[_N]
bysort district_id (state district): replace district = district[_N]

* Replace missing values to 0 for cases/deaths/tested 
* (only dates that reported a case in the raw data appear, so missing values indicate that day had no freported cases/deaths/tests)
replace num_cases = 0 if missing(num_cases)
replace num_deaths = 0 if missing(num_deaths)
replace num_tested = 0 if missing(num_tested)

* Add state id
egen state_id = group(state)

******************************************************************
* Backfill negative cases, deaths, and tests over previous positive entries
******************************************************************

local varlist cases deaths tested
foreach var of local varlist {
	
	preserve
	
	* Keep only observations with a nonmissing, nonzero entry
	keep if num_`var' != 0 & !missing(num_`var')

	* Initialize a variable equal to the value of `var'/deaths/tests if negative
	* and 0 otherwise
	gen neg_`var' = 0
	replace neg_`var' = num_`var' if num_`var' < 0 & !missing(num_`var')
	gen neg_flag = 0
	replace neg_flag = 1 if neg_`var' < 0 & !missing(num_`var')
	
	* Drop places that have no negative entries
	bysort state district: egen tot_neg = total(neg_flag)
	drop if tot_neg == 0

	* By district date, get the number of previous obs that are NOT negative
	* for each negative entry
	gen pos_`var' = 0
	replace pos_`var' = 1 if neg_flag == 0
	bysort state district (date): gen num_prev_pos_`var' = ///
		sum(pos_`var')
	
	* Average the negative values by those obs numbers, excluding when
	* the negative is the first negative of its district's time series. 
	* If the negative occurs before any positives (eg Lohit `var'), it
	* will be divided by 0 and coded as missing
	replace neg_`var' = neg_`var' / num_prev_pos_`var'

	* For each district, evenly back fill the negatives. If two negatives
	* overlap, sum them
	gsort state district -date
	by state district: replace neg_`var' = ///
		neg_`var'[_n] + neg_`var'[_n - 1] if _n > 1
	
	* Recode formerly negative entires to missing
	replace neg_`var' = . if neg_flag == 1
	
	* Take off the distributed negative entries from the original, 
	* positive ones. any originally negative entries are turned to missing
	replace num_`var' = num_`var' + neg_`var'
	
	* Recode remaining negatives to 0: all orig negatives have already been 
	* accounted for, and any remaining negatives had more than their previous
	* count subtracted off, eg 1 - 1.14
	replace num_`var' = 0 if num_`var' < 0 & !missing(num_`var') 

	* Keep necessary variables for merging back
	keep state district date num_`var'
	rename num_`var' num_`var'_fxd

	* Save fixes
	tempfile tmpfile
	save `tmpfile', replace

	* Reload original dataset
	restore
	
	* Add backfilled estimates back on
	merge 1:1 state district date using `tmpfile'

	* Use fixed estimates
	replace num_`var' = num_`var'_fxd if _merge == 3
	drop _merge num_`var'_fxd	

}

sort state district date

******************************************************************
* If cases are reported on day t and are reported before tests on day t', evenly backfill tests from t' to t-1
******************************************************************

* Get the first reported test number for each district and the date
replace num_tested = . if num_tested == 0

preserve
keep if !missing(num_tested)
bysort state district (date): gen num_tested_reports = _n if !missing(num_tested)
gen first_report_flag = 0
replace first_report_flag = 1 if num_tested_reports == 1
gsort state district -first_report_flag
by state district: gen date_first_report = date[1]
format date_first_report %td
keep state district date first_report_flag date_first_report
tempfile reports
save `reports'
restore

merge 1:1 state district date using `reports', nogen
replace first_report_flag = 0 if missing(first_report_flag)

gsort state district -first_report_flag
by state district: gen first_report_tests = num_tested[1]
by state district: replace date_first_report = date_first_report[1]

* Find the number of preceding days between the first test was reported and 
* 1 day prior to the first case being reported
preserve
bysort state district: keep if date <= date_first_report

* Drop districts that report no testing at any point for this section
drop if missing(date_first_report)

gen pos_case = 0
replace pos_case = 1 if num_cases > 0 & !missing(num_cases)

* Drop places with no positive cases before the first test date
by state district: egen tot_pos_cases = total(pos_case)
drop if tot_pos_cases == 0
	
* Find the day preceding the first positive case
gsort state district -pos_case date
by state district: gen day_before_first_case = date[1] - 1
format day_before_first_case %td

* Keep from the day before the first positive case to the day of the first test
by state district: keep if date >= day_before_first_case

* Find the number of days in this range
by state district: gen num_days = _N

* Divide tests on the first day by 
gen num_tested_fixed = first_report_tests / num_days

* Keep necessary variables
keep state district date num_tested_fixed date_first_report

tempfile fixed_tests
save `fixed_tests', replace
restore

* Add on to full dataset
merge 1:1 state district date using `fixed_tests'

* Replace old testing values with fixed ones where appropriate
replace num_tested = num_tested_fixed if _merge == 3
drop _merge num_tested_fixed first_report_tests first_report_flag
format date_first_report %td

* Top code testing values to the 99th percentile
replace num_tested = 0 if missing(num_tested)
bys state district: egen p99 = pctile(num_tested), p(99)
by state district: replace num_tested = p99 if num_tested > p99

******************************************************************
* Create running weekly test sum
******************************************************************

replace num_tested = . if num_tested == 0
rangestat (sum) num_tested_1wk = num_tested, ///
	interval(date -7 0) by(state district)

* Replace running weekly sum value to missing if no tests are reported past a given day in the sample
bysort state district (date): replace num_tested_1wk = . if ///
	missing(num_tested[_n]) & ///
	missing(num_tested[_n + 1]) & missing(num_tested[_n + 2]) & ///
	missing(num_tested[_n + 3]) & missing(num_tested[_n + 4]) & ///
	missing(num_tested[_n + 5]) & missing(num_tested[_n + 6]) & ///
	missing(num_tested[_n + 7]) & missing(num_tested[_n + 8]) & ///
	missing(num_tested[_n + 9]) & missing(num_tested[_n + 10]) & ///
	missing(num_tested[_n + 11]) & missing(num_tested[_n + 12]) & ///
	missing(num_tested[_n + 13]) & missing(num_tested[_n + 14]) & ///
	missing(num_tested[_n + 15]) & missing(num_tested[_n + 16]) & ///
	missing(num_tested[_n + 17]) & missing(num_tested[_n + 18]) & ///
	missing(num_tested[_n + 19]) & missing(num_tested[_n + 20]) & ///
	missing(num_tested[_n + 21]) & missing(num_tested[_n + 22]) & ///
	missing(num_tested[_n + 23]) & missing(num_tested[_n + 24]) & ///
	missing(num_tested[_n + 25]) & missing(num_tested[_n + 26]) & ///
	missing(num_tested[_n + 27]) & missing(num_tested[_n + 28]) & ///
	missing(num_tested[_n + 29]) & missing(num_tested[_n + 30]) & ///
	missing(num_tested[_n + 31]) & missing(num_tested[_n + 32]) & ///
	missing(num_tested[_n + 33]) & missing(num_tested[_n + 34]) & ///
	missing(num_tested[_n + 35]) & missing(num_tested[_n + 36]) & ///
	missing(num_tested[_n + 37]) & missing(num_tested[_n + 38]) & ///
	missing(num_tested[_n + 39]) & missing(num_tested[_n + 40]) & ///
	missing(num_tested[_n + 41]) & missing(num_tested[_n + 42]) & ///
	missing(num_tested[_n + 43]) & missing(num_tested[_n + 44]) & ///
	missing(num_tested[_n + 45]) & missing(num_tested[_n + 46]) & ///
	missing(num_tested[_n + 47]) & missing(num_tested[_n + 48]) & ///
	missing(num_tested[_n + 49]) & missing(num_tested[_n + 50]) & ///
	missing(num_tested[_n + 51]) & missing(num_tested[_n + 52]) & ///
	missing(num_tested[_n + 53]) & missing(num_tested[_n + 54]) & ///
	missing(num_tested[_n + 55]) & missing(num_tested[_n + 56]) & ///
	missing(num_tested[_n + 57]) & missing(num_tested[_n + 58]) & ///
	missing(num_tested[_n + 59]) & missing(num_tested[_n + 60]) & ///
	missing(num_tested[_n + 61]) & missing(num_tested[_n + 62]) & ///
	missing(num_tested[_n + 63]) & missing(num_tested[_n + 64]) & ///
	missing(num_tested[_n + 65]) & missing(num_tested[_n + 66]) & ///
	missing(num_tested[_n + 67]) & missing(num_tested[_n + 68]) & ///
	missing(num_tested[_n + 69]) & missing(num_tested[_n + 70]) & ///
	missing(num_tested[_n + 71]) & missing(num_tested[_n + 72]) & ///
	missing(num_tested[_n + 73]) & missing(num_tested[_n + 74]) & ///
	missing(num_tested[_n + 75]) & missing(num_tested[_n + 76]) & ///
	missing(num_tested[_n + 77]) & missing(num_tested[_n + 78]) & ///
	missing(num_tested[_n + 79]) & missing(num_tested[_n + 80]) & ///
	missing(num_tested[_n + 81]) & missing(num_tested[_n + 82]) & ///
	missing(num_tested[_n + 83]) & missing(num_tested[_n + 84]) & ///
	missing(num_tested[_n + 85]) & missing(num_tested[_n + 86]) & ///
	missing(num_tested[_n + 87]) & missing(num_tested[_n + 88]) & ///
	missing(num_tested[_n + 89]) & missing(num_tested[_n + 90]) & ///
	missing(num_tested[_n + 91]) & missing(num_tested[_n + 92]) & ///
	missing(num_tested[_n + 93]) & missing(num_tested[_n + 94]) & ///
	missing(num_tested[_n + 95]) & missing(num_tested[_n + 96]) & ///
	missing(num_tested[_n + 97]) & missing(num_tested[_n + 98]) & ///
	missing(num_tested[_n + 99]) & missing(num_tested[_n + 100]) & ///
	missing(num_tested[_n + 101]) & missing(num_tested[_n + 102]) & ///
	missing(num_tested[_n + 103]) & missing(num_tested[_n + 104]) & ///
	missing(num_tested[_n + 105]) & missing(num_tested[_n + 106]) & ///
	missing(num_tested[_n + 107]) & missing(num_tested[_n + 108]) & ///
	missing(num_tested[_n + 109]) & missing(num_tested[_n + 110]) & ///
	missing(num_tested[_n + 111]) & missing(num_tested[_n + 112]) & ///
	missing(num_tested[_n + 113]) & missing(num_tested[_n + 114]) & ///
	missing(num_tested[_n + 115]) & missing(num_tested[_n + 116]) & ///
	missing(num_tested[_n + 117]) & missing(num_tested[_n + 118]) & ///
	missing(num_tested[_n + 119]) & missing(num_tested[_n + 120]) & ///
	missing(num_tested[_n + 121]) & missing(num_tested[_n + 122]) & ///
	missing(num_tested[_n + 123]) & missing(num_tested[_n + 124]) & ///
	missing(num_tested[_n + 125]) & missing(num_tested[_n + 126]) & ///
	missing(num_tested[_n + 127]) & missing(num_tested[_n + 128]) & ///
	missing(num_tested[_n + 129]) & missing(num_tested[_n + 130]) & ///
	missing(num_tested[_n + 131]) & missing(num_tested[_n + 132]) & ///
	missing(num_tested[_n + 133]) & missing(num_tested[_n + 134]) & ///
	missing(num_tested[_n + 135]) & missing(num_tested[_n + 136]) & ///
	missing(num_tested[_n + 137]) & missing(num_tested[_n + 138]) & ///
	missing(num_tested[_n + 139]) & missing(num_tested[_n + 140]) & ///
	missing(num_tested[_n + 141]) & missing(num_tested[_n + 142]) & ///
	missing(num_tested[_n + 143]) & missing(num_tested[_n + 144]) & ///
	missing(num_tested[_n + 145]) & missing(num_tested[_n + 146]) & ///
	missing(num_tested[_n + 147]) & missing(num_tested[_n + 148]) & ///
	missing(num_tested[_n + 149]) & missing(num_tested[_n + 150]) & ///
	missing(num_tested[_n + 151]) & missing(num_tested[_n + 152]) & ///
	missing(num_tested[_n + 153]) & missing(num_tested[_n + 154]) & ///
	missing(num_tested[_n + 155]) & missing(num_tested[_n + 156]) & ///
	missing(num_tested[_n + 157]) & missing(num_tested[_n + 158]) & ///
	missing(num_tested[_n + 159]) & missing(num_tested[_n + 160]) & ///
	missing(num_tested[_n + 161]) & missing(num_tested[_n + 162]) & ///
	missing(num_tested[_n + 163]) & missing(num_tested[_n + 164]) & ///
	missing(num_tested[_n + 165]) & missing(num_tested[_n + 166]) & ///
	missing(num_tested[_n + 167]) & missing(num_tested[_n + 168]) & ///
	missing(num_tested[_n + 169]) & missing(num_tested[_n + 170]) & ///
	missing(num_tested[_n + 171]) & missing(num_tested[_n + 172]) & ///
	missing(num_tested[_n + 173]) & missing(num_tested[_n + 174]) & ///
	missing(num_tested[_n + 175]) & missing(num_tested[_n + 176]) & ///
	missing(num_tested[_n + 177]) & missing(num_tested[_n + 178]) & ///
	missing(num_tested[_n + 179]) & missing(num_tested[_n + 180]) & ///
	missing(num_tested[_n + 181]) & missing(num_tested[_n + 182]) & ///
	missing(num_tested[_n + 183]) & missing(num_tested[_n + 184]) & ///
	missing(num_tested[_n + 185]) & missing(num_tested[_n + 186]) & ///
	missing(num_tested[_n + 187]) & missing(num_tested[_n + 188]) & ///
	missing(num_tested[_n + 189]) & missing(num_tested[_n + 190]) & ///
	missing(num_tested[_n + 191]) & missing(num_tested[_n + 192]) & ///
	missing(num_tested[_n + 193]) & missing(num_tested[_n + 194]) & ///
	missing(num_tested[_n + 195]) & missing(num_tested[_n + 196]) & ///
	missing(num_tested[_n + 197]) & missing(num_tested[_n + 198]) & ///
	missing(num_tested[_n + 199]) & missing(num_tested[_n + 200]) & ///
	missing(num_tested[_n + 201]) & missing(num_tested[_n + 202]) & ///
	missing(num_tested[_n + 203]) & missing(num_tested[_n + 204]) & ///
	missing(num_tested[_n + 205]) & missing(num_tested[_n + 206]) & ///
	missing(num_tested[_n + 207]) & missing(num_tested[_n + 208]) & ///
	missing(num_tested[_n + 209]) & missing(num_tested[_n + 210]) & ///
	missing(num_tested[_n + 211]) & missing(num_tested[_n + 212]) & ///
	missing(num_tested[_n + 213])
	
replace num_tested = 0 if missing(num_tested)
	
* Change weekly tests to missing if cases are reported on a day
* but no weekly tests
replace num_tested_1wk = . if num_tested_1wk == 0 & ///
	num_cases > 0 & !missing(num_cases)
	
******************************************************************
* Average deaths on june 16 (reporting spike) over the previous 7 days for delhi and maha
******************************************************************

gen deaths_jun16 = num_deaths if ///
	date == date("2020/06/16", "YMD") & ///
	(state == "DELHI" | state == "MAHARASHTRA")
// divide by 8 since its -7 to 0 days
gen deaths_jun16_over8 = deaths_jun16 / 8 if ///
	(state == "DELHI" | state == "MAHARASHTRA")  
bysort state district (date): gen rownum = _n if ///
	(state == "DELHI" | state == "MAHARASHTRA")  
by state district (date): replace deaths_jun16_over8 = ///
	deaths_jun16_over8[107] if (rownum >= 107 - 7 & rownum <= 107) & ///
	(state == "DELHI" | state == "MAHARASHTRA") 

// replace deaths on the preceding 7 days with the averaged number plus
// however many deaths those days already had
replace num_deaths = 0 if missing(num_deaths) & ///
	(rownum >= 107 - 7 & rownum <= 107) & ///
	(state == "DELHI" | state == "MAHARASHTRA") 
replace num_deaths = 0 if ///
	(rownum == 107) & ///
	(state == "DELHI" | state == "MAHARASHTRA") 
replace num_deaths = num_deaths + deaths_jun16_over8 if ///
	(rownum >= 107 - 7 & rownum <= 107) & ///
	(state == "DELHI" | state == "MAHARASHTRA") 
	
drop deaths_jun16 deaths_jun16_over8 rownum

******************************************************************
* Tidy and output
******************************************************************

* Keep necessary variables
keep state district date num_cases num_deaths num_tested num_tested_1wk

* Create state and district identifiers
egen state_id = group(state)
egen district_id = group(state district)

* Output
compress *
save "$dirpath_int_covid/covid19india_data_cleaned.dta", replace

