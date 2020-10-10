***************************************************************************
***************************************************************************

***** Merge district-wise populations onto cases data

***************************************************************************
***************************************************************************

***** SETUP:
global dirpath_cases "$dirpath/data/generated/intermediate/covid"
global dirpath_pop "$dirpath/data/generated/intermediate/Census"

***************************************************************************
***************************************************************************

** Load cases/flows data
use "$dirpath_cases/covid19india_data_cleaned_remittances.dta", clear
drop state_id district_id flows_birth_s in_state share_birth_d tot_5m 

**** Aggregate districts names formed since 2011
* ARUNACHAL PRADESH
replace district = "TIRAP" if district == "LONGDING" ///
	& state == "ARUNACHAL PRADESH"
replace district = "LOHIT" if district == "NAMSAI" ///
	& state == "ARUNACHAL PRADESH"
replace district = "KURUNG KUMEY" if district == "KRA DAADI" ///
	& state == "ARUNACHAL PRADESH"
replace district = "SIANG_COMB" if (district == "EAST SIANG" | ///
	district == "WEST SIANG" | district == "LOWER SIANG" | ///
	district == "LEPA RADA" | district == "SHI YOMI" | district == "SIANG") ///
	& state == "ARUNACHAL PRADESH"
replace district = "KAMLE_COMB" if (district == "LOWER SUBANSIRI" | ///
	district == "UPPER SUBANSIRI" | district == "KAMLE") & ///
	state == "ARUNACHAL PRADESH"
replace district = "EAST KAMENG" if district == "PAKKE KESSANG" ///
	& state == "ARUNACHAL PRADESH"
	
* CHHATTISGARH
replace district = "DAKSHIN BASTAR DANTEWADA" if district == "SUKMA" & ///
	state == "CHHATTISGARH"
replace district = "BASTAR" if district == "KONDAGAON" & ///
	state == "CHHATTISGARH"
replace district = "DURG" if (district == "BALOD" | district == "BAMETARA") & ///
	state == "CHHATTISGARH"
replace district = "RAIPUR" if (district == "BALODA BAZAR" | ///
	district == "GARIABAND") & state == "CHHATTISGARH"
replace district = "BILASPUR" if district == "MUNGELI" & ///
	state == "CHHATTISGARH"
replace district = "SURGUJA" if (district == "SURAJPUR" | ///
	district == "BALRAMPUR") & state == "CHHATTISGARH"

	
* GUJARAT
replace district = "SABAR KANTHA" if district == "ARAVALLI" & /// 
	state == "GUJARAT"
replace district = "BOTAD_COMB" if (district == "AHMADABAD" | ///
	district == "BHAVNAGAR" | district == "BOTAD") & state == "GUJARAT"
replace district = "VADODARA" if district == "CHOTA UDAIPUR" & /// 
	state == "GUJARAT"
replace district = "JAMNAGAR" if district == "DEVBHUMI DWARKA" & /// 
	state == "GUJARAT"
replace district = "MAHISAGAR_COMB" if (district == "KHEDA" | ///
	district == "PANCH MAHALS" | district == "MAHISAGAR") & state == "GUJARAT"
replace district = "MORBI_COMB" if (district == "RAJKOT" | ///
	district == "SURENDRANAGAR" | district == "JAMNAGAR" | ///
	district == "MORBI") & state == "GUJARAT"
replace district = "JUNAGADH" if district == "GIR SOMNATH" & /// 
	state == "GUJARAT"
	
* HARYANA
replace district = "BHIWANI" if district == "CHARKI DADRI" & ///
	state == "HARYANA"
	
* MADHYA PRADESH
replace district = "TIKAMGARH" if district == "NIWARI" & ///
	state == "MADHYA PRADESH"
replace district = "SHAJAPUR" if district == "AGAR MALWA" & ///
	state == "MADHYA PRADESH"
	
* MEGHALAYA
replace district = "JAINTIA HILLS" if ///
	(district == "EAST JAINTIA HILLS" | district == "WEST JAINTIA HILLS") & ///
	state == "MEGHALAYA"
replace district = "EAST GARO HILLS" if district == "NORTH GARO HILLS" & ///
	state == "MEGHALAYA"
replace district = "WEST GARO HILLS" if ///
	district == "SOUTH WEST GARO HILLS" & state == "MEGHALAYA"
replace district = "WEST KHASI HILLS" if ///
	district == "SOUTH WEST KHASI HILLS" & state == "MEGHALAYA"
	
