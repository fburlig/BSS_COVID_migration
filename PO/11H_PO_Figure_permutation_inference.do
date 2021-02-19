
* Plot permutation inference results

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
local phase1_color2 = "midblue*1.25"
local phase2_color = "midblue*0.75"
local phase2_color2 = "midblue*0.5"
local phase3_color = "79 41 132"
local phase3_color2 = "`phase3_color'*0.75"

******************************************************************
* Plot
******************************************************************

* Macros for plotting
local tick_axis_thick = 0.3
local xyline_gray = "gs12"

* Loop through phases
forvalues phase = 1(1)3 {

* Load data
use "$dirpath_final_results/RESULTS_permutation_inference_test_phases123.dta", clear

* Keep phase in question
keep if phase == `phase'
assert _N == 10001

* Use adjusted estimates
drop *_unadj
rename beta_adj beta

* Conver to thousands
replace beta = beta * 1000

* Get empirical estimate from actual data
preserve
count if missing(seed)
assert r(N) == 1
sum beta if missing(seed)
local true_beta_val_str = string(round(r(max), 0.01), "%10.2f")
di "`true_beta'"
keep if beta > r(max)
assert !missing(seed)
local pval = _N / 10000
if `pval' > 0 {
	local pval_str = string(`pval', "%10.4f")
}
if `pval' == 0 {
	local pval_str = "< 0.0001"
}
restore

* Convert to thousands for plotting
sum beta if missing(seed)
local true_beta_val = r(max)

* Macros for plotting
if `phase' == 1 {
	local y_line_height = 9.3 * 0.995
	local y_text_height_1 = 9.3 * 0.925
	local y_text_height_2 = `y_text_height_1' * 0.618
	local x_adj_pci_1 = -0.0345 * 1000
	local x_adj_pci_2 = -0.0195 * 1000
	local ylab = "0(3.1)9.3"
	local xlab = "-40(20)40"
	local ytitle = ""
	local xrange_lo = -0.04 * 1000
	local xrange_hi = 0.04 * 1000
}
if `phase' == 2 {
	local y_line_height = 75 * 0.995
	local y_text_height_1 = 75 * 0.925
	local y_text_height_2 = `y_text_height_1' * 0.618
	local x_adj_pci_1 = 0.065 * 1000
	local x_adj_pci_2 = `x_adj_pci_1' + 0.2*1000
	local ylab = "0(25)75"
	local xlab = "-250(250)750"
	local ytitle = ""
	local xrange_lo = -0.25 * 1000
	local xrange_hi = 0.9 * 1000
	
}
if `phase' == 3 {
	local y_line_height = 13.5 * 0.995
	local y_text_height_1 = 13.5 * 0.925
	local y_text_height_2 = `y_text_height_1' * 0.618
	local x_adj_pci_1 = -0.12 * 1000
	local x_adj_pci_2 = -0.16 * 1000
	local ylab = "0(4.5)13.5"
	local xlab = "-400(200)200"
	local ytitle = ""
	local xrange_lo = -0.4 * 1000
	local xrange_hi = 0.2 * 1000
}


* Plot
twoway ///
	(pci `y_line_height' `true_beta_val' ///
		`y_line_height' ///
		`=`true_beta_val'+`x_adj_pci_1'', ///
		lcolor("`xyline_gray'") lwidth("`tick_axis_thick'") ///
		text(`y_text_height_1' ///
			`=`true_beta_val'+`x_adj_pci_1'+`x_adj_pci_2'' ///
		"Observed point" "estimate in" "real data:" ///
			"`true_beta_val_str'", ///
		size(large) color(black))) ///
	(pci `y_text_height_2' `true_beta_val' ///
		`y_text_height_2' ///
		`=`true_beta_val'+`x_adj_pci_1'', ///
		lcolor(white%100) ///
		text(`y_text_height_2' ///
		`=`true_beta_val'+`x_adj_pci_1'+`x_adj_pci_2'' ///
		"Permutation" "inference" "p-value:" "`pval_str'", ///
		size(large) color(black))) ///
	(histogram beta, percent ///
		fcolor("`phase`phase'_color'") ///
		lcolor("`phase`phase'_color2'")) ///
	, ///
	legend(off) ///
	xline(`true_beta_val', lcolor("`xyline_gray'") ///
		lp(solid) lw("`tick_axis_thick'")) ///
	xlabel("`xlab'", format(%9.0f) labsize(vlarge) ///
		tlwidth(`tick_axis_thick')) ///
	ylabel("`ylab'", labsize(vlarge) ///
		tlwidth(`tick_axis_thick')) ///
	ytitle("`ytitle'", ///
		size(vlarge)) ///
	xtitle("", ///
		size(large)) ///
	xsc(lw("`tick_axis_thick'") r(`xrange_lo' `xrange_hi')) ///
	ysc(lw("`tick_axis_thick'")) ///
	name("phase`phase'", replace)

}

* Combine figures
graph combine phase1 phase2 phase3, ///
	rows(1) ///
	xsize(7.2) ///
	ysize(3) ///
	b1("Excess COVID-19 cases per 1,000 migrants", ///
		size(large)) ///
	l1("     Percent of draws with scrambled cases", ///
		size(large))

graph export "$dirpath_outputs_figs/Figure_permutation_inference_phase123.pdf", replace


