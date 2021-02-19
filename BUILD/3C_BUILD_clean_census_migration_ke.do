
***** Clean census data for kenya

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
import delimited "$dirpath_raw_census/kenya/kn_2009_census_migration.csv", clear

* Keep necessary variables
drop migctry1 migyrs1 mig1_1_ke
/*
-pernum numbers all persons within each household consecutively
-perwt indicates the number of persons in the actual population represented by the person in the sample.
-geolev1 indicates major administrative unit in which the household was enumerated
---> has 8 unique values
-geolev2 indicates minor admin unit in which household was eumerated
---> has 35 unique values
-migrate1 indicates whether the person's residence 1 year ago was the same minor administrative unit, major unit, or country
-geomig1_1 indicates the major administrative unit in which the person resided 1 year ago
---> 10 unique values
-migza indicates the person's district of previous residence within South Africa
---> 160 unique values
*/

* Check there are no duplicates
gduplicates drop

* Make sure no entries are missing
foreach var of varlist * {
	assert !missing(`var')
}

***************************************************************
* Clean data
***************************************************************

* Province of enumeration
gen geolev1_name = ""
replace geolev1_name = "Nairobi" if geolev1 == 404001
replace geolev1_name = "Central" if geolev1 == 404002
replace geolev1_name = "Coast" if geolev1 == 404003
replace geolev1_name = "Eastern" if geolev1 == 404004
replace geolev1_name = "Northeastern" if geolev1 == 404005
replace geolev1_name = "Nyanza" if geolev1 == 404006
replace geolev1_name = "Rift Valley" if geolev1 == 404007
replace geolev1_name = "Western" if geolev1 == 404008
assert !missing(geolev1_name)
drop geolev1

* District of enumeration
* Since only doing hotspot enumerated places for now, skip this
gen geolev2_name = ""
replace geolev2_name = "Nairobi East, Nairobi North, Nairobi West, Westlands" if geolev2 == 404001001
replace geolev2_name = "Gatanga, Gatundu, Githunguri, Kiambu (Kiambaa), Kiambu West, Kikuyu, Lari, Muranga North, Muranga South, Nyandarua North, Nyandarua South, Ruiru, Thika East, Thika West" if geolev2 == 404002001
replace geolev2_name = "Nyeri North, Nyeri South" if geolev2 == 404002002
replace geolev2_name = "Kilindini, Kilindini" if geolev2 == 404003001
replace geolev2_name = "Kinango, Kwale, Msambweni" if geolev2 == 404003002
replace geolev2_name = "Kaloleni, Kilifi, Malindi" if geolev2 == 404003003
replace geolev2_name = "Tana Delta, Tana River" if geolev2 == 404003004
replace geolev2_name = "Lamu" if geolev2 == 404003005
replace geolev2_name = "Taita, Taveta404004001" if geolev2 == 404003006
replace geolev2_name = "Chalbi, Laisamis, Marsabit, Moyale" if geolev2 == 404004001
replace geolev2_name = "Garba Tulla, Igembe, Imenti Central, Imenti North, Imenti South, Isiolo, Maara, Meru South, Tharaka, Tigania" if geolev2 == 404004002
replace geolev2_name = "Embu, Kangundo, Kibwezi, Machakos, Makueni, Mbeere, Mbooni, Mwala, Nzaui, Yatta" if geolev2 == 404004003
replace geolev2_name = "Kitui North, Kitui South (Mutomo), Kyuso, Mwingi" if geolev2 == 404004004
replace geolev2_name = "Fafi, Garissa, Ijara, Lagdera" if geolev2 == 404005001
replace geolev2_name = "Wajir East, Wajir North, Wajir South, Wajir West" if geolev2 == 404005002
replace geolev2_name = "Mandera Central, Mandera East, Mandera West" if geolev2 == 404005003
replace geolev2_name = "Bondo, Rarieda, Siaya" if geolev2 == 404006001
replace geolev2_name = " Kisumu East, Kisumu West, Nyando" if geolev2 == 404006002
replace geolev2_name = "Homa Bay, Kuria East, Kuria West, Migori, Rachuonyo, Rongo, Suba" if geolev2 == 404006003
replace geolev2_name = "Borabu, Gucha, Gucha South, Kisii Central, Kisii South, Manga, Masaba, Nyamira" if geolev2 == 404006004
replace geolev2_name = "Turkana Central, Turkana North, Turkana South" if geolev2 == 404007001
replace geolev2_name = "Pokot Central, Pokot North, West Pokot" if geolev2 == 404007002
replace geolev2_name = "Kirinyaga" if geolev2 == 404002003
replace geolev2_name = "Samburu Central, Samburu East, Samburu North" if geolev2 == 404007003
replace geolev2_name = "Kwanza, Trans Nzoia East, Trans Nzoia West" if geolev2 == 404007004
replace geolev2_name = "Baringo, Baringo North, East Pokot, Koibatek, Laikipia East, Laikipia North, Laikipia West" if geolev2 == 404007005
replace geolev2_name = "Eldoret East, Eldoret West, Wareng" if geolev2 == 404007006
replace geolev2_name = "Keiyo, Marakwet" if geolev2 == 404007007
replace geolev2_name = "Nandi Central, Nandi East, Nandi North, Nandi South, Tinderet" if geolev2 == 404007008
replace geolev2_name = " Kaijiado Central, Kaijiado North, Loitoktok, Molo, Naivasha, Nakuru, Nakuru North" if geolev2 == 404007009
replace geolev2_name = "Narok North, Narok South, Trans Mara" if geolev2 == 404007010
replace geolev2_name = "Bomet, Buret, Kericho, Kipkelion, Sotik" if geolev2 == 404007011
replace geolev2_name = "Butere, Emuhaya, Hamisi, Kakamega Central, Kakamega East, Kakamega North, Kakamega South, Lugari, Mumias, Vihiga" if geolev2 == 404008001
replace geolev2_name = "Bungoma East, Bungoma North, Bungoma South, Bungoma West, Mt. Elgon" if geolev2 == 404008002
replace geolev2_name = "Bunyala, Busia, Samia, Teso North, Teso South" if geolev2 == 404008003
replace geolev2_name = "Waterbodies" if geolev2 == 404888888
assert !missing(geolev2_name)
drop geolev2
replace geolev2_name = strtrim(geolev2_name)


* Province of origin
gen geomig1_1_name = ""
replace geomig1_1_name = "Nairobi" if geomig1_1 == 404001
replace geomig1_1_name = "Central" if geomig1_1 == 404002
replace geomig1_1_name = "Coast" if geomig1_1 == 404003
replace geomig1_1_name = "Eastern" if geomig1_1 == 404004
replace geomig1_1_name = "Northeastern" if geomig1_1 == 404005
replace geomig1_1_name = "Nyanza" if geomig1_1 == 404006
replace geomig1_1_name = "Rift Valley" if geomig1_1 == 404007
replace geomig1_1_name = "Western" if geomig1_1 == 404008
replace geomig1_1_name = "Abroad" if geomig1_1 == 404097
replace geomig1_1_name = "Unknown" if geomig1_1 == 404098
replace geomig1_1_name = "NIU (not in universe)" if geomig1_1 == 404099
assert !missing(geomig1_1_name)
drop geomig1_1

* District of origin
gen migke_name = ""
replace migke_name = "NIU (not in universe)" if migke == 0
replace migke_name = "Nairobi West" if migke == 101
replace migke_name = "Nairobi East" if migke == 102
replace migke_name = "Nairobi North" if migke == 103
replace migke_name = "Westlands" if migke == 104
replace migke_name = "Nyandarua North" if migke == 201
replace migke_name = "Nyandarua South" if migke == 202
replace migke_name = "Nyeri North" if migke == 203
replace migke_name = "Nyeri South" if migke == 204
replace migke_name = "Kirinyaga" if migke == 205
replace migke_name = "Muranga North" if migke == 206
replace migke_name = "Muranga South" if migke == 207
replace migke_name = "Kiambu (Kiambaa)" if migke == 208
replace migke_name = "Kikuyu" if migke == 209
replace migke_name = "Kiambu West" if migke == 210
replace migke_name = "Lari" if migke == 211
replace migke_name = "Githunguri" if migke == 212
replace migke_name = "Thika East" if migke == 213
replace migke_name = "Thika West" if migke == 214
replace migke_name = "Ruiru" if migke == 215
replace migke_name = "Gatanga" if migke == 216
replace migke_name = "Gatundu" if migke == 217
replace migke_name = "Mombasa" if migke == 301
replace migke_name = "Kilindini" if migke == 302
replace migke_name = "Kwale" if migke == 303
replace migke_name = "Kinango" if migke == 304
replace migke_name = "Msambweni" if migke == 305
replace migke_name = "Kilifi" if migke == 306
replace migke_name = "Kaloleni" if migke == 307
replace migke_name = "Malindi" if migke == 308
replace migke_name = "Tana River" if migke == 309
replace migke_name = "Tana Delta" if migke == 310
replace migke_name = "Lamu" if migke == 311
replace migke_name = "Taita" if migke == 312
replace migke_name = "Taveta" if migke == 313
replace migke_name = "Marsabit" if migke == 401
replace migke_name = "Chalbi" if migke == 402
replace migke_name = "Laisamis" if migke == 403
replace migke_name = "Moyale" if migke == 404
replace migke_name = "Isiolo" if migke == 405
replace migke_name = "Garba Tulla" if migke == 406
replace migke_name = "Imenti Central" if migke == 407
replace migke_name = "Imenti North" if migke == 408
replace migke_name = "Imenti south" if migke == 409
replace migke_name = "Meru south" if migke == 410
replace migke_name = "Maara" if migke == 411
replace migke_name = "Igembe" if migke == 412
replace migke_name = "Tigania" if migke == 413
replace migke_name = "Tharaka" if migke == 414
replace migke_name = "Embu" if migke == 415
replace migke_name = "Mbeere" if migke == 416
replace migke_name = "Kitui North" if migke == 417
replace migke_name = "Kitui South (Mutomo)" if migke == 418
replace migke_name = "Mwingi" if migke == 419
replace migke_name = "Kyuso" if migke == 420
replace migke_name = "Machakos" if migke == 421
replace migke_name = "Mwala" if migke == 422
replace migke_name = "Yatta" if migke == 423
replace migke_name = "Kangundo" if migke == 424
replace migke_name = "Makueni" if migke == 425
replace migke_name = "Mbooni" if migke == 426
replace migke_name = "Kibwezi" if migke == 427
replace migke_name = "Nzaui" if migke == 428
replace migke_name = "Garissa" if migke == 501
replace migke_name = "Lagdera" if migke == 502
replace migke_name = "Fafi" if migke == 503
replace migke_name = "Ijara" if migke == 504
replace migke_name = "Wajir South" if migke == 505
replace migke_name = "Wajir North" if migke == 506
replace migke_name = "Wajir East" if migke == 507
replace migke_name = "Wajir West" if migke == 508
replace migke_name = "Mandera Central" if migke == 509
replace migke_name = "Mandera East" if migke == 510
replace migke_name = "Mandera West" if migke == 511
replace migke_name = "Siaya" if migke == 601
replace migke_name = "Bondo" if migke == 602
replace migke_name = "Rarieda" if migke == 603
replace migke_name = "Kisumu East" if migke == 604
replace migke_name = "Kisumu West" if migke == 605
replace migke_name = "Nyando" if migke == 606
replace migke_name = "Homa Bay" if migke == 607
replace migke_name = "Suba" if migke == 608
replace migke_name = "Rachuonyo" if migke == 609
replace migke_name = "Migori" if migke == 610
replace migke_name = "Rongo" if migke == 611
replace migke_name = "Kuria West" if migke == 612
replace migke_name = "Kuria East" if migke == 613
replace migke_name = "Kisii Central" if migke == 614
replace migke_name = "Kisii South" if migke == 615
replace migke_name = "Masaba" if migke == 616
replace migke_name = "Gucha" if migke == 617
replace migke_name = "Gucha South" if migke == 618
replace migke_name = "Nyamira" if migke == 619
replace migke_name = "Manga" if migke == 620
replace migke_name = "Borabu" if migke == 621
replace migke_name = "Turkana Central" if migke == 701
replace migke_name = "Turkana North" if migke == 702
replace migke_name = "Turkana South" if migke == 703
replace migke_name = "West Pokot" if migke == 704
replace migke_name = "Pokot North" if migke == 705
replace migke_name = "Pokot Central" if migke == 706
replace migke_name = "Samburu Central" if migke == 707
replace migke_name = "Samburu East" if migke == 708
replace migke_name = "Samburu North" if migke == 709
replace migke_name = "Trans Nzoia West" if migke == 710
replace migke_name = "Trans Nzoia East" if migke == 711
replace migke_name = "Kwanza" if migke == 712
replace migke_name = "Baringo" if migke == 713
replace migke_name = "Baringo North" if migke == 714
replace migke_name = "East Pokot" if migke == 715
replace migke_name = "Koibatek" if migke == 716
replace migke_name = "Eldoret West" if migke == 717
replace migke_name = "Eldoret East" if migke == 718
replace migke_name = "Wareng" if migke == 719
replace migke_name = "Marakwet" if migke == 720
replace migke_name = "Keiyo" if migke == 721
replace migke_name = "Nandi North" if migke == 722
replace migke_name = "Nandi Central" if migke == 723
replace migke_name = "Nandi East" if migke == 724
replace migke_name = "Nandi South" if migke == 725
replace migke_name = "Tinderet" if migke == 726
replace migke_name = "Laikipia North" if migke == 727
replace migke_name = "Laikipia East" if migke == 728
replace migke_name = "Laikipia West" if migke == 729
replace migke_name = "Nakuru" if migke == 730
replace migke_name = "Nakuru North" if migke == 731
replace migke_name = "Naivasha" if migke == 732
replace migke_name = "Molo" if migke == 733
replace migke_name = "Narok North" if migke == 734
replace migke_name = "Narok South" if migke == 735
replace migke_name = "Trans Mara" if migke == 736
replace migke_name = "Kajiado Central" if migke == 737
replace migke_name = "Loitoktok" if migke == 738
replace migke_name = "Kericho" if migke == 739
replace migke_name = "Kipkelion" if migke == 740
replace migke_name = "Buret" if migke == 741
replace migke_name = "Sotik" if migke == 742
replace migke_name = "Bomet" if migke == 743
replace migke_name = "Kajiado North" if migke == 744
replace migke_name = "Kakamega Central" if migke == 801
replace migke_name = "Kakamega South" if migke == 802
replace migke_name = "Kakamega North" if migke == 803
replace migke_name = "Kakamega East" if migke == 804
replace migke_name = "Lugari" if migke == 805
replace migke_name = "Vihiga" if migke == 806
replace migke_name = "Emuhaya" if migke == 807
replace migke_name = "Hamisi" if migke == 808
replace migke_name = "Mumias" if migke == 809
replace migke_name = "Butere" if migke == 810
replace migke_name = "Bungoma South" if migke == 811
replace migke_name = "Bungoma North" if migke == 812
replace migke_name = "Bungoma East" if migke == 813
replace migke_name = "Bungoma West" if migke == 814
replace migke_name = "Mt. Elgon" if migke == 815
replace migke_name = "Busia" if migke == 816
replace migke_name = "Teso North" if migke == 817
replace migke_name = "Samia" if migke == 818
replace migke_name = "Bunyala" if migke == 819
replace migke_name = "Teso South" if migke == 820
replace migke_name = "ABROAD" if migke == 998
assert !missing(migke_name)
drop migke


foreach var of varlist ///
geolev1_name geolev2_name geomig1_1_name migke_name {
	replace `var' = lower(`var')
	replace `var' = strtrim(`var')
}

* Keep enumerated hotspot region: nairobi
// MOMBASA IS ALSO A HOTSPOT
keep if geolev1_name == "nairobi" | ///
	geolev2_name == "kilindini, kilindini"

* Drop origin hotspot region: 
drop if geomig1_1_name == "nairobi" | ///
	migke_name == "kilindini" | ///
	migke_name == "mombasa"

* Drop abroad/unknown
count if migke_name == "niu (not in universe)" | ///
	migke_name == "abroad"
local na = r(N)
count if geomig1_1_name == "niu (not in universe)" | ///
	geomig1_1_name == "abroad"
assert r(N) == `na'
drop if  migke_name == "niu (not in universe)" | ///
	migke_name == "abroad"

* Keep necessary variables
keep perwt geolev1_name geolev2_name geomig1_1_name migke_name

* Collapse to recipient-district level
collapse (sum) migrants = perwt, ///
	by(geomig1_1_name migke_name)

* Rename variables
rename geomig1_1_name subregion1_name
rename migke_name subregion2_name

* Output
save "$dirpath_int_census/kenya_hotspot_to_nonhotspot_migrants", replace

