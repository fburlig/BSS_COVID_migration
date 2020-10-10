***** District wise migration counts to Mumbai/Mumbai Suburban 

***** SETUP:
global dirpath_in "$dirpath/data/raw/census11"
global dirpath_out "$dirpath/data/generated/intermediate/Census"

****************************************************************************
****************************************************************************

** Steps:
* 1. Find the in-state district-wise migration-from-birth counts for Mumbai+Mumbai 
* Suburban (hereafter just Mumbai)
* (from the D11)

* 2. Find the state-wise number --> share who have migrated to Mumbai from birth
* (from the D1)

* 3. Since Telangana was formed in 2014 from part of Andhra Pradesh, 
* split the shares/flows to AP by the total population between the eventual
* Telangana and non-Telangana districts

* 4. Similar to 3 for Ladakh splitting from Jammu & Kashmir in 2019

* 5. Merge datasets

* 6. Clean up and output

*****************************************************************************
*****************************************************************************

** 1: Find the in-state district-wise migration-from-birth counts for 
* Mumbai+Mumbai Suburban

******************************************************************************
***==*************************************************************************

* Load in-state flows from birth to Mumbai+Mumbai suburban
cd "$dirpath_in/d11"
import excel "DS-2700-D11-MDDS.XLSX", clear

* Keep necessary variables
keep D-F
	
* Rename variables
drop in 1
renvars, map(strtoname(@[1]))
drop in 1/4
rename *, lower
rename area_name district_dest
rename birth_place district_src
rename place_of_enumeration flows_birth_d

* Recast variables as numeric
destring flows_birth_d, replace
	
* Clean source district names
keep if substr(district_src, 1, 8) == "District"
replace district_src = substr(district_src, 12, .)
replace district_src = substr(district_src, 1, length(district_src) - 5)
	
* Remove intra-district pairs
drop if district_dest == district_src
	
* Keep mumbai+mumbai suburban districts as only sources, drop them from
* destinations
keep if district_dest == "Mumbai" | district_dest == "Mumbai Suburban"
drop if district_src == "Mumbai" | district_src == "Mumbai Suburban"

* Add state name
gen state_src = "Maharashtra"

* Sum flows sent by each source district
collapse (sum) flows_birth_d, by(state_src district_src)

* Get in-state shares
egen tot_birth_d = total(flows_birth_d)
gen share_birth_d = flows_birth_d / tot_birth_d

* Keep necessary variables
keep state_src district_src share_birth_d

* Reorder dataset
order state_src district_src share_birth_d

* Temporarily save
tempfile share_birth_d_maha
save `share_birth_d_maha'

*****************************************************************************
*****************************************************************************

** 2. Find the state-wise number --> share who have migrated to Mumbai from birth

*****************************************************************************
*****************************************************************************

* Load data
cd "$dirpath_in/d1"
import excel "DS-2700-D01-MDDS.XLSX", clear

* Keep necessary variables
keep D-F

* Rename variables
drop in 1
replace D = "district" if _n == 1
replace E = "birth_place" if _n == 1
replace F = "flows_birth_s" if _n == 1
renvars, map(strtoname(@[1]))
drop in 1/4

* Recast flow counts to numeric
destring flows_birth_s, replace

* Keep flows to Mumbai + Mumbai Suburban 
* note: some district-wise counts are unclassifiable, so the sum of the district
* wise counts will be slightly lower than mumbai+mumbai suburbans's total
* number of inter-district intra-state migrants
keep if district == "Mumbai Suburban" | district == "Mumbai"

* Keep Indian states among all sources (domestic + international) exluding
* note. Maha counts are given by "born in other districts of the state"
keep if birth_place == "Jammu & Kashmir" | birth_place == "Himachal Pradesh" | ///
	birth_place == "Punjab" | birth_place == "Chandigarh" | ///
	birth_place == "Uttarakhand" | birth_place == "Haryana" | ///
	birth_place == "NCT of Delhi" | birth_place == "Rajasthan" | ///
	birth_place == "Uttar Pradesh" | birth_place == "Bihar" | ///
	birth_place == "Sikkim" | birth_place == "Arunachal Pradesh" | ///
	birth_place == "Nagaland" | birth_place == "Manipur" | ///
	birth_place == "Mizoram" | birth_place == "Tripura" | ///
	birth_place == "Meghalaya" | birth_place == "Assam" | ///
	birth_place == "West Bengal" | birth_place == "Jharkhand" | ///
	birth_place == "Odisha" | birth_place == "Chhattisgarh" | ///
	birth_place == "Madhya Pradesh" | birth_place == "Gujarat" | ///
	birth_place == "Daman & Diu" | birth_place == "Dadra & Nagar Haveli" | ///
	birth_place == "Andhra Pradesh" | birth_place == "Karnataka" | ///
	birth_place == "Goa" | birth_place == "Lakshadweep" | ///
	birth_place == "Kerala" | birth_place == "Tamil Nadu" | ///
	birth_place == "Puducherry" | birth_place == "Andaman & Nicobar Islands" | ///
	birth_place == "Born in other districts of the state"
	
* Recode inter-district intra-state Maha flows to Mumbai
replace birth_place = "Maharashtra" if ///
	birth_place == "Born in other districts of the state"
	
* Combine Dadra & Nagar Haveli and Daman & Diu
replace birth_place = "Daman & Diu" if birth_place == "Dadra & Nagar Haveli"
collapse (sum) flows_birth_s, by(birth_place)

* Rename state variable
rename birth_place state_src

* Temporarily save
tempfile flows_birth_s
save `flows_birth_s'