* MIZORAM
replace district = "LUNGLEI" if district == "HNAHTHIAL" & ///
	state == "MIZORAM"
replace district = "CHAMPHAI" if district == "KHAWZAWL" & ///
	state == "MIZORAM"
replace district = "AIZAWL" if district == "SAITUAL" & ///
	state == "MIZORAM"
	
* PUNJAB
replace district = "FIROZPUR" if district == "FAZILKA" & ///
	state == "PUNJAB"
replace district = "GURDASPUR" if district == "PATHANKOT" & ///
	state == "PUNJAB"
	
* TAMIL NADU
replace district = "TIRUNELVELI" if district == "TENKASI" ///
	& state == "TAMIL NADU"
replace district = "VILUPPURAM" if district == "KALLAKURICHI" & ///
	state == "TAMIL NADU"
replace district = "VELLORE" if (district == "RANIPET" | ///
	district == "TIRUPATHUR") & state == "TAMIL NADU"
replace district = "KANCHEEPURAM" if district == "CHENGALPATTU" & ///
	state == "TAMIL NADU"
	
* TRIPURA
replace district = "NORTH TRIPURA" if district == "UNOKOTI" & ///
	state == "TRIPURA"
replace district = "WEST TRIPURA" if (district == "KHOWAI" | ///
	district == "SIPAHIJALA") & state == "TRIPURA"
replace district = "SOUTH TRIPURA" if district == "GOMATI" & ///
	state == "TRIPURA"
	
* UTTAR PRADESH
replace district = "SULTANPUR" if district == "AMETHI" & ///
	state == "UTTAR PRADESH"
replace district = "MORADABAD_COMB" if ///
	(district == "SAMBHAL" | district == "MORADABAD" | district == "BUDAUN") & ///
	state == "UTTAR PRADESH"
replace district = "MUZAFFARNAGAR" if district == "SHAMLI" & ///
	state == "UTTAR PRADESH"
replace district = "GHAZIABAD" if district == "HAPUR"
	
* WEST BENGAL
replace district = "JALPAIGURI" if district == "ALIPURDUAR" & ///
	state == "WEST BENGAL"
replace district = "DARJILING" if district == "KALIMPONG" & ///
	state == "WEST BENGAL"
replace district = "MEDINIPUR WEST" if district == "JHARGRAM" & ///
	state == "WEST BENGAL"
replace district = "BARDDHAMAN" if (district == "PASCHIM BARDHAMAN" | ///
	district == "PURBA BARDHAMAN") & state == "WEST BENGAL"
	
* Aggregate district cases/deaths/tests
egen group = group(state district date)

* If any district-date observation in an aggregation is missing, set
* the aggregated value to missing
local varlist num_cases num_deaths num_tested num_tested_1wk ///
	remittance_flows
foreach var of local varlist {
	bysort group: gen `var'_missing = missing(`var')
	gsort group -`var'_missing
	by group: replace `var'_missing = `var'_missing[1]
	by group: egen `var'_agg = total(`var')
	replace `var'_agg = . if `var'_missing == 1
	drop `var' `var'_missing	
	rename `var'_agg `var'
}

* Drop duplicate group observations
duplicates drop group, force
drop group

* Reassign new district ids after aggregating to ensure they are specific
* to each district
egen district_id = group(state district)

* Temporarily save full cases data
tempfile full_cases
save `full_cases'

* Keep unique districts for matching
duplicates drop district_id, force
keep state district district_id
order state district district_id	
	
* Fuzzy join district-level population data onto cases data
reclink state district using "$dirpath_pop/census11_districtpop.dta", ///
	idmaster(district_id) idusing(pop_id) gen(reclinkscore)

* Split populations for palghar and thane
* Palghar taluks list: https://palghar.gov.in/
* Populations list https://censusindia.gov.in/2011census/dchb/DCHB_A/27/2721_PART_A_DCHB_THANE.pdf
replace population = 11060148-2990116 if district == "THANE" & state == "MAHARASHTRA"
replace population = 2990116 if district == "PALGHAR" & state == "MAHARASHTRA"

* Match back to full cases
keep district_id population
merge 1:m district_id using `full_cases', nogen

* Order/sort/etc
egen state_id = group(state)
order state state_id district district_id date num_cases num_deaths ///
	num_tested num_tested_1wk population
sort state district date

* Indicator for in the state of Maharashtra
gen in_state = 0
replace in_state = 1 if state == "MAHARASHTRA"

* Output
save "$dirpath_cases/covid19india_data_cleaned_remittances_pops.dta", replace


