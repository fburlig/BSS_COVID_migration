
***** Clean census data for the Philippines

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
global dirpath_int_shapefiles "$dirpath_int/shapefiles"
global dirpath_final "$dirpath_gen/final"
global dirpath_final_reg_inputs "$dirpath_final/Regression inputs"
global dirpath_final_results "$dirpath_final/results"

***************************************************************
* Subset data
***************************************************************

* Load data
use "$dirpath_raw_census/Philippines/philippines_2010_prepped.dta", clear

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
	assert !missing(`var')
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
	replace `var'_name = "Abra" if `var' == 608001
	replace `var'_name = "Agusan del norte" if `var' == 608002
	replace `var'_name = "Agusan del sur" if `var' == 608003
	replace `var'_name = "Aklan" if `var' == 608004
	replace `var'_name = "Albay" if `var' == 608005
	replace `var'_name = "Antique" if `var' == 608006
	replace `var'_name = "Basilan, City Of Isabela" if ///
		`var' == 608007
	replace `var'_name = "Bataan" if `var' == 608008
	replace `var'_name = "Batangas" if `var' == 608010
	replace `var'_name = "Benguet" if `var' == 608011
	replace `var'_name = "Bohol" if `var' == 608012
	replace `var'_name = "Bukidnon" if `var' == 608013
	replace `var'_name = "Bulacan" if `var' == 608014
	replace `var'_name = "Cagayan, Batanes" if `var' == 608015
	replace `var'_name = "Camarines norte" if `var' == 608016
	replace `var'_name = "Camarines Sur" if `var' == 608017
	replace `var'_name = "Camiguin" if `var' == 608018
	replace `var'_name = "Capiz" if `var' == 608019
	replace `var'_name = "Catanduanes" if `var' == 608020
	replace `var'_name = "Cavite" if `var' == 608021
	replace `var'_name = "Cebu" if `var' == 608022
	replace `var'_name = "Davao (Davao del Norte)" if ///
		`var' == 608023
	replace `var'_name = "Davao del Sur" if `var' == 608024
	replace `var'_name = "Davao Oriental" if `var' == 608025
	replace `var'_name = "Eastern Samar" if `var' == 608026
	replace `var'_name = "Ifugao" if `var' == 608027
	replace `var'_name = "Ilocos Norte" if `var' == 608028
	replace `var'_name = " Ilocos Sur" if `var' == 608029
	replace `var'_name = "Iloilo, Guimaras" if `var' == 608030
	replace `var'_name = "Isabela" if `var' == 608031
	replace `var'_name = "Kalinga-Apayao, Apayo, Kalinga" if ///
		`var' == 608032
	replace `var'_name = "La Union" if `var' == 608033
	replace `var'_name = "Laguna" if `var' == 608034
	replace `var'_name = "Lanao del Norte" if `var' == 608035
	replace `var'_name = "Lanao del Sur" if `var' == 608036
	replace `var'_name = "Leyte, Biliran" if `var' == 608037
	replace `var'_name = "Maguindanao, Cotabato city" if ///
		`var' == 608038
	replace `var'_name = "Manila" if `var' == 608039
	replace `var'_name = "Marinduque" if `var' == 608040
	replace `var'_name = "Masbate" if `var' == 608041
	replace `var'_name = "Misamis Occidental" if `var' == 608042
	replace `var'_name = "Misamis Oriental" if `var' == 608043
	replace `var'_name = "Mountain Province" if `var' == 608044
	replace `var'_name = "Negros Occidental" if `var' == 608045
	replace `var'_name = "Negros Oriental" if `var' == 608046
	replace `var'_name = "Cotabato (North Cotabato)" if ///
		`var' == 608047
	replace `var'_name = "Northern Samar" if `var' == 608048
	replace `var'_name = "Nueva Ecija" if `var' == 608049
	replace `var'_name = "Nueva Vizcaya" if `var' == 608050
	replace `var'_name = "Occidental Mindoro" if `var' == 608051
	replace `var'_name = "Oriental Mindoro" if `var' == 608052
	replace `var'_name = "Palawan" if `var' == 608053
	replace `var'_name = "Pampanga" if `var' == 608054
	replace `var'_name = "Pangasinan" if `var' == 608055
	replace `var'_name = "Quezon" if `var' == 608056
	replace `var'_name = "Quirino" if `var' == 608057
	replace `var'_name = "Rizal" if `var' == 608058
	replace `var'_name = "Romblon" if `var' == 608059
	replace `var'_name = "Samar (Western Samar)" if ///
		`var' == 608060
	replace `var'_name = "Siquijor" if `var' == 608061
	replace `var'_name = "Sorsogon" if `var' == 608062
	replace `var'_name = "South Cotabato, Sarangani" if ///
		`var' == 608063
	replace `var'_name = "Southern Leyte" if `var' == 608064
	replace `var'_name = "Sultan Kudarat" if `var' == 608065
	replace `var'_name = "Sulu" if `var' == 608066
	replace `var'_name = "Surigao Del Norte, Dinagat islands" ///
		if `var' == 608067
	replace `var'_name = "Surigao del Sur" if `var' == 608068
	replace `var'_name = "Tarlac" if `var' == 608069
	replace `var'_name = "Tawi-Tawi" if `var' == 608070
	replace `var'_name = "Zambales" if `var' == 608071
	replace `var'_name = "Zamboanga Norte" if `var' == 608072
	replace `var'_name = ///
		"Zamboanga del Sur, Zamboanga Sibugay" if `var' == 608073
	replace `var'_name = "Manila Metro, 2nd District" if ///
		`var' == 608074
	replace `var'_name = "Manila Metro, 3rd District" if ///
		`var' == 608075
	replace `var'_name = "Manila Metro, 4th District" if ///
		`var' == 608076
	replace `var'_name = "Aurora" if `var' == 608077
	
	* Make sure replaced all names
	assert !missing(`var'_name)
	
	* Clean up names
	replace `var'_name = lower(`var'_name)
	replace `var'_name = strtrim(`var'_name)
	
	* Combine regions in national capital region
	replace `var'_name = "national capital region" if ///
		`var'_name == "manila" | ///
		`var'_name == "manila metro, 2nd district" | ///
		`var'_name == "manila metro, 3rd district" | ///
		`var'_name == "manila metro, 4th district"

	* Clean names to better match covid data
	replace `var'_name = "samar" if ///
		`var'_name == "samar (western samar)"
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
// hotspots = national capital region, cebu
preserve
keep if geolev1_destin_name == "national capital region" | ///
	geolev1_destin_name == "cebu"
drop if geolev1_orig_name == "national capital region" | ///
	geolev1_orig_name == "cebu"
collapse (sum) migrants, by(geolev1_orig_name)
rename geolev1_orig_name subregion2_name
egen census_id = group(subregion2_name)
compress *
save "$dirpath_int_census/philippines_hotspot_to_nonhotspot_migrants.dta", replace
restore
