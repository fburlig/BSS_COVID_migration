
* Plot cross-country comparison figures

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
global dirpath_outputs "$dirpath/outputs"
global dirpath_outputs_figs "$dirpath_outputs/figures"
global dirpath_outputs_tables "$dirpath_outputs/tables"

******************************************************************
* Prep cases data for cases per capita vs ban duration figure
******************************************************************

* Load india data (Mumbai)
use "$dirpath_int_covid/Mumbai_cleaned_case_timeseries.dta", clear
drop num_tested

* Append to other country data
append using "$dirpath_int_covid/cleaned_non_india_covid_data.dta"

* Keep hotspot regions
keep if ///
	(country_name == "china" & subregion1_name == "hubei") | ///
	(country_name == "kenya" & ///
		(subregion1_name == "nairobi city" | ///
		subregion1_name == "mombasa")) | ///
	(country_name == "indonesia" & ///
		subregion1_name == "jakarta") | ///
	(country_name == "south africa" & ///
		subregion2_name == "city of cape town metropolitan municipality") | ///
	(country_name == "philippines" & ///
		(subregion2_name == "national capital region" | ///
		subregion2_name == "cebu")) | ///
	(country_name == "india" & subregion2_name == "mumbai")

* Keep data within 1 week of travel ban
// release dates
local release_ke = date("2020/07/07", "YMD")
local release_id = date("2020/05/07", "YMD")
local release_ph = date("2020/05/30", "YMD")
local release_za = date("2020/05/01", "YMD")
local release_in_p1 = date("2020/05/08", "YMD")
local release_cn = date("2020/04/08", "YMD")
// drop outside 1 week of that date
drop if country_name == "kenya" & ///
	(date < `release_ke' - 7 | date > `release_ke' + 7)
drop if country_name == "indonesia" & ///
	(date < `release_id' - 7 | date > `release_id' + 7)
drop if country_name == "philippines" & ///
	(date < `release_ph' - 7 | date > `release_ph' + 7)
drop if country_name == "south africa" & ///
	(date < `release_za' - 7 | date > `release_za' + 7)	
drop if country_name == "india" & ///
	(date < `release_in_p1' - 7 | date > `release_in_p1' + 7)
drop if country_name == "china" & ///
	(date < `release_cn' - 7 | date > `release_cn' + 7)
	
* Collapse to country-date level (sum)
collapse (sum) num_cases population, by(country_name date)
bys country_name: gen obs = _N
assert obs == 15

* Get cases per capita on each day
gen cases_p1000 = (num_cases / population) * 1000

* Collapse to country level
collapse (sum) tot_cases_p1000 = cases_p1000, by(country_name)

* Check that there are only 6 observations
assert _N == 6

* Mark feset to be consistent with other quadratic
gen feset = .
replace feset = 1 if country_name == "kenya"
replace feset = 2 if country_name == "indonesia"
replace feset = 3 if country_name == "philippines"
replace feset = 4 if country_name == "south africa"
replace feset = 5 if country_name == "india"
replace feset = 6 if country_name == "china"
assert !missing(feset)
sort feset

* Mark ban durations
gen ban_duration = .
replace ban_duration = ///
	date("2020/07/07", "YMD") - date("2020/04/06", "YMD") if ///
	feset == 1
replace ban_duration = ///
	date("2020/05/07", "YMD") - date("2020/04/24", "YMD") if ///
	feset == 2
replace ban_duration = ///
	date("2020/05/30", "YMD") - date("2020/03/15", "YMD") if ///
	feset == 3
replace ban_duration = ///
	date("2020/05/01", "YMD") - date("2020/03/26", "YMD") ///
	if feset == 4
replace ban_duration = ///
	date("2020/05/08", "YMD") - date("2020/03/25", "YMD") ///
	if feset == 5
replace ban_duration = ///
	date("2020/04/08", "YMD") - date("2020/01/23", "YMD") if ///
	feset == 6
assert !missing(ban_duration)

******************************************************************
* Plot quadratic cases per capita hotspot vs ban duration
******************************************************************

* Macros for plotting
// non-india
forvalues feset = 1/6 {	
	// ban duration
	qui sum ban_duration if feset == `feset'
	local ban_duration_`feset' = r(max)
	// total cases
	qui sum tot_cases_p1000 if feset == `feset'
	local tot_cases_p1000_`feset' = r(max)
}

* Plot
local x_dsp = 6
local y_dsp = 0.055
local y_dsp2 = `y_dsp' + 0.025
local tick_axis_thick = 0.3
local refline_color = "gs13"
local qfit_color = "gs11" 
local title_size = 4.25

twoway ///
	(pci `=`tot_cases_p1000_1'+`y_dsp'' ///
		`=`ban_duration_1'' ///
		`=`tot_cases_p1000_1'' `=`ban_duration_1'', ///
		lp(solid) lcolor("`refline_color'") ///
		text(`=`tot_cases_p1000_1'+`y_dsp2'' ///
		`=`ban_duration_1'' ///
		"Kenya", color(black) size(medlarge))) /// ke
	(pci `=`tot_cases_p1000_2'' `=`ban_duration_2'+`x_dsp'' ///
		`=`tot_cases_p1000_2'' `=`ban_duration_2'', ///
		lp(solid) lcolor("`refline_color'")  ///
		text(`=`tot_cases_p1000_2'' `=`ban_duration_2'+17' ///
		"Indonesia", color(black) size(medlarge))) /// id
	(pci `=`tot_cases_p1000_3'' `=`ban_duration_3'-`x_dsp'' ///
		`=`tot_cases_p1000_3'' `=`ban_duration_3'', ///
		lp(solid) lcolor("`refline_color'")  ///
		text(`=`tot_cases_p1000_3'' `=`ban_duration_3'-18.25' ///
		"Philippines", color(black) size(medlarge))) /// ph
	(pci `=`tot_cases_p1000_4'' `=`ban_duration_4'-`x_dsp'' ///
		`=`tot_cases_p1000_4'' `=`ban_duration_4'', ///
		lp(solid) lcolor("`refline_color'")  ///
		text(`=`tot_cases_p1000_4'' `=`ban_duration_4'-19.5' ///
		"South Africa", color(black) size(medlarge))) /// za 
	(pci `=`tot_cases_p1000_5'' ///
		`=`ban_duration_5'+`x_dsp'' ///
		`=`tot_cases_p1000_5'' ///
		`=`ban_duration_5'', ///
		lp(solid) lcolor("`refline_color'")  ///
		text(`=`tot_cases_p1000_5'' ///
		`=`ban_duration_5'+12.5' "India", ///
		color(black) size(medlarge))) /// india phase 1
	(pci `=`tot_cases_p1000_6'+`y_dsp'' ///
		`=`ban_duration_6'' ///
		`=`tot_cases_p1000_6'' `=`ban_duration_6'', ///
		lp(solid) lcolor("`refline_color'")  ///
		text(`=`tot_cases_p1000_6'+`y_dsp2'' ///
		`=`ban_duration_6'' ///
		"China", color(black) size(medlarge))) /// cn
	(qfit tot_cases_p1000 ban_duration, ///
		lc("`qfit_color'") lp(solid) lw(medthick)) ///
	(scatter tot_cases_p1000 ban_duration, ///
		msize(large) msymbol(circle) mlw(medthick) ///
		mlcolor(midblue) mfcolor(white)) ///
		, ///
		legend(off) ///
		ytitle("Hotspot COVID-19 cases per 1,000 people", ///
			size(`title_size')) ///
		xtitle("", size(large)) ///
		xlabel("", notick) ///
		ylabel(`ylab', tlwidth(`tick_axis_thick') ///
			labsize(large)) ///
		title("") ///
		xsc(r(0 102) lw(`tick_axis_thick') noline) ///
		ysc(lw(`tick_axis_thick') titlegap(*4.75)) ///
		title("{bf: {fontface Arial: A}}", ///
			pos(10) size(vhuge)) ///
		name("hotspot_cases", replace)


******************************************************************
* Plot quadratic marginal effects
******************************************************************

* Load data
use "$dirpath_final_results/RESULTS_event_studies_countries_adj.dta", clear

* Keep total case estimates
keep if tot_cases == 1

* Keep main spec
keep if spec == 1
assert _N == 6

* Note phase (for India it's phase 1. the others don't have phases)
gen phase = .
replace phase = 1 if country_name == "india"

* Use adjusted estimates, scale to per 1,000 migrants
drop *_unadj
local varlist beta ci90_lo ci90_hi ci95_lo ci95_hi
foreach var of local varlist {
	rename `var'_adj `var'
	replace `var' = `var' * 1000
}

foreach i of numlist 1/6 {
	
	qui sum ban_duration if feset == `i'
	local ban_duration_`i' = r(max)

	qui sum beta if feset == `i'
	local beta_`i' = r(max)
}

local x_adj = 6
local y_adj = 0.00425 * 1000
local y_adj2 = `y_adj' + (0.002 * 1000)
local tick_axis_thick = 0.3
local xyline_gray = "gs12"
local ci_color = "gs8"
local refline_color = "gs13"
local qfit_color = "gs11" 


twoway ///
	(pci `=`beta_1'+`y_adj'/1.325' ///
		`=`ban_duration_1'+2' `=`beta_1'' ///
		`ban_duration_1', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_1'+`y_adj2'/1.1755' ///
		`=`ban_duration_1'+3.25' "Kenya", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_2'' ///
		`=`ban_duration_2'+`x_adj'' `=`beta_2'' ///
		`=`ban_duration_2'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_2'' ///
			`=`ban_duration_2'+16' "Indonesia", ///
			color(black) size(medlarge))) ///
	(pci `=`beta_3'' ///
		`=`ban_duration_3'+`x_adj'' `=`beta_3'' ///
		`=`ban_duration_3'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_3'' ///
		`=`ban_duration_3'+18' "Philippines", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_4'' ///
		`=`ban_duration_4'-`x_adj'' `=`beta_4'' ///
		`=`ban_duration_4'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_4'' ///
		`=`ban_duration_4'-19' "South Africa", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_5'+(0.001*1000)' ///
		`=`ban_duration_5'+5.25' `=`beta_5'' ///
		`=`ban_duration_5'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_5'+(0.001375*1000)' ///
		`=`ban_duration_5'+10.6' "India", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_6'+`y_adj'/1.325' ///
		`=`ban_duration_6'-2' `=`beta_6'' ///
		`ban_duration_6', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_6'+`y_adj2'/1.1755' ///
		`=`ban_duration_6'-3.25' "China", ///
		color(black) size(medlarge))) ///
	(qfit beta ban_duration, ///
		lc("`qfit_color'") lp(solid) lw(medthick)) ///
	(rspike ci90_lo ci90_hi ban_duration, ///
		lcolor("`ci_color'") lwidth(medium))  ///
	(scatter beta ban_duration, ///
		msize(large) msymbol(circle) mlw(medthick) ///
		mlcolor(midblue) mfcolor(white)) ///
		, ///
		legend(off) ///
		ytitle("Excess COVID-19 cases per 1,000 migrants", ///
			size(`title_size')) ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xtitle("Travel ban duration (days)", ///
			size(`title_size')) ///
		xlabel(0(20)100 , tlwidth(`tick_axis_thick') ///
			labsize(large)) ///
		ylabel(0(15)45, tlwidth(`tick_axis_thick') ///
			labsize(large)) ///
		xsc(r(0 102) lw(0.3)) ///
		ysc(lw(`tick_axis_thick')) ///
		title("{bf: {fontface Arial: B}}", ///
			pos(10) size(vhuge)) ///
		name("marginal_effects", replace)

		
		******************************************************************
* Combine graphs
******************************************************************

local xsize = 3.5
local ysize = 2.55 * 2

graph combine hotspot_cases marginal_effects, ///
	rows(2) ///
	xsize(`xsize') ///
	ysize(`ysize')
	
graph export "$dirpath_outputs_figs/Figure_countries_banduration_hotspotcases_marginaleffects.pdf", replace

******************************************************************
* Plot robustness
******************************************************************

* Load data
use "$dirpath_final_results/RESULTS_event_studies_countries_adj.dta", clear

* Keep total case estimates
keep if tot_cases == 1

* Check that there are 3 specs
gunique spec
assert r(unique) == 3
assert _N == r(unique) * 6

* Duplicate main spec
expand 2 if spec == 1
replace spec = 4 if _n > r(unique) * 6

* Use unadjusted estimates for main spec
local varlist beta ci90_lo ci90_hi ci95_lo ci95_hi
foreach var of local varlist {
	replace `var'_adj = `var'_unadj if spec == 4
}

* Note phase (for India it's phase 1. the others don't have phases)
gen phase = .
replace phase = 1 if country_name == "india"

* Use adjusted estimates and scale to per 1,000 migrants
drop *_unadj
foreach var of local varlist {
	rename `var'_adj `var'
	replace `var' = `var' * 1000
}

local x_adj = 6
local y_adj = 0.00425 * 1000
local y_adj2 = `y_adj' + (0.002 * 1000)
local tick_axis_thick = 0.3
local xyline_gray = "gs12"
local ci_color = "gs8"
local refline_color = "gs13"
local text_size = 3
local lab_size = 3.875
local msize = 2
local qfit_color = "gs11" 
local spec1_color = "midblue"
local spec2_color = "midblue*0.5"
local spec3_color = "79 41 132"
local spec4_color = "79 41 132"
local xsize = 3.5
local ysize = 2.55
local title_size = 4.25

* Macros for plotting
preserve
keep if spec == 1
foreach i of numlist 1/6 {
	qui sum ban_duration if feset == `i'
	local ban_duration_`i' = r(max)
	qui sum beta if feset == `i'
	local beta_`i' = r(max)
}
restore


twoway ///
	(pci `=`beta_1'+`y_adj'/1.325' ///
		`=`ban_duration_1'+2' `=`beta_1'' ///
		`ban_duration_1', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_1'+`y_adj2'/1.1755' ///
		`=`ban_duration_1'+3.25' "Kenya", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_2'' ///
		`=`ban_duration_2'+`x_adj'' `=`beta_2'' ///
		`=`ban_duration_2'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_2'' ///
			`=`ban_duration_2'+15' "Indonesia", ///
			color(black) size(medlarge))) ///
	(pci `=`beta_3'' ///
		`=`ban_duration_3'+`x_adj'' `=`beta_3'' ///
		`=`ban_duration_3'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_3'' ///
		`=`ban_duration_3'+16.25' "Philippines", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_4'' ///
		`=`ban_duration_4'-`x_adj'' `=`beta_4'' ///
		`=`ban_duration_4'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_4'' ///
		`=`ban_duration_4'-17.5' "South Africa", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_5'+(0.001*1000)' ///
		`=`ban_duration_5'+5' `=`beta_5'' ///
		`=`ban_duration_5'', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_5'+(0.001375*1000)' ///
		`=`ban_duration_5'+10' "India", ///
		color(black) size(medlarge))) ///
	(pci `=`beta_6'+`y_adj'/1.325' ///
		`=`ban_duration_6'-2' `=`beta_6'' ///
		`ban_duration_6', lp(solid) ///
		lcolor("`refline_color'") ///
		text(`=`beta_6'+`y_adj2'/1.1755' ///
		`=`ban_duration_6'-3.25' "China", ///
		color(black) size(medlarge))) ///
	(qfit beta ban_duration if spec == 1, ///
		lc("`spec1_color'") lp(solid) lw(medthick)) ///
	(qfit beta ban_duration if spec == 2, ///
		lc("`qfit_color'") lp(solid) lw(medthick)) ///
	(qfit beta ban_duration if spec == 3, ///
		lc("`qfit_color'") lp(shortdash) lw(medthick)) ///
	(qfit beta ban_duration if spec == 4, ///
		lc("`qfit_color'") lp("-_") lw(medthick)) ///
	(rspike ci90_lo ci90_hi ban_duration if spec == 1, ///
		lcolor("`ci_color'") lwidth(medium))  ///
	(scatter beta ban_duration if spec == 1, ///
		msize(large) msymbol(circle) mlw(medthick) ///
		mlcolor(midblue) mfcolor(white)) ///
		, ///
		legend( ///
			order(7 "Main specification" ///
			8 "- Date fixed effects" ///
			9 "- Date fixed effects" "+ Date polynomial" ///
			10 "- Pre-trend adjustment" ///
				) rows(4) pos(2) ring(0) bmargin(-13)) ///
		ytitle("Excess COVID-19 cases per 1,000 migrants", ///
			size(`title_size')) ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xtitle("Travel ban duration (days)", ///
			size(`title_size')) ///
		xlabel(0(20)100 , tlwidth(`tick_axis_thick') ///
			labsize(large)) ///
		ylabel(0(15)45, tlwidth(`tick_axis_thick') ///
			labsize(large)) ///
		xsc(r(0 102) lw(0.3)) ///
		ysc(lw(`tick_axis_thick'))

		
graph export "$dirpath_outputs_figs/Figure_countries_robustness.png", replace


