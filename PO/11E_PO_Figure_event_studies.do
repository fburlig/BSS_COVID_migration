
* Plot event study regression results

*****************************************************************************
*****************************************************************************
* Set paths
global dirpath_in "$dirpath/data/generated/final/results"
global dirpath_out "$dirpath/outputs/figures"


*****************************************************************************
*****************************************************************************

* Load data
use "$dirpath_in/RESULTS_event_study_phase1_phase2_phase3.dta", clear

* Sort by day
sort T

* Local macros for x-axis labels
local mar2_apr15 = 77
local may1 = 93
local jun1 = 124
local jul1 = 154
local aug1 = 185
local sep1 = 216
local sep15_sep30 = 230


* Plot weighted average cases
preserve

keep if depvar == "num_cases"
keep if phase2_phase3_wavg == 1

twoway ///
	(pci 0.05 80 0.05 80, lcolor(white) lp(solid) ///
		text(0.06 213 "Excess cases" "by Sep 30:" "551,620")) ///
	(pci 0.055 100 0.055 95, lcolor(gs8) lp(solid) ///
		text(0.055 88 "May 8:" "Phase 1" "restrictions lifted")) ///
	(pci 0.055 128 0.055 123, lcolor(gs8) lp(solid) ///
		text(0.055 116 "Jun 5:" "Phase 2" "restrictions lifted")) ///
	(pci 0.055 203 0.055 198, lcolor(gs8) lp(solid) ///
		text(0.055 191 "Aug 19:" "Phase 3" "restrictions lifted")) ///
	(rspike ci90_lo ci90_hi T, lcolor(gs10) lwidth(medium))  ///
	(connected beta T if T < 128, msize(medthick) msymbol(circle) mlcolor(gs10) mfcolor(white) lwidth(medthick) lcolor(gs10) lp(solid)) ///
	(connected beta T if T >= 128 & T < 203, msize(medthick) msymbol(circle) mlcolor(midblue*0.5) mfcolor(white) lwidth(medthick) lcolor(midblue*0.5) lp(solid)) ///
	(connected beta T if T >= 203, msize(medthick) msymbol(circle) mlcolor(midblue*1.5) mfcolor(white) lwidth(medthick) lcolor(midblue*1.5) lp(solid)) ///
		, ///
		legend(off) ///
		ytitle("Marginal effect of 1 returning migrant" "on home-district COVID-19 cases", size(medlarge)) ///
		yline(0, lcolor(gs10)) ///
		xline(100 128 203, lcolor(gs8)) ///
		xlabel(`mar2_apr15' "Mar 2 - Apr 15" ///
			`may1' "May 1" `jun1' "Jun 1" ///
			`jul1' "Jul 1" `aug1' "Aug 1" ///
			`sep1' "Sep 1" `sep15_sep30' "Sep 15 - Sep 30") ///
		xtitle("") ///
		xsize(10) ///
		xsc(r(77 235)) ///
		ylabel(0(0.02)0.06) ///
		title("{bf: {fontface Arial: B}}", pos(10) size(vhuge)) ///

graph export "$dirpath_out/Figure_incmarg_cases.pdf", replace

restore



* Plot weighted average deaths
preserve

keep if depvar == "num_deaths"
keep if phase2_phase3_wavg == 1

twoway ///
	(pci 0.001 80 0.001 80, lcolor(white) lp(solid) ///
		text(0.00275 213 "Excess deaths" "by Sep 30:" "12,500")) ///
	(pci 0.0025 100 0.0025 95, lcolor(gs8) lp(solid) ///
		text(0.0025 88 "May 8:" "Phase 1" "restrictions lifted")) ///
	(pci 0.0025 128 0.0025 123, lcolor(gs8) lp(solid) ///
		text(0.0025 116 "Jun 5:" "Phase 2" "restrictions lifted")) ///
	(pci 0.0025 203 0.0025 198, lcolor(gs8) lp(solid) ///
		text(0.0025 191 "Aug 19:" "Phase 3" "restrictions lifted")) ///
	(rspike ci90_lo ci90_hi T, lcolor(gs10) lwidth(medium))  ///
	(connected beta T if T < 128, msize(medthick) msymbol(circle) mlcolor(gs10) mfcolor(white) lwidth(medthick) lcolor(gs10) lp(solid)) ///
	(connected beta T if T >= 128 & T < 203, msize(medthick) msymbol(circle) mlcolor(midblue*0.5) mfcolor(white) lwidth(medthick) lcolor(midblue*0.5) lp(solid)) ///
	(connected beta T if T >= 203, msize(medthick) msymbol(circle) mlcolor(midblue*1.5) mfcolor(white) lwidth(medthick) lcolor(midblue*1.5) lp(solid)) ///
		, ///
		legend(off) ///
		ytitle("Marginal effect of 1 returning migrant" "on home-district COVID-19 deaths", size(medlarge)) ///
		yline(0, lcolor(gs10)) ///
		xline(100 128 203, lcolor(gs8)) ///
		xlabel(`mar2_apr15' "Mar 2 - Apr 15" ///
			`may1' "May 1" `jun1' "Jun 1" ///
			`jul1' "Jul 1" `aug1' "Aug 1" ///
			`sep1' "Sep 1" `sep15_sep30' "Sep 15 - Sep 30") ///
		xtitle("") ///
		xsize(10) ///
		xsc(r(77 235)) ///
		ylabel(0(0.001)0.003)

graph export "$dirpath_out/Figure_SI_incmarg_deaths.pdf", replace

restore


* Plot Phase 1 cases
preserve

keep if depvar == "num_cases"
keep if phase1 == 1

twoway ///
	(pci 0.0025 100 0.0025 95, lcolor(gs8) lp(solid) ///
		text(0.0025 88 "May 8:" "Phase 1" "restrictions lifted")) ///
	(pci 0.0025 128 0.0025 123, lcolor(gs8) lp(solid) ///
		text(0.0025 116 "Jun 5:" "Phase 2" "restrictions lifted")) ///
	(pci 0.0025 203 0.0025 198, lcolor(gs8) lp(solid) ///
		text(0.0025 191 "Aug 19:" "Phase 3" "restrictions lifted")) ///
	(rspike ci90_lo ci90_hi T, lcolor(gs10) lwidth(medium))  ///
	(connected beta T, msize(medthick) msymbol(circle) mlcolor(gs10) mfcolor(white) lwidth(medthick) lcolor(gs10) lp(solid)) ///
		, ///
		legend(off) ///
		ytitle("Marginal effect of 1 returning Phase 1" "migrant on home-district COVID-19 cases", size(medlarge)) ///
		yline(0, lcolor(gs10)) ///
		xline(100 128 203, lcolor(gs8)) ///
		xlabel(`mar2_apr15' "Mar 2 - Apr 15" ///
			`may1' "May 1" `jun1' "Jun 1" ///
			`jul1' "Jul 1" `aug1' "Aug 1" ///
			`sep1' "Sep 1" `sep15_sep30' "Sep 15 - Sep 30") ///
		xtitle("") ///
		xsize(10) ///
		xsc(r(77 236)) ///
		title("{bf: {fontface Arial: A}}", pos(10) size(vhuge)) ///

graph export "$dirpath_out/Figure_SI_incmarg_cases_phase1.pdf", replace

restore




* Plot Phase 2 cases
preserve

keep if depvar == "num_cases"
keep if phase2 == 1

twoway ///
	(pci 0.0225 100 0.0225 95, lcolor(gs8) lp(solid) ///
		text(0.0225 88 "May 8:" "Phase 1" "restrictions lifted")) ///
	(pci 0.0225 128 0.0225 123, lcolor(gs8) lp(solid) ///
		text(0.0225 116 "Jun 5:" "Phase 2" "restrictions lifted")) ///
	(pci 0.0225 203 0.0225 198, lcolor(gs8) lp(solid) ///
		text(0.0225 191 "Aug 19:" "Phase 3" "restrictions lifted")) ///
	(rspike ci90_lo ci90_hi T, lcolor(gs10) lwidth(medium))  ///
	(connected beta T, msize(medthick) msymbol(circle) mlcolor(midblue*0.5) mfcolor(white) lwidth(medthick) lcolor(midblue*0.5) lp(solid)) ///
		, ///
		legend(off) ///
		ytitle("Marginal effect of 1 returning Phase 2" "migrant on home-district COVID-19 cases", size(medlarge)) ///
		yline(0, lcolor(gs10)) ///
		xline(100 128 203, lcolor(gs8)) ///
		xlabel(`mar2_apr15' "Mar 2 - Apr 15" ///
			`may1' "May 1" `jun1' "Jun 1" ///
			`jul1' "Jul 1" `aug1' "Aug 1" ///
			`sep1' "Sep 1" `sep15_sep30' "Sep 15 - Sep 30") ///
		xtitle("") ///
		xsize(10) ///
		xsc(r(77 236)) ///
		title("{bf: {fontface Arial: B}}", pos(10) size(vhuge)) ///

graph export "$dirpath_out/Figure_SI_incmarg_cases_phase2.pdf", replace

restore






* Plot Phase 3 cases
preserve

keep if depvar == "num_cases"
keep if phase3 == 1

twoway ///
	(pci 0.095 100 0.095 95, lcolor(gs8) lp(solid) ///
		text(0.095 88 "May 8:" "Phase 1" "restrictions lifted")) ///
	(pci 0.095 128 0.095 123, lcolor(gs8) lp(solid) ///
		text(0.095 116 "Jun 5:" "Phase 2" "restrictions lifted")) ///
	(pci 0.095 203 0.095 198, lcolor(gs8) lp(solid) ///
		text(0.095 191 "Aug 19:" "Phase 3" "restrictions lifted")) ///
	(rspike ci90_lo ci90_hi T, lcolor(gs10) lwidth(medium))  ///
	(connected beta T, msize(medthick) msymbol(circle) mlcolor(midblue*1.5) mfcolor(white) lwidth(medthick) lcolor(midblue*1.5) lp(solid)) ///
		, ///
		legend(off) ///
		ytitle("Marginal effect of 1 returning Phase 3" "migrant on home-district COVID-19 cases", size(medlarge)) ///
		yline(0, lcolor(gs10)) ///
		xline(100 128 203, lcolor(gs8)) ///
		xlabel(`mar2_apr15' "Mar 2 - Apr 15" ///
			`may1' "May 1" `jun1' "Jun 1" ///
			`jul1' "Jul 1" `aug1' "Aug 1" ///
			`sep1' "Sep 1" `sep15_sep30' "Sep 15 - Sep 30") ///
		xtitle("") ///
		xsize(10) ///
		xsc(r(77 236)) ///
		title("{bf: {fontface Arial: C}}", pos(10) size(vhuge)) ///

graph export "$dirpath_out/Figure_SI_incmarg_cases_phase3.pdf", replace

restore


