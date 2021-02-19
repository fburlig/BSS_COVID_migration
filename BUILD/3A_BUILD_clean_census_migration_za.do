
***** Clean census data for South Africa

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
import delimited "$dirpath_raw_census/South Africa/za_2011_census_migration.csv", clear

* Keep necessary variables
/*
-pernum numbers all persons within each household consecutively
-perwt indicates the number of persons in the actual population represented by the person in the sample.
-geolev1 indicates major administrative unit in which the household was enumerated
---> has 4 unique values
-geolev2 indicates minor admin unit in which household was eumerated
---> has 18 unique values
-migratep indicates whether the person's most recent move (if any) was between minor administrative units, major units, or countries
-geomig1_p indicates the major administrative unit in which the person previously resided prior
---> 7 unique values
-migyrs2: number of years that the respondent has lived in his/her current dwelling
---> 12 unique values
-migza indicates the person's district of previous residence within South Africa
---> 54 unique values
*/
drop mig1_p_za
//keep perwt geolev1_destin migrate5_adm1 geolev1_orig

* Check there are no duplicates
gduplicates drop

* Make sure no entries are missing
foreach var of varlist * {
	assert !missing(`var')
}

* Keep those who migrated in the past 5 years
keep if migyrs2 <= 5

* Keep if indicated they migrated within the country
keep if migratep == 10 | migratep == 11 | migratep == 12 | migratep == 20

***************************************************************
* Clean data
***************************************************************

* Province of enumeration
gen geolev1_name = ""
replace geolev1_name = "Western Cape" if geolev1 == 710001
replace geolev1_name = "Free State" if geolev1 == 710004
replace geolev1_name = "Eastern Cape, KwaZulu‐Natal" if geolev1 == 710005
replace geolev1_name = "Gauteng, Limpopo, Mpumalanga, North West, Northern Cape" if geolev1 == 710007
assert !missing(geolev1_name)

* District of enumeration
gen geolev2_name = ""
replace geolev2_name = "West Coast" if geolev2 == 710001001
replace geolev2_name = "Cape Winelands, Overberg" if geolev2 == 710001002
replace geolev2_name = "Eden" if geolev2 == 710001003
replace geolev2_name = "Central Karoo" if geolev2 == 710001004
replace geolev2_name = "City of Cape Town" if geolev2 == 710001005
replace geolev2_name = "Thabo Mofutsanyane, Mangaung, Lejweleputswa, Fezile Dabi, Xhariep" if geolev2 == 710004001
replace geolev2_name = "Cacadu" if geolev2 == 710005001
replace geolev2_name = "Nelson Mandela Bay" if geolev2 == 710005002
replace geolev2_name = "Uthukela, Amajuba" if geolev2 == 710005003
replace geolev2_name = "Umkhanyakude" if geolev2 == 710005004
replace geolev2_name = "Uthungulu" if geolev2 == 710005005
replace geolev2_name = "iLembe" if geolev2 == 710005006
replace geolev2_name = "eThekwini, O.R.Tambo, Umgungundlovu, Amathole, Zululand, Alfred Nzo, Chris Hani, Buffalo City, Ugu, Umzinyathi, Sisonke, Joe Gqabi" if geolev2 == 710005007
replace geolev2_name = "Namakwa" if geolev2 == 710007001
replace geolev2_name = "Sedibeng, Ngaka Modiri Molema, West Rand, Dr Kenneth Kaunda, Dr Ruth Segomotsi Mompati, Frances Baard, Siyanda, John Taolo Gaetsewe, Pixley ka Seme" if geolev2 == 710007002
replace geolev2_name = "Ekurhuleni, City of Tshwane, Ehlanzeni, Bojanala, Nkangala, Vhembe, Capricorn, Greater Sekhukhune, Mopani, Waterberg" if geolev2 == 710007003
replace geolev2_name = "City of Johannesburg" if geolev2 == 710007004
replace geolev2_name = "Gert Sibande" if geolev2 == 710007005
replace geolev2_name = "Unknown" if geolev2 == 710099099
assert !missing(geolev2_name)


* Province of previous residence
gen geomig1_p_name = ""
replace geomig1_p_name = "Western Cape" if geomig1_p == 710001
replace geomig1_p_name = "Free State" if geomig1_p == 710004
replace geomig1_p_name = "Eastern Cape, KwaZulu-Natal" if geomig1_p == 710005
replace geomig1_p_name = "Gauteng, Limpopo, Mpumalanga, North West, Northern Cape" if geomig1_p == 710007
replace geomig1_p_name = "Foreign country" if geomig1_p == 710097
replace geomig1_p_name = "Unknown" if geomig1_p == 710098
replace geomig1_p_name = "NIU (not in universe)" if geomig1_p == 710099
assert !missing(geomig1_p_name)

* District of previous residence
gen migza_name = ""
replace migza_name = "West Coast" if migza == 101
replace migza_name = "Cape Winelands" if migza == 102
replace migza_name = "Overberg" if migza == 103
replace migza_name = "Eden" if migza == 104
replace migza_name = "Central Karoo" if migza == 105
replace migza_name = "City of Cape Town" if migza == 199
replace migza_name = "Cacadu" if migza == 210
replace migza_name = "Amathole" if migza == 212
replace migza_name = "Chris Hani" if migza == 213
replace migza_name = "Joe Gqabi" if migza == 214
replace migza_name = "O.R. Tambo" if migza == 215
replace migza_name = "Alfred Nzo" if migza == 244
replace migza_name = "Buffalo City" if migza == 260
replace migza_name = "Nelson Mandela Bay" if migza == 299
replace migza_name = "Namakwa" if migza == 306
replace migza_name = "Pixley ka Seme" if migza == 307
replace migza_name = "Siyanda" if migza == 308
replace migza_name = "Frances Baard" if migza == 309
replace migza_name = "John Taolo Gaetsewe" if migza == 345
replace migza_name = "Xariep" if migza == 416
replace migza_name = "Lejweleputswa" if migza == 418
replace migza_name = "Thabo Mofutsanyane" if migza == 419
replace migza_name = "Fezile Dabi" if migza == 420
replace migza_name = "Mangaung" if migza == 499
replace migza_name = "Ugu" if migza == 521
replace migza_name = "UMgungundlovu" if migza == 522
replace migza_name = "Uthukela" if migza == 523
replace migza_name = "Umkhanyakude" if migza == 527
replace migza_name = "Uthungulu" if migza == 528
replace migza_name = "Sisonke" if migza == 543
replace migza_name = "Umzinyathi" if migza == 554
replace migza_name = "Amajuba" if migza == 555
replace migza_name = "Zululand" if migza == 556
replace migza_name = "Ilembe" if migza == 559
replace migza_name = "eThekwini Metropolitan" if migza == 599
replace migza_name = "Bojanala" if migza == 637
replace migza_name = "Ngaka Modiri Molema" if migza == 638
replace migza_name = "Dr Ruth Segomotsi Mompati" if migza == 639
replace migza_name = "Dr Kenneth Kaunda" if migza == 640
replace migza_name = "Sedibeng" if migza == 742
replace migza_name = "West Rand" if migza == 748
replace migza_name = "Ekurhuleni" if migza == 797
replace migza_name = "City of Johannesburg" if migza == 798
replace migza_name = "City of Tshwane" if migza == 799
replace migza_name = "Gert Sibande" if migza == 830
replace migza_name = "Nkangala" if migza == 831
replace migza_name = "Ehlanzeni" if migza == 832
replace migza_name = "Mopani" if migza == 933
replace migza_name = "Vhembe" if migza == 934
replace migza_name = "Capricorn" if migza == 935
replace migza_name = "Waterberg" if migza == 936
replace migza_name = "Greater Sekhukhune" if migza == 947
replace migza_name = "Abroad" if migza == 997
replace migza_name = "Unknown" if migza == 998
replace migza_name = "NIU (not in universe)" if migza == 999
assert !missing(migza_name)

* Clean up names
foreach var of varlist ///
geolev1_name geolev2_name geomig1_p_name migza_name {
	replace `var' = lower(`var')
	replace `var' = strtrim(`var')
}

* Keep migrants enumerated in hotspot province: western cape 
keep if geolev2_name == "city of cape town"

* Drop migrants going to cape town or unknown areas
drop if migza_name == "city of cape town" | ///
	migza_name == "unknown"

* Rename recipient areas to match covid data
replace migza_name = "king cetshwayo" if migza_name == "uthungulu"
replace migza_name = "zf mgcawu" if migza_name == "siyanda"
replace migza_name = "garden route" if migza_name == "eden"
replace migza_name = "sarah baartman" if migza_name == "cacadu"
replace migza_name = "ekurhuleni metropolitan municipality" if migza_name == "ekurhuleni"
replace migza_name = "ethekwini metropolitan" if migza_name == "ethekwini metropolitan municipality"

* Keep necessary variables
keep perwt geolev2_name migza_name

* Collapse to recipient-district level
collapse (sum) migrants = perwt, by(geolev2_name migza_name)

* Output
drop geolev2_name
rename migza_name subregion2_name
egen census_id = group(subregion2_name)

save "$dirpath_int_census/za_hotspot_to_nonhotspot_migrants", replace

