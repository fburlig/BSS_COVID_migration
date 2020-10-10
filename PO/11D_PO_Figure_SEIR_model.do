
* Plot SEIR model predictions

*****************************************************************************
*****************************************************************************
* Set paths
global dirpath_in "$dirpath/data/generated/final/results"
global dirpath_out "$dirpath/outputs/figures"

set scheme fb2, perm

*****************************************************************************
*****************************************************************************

* Load data
import delimited "$dirpath_in/sier_travel_phases.csv", clear


* Convert to thousands
replace rural_infections = rural_infections / 1000


* Create state-formatted date variable
gen date_stata = date(date, "YMD")


* Translate into number of days travel restrictions in place
sum date_stata, det
local min_date = r(min)
replace date_stata =  date_stata - `min_date' + 1


* Adjust cases relative to may 8th
preserve
keep if phase2 == 1
keep if date == "2020-05-08"
local phase2_val_may8 = rural_infections[1]
restore

preserve
keep if phase2 == 0
keep if date == "2020-05-08"
local phase3_val_may8 = rural_infections[1]
restore

replace rural_infections = rural_infections - `phase2_val_may8' if ///
	phase2 == 1
replace rural_infections = rural_infections - `phase3_val_may8' if ///
	phase2 == 0

	
* Create local macros for plotting
// restriction lengths to dates
local may8 = 45
local jun5 = 73
local aug19 = 148

// values
preserve
keep if phase2 == 1
local phase2_val = rural_infections[73]
restore

preserve
keep if phase2 == 0
local phase3_val = rural_infections[148]
restore


* Plot 
twoway ///
	(pci `phase2_val' 0 `phase2_val' `jun5', lcolor(midblue*0.5) lp(dash)) ///
	(pci `phase3_val' 0 `phase3_val' `aug19', lcolor(midblue*1.5) lp(dash)) ///
	(pci 750 `may8' 750 `=`may8'+5', lcolor(gs8) lp(solid) lw(medthick) ///
		text(750 `=`may8'+12' "Phase 1" "mobility" "restrictions" "duration")) ///
	(pci 750 `jun5' 750 `=`jun5'+5', lcolor(gs8) lp(solid) lw(medthick) ///
		text(750 `=`jun5'+12' "Phase 2" "mobility" "restrictions" "duration")) ///
	(pci 750 `aug19' 750 `=`aug19'-5', lcolor(gs8) lp(solid) lw(medthick) ///
		text(750 `=`aug19'-12' "Phase 3" "mobility" "restrictions" "duration")) ///
	(line rural_infections date_stata if phase2 == 1, msize(medthick) msymbol(circle) mlcolor(midblue) mfcolor(white) lwidth(medthick) lcolor(midblue*0.5) lp(solid) lw(medthick) ///
	text(350 `=`may8'-12' "Excess cases" "from Phase 2" "restrictions")) ///
	(line rural_infections date_stata if phase2 == 0, msize(medthick) msymbol(circle) mlcolor(midblue) mfcolor(white) lwidth(medthick) lcolor(midblue*1.5) lp(solid) lw(medthick) ///
	text(350 `=`may8'-35' "Excess cases" "from Phase 3" "restrictions")) ///
	, ///
	title("{bf: {fontface Arial: A}}", pos(10) size(vhuge)) ///
	xlabel(, labsize(large)) ///
	ylabel(, labsize(large)) ///
	xtitle("Duration of travel restrictions (days)", size(large)) ///
	ytitle("Excess cases relative to" "May 8th (thousands)", size(large)) ///
	xsize(10) ///
	xline(`may8' `jun5' `aug19', lwidth(medthick) lcolor(gs10)) ///
	yline(0, lcolor(gs8) lp(solid)) ///
	legend(order(6 "Phase 2 migrants" 7 "Phase 3 migrants") row(2) ring(0) pos(11))
	
	
graph export "$dirpath_out/Figure_seir_model.pdf", replace
