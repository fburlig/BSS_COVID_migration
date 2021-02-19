
* Plot SEIR model predictions

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

******************************************************************
* Prep data for plotting
******************************************************************

* Load data
import delimited "$dirpath_final_results/RESULTS_seir_model_predictions.csv", clear

* Convert estimates to per 1,000 phase 2 migrants
gen rural_infections_pmig = (rural_infections / 50229) * 1000

* Translate into number of days travel restrictions in place
gen date_stata = _n

******************************************************************
* Plot
******************************************************************

* Macros for plotting
local xyline_gray = "gs12"
local xyline_gray = "gs12"
local tick_axis_thick = 0.3
local phase2_color = "midblue*0.75"
local msize = 3
local x_adj = 6
//local line_text_height = 3.75
local line_text_height = 3800
local text_size = 4
local early_release = 52
local early_release_val = rural_infections_pmig[`early_release']
local middle_release = 100
local middle_release_val = rural_infections_pmig[`middle_release']
local late_release = 148
local late_release_val = rural_infections_pmig[`late_release']
local mean_early_late = ///
	(`early_release_val' + `late_release_val') / 2
local mean_middle_late = ///
	(`middle_release_val' + `late_release_val') / 2
local ytext_size = 4


* Plot 
twoway ///
	(pci `line_text_height' `early_release' ///
		`line_text_height' `=`early_release'-`x_adj'', ///
		lw(`tick_axis_thick') lc("`xyline_gray'") lp(solid) ///
		text(`line_text_height' ///
			`=`early_release'-`x_adj'-9.5' ///
			"Short ban" "duration", size(`text_size'))) ///
	(pci `line_text_height' `middle_release' ///
		`line_text_height' `=`middle_release'-`x_adj'', ///
		lw(`tick_axis_thick') lc("`xyline_gray'") lp(solid) ///
		text(`line_text_height' ///
			`=`middle_release'-`x_adj'-11.75' ///
			"Intermediate" "ban duration", size(`text_size'))) ///
	(pci `line_text_height' `late_release' ///
		`line_text_height' `=`late_release'-`x_adj'', ///
		lw(`tick_axis_thick') lc("`xyline_gray'") lp(solid) ///
		text(`line_text_height' ///
			`=`late_release'-`x_adj'-9' ///
			"Long ban" "duration", size(`text_size'))) ///
	(pci `early_release_val' `early_release' ///
		`early_release_val' 0, lp(dash) lc(midblue) ///
			lw(`tick_axis_thick') ///
			text(`mean_early_late' 38 ///
			"Long" "vs short" "ban duration", ///
			size(`text_size'))) ///
	(pci `middle_release_val' `middle_release' ///
		`middle_release_val' 0, lp(dash) lc(midblue) ///
			lw(`tick_axis_thick') ///
			text(`mean_middle_late' 11 ///
			"Intermediate" "vs short" "ban duration", ///
			size(`text_size'))) ///
	(pci `late_release_val' `late_release' ///
		`late_release_val' 0, lp(dash) lc(midblue) ///
			lw(`tick_axis_thick')) ///
	(line rural_infections_pmig date_stata, ///
		lc(gs10) lp(solid) lw(0.5)) ///
	(scatter rural_infections_pmig date_stata if ///
		date_stata == `early_release' | ///
		date_stata == `middle_release' | ///
		date_stata == `late_release', ///
		mlcolor(midblue) mfcolor("white") ///
		msize(`msize') msymbol(circle) mlw(medthick)) ///
	, ///
	legend(off) ///
	xlabel(, labsize(`ytext_size') tlwidth(`tick_axis_thick')) ///
	ylabel(, labsize(`ytext_size') tlwidth(`tick_axis_thick') ///
		format(%10.0fc)) ///
	xtitle("Travel ban duration (days)", ///
		size(`ytext_size')) ///
	ytitle("Excess COVID-19 cases per 1,000 migrants" , ///
		size(`ytext_size')) ///
	xsize(3.5) ///
	ysize(1.9) ///
	xline(`early_release' `middle_release' `late_release', ///
		lc("`xyline_gray'") ///	
		lw(`tick_axis_thick')) ///
	xsc(lw(`tick_axis_thick')) ///
	ysc(lw(`tick_axis_thick'))
	
	
graph export "$dirpath_outputs_figs/Figure_seir_model.pdf", replace

