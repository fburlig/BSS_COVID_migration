
***** Clean census data for Indonesia

***** SETUP:
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
global dirpath_final "$dirpath_gen/final"
global dirpath_final_reg_inputs "$dirpath_final/Regression inputs"
global dirpath_final_results "$dirpath_final/results"

***************************************************************
* Subset data
***************************************************************

* Load data
use "$dirpath_raw_census/indonesia/indonesia_2010_prepped.dta", clear

* Keep necessary variables
/*
-pernum numbers all persons within each household consecutively
-perwt indicates the number of persons in the actual population represented by the person in the sample.
-geolev1_destin indicates major administrative unit in which the household was enumerated
---> only enumerated location var I could find. the source variable I chose corresponds to this
-migrate5_adm1 indicates whether someone migrated provinces from 5 years ago
---> matches when geolev1_destin != geolev1_orig
-geolev1_orig indicates province of residence 5 years ago
---> other variables with the suffix orig indicate province of residence 5 years ago, eg orig_adm1
*/

keep perwt geolev1_destin migrate5_adm1 geolev1_orig

* Make sure no entries are missing
foreach var of varlist * {
	drop if missing(`var')
}

* Keep if indicated they migrated
count if geolev1_destin != geolev1_orig
local count_diff = r(N)
count if migrate5_adm1 == 1
assert `count_diff' == r(N)
keep if migrate5_adm1 == 1
assert geolev1_destin != geolev1_orig
drop migrate5_adm1

***************************************************************
* Clean data
***************************************************************

* Code in names of provinces
// https://international.ipums.org/international/resources/misc_docs/geolevel1.pdf
foreach var of varlist geolev1_destin geolev1_orig {
	gen `var'_name = ""
	replace `var'_name = "Nanggroe Aceh Darussalam" if `var' == 360011
	replace `var'_name = "Sumatera Utara" if `var' == 360012
	replace `var'_name = "Sumatera Barat" if `var' == 360013
	replace `var'_name = "Kepulauan Riau, Riau" if `var' == 360014
	replace `var'_name = "Jambi" if `var' == 360015
	replace `var'_name = "Bangka Belitung, Sumatera Selatan" ///
		if `var' == 360016
	replace `var'_name = "Bengkulu" if `var' == 360017
	replace `var'_name = "Lampung" if `var' == 360018
	replace `var'_name = "DKI Jakarta" if `var' == 360031
	replace `var'_name = "Banten, Jawa Barat" if `var' == 360032
	replace `var'_name = "Jawa Tengah" if `var' == 360033
	replace `var'_name = "DKI Yogyakarta" if `var' == 360034
	replace `var'_name = "Jawa Timur" if `var' == 360035
	replace `var'_name = "Bali" if `var' == 360051
	replace `var'_name = "Nusa Tenggara Barat" if `var' == 360052
	replace `var'_name = "Nusa Tenggara Timur" if `var' == 360053
	replace `var'_name = "Kalimantan Barat" if `var' == 360061
	replace `var'_name = "Kalimantan Tengah" if `var' == 360062
	replace `var'_name = "Kalimantan Selatan" if `var' == 360063
	replace `var'_name = "Kalimantan Timur" if `var' == 360064
	replace `var'_name = "Gorontalo, Sulawesi Utara" ///
		if `var' == 360071
	replace `var'_name = "Sulawesi Tengah" if `var' == 360072
	replace `var'_name = "Sulawesi Barat, Sulawesi Selatan" ///
		if `var' == 360073
	replace `var'_name = "Sulawesi Tenggara" if `var' == 360074
	replace `var'_name = "Maluku, Maluku Utara" if `var' == 360081
	replace `var'_name = "Papua, Papua Barat" if `var' == 360094
	replace `var'_name = "East Timor" if `var' == 360626
	replace `var'_name = "Lake Toba" if `var' == 360888

	* Make sure replaced all names
	assert !missing(`var'_name)
	
	* Clean up names
	replace `var'_name = lower(`var'_name)
	replace `var'_name = strtrim(`var'_name)
	replace `var'_name = "aceh" if ///
		`var'_name == "nanggroe aceh darussalam"
	replace `var'_name = "jakarta" if ///
		`var'_name == "dki jakarta"
	replace `var'_name = "yogyakarta" if ///
		`var'_name == "dki yogyakarta"
	
	* Convert indonesian words to english
	replace `var'_name = ///
		subinstr(`var'_name, "kepulauan", "islands", .)
	replace `var'_name = subinstr(`var'_name, "utara", "north", .)
	replace `var'_name = subinstr(`var'_name, "barat", "west", .)
	replace `var'_name = ///
		subinstr(`var'_name, "tengah", "central", .)
	replace `var'_name = subinstr(`var'_name, "timur", "east", .)
	replace `var'_name = ///
		subinstr(`var'_name, "selatan", "south", .)
}

* Drop if, after collapsing, two regions go to each other
drop if geolev1_destin_name == geolev1_orig_name

* Create send-rec pairwise matrix
collapse (sum) migrants = perwt, ///
	by(geolev1_destin_name geolev1_orig_name)
	
***************************************************************
* Output
***************************************************************

// counts from hotspots --> non-hotspots
// hotspot = jakarta
keep if geolev1_destin_name == "jakarta"
drop if geolev1_orig_name == "jakarta"
collapse (sum) migrants, by(geolev1_orig_name)
rename geolev1_orig_name subregion1_name
egen census_id = group(subregion1_name)
compress *
save "$dirpath_int_census/indonesia_hotspot_to_nonhotspot_migrants.dta", replace

