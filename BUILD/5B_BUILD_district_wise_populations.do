

***** Clean district wise populations from the 2011 Census

*****************************************************************************
*****************************************************************************

***** SETUP:
global dirpath_in "$dirpath/data/raw/census11/d1"
global dirpath_out "$dirpath/data/generated/intermediate/Census"

*****************************************************************************
*****************************************************************************

* Initialize file paths in the directory
local files : dir "$dirpath_in" files "*.XLSX"
di `files'
cd "$dirpath_in"

* Initialize macro to append cleaned datasets to
tempfile districts
save `districts', emptyok

* Loop through files (states)
foreach file in `files' {
	
	* Load data
	import excel `file', clear
	
	* Keep necessary variables
	keep D-F
	
	* Rename variables
	drop in 1
	replace D = "district" if _n == 1
	replace E = "population_type" if _n == 1
	replace F = "population" if _n == 1
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
	destring population, replace
	
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

* Clean state names to match cases data
replace state = "DELHI" if state == "NCT OF DELHI"
replace state = "ANDAMAN & NICOBAR" if state == "ANDAMAN & NICOBAR ISLANDS"
replace state = "DAMAN & DIU" if state == "DADRA & NAGAR HAVELI"
drop if state == "LAKSHADWEEP"

* Combine populations for states/districts that are aggregated in the cases data
replace district = "DELHI" if state == "DELHI"
replace district = "TELANGANA" if state == "TELANGANA"
replace district = "ANDAMAN & NICOBAR" if state == "ANDAMAN & NICOBAR"
replace district = "ASSAM" if state == "ASSAM"
replace district = "GOA" if state == "GOA"
replace district = "MANIPUR" if state == "MANIPUR"


replace district = "SIANG_COMB" if (district == "EAST SIANG" | ///
	district == "WEST SIANG" | district == "LOWER SIANG" | ///
	district == "LEPA RADA" | district == "SHI YOMI" | district == "SIANG") ///
	& state == "ARUNACHAL PRADESH"
replace district = "KAMLE_COMB" if (district == "LOWER SUBANSIRI" | ///
	district == "UPPER SUBANSIRI" | district == "KAMLE") & ///
	state == "ARUNACHAL PRADESH"
replace district = "BOTAD_COMB" if (district == "AHMADABAD" | ///
	district == "BHAVNAGAR" | district == "BOTAD") & state == "GUJARAT"
replace district = "MORADABAD_COMB" if ///
	(district == "SAMBHAL" | district == "MORADABAD" | district == "BUDAUN") & ///
	state == "UTTAR PRADESH"
replace district = "MORBI_COMB" if (district == "RAJKOT" | ///
	district == "SURENDRANAGAR" | district == "JAMNAGAR" | ///
	district == "MORBI") & state == "GUJARAT"
replace district = "MAHISAGAR_COMB" if (district == "KHEDA" | ///
	district == "PANCH MAHALS" | district == "MAHISAGAR") & state == "GUJARAT"
replace district = "MUMBAI" if district == "MUMBAI SUBURBAN"

* Clean district names to match cases data
replace district = "UPPER DIBANG VALLEY" if district == "DIBANG VALLEY" & ///
	state == "ARUNACHAL PRADESH"
replace district = "BENGALURU RURAL" if district == "BANGALORE RURAL" & ///
	state == "KARNATAKA"
replace district = "VIJAYAPURA" if district == "BIJAPUR" & ///
	state == "KARNATAKA"
replace district = "EAST NIMAR" if district == "KHANDWA (EAST NIMAR)"
replace district = "BELAGAVI" if district == "BELGAUM"
replace district = "BALLARI" if district == "BELLARY"
replace district = "WEST NIMAR" if district == "KHARGONE (WEST NIMAR)"
replace district = "MEDINIPUR WEST" if district == "PASCHIM MEDINIPUR"
replace district = "LEH" if district == "LEH(LADAKH)"
replace district = "JYOTIBA PHULE NAGAR" if district == "AMROHA" & ///
	state == "UTTAR PRADESH"
replace district = "BHADOHI" if district == "SANT RAVIDAS NAGAR (BHADOHI)"
replace district = "HATHRAS" if district == "MAHAMAYA NAGAR" & ///
	state == "UTTAR PRADESH"
replace district = "KASGANJ" if district == "KANSHIRAM NAGAR" & ///
	state == "UTTAR PRADESH"
replace district = "PRAYAGRAJ" if district == "ALLAHABAD" & ///
	state == "UTTAR PRADESH"
replace district = "HOOGHLY" if district == "HUGLI"
replace district = "HOWRAH" if district == "HAORA"
replace district = "AMROHA" if district == "JYOTIBA PHULE NAGAR"
replace district = "KALABURAGI" if district == "GULBARGA"
replace district = "NUH" if district == "MEWAT"

replace district = "SIKKIM" if state == "SIKKIM"

collapse (sum) population, by(state district)

* Drop mumbai
drop if district == "MUMBAI"
drop if state == "ANDAMAN & NICOBAR"

* Create unique district id
egen pop_id = group(state district)

order state district pop_id population

* Output
save "$dirpath_out/census11_districtpop.dta", replace



