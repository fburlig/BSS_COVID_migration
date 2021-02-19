
* Plot event study regression results for India

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
* Prep data for plotting
******************************************************************

* Load event study coefficient results
use "$dirpath_final_results/RESULTS_event_studies_phase1_phase2_phase3_adj.dta", clear

* Drop aggregated estimates
drop if total == 1

* Keep cases and deaths main specs
keep if spec == 1 | spec == 8
gunique tot_migrants phase
assert r(unique) == 3
gunique T
assert _N == 2 * 3 * r(unique)

* Drop 95% CIs
drop ci95*

* Convert to total case estimates, rather than marginals
foreach var of varlist beta_unadj se ci90_lo_unadj ci90_hi_unadj beta_adj ci90_lo_adj ci90_hi_adj {
	replace `var' = `var' * tot_migrants
}

******************************************************************
* Plot
******************************************************************

* Macros used in plot that are not spec or phase specific
local labsize = "vlarge"
local msize = 1.2
local tick_axis_thick = 0.3
local xyline_gray = "gs12"
local ci_color = "gs8"
local pretrend_line_color = "gs11"

* Save dataset to reload in subsequent passes through plots
save "$dirpath_int_temp/india_event_study_temp.dta", replace

* Loop through phases
forvalues phase = 1(1)3 {
	
* Load data
use "$dirpath_int_temp/india_event_study_temp.dta", clear
	
* Spec details
// Plot 1 = adjusted estimates, cases (thousands), main spec
keep if spec == 1
drop *_unadj
rename beta_adj beta
rename ci90_hi_adj ci90_hi
rename ci90_lo_adj ci90_lo
// convert to thousands
foreach var of varlist beta ci90_hi ci90_lo {
	replace `var' = `var' / 1000
}
local filename = "total_cases_adjusted"
local depvar = "cases (thousands)"
local xsize = 2.4
local ysize = 5.313
local xtitle_space = "       "
local panel_num = "c"

* Phase details
keep if phase == `phase'
	
if `phase' == 1 {
	local xlabel = ""
	local x_line = "noline"
	local mcolor = "`phase1_color'"
	local text_y = 0.003 + .001
	local xtitle = ""
	local ylabel = "0(1)3"
	local title_gap = "5.75"
	local ylab_format = "%10.0fc"
}
if `phase' == 2 {
	local xlabel = ""
	local x_line = "noline"
	local mcolor = "`phase2_color'"
	local text_y = 0.04 + 0.01333333
	local xtitle = "Days since travel ban release"
	local title_gap = "5.75"
	local ylabel = "0(1)3"
	local ylab_format = "%10.0fc"
}

if `phase' == 3 {
	local xlabel = "-30(15)30"
	local x_line = ""
	local mcolor = "`phase3_color'"
	local text_y = 0.044 + 0.01333333
	local xtitle = ""
	local title_gap = "0"
	local ylabel = "-3(3)6"
	local ylab_format = "%10.0fc"
}

if `phase' == 1 {
twoway ///
	(rspike ci90_lo ci90_hi T, ///
		lcolor(gs8) lwidth(medium))  ///
	(connected beta T, ///
		mlw(medium) msize("`msize'") msymbol(circle) ///
		mlcolor("`mcolor'") mfcolor(white) ///
		lwidth(medthick) lcolor("`mcolor'") lp(solid)) ///
	, ///
		legend(off) ///
		ytitle("") ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xline(-1, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xtitle("") ///
		xlabel("`xlabel'", notick labsize("`labsize'")) ///
		ylabel("`ylabel'", labsize("`labsize'") ///
			tlwidth(`tick_axis_thick') ///
			format("`ylab_format'")) ///
		xsc(noline) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		name("graph_phase`phase'", replace)
		
}

if `phase' == 2 {
twoway ///
	(rspike ci90_lo ci90_hi T, ///
		lcolor(gs8) lwidth(medium))  ///
	(connected beta T, ///
		mlw(medium) msize("`msize'") msymbol(circle) ///
		mlcolor("`mcolor'") mfcolor(white) ///
		lwidth(medthick) lcolor("`mcolor'") lp(solid)) ///
	, ///
		legend(off) ///
		ytitle("") ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xline(-1, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xtitle("") ///
		xlabel("`xlabel'", notick labsize("`labsize'")) ///
		ylabel("`ylabel'", labsize("`labsize'") ///
			tlwidth(`tick_axis_thick') ///
			format("`ylab_format'")) ///
		xsc(noline) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		name("graph_phase`phase'", replace)
		
}

if `phase' == 3 {
twoway ///
	(rspike ci90_lo ci90_hi T, ///
		lcolor(gs8) lwidth(medium))  ///
	(connected beta T, ///
		mlw(medium) msize("`msize'") msymbol(circle) ///
		mlcolor("`mcolor'") mfcolor(white) ///
		lwidth(medthick) lcolor("`mcolor'") lp(solid)) ///
	, ///
		legend(off) ///
		ytitle("") ///
		yline(0, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xline(-1, lcolor("`xyline_gray'") ///
			lw(`tick_axis_thick')) ///
		xtitle("") ///
		xlabel("`xlabel'", notick labsize("`labsize'") ///
			tlwidth(`tick_axis_thick')) ///
		ylabel("`ylabel'", labsize("`labsize'") ///
			tlwidth(`tick_axis_thick') ///
			format("`ylab_format'")) ///
		ysc(lw(`tick_axis_thick') titlegap(*`title_gap')) ///
		name("graph_phase`phase'", replace)
		
}

} // end phase loop

graph combine graph_phase1 graph_phase2 graph_phase3, ///
	title("{bf: {fontface Arial: `panel_num'}}", ///
		pos(10) size(vhuge)) ///
	rows(3) ///
	xsize(`xsize') /// default is 5.5
	ysize(`ysize') /// old: 4 default is 4
	b1("`xtitle_space'Days since travel ban release", ///
		size(large)) ///
	l1("Excess COVID-19 `depvar'", size(large))

graph export "$dirpath_outputs_figs/Figure_india_event_studies_`filename'.pdf", replace


******************************************************************
* Clear temporary directory
******************************************************************

cd "$dirpath_int_temp"
local files: dir . files "*.dta"

foreach file of local files {
	erase `file'
}
