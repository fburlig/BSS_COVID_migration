
* Plot India event study regression results for difference specifications

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

set scheme fb2, perm
local phase1_color = "midblue*1.5"
local phase2_color = "midblue*0.75"
local phase3_color = "79 41 132"

******************************************************************
******************************************************************
	
* Load data
use "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3_adj.dta", clear

* Keep totals
keep if total == 1

* Keep desired specs
drop if depvar == "num_deaths" | spec == 9

* Drop 95% CIs
drop ci95*

* Keep aggregated estimates
unique spec
local num_specs = r(unique)
assert _N == `num_specs' * 3
assert total == 1

* Duplicate main specification
expand 2 if spec == 1
replace spec = 999 if _n > `num_specs' * 3
assert _N == `=`num_specs'+1' * 3

* Keep adjusted elements for all but the duplicated main spec
local varlist beta ci90_lo ci90_hi
foreach var of local varlist {
	gen `var' = .
	replace `var' = `var'_adj if spec != 999
	replace `var' = `var'_unadj if spec == 999
	drop `var'_adj `var'_unadj
	* Convert to thousands of migrants
	replace `var' = `var' * 1000
}

* Divide spec without migrants by N for each phase
preserve
keep if spec == 1
sort phase
forvalues i = 1(1)3 {
	local phase`i'_migrants = tot_migrants[`i']
}
restore
foreach var of local varlist {
	forvalues i = 1(1)3 {
		replace `var' = `var' / `phase`i'_migrants' if ///
			spec == 6 & phase == `i'
	}
}

gen ci99_hi = (beta + se * 2.576 * 1000)
gen ci99_lo = (beta - se * 2.576 * 1000)
gen ci95_hi = (beta + se * 1.96 * 1000)
gen ci95_lo = (beta - se * 1.96 * 1000)


* Make string versions
foreach var of local varlist  {
	// make string labels
	gen `var'_str = round(`var', 0.01)
	tostring `var'_str, replace format(%10.2f) force
}

* Null value for generating second y-axis
gen null = 0

* Macros for plotting
local mlw = "medthick"
local xlab_size = "2.05"
local ytext_size = "3.5"
local qfit_color = "gs11" 
local msize = 2

gen row = .
replace row = 0.7 if spec == 1
replace row = 2 if spec == 2
replace row = 3 if spec == 3
replace row = 4 if spec == 7
replace row = 7 if spec == 999
replace row = 8 if spec == 6
assert !missing(row)
sort row
sort row phase
drop row

gen row = _n

* Trim in phase 1 and phase 3
local row_adj = 0.25
replace row = row + `row_adj' if phase == 1
replace row = row - `row_adj' if phase == 3

sort row phase
bys spec (phase): egen mean_row = mean(row)
foreach spec of numlist 1/3 6/7 999 {
	preserve
	keep if spec == `spec'
	local mean_row_spec`spec' = mean_row[1]
	restore
}
sort row phase

sort row phase
local ylab_adj_4 = 0.6
local ylab_adj_2 = `ylab_adj_4' / 2
local ylab2_adj_2 = `ylab_adj_4' / 3.5
local tick_axis_thick = 0.3

* Put confidence interval into a string
gen ci90_str = "(" + ci90_lo_str + ", " + ci90_hi_str + ")"
	sort row phase
	
* Labels and row numbers
local nrows = _N
foreach spec of numlist 1/3 6/7 999 {
	forvalues phase = 1/3 {
	preserve
	keep if spec == `spec' & phase == `phase'
		local beta_s`spec'_p`phase' = beta_str[1]
		local ci90_s`spec'_p`phase' = ci90_str[1]
		local beta_s`spec'_p`phase'_val = beta[1]
		local row_s`spec'_p`phase' = row[1]
	restore
}
}

