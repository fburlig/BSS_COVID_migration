
* Plot main empirical results for India

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

* Macros for plotting
local tick_axis_thick = 0.3
local xyline_gray = "gs12"
local range_x1_cases = -0.75 
local range_x2_cases = 3.75
local range_x1_deaths = -0.3 
local range_x2_deaths = 3.3
local phase1_color = "midblue*1.5"
local phase1_color2 = "midblue*1.25"
local phase2_color = "midblue*0.75"
local phase2_color2 = "midblue*0.5"
local phase3_color = "79 41 132"
local phase3_color2 = "`phase3_color'*0.75"
local ci_color = "gs8"
local qfit_color = "gs11" 
local depvars num_cases num_deaths

******************************************************************* Plot dot plot showing marginal case effects
******************************************************************

* Load data
use "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3_adj.dta", clear

* Keep main spec for cases and deaths
keep if spec == 1 | spec == 8

* Keep totals
keep if total == 1
assert _N == 6

* Keep adjusted estimates
drop *_unadj

* Keep 90% CIs
drop ci95*

* Rename variables and convert to per 1,000 migrants
local varlist beta ci90_lo ci90_hi
foreach var of local varlist {
	rename `var'_adj `var'
	replace `var' = `var' * 1000
}

* Loop through cases and deaths
foreach depvar of local depvars {

preserve

* Keep dependent var in question
keep if depvar == "`depvar'"

* Generate x-axis positions
gen x_pos = .
bys spec: replace x_pos = 0 if _n == 1
bys spec: replace x_pos = 1.5 if _n == 2
bys spec: replace x_pos = 3 if _n == 3
assert !missing(x_pos)

if "`depvar'" == "num_cases" {
	local y_adj = 0.03 * 1000
	local varname = "cases"
	local p1_text_x = `=`range_x1_cases'/2'
	local p2_text_x = 1.5
	local p3_text_x = 3.45
	local title_gap = 0
	local ylab = "-150(150)600"
	local panel_num = "d"
}

if "`depvar'" == "num_deaths" {
	local y_adj = .001 * 1000
	local varname = "deaths"
	local p1_text_x = 0
	local p2_text_x = 1.5
	local p3_text_x = 3
	local title_gap = 0
	local ylab = "-6(6)18"
	local panel_num = "a"
}

gsort phase

* Store point estimates for each phase
forvalues phase = 1(1)3 {
	if "`depvar'" == "num_cases" {
		local beta_phase`phase'_lab = ///
			string(beta[`phase'], "%10.2f")
	}
	if "`depvar'" == "num_deaths" {
		local beta_phase`phase'_lab = ///
			string(beta[`phase'], "%10.2f")
	}
	local beta_phase`phase' = beta[`phase']
	local ci90_hi_phase`phase' = ci90_hi[`phase']
	local ci90_lo_phase`phase' = ci90_lo[`phase']
}

* Plot
if "`depvar'" == "num_cases" {
twoway ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase1'+`y_adj'' `=`p1_text_x'' ///
			"`beta_phase1_lab'", size(large))) ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase2'+`y_adj'' `p2_text_x' ///
			"`beta_phase2_lab'", size(large))) ///
	(pci 0 0 0 0, ///
		text(`=`beta_phase3'+40' `p3_text_x' ///
			"`beta_phase3_lab'", size(large))) ///
	(qfit beta x_pos, ///
		lc("`qfit_color'") lp(solid) lw(medthick)) ///
	(rspike ci90_lo ci90_hi x_pos, ///
		lcolor("`ci_color'") lwidth(0.35))  ///   
	(scatter beta x_pos if phase == 1, /// adj
		mlcolor("`phase1_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	(scatter beta x_pos if phase == 2, /// adj
		mlcolor("`phase2_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	(scatter beta x_pos if phase == 3, /// adj
		mlcolor("`phase3_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
		, ///
		legend(off) ///
		xtitle("") ///
		ytitle("Excess COVID-19 `varname' per 1,000 migrants" ///
			"by 30 days after release", ///
			size(vlarge)) ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xsc(noline r("`range_x1_cases'" "`range_x2_cases'")) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		ylab("`ylab'", labsize(vlarge) ///
			tlwidth(`tick_axis_thick')) ///
		xlab(0 "Phase 1" ///
			1.5 "Phase 2" ///
			3 "Phase 3", ///
			labsize(vlarge) notick) ///
		xsize(2.4) /// default is 5.5
		ysize(2.67) /// old: 2 default is 4
		title("{bf: {fontface Arial: `panel_num'}}", ///
			pos(10) size(vhuge)) ///
		name("dots_`depvar'", replace)
}

if "`depvar'" == "num_deaths" {
twoway ///
	(pci 0 0 0 0, ///
		text(`=`ci90_lo_phase1'-`y_adj'' `=`p1_text_x'' ///
			"`beta_phase1_lab'", size(large))) ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase2'+`y_adj'' `p2_text_x' ///
			"`beta_phase2_lab'", size(large))) ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase3'+`y_adj'' `p3_text_x' ///
			"`beta_phase3_lab'", size(large))) ///
	(qfit beta x_pos, ///
		lc("`qfit_color'") lp(solid) lw(medthick)) ///
	(rspike ci90_lo ci90_hi x_pos, ///
		lcolor("`ci_color'") lwidth(0.35))  ///   
	(scatter beta x_pos if phase == 1, /// adj
		mlcolor("`phase1_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	(scatter beta x_pos if phase == 2, /// adj
		mlcolor("`phase2_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
	(scatter beta x_pos if phase == 3, /// adj
		mlcolor("`phase3_color'") mfcolor(white) ///
		msize(vlarge) msymbol(circle) mlw(medthick)) ///
		, ///
		legend(off) ///
		xtitle("") ///
		ytitle("Excess COVID-19 `varname' per 1,000 migrants" ///
			"by 30 days after release", ///
			size(vlarge)) ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xsc(noline r("`range_x1_cases'" "`range_x2_cases'")) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		ylab("`ylab'", labsize(vlarge) ///
			tlwidth(`tick_axis_thick')) ///
		xlab(0 "Phase 1" ///
			1.5 "Phase 2" ///
			3 "Phase 3", ///
			labsize(vlarge) notick) ///
		xsize(2.4) /// default is 5.5
		ysize(2.67) /// old: 2 default is 4
		title("{bf: {fontface Arial: `panel_num'}}", ///
			pos(10) size(vhuge)) ///
		name("dots_`depvar'", replace)
}

restore
}

******************************************************************* Plot bar chart showing effects by june 30th
******************************************************************

* Load data
use "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3_adj.dta", clear

keep if spec == 9 | spec == 10

* Keep adjusted estimates
drop *_unadj

* Keep 90% CIs
drop ci95*

* Rename variables
local varlist beta ci90_lo ci90_hi
foreach var of local varlist {
	rename `var'_adj `var'
}

* Convert to per 1,000 migrants
foreach var of varlist beta ci90_lo ci90_hi {
	replace `var' = `var' * 1000
}

* Macros for plotting
local barwidth = 1

* Loop through cases and deaths
local depvars num_cases num_deaths
foreach depvar of local depvars {

preserve

* Keep dependent var in question
keep if depvar == "`depvar'"

* Generate x-axis positions
local x_pos_p1 = 0.5
local x_pos_p2 = 2.5
gen x_pos = .
bys spec: replace x_pos = `x_pos_p1' if _n == 1
bys spec: replace x_pos = `x_pos_p2' if _n == 2
assert !missing(x_pos)

* Cases details
if "`depvar'" == "num_cases" {
	local y_adj = 12
	local title_gap = 5.5
	local varname = "cases"
	local panel_num = "e"
}
if "`depvar'" == "num_deaths" {
	local y_adj = 0.5
	local title_gap = 2
	local varname = "deaths"
	local panel_num = "b"
	local ylab = "-3(3)9"
}
gsort phase

* Store point estimates for each phase
forvalues phase = 1(1)3 {
	if "`depvar'" == "num_cases" {
		local beta_phase`phase'_lab = ///
			string(round(beta[`phase'], 0.01), "%10.2fc")
	}
	if "`depvar'" == "num_deaths" {
		local beta_phase`phase'_lab = ///
			string(round(beta[`phase'], 0.01), "%10.2f")
	}
	local beta_phase`phase' = beta[`phase']
	local ci90_hi_phase`phase' = ci90_hi[`phase']
}

* Plot
if "`depvar'" == "num_cases" {
twoway ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase1'+`y_adj'' `x_pos_p1' ///
			"`beta_phase1_lab'", size(large))) ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase2'+`y_adj'' `x_pos_p2' ///
			"`beta_phase2_lab'", size(large))) ///
	(bar beta x_pos if phase == 1, ///
		fcolor("`phase1_color'") lcolor("`phase1_color2'") ///
		lw(vthin) barwidth(`barwidth')) ///
	(bar beta x_pos if phase == 2, ///
		fcolor("`phase2_color'") lcolor("`phase2_color2'") ///
		lw(vthin) barwidth(`barwidth')) ///
	(rspike ci90_lo ci90_hi x_pos if ///
		phase == 1 | phase == 2, ///
		lcolor(gs4) lwidth(0.35))  /// 
		, ///
		legend(off) ///
		xtitle("") ///
		ytitle("Excess COVID-19 `varname' per 1,000 migrants" ///
			"by June 30th", ///
			size(vlarge)) ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xsc(noline r("`range_x1_cases'" "`range_x2_cases'")) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		ylab(, labsize(vlarge) tlwidth(`tick_axis_thick') ///
			format(%10.0fc)) ///
		xlab(`x_pos_p1' "Phase 1" `x_pos_p2' "Phase 2", ///
			labsize(vlarge) notick) ///
		xsize(2.4) /// default is 5.5
		ysize(2.67) /// old: 2 default is 4
		title("{bf: {fontface Arial: `panel_num'}}", ///
			pos(10) size(vhuge)) ///
		name("bars_`depvar'", replace)

}
 
if "`depvar'" == "num_deaths" {
twoway ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase1'+`y_adj'' `x_pos_p1' ///
			"`beta_phase1_lab'", size(large))) ///
	(pci 0 0 0 0, ///
		text(`=`ci90_hi_phase2'+`y_adj'' `x_pos_p2' ///
			"`beta_phase2_lab'", size(large))) ///
	(bar beta x_pos if phase == 1, ///
		fcolor("`phase1_color'") lcolor("`phase1_color2'") ///
		lw(vthin) barwidth(`barwidth')) ///
	(bar beta x_pos if phase == 2, ///
		fcolor("`phase2_color'") lcolor("`phase2_color2'") ///
		lw(vthin) barwidth(`barwidth')) ///
	(rspike ci90_lo ci90_hi x_pos, ///
		lcolor(gs4) lwidth(0.35))  /// 
		, ///
		legend(off) ///
		xtitle("") ///
		ytitle("Excess COVID-19 `varname' per 1,000 migrants" ///
			"by June 30th", ///
			size(vlarge)) ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xsc(noline r("`range_x1_cases'" "`range_x2_cases'")) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		ylab("`ylab'", labsize(vlarge) ///
			tlwidth(`tick_axis_thick') ///
			format(%10.0fc)) ///
		xlab(`x_pos_p1' "Phase 1" `x_pos_p2' "Phase 2", ///
			labsize(vlarge) notick) ///
		xsize(2.4) /// default is 5.5
		ysize(2.67) /// old: 2 default is 4
		title("{bf: {fontface Arial: `panel_num'}}", ///
			pos(10) size(vhuge)) ///
		name("bars_`depvar'", replace)

}

restore
}

******************************************************************* Combine graphs
******************************************************************

foreach depvar of local depvars {
	if "`depvar'" == "num_cases" {
		local xsize = 2.4
		local ysize = 5.313
	}
	if "`depvar'" == "num_deaths" {
		local xsize = (7.2 / 2) * 0.7
		local ysize = 9.72 * 0.5
	}
	graph combine dots_`depvar' bars_`depvar', ///
		rows(2) ///
		xsize(`xsize') ///
		ysize(`ysize')
	
graph export "$dirpath_outputs_figs/Figure_india_cases_marginal_total_effects_`depvar'.pdf", replace	
}
