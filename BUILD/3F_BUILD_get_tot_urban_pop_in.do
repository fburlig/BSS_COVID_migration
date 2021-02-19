
* Clean the fraction of each Indian district that is urban to identify those that are at least 80% urban

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

***************************************************************

* Initialize file paths in the directory
local files : dir "$dirpath_raw_census/india/d1" files "*.XLSX"
di `files'
cd "$dirpath_raw_census/india/d1"

* Initialize macro to append cleaned datasets to
tempfile districts
save `districts', emptyok

* Loop through files (states)
foreach file in `files' {
	
	* Load data
	import excel `file', clear

	* Keep necessary variables
	keep D-F L

	* Rename variables
	drop in 1
	replace D = "district" if _n == 1
	replace E = "population_type" if _n == 1
	replace F = "total_population" if _n == 1
	replace L = "urban_population" if _n == 1
	renvars, map(strtoname(@[1]))
	drop in 1/4

	* Keep population counts
	keep if population_type == "Total Population"
	drop population_type
	
	* Split by states/union territories
	if substr(district, 1, 5) == "State" {
		
		* Indicate the state
		gen state = substr(district, 9, strlen(district)) if ///
			substr(district, 1, 5) == "State" // state name
		gsort -state district // fill down
		replace state = state[1]
		
		* Drop state-total for states with more than 1 district
		drop if substr(district, 1, 5) == "State" & _N > 1
	}
	
	else if substr(district, 1, 15) == "Union Territory" {
		gen state = substr(district, 19, strlen(district)) if ///
			substr(district, 1, 15) == "Union Territory"
		gsort -state district
		replace state = state[1]
		drop if substr(district, 1, 15) == "Union Territory" & _N > 1
	}
	
	* Make district names uppercase
	replace district = upper(district)
	
	* Recast flow counts to numeric
	destring total_population urban_population, replace
	
	* Split Andhra Pradesh and Jammu & Kashmir into Telangana and Ladakh, resp.,
	* since the latter two states were formed after the 2011 Census was enumerated
	replace state = "TELANGANA" if state == "ANDHRA PRADESH" & ///
		(district == "KHAMMAM" | district == "KARIMNAGAR" | ///
		district == "WARANGAL" | district == "MEDAK" | ///
		district == "ADILABAD" | district == "RANGAREDDY" | ///
		district == "HYDERABAD" | district == "MAHBUBNAGAR" | ///
		district == "NALGONDA" | district == "NIZAMABAD")
		
	replace state = "LADAKH" if state == "JAMMU & KASHMIR" & ///
		(district == "LEH(LADAKH)" | district == "KARGIL")
	
	* Append to local macro collecting every district
	append using `districts'
    save `"`districts'"', replace
}

* Drop districts not in regressions
drop if (district == "PUNE" & state == "MAHARASHTRA") | ///
	(district == "AHMADABAD" & state == "GUJARAT") | ///
	(district == "INDORE" & state == "MADHYA PRADESH") | ///
	(district == "MUMBAI" & state == "MAHARASHTRA") | ///
	(district == "MUMBAI SUBURBAN" & state == "MAHARASHTRA") | ///
	state == "NCT OF DELHI" | ///
	state == "ANDAMAN & NICOBAR ISLANDS" | ///
	state == "LAKSHADWEEP"
	
* Aggregate states that are aggregated in the regs
replace district = "TELANGANA" if state == "TELANGANA"
replace district = "ASSAM" if state == "ASSAM"
replace district = "GOA" if state == "GOA"
replace district = "MANIPUR" if state == "MANIPUR"
replace district = "SIKKIM" if state == "SIKKIM"
collapse (sum) total_population urban_population, by(state district)

* Fraction of population that is urban
gen frac_urban = urban_population / total_population

* Tidy
order state district total_population urban_population

* Keep those whose population is at least 80% urban
keep if frac_urban >= 0.8
gsort -frac_urban