*****************************************************************************
*****************************************************************************

** 3. Split Andhra Pradesh into 2 pieces: Andhra Pradesh and Telangana
* by the district-wise population of eventual Telangana districts

*****************************************************************************
*****************************************************************************

* Load data
cd "$dirpath_in/d1"
import excel "DS-2800-D01-MDDS.XLSX", clear

* Keep necessary variables
keep D-F

* Rename variables
drop in 1
replace D = "district_src" if _n == 1
replace E = "pop_indicator" if _n == 1
replace F = "population" if _n == 1
renvars, map(strtoname(@[1]))
drop in 1/4

* Keep only district-wise population counts
keep if pop_indicator == "Total Population"
drop if district_src == "State - ANDHRA PRADESH"
drop pop_indicator

* Recast flow counts to numeric
destring population, replace

* Add a variable for AP for merging
gen state_src = "Andhra Pradesh"

* Make district names upper case
replace district_src = upper(district_src)

* Indicate whether the district is now in Telangana or still in AP
gen in_TG = 0
replace in_TG = 1 if district == "KHAMMAM" | district == "KARIMNAGAR" | ///
	district == "WARANGAL" | district == "MEDAK" | ///
	district == "ADILABAD" | district == "RANGAREDDY" | ///
	district == "HYDERABAD" | district == "MAHBUBNAGAR" | ///
	district == "NALGONDA" | district == "NIZAMABAD"

* Find share of population in what is now Telangana vs Andhra Pradesh
egen tot_p = total(population)
bysort in_TG: egen tot_p_AP_TG = total(population)
gen pop_share_AP_TG = tot_p_AP_TG / tot_p

* Keep necessary variables
keep state_src in_TG pop_share_AP_TG

duplicates drop in_TG, force

* Temporarily save
tempfile AP_TG_pop_share
save `AP_TG_pop_share'

*****************************************************************************
*****************************************************************************

** 4. Similar to 3 for Ladakh splitting from J&K

*****************************************************************************
*****************************************************************************

* Load data
cd "$dirpath_in/d1"
import excel "DS-0100-D01-MDDS.XLSX", clear

* Keep necessary variables
keep D-F

* Rename variables
drop in 1
replace D = "district_src" if _n == 1
replace E = "pop_indicator" if _n == 1
replace F = "population" if _n == 1
renvars, map(strtoname(@[1]))
drop in 1/4

* Keep only district-wise population counts
keep if pop_indicator == "Total Population"
drop if district_src == "State - JAMMU & KASHMIR"
drop pop_indicator

* Recast flow counts to numeric
destring population, replace

* Add a variable for AP for merging
gen state_src = "Jammu & Kashmir"

* Make district names upper case
replace district_src = upper(district_src)

* Indicate whether the district is now in Telangana or still in AP
gen in_LA = 0
replace in_LA = 1 if district == "LEH(LADAKH)" | district == "KARGIL"

* Find share of population in what is now Telangana vs Andhra Pradesh
egen tot_p = total(population)
bysort in_LA: egen tot_p_JK_LA = total(population)
gen pop_share_JK_LA = tot_p_JK_LA / tot_p

* Keep necessary variables
keep state_src in_LA pop_share_JK_LA

duplicates drop in_LA, force

* Temporarily save
tempfile JK_LA_pop_share
save `JK_LA_pop_share'

*****************************************************************************
*****************************************************************************

** 5. Merge

*****************************************************************************
*****************************************************************************

* Load state-wise birth flows
use `flows_birth_s', clear

* Add indicator for in Maharashtra or not
gen in_state = 0
replace in_state = 1 if state_src == "Maharashtra"

* Adjust AP and TJ flows/shares
merge 1:m state_src using `AP_TG_pop_share', nogen
replace state = "Telangana" if in_TG == 1
replace flows_birth_s = flows_birth_s * pop_share_AP_TG if !missing(in_TG)
drop in_TG pop_share_AP_TG

* Adjust JK and LA flows/shares
merge 1:m state_src using `JK_LA_pop_share', nogen
replace state = "Ladakh" if in_LA == 1
replace flows_birth_s = flows_birth_s * pop_share_JK_LA if !missing(in_LA)
drop in_LA pop_share_JK_LA

* Add district-wise birth flows within maha
merge 1:m state_src using `share_birth_d_maha', nogen

* Temporarily save
tempfile flows_all
save `flows_all'


*****************************************************************************
*****************************************************************************

**** 6. Clean up and output

*****************************************************************************
*****************************************************************************

* Rename Delhi
replace state_src = "Delhi" if state_src == "NCT of Delhi"

* Make all names uppercase
replace state_src = upper(state_src)
replace district_src = upper(district_src)

* Rename variables
rename state_src state
rename district_src district

* Drop island UTs
drop if state == "LAKSHADWEEP"
drop if state == "ANDAMAN & NICOBAR ISLANDS"

* Sort dataset
sort state district

* Output
save "$dirpath_out/census11_migrants_mumbai.dta", replace