sort row phase
local 1 `""Rotation""'


twoway /// 
	(qfit beta row if spec == 1, ///
		lp(solid) lc("`qfit_color'") yaxis(1 2)) ///
	(qfit beta row if spec == 2, ///
		lp(solid) lc("`qfit_color'") yaxis(1 2)) ///
	(qfit beta row if spec == 3, ///
		lp(solid) lc("`qfit_color'") yaxis(1 2)) ///
	(qfit beta row if spec == 6, ///
		lp(solid) lc("`qfit_color'") yaxis(1 2)) ///
	(qfit beta row if spec == 7, ///
		lp(solid) lc("`qfit_color'") yaxis(1 2)) ///
	(qfit beta row if spec == 999, ///
		lp(solid) lc("`qfit_color'") yaxis(1 2)) ///
	(rspike ci90_lo ci90_hi row, ///
		lcolor(gs14) yaxis(1 2)) ///
	(scatter null row, yaxis(1 2) xaxis(2) mc(white%0)) ///
	(scatter beta row if phase == 1 & spec == 1, /// adj
		mcolor("`phase1_color'") ///
		msize(`msize') msymbol(circle) mlw(medthick) ///
		yaxis(1 2)) ///
	(scatter beta row if phase == 2 & spec == 1, /// adj
		mcolor("`phase2_color'") ///
		msize(`msize') msymbol(circle) mlw(medthick) ///
		yaxis(1 2)) ///
	(scatter beta row if phase == 3 & spec == 1, /// adj
		mcolor("`phase3_color'") ///
		msize(`msize') msymbol(circle) mlw(medthick) ///
		yaxis(1 2)) ///
	(scatter beta row if phase == 1 & spec != 1, /// adj
		mlcolor("`phase1_color'") mfcolor(white) ///
		msize(`msize') msymbol(circle) mlw(medthick) ///
		yaxis(1 2)) ///
	(scatter beta row if phase == 2 & spec != 1, /// adj
		mlcolor("`phase2_color'") mfcolor(white) ///
		msize(`msize') msymbol(circle) mlw(medthick) ///
		yaxis(1 2)) ///
	(scatter beta row if phase == 3 & spec != 1, /// adj
		mlcolor("`phase3_color'") mfcolor(white) ///
		msize(`msize') msymbol(circle) mlw(medthick) ///
		yaxis(1 2)) ///
		, ///
		legend(off) ///
		xtitle(, size(large) orientation(vertical) ///
			axis(1)) ///
		xtitle(, size(large) orientation(vertical) ///
			axis(2)) ///
		xlab( ///
	`=`mean_row_spec1'-2*`ylab_adj_4'' ///
		"{bf:Main specification}" ///
	`=`mean_row_spec1'-1*`ylab_adj_4'' /// 
		"Date fixed effects: yes" ///
	`mean_row_spec1' ///
		"Testing control: no" ///
	`=`mean_row_spec1'+1*`ylab_adj_4'' ///
		"Pre-trend adjustment: yes" ///
	`=`mean_row_spec1'+2*`ylab_adj_4'' ///
		"Migrants: yes" ///
	`=`mean_row_spec2'' ///
		"- Date fixed effects" ///
	`=`mean_row_spec3'-1*`ylab_adj_2'' ///
		"- Date fixed effects" ///
	`=`mean_row_spec3'+1*`ylab_adj_2'' ///
		"+ Date polynomial" ///
	`=`mean_row_spec7'' ///
		"+ Testing control" ///
	`=`mean_row_spec999'' ///
		"- Pre-trend adjustment" ///
	`mean_row_spec6' "- Migrants" ///
		, ///
		angle(90) axis(1) labsize("`xlab_size'")) ///
		xlab( ///
		`=`row_s1_p1'-`ylab2_adj_2'' "        `beta_s1_p1'" ///
			`=`row_s1_p1'+`ylab2_adj_2'' " `ci90_s1_p1'" ///
		`=`row_s1_p2'-`ylab2_adj_2'' "        `beta_s1_p2'" ///
			`=`row_s1_p2'+`ylab2_adj_2'' " `ci90_s1_p2'" ///
		`=`row_s1_p3'-`ylab2_adj_2'' "        `beta_s1_p3'" ///
			`=`row_s1_p3'+`ylab2_adj_2'' " `ci90_s1_p3'" ///
		`=`row_s2_p1'-`ylab2_adj_2'' "        `beta_s2_p1'" ///
			`=`row_s2_p1'+`ylab2_adj_2'' " `ci90_s2_p1'" ///
		`=`row_s2_p2'-`ylab2_adj_2'' "        `beta_s2_p2'" ///
			`=`row_s2_p2'+`ylab2_adj_2'' " `ci90_s2_p2'" ///
		`=`row_s2_p3'-`ylab2_adj_2'' "        `beta_s2_p3'" ///
			`=`row_s2_p3'+`ylab2_adj_2'' " `ci90_s2_p3'" ///
		`=`row_s3_p1'-`ylab2_adj_2'' "        `beta_s3_p1'" ///
			`=`row_s3_p1'+`ylab2_adj_2'' " `ci90_s3_p1'" ///
		`=`row_s3_p2'-`ylab2_adj_2'' "        `beta_s3_p2'" ///
			`=`row_s3_p2'+`ylab2_adj_2'' " `ci90_s3_p2'" ///
		`=`row_s3_p3'-`ylab2_adj_2'' "        `beta_s3_p3'" ///
			`=`row_s3_p3'+`ylab2_adj_2'' " `ci90_s3_p3'" ///
		`=`row_s6_p1'-`ylab2_adj_2'' "        `beta_s6_p1'" ///
			`=`row_s6_p1'+`ylab2_adj_2'' " `ci90_s6_p1'" ///
		`=`row_s6_p2'-`ylab2_adj_2'' "        `beta_s6_p2'" ///
			`=`row_s6_p2'+`ylab2_adj_2'' " `ci90_s6_p2'" ///
		`=`row_s6_p3'-`ylab2_adj_2'' "        `beta_s6_p3'" ///
			`=`row_s6_p3'+`ylab2_adj_2'' " `ci90_s6_p3'" ///
		`=`row_s7_p1'-`ylab2_adj_2'' "        `beta_s7_p1'" ///
			`=`row_s7_p1'+`ylab2_adj_2'' " `ci90_s7_p1'" ///
		`=`row_s7_p2'-`ylab2_adj_2'' "        `beta_s7_p2'" ///
			`=`row_s7_p2'+`ylab2_adj_2'' " `ci90_s7_p2'" ///
		`=`row_s7_p3'-`ylab2_adj_2'' "        `beta_s7_p3'" ///
			`=`row_s7_p3'+`ylab2_adj_2'' " `ci90_s7_p3'" ///
		`=`row_s999_p1'-`ylab2_adj_2'' ///
		"        `beta_s999_p1'" ///
			`=`row_s999_p1'+`ylab2_adj_2'' ///
			" `ci90_s999_p1'" ///
		`=`row_s999_p2'-`ylab2_adj_2'' ///
		"        `beta_s999_p2'" ///
			`=`row_s999_p2'+`ylab2_adj_2'' ///
			" `ci90_s999_p2'" ///
		`=`row_s999_p3'-`ylab2_adj_2'' ///
		"        `beta_s999_p3'" ///
			`=`row_s999_p3'+`ylab2_adj_2'' ///
			" `ci90_s999_p3'" ///
		, ///
		angle(90) axis(2) notick ///
			labsize("`=`xlab_size'-0.25'")) ///
		xlab(, axis(1) notick) ///
		xtitle("", axis(1)) ///
		xtitle("", axis(2)) ///
		xsc(noline axis(1)) ///
		xsc(noline axis(2)) ///
		ysc(noline axis(1)) ///
		ysc(lw(0.3) axis(2)) ///
		ylab("", axis(1)) ///
		ytitle("Excess COVID-19 cases per 1,000 migrants", ///
			axis(2) size("`ytext_size'")) ///
		ylab(-200(200)600, ///
			axis(2) angle(90) ///
			labsize("`ytext_size'") ///
			tlwidth(`tick_axis_thick')) ///
		ytitle("", axis(1)) ///
		ylab(, angle(90) axis(1)) ///
		xsize(8) /// 9.7
		ysize(7.2) /// 7.2 
		yline(0, lp(solid) lc(black) axis(1) ///
			lw(`tick_axis_thick')) ///
		graphregion(margin(l r+1 u-6 d))

graph export "$dirpath_outputs_figs/Figure_robustness_cases.pdf", replace
