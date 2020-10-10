
* Plot event study regression results for difference specifications

*****************************************************************************
*****************************************************************************
* Set paths
global dirpath_in "$dirpath/data/generated/final/results"
global dirpath_out "$dirpath/outputs/figures"

*****************************************************************************
*****************************************************************************

* Load data
use "$dirpath_in/RESULTS_event_study_phase1_phase2_phase3.dta", clear


* Keep total case estimates 
keep if tot_phase2_phase3_wavg == 1 & depvar == "num_cases"


* Order specs
gen row = .
replace row = 1 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "poly_week" & ///
	controls == "cases+tests" & ///
	weight == "none"
replace row = 2 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "none" & ///
	controls == "cases+tests" & ///
	weight == "none"
replace row = 3 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "week_fe" & ///
	controls == "cases+tests" & ///
	weight == "none"
replace row = 4 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "poly_week" & ///
	controls == "cases+tests" & ///
	weight == "migrants"
replace row = 5 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "poly_week" & ///
	controls == "cases+tests" & ///
	weight == "population"
replace row = 6 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "poly_week" & ///
	controls == "tests" & ///
	weight == "none"
replace row = 7 if ///
	migrant_counts == "T5m_Dremittance" & ///
	time_control == "poly_week" & ///
	controls == "cases" & ///
	weight == "none" 
replace row = 8 if /// 
	migrant_counts == "T5m_TSsbth_DSsremittance" & ///
	time_control == "poly_week" & ///
	controls == "cases+tests" & ///
	weight == "none"
replace row = 9 if ///
	migrant_counts == "T5m_TSsbth_DScns"

sort row

* Add space between main spec and following specs
gen main_spec = 0
replace main_spec = 1 if row == 1

replace row = .7  if main_spec == 1

* Convert to thousands
foreach var of varlist beta ci90_lo ci90_hi ci95_lo ci95_hi {
	replace `var' = `var' / 1000
}

* Make string versions
foreach var of varlist beta ci90_lo ci90_hi ci95_lo ci95_hi {
	gen `var'_str = `var'
	tostring `var'_str, replace format(%04.2f) force
}

* Combine confidence intervals in string
gen ci90_str = "(" + ci90_lo_str + ", " + ci90_hi_str + ")"
gen ci95_str = "(" + ci95_lo_str + ", " + ci95_hi_str + ")"
	
* Cases by labels
local nrows = _N
forvalues i = 1/`nrows' {
	local beta`i' = beta_str[`i']
	local ci90_`i' = ci90_str[`i']
	local ci95_`i' = ci95_str[`i']
}
local x_line_main_spec = beta[1]
local seir_prediction = 375.89

gen dummy = 0

twoway ///
	(pci 0 0 9.3 0, lcolor(black) lwidth(medthick)) /// line at 0
	(pci 0 `x_line_main_spec' 9.3 `x_line_main_spec', lcolor(midblue*1.3) lwidth(medthick) lp(shortdash) /// ine at main spec
	text(-0.5 `=`x_line_main_spec'+180' "Empirical estimate:" "Main specification", /// main spec text
			size(small) color(black))) ///
	(pci -0.5 `=`x_line_main_spec'+28' -0.5 `x_line_main_spec', lcolor(gs10)) ///  arrow for main spec
	(pcarrowi -0.5 `x_line_main_spec' -0.05 `x_line_main_spec', lcolor(gs10) mcolor(gs10)) /// arrow for main spec
	(pci 0 `seir_prediction' 9.3 `seir_prediction', lcolor(midblue*1.6) lwidth(medthick) lp(shortdash) /// line at SEIR prediction
	text(-0.5 `=`seir_prediction'-165' "SEIR prediction:" "`seir_prediction'", ///
			size(small) color(black))) /// SEIR prediction text
	(pci -0.5 `=`seir_prediction'-37' -0.5 `seir_prediction', lcolor(gs10)) ///  arrow for SEIR prediction
	(pcarrowi -0.5 `seir_prediction' -0.05 `seir_prediction', lcolor(gs10) mcolor(gs10)) /// arrow for SEIR prediction
	(rspike ci95_lo ci95_hi row, horizontal color(gs10) yaxis(1)) /// 90% CI
	(scatter row beta if main_spec == 1, mcolor(midblue) yaxis(1) msymbol(circle) msize(medlarge)) /// 
	(scatter row beta if main_spec == 0, mcolor(midblue) yaxis(1) msymbol(circle) mfcolor(white) msize(medlarge)) /// 
	(scatter row dummy if row == 1, mcolor(white) yaxis(2)) /// for 2nd yaxis values
	, ///
	legend(off) ///
	xtitle("Excess cases by September 30th (thousands)", size(medlarge)) /// 
	ytitle("", axis(1) orientation(hor)) /// 
	ytitle("", axis(2) orientation(hor) height(10)) /// 
	xlabel(, labsize(medlarge)) ///
	xsc(lw(medthick) r(0 815)) ///
	xlabel(0(200)800, tlw(medthick) format(%5.0fc)) ///
	yscale(reverse lstyle(none) axis(1) r(-0.6 9.2)) /// y axis is flipped
	yscale(reverse lstyle(none) axis(2) r(-0.6 9.2)) ///
	ylabel(0 "{bf:Remittances only}" /// 	spec 1
		0.35 "Week polynomials: yes" ///
		0.7 "Weighted: no" ///
		1.05 "Control district cases: yes" ///
		1.4 "Testing control: yes" ///
		1.83 "{bf:Remittances only}" /// 	spec 2
		2.17 "- Week polynomials" ///
		2.65 "{bf:Remittances only}" /// 	spec 3
		3 "- Week polynomials" ///
		3.35 "+ Week fixed effects" ///
		3.83 "{bf:Remittances only}" /// 	spec 5
		4.17 "+ Migrant weights" ///
		4.83 "{bf:Remittances only}" /// 	spec 5
		5.17 "+ Population weights" ///
		5.83 "{bf:Remittances only}" /// 	spec 6
		6.17 "- Control district cases" ///
		6.83 "{bf:Remittances only}" /// 	spec 7
		7.17 "- Testing control" ///
		8 "{bf:Remittances & Census}" /// 		spec 9
		9 "{bf:Census only}" /// 		spec 10		
		, ///
		angle(0) labsize(2.7) noticks axis(1)) ///
	ylabel(.5 "        `beta1'" 0.9 " `ci95_1'" /// 		spec 1
			1.8 "       `beta2'" 2.2 " `ci95_2'" ///		spec 2
			2.8 "       `beta3'" 3.2 " `ci95_3'" ///		spec 3
			3.8 "        `beta4'" 4.2 " `ci95_4'" ///		spec 4
			4.8 "       `beta5'" 5.2 " `ci95_5'" ///		spec 5
			5.8 "        `beta6'" 6.2 " `ci95_6'" ///		spec 6
			6.8 "       `beta7'" 7.2 " `ci95_7'" ///		spec 7
			7.8 "       `beta8'" 8.2 " `ci95_8'" ///		spec 8
			8.8 "       `beta9'" 9.2 " `ci95_9'" ///		spec 9
			, ///
		axis(2) noticks angle(0) labsize(2.7)) ///
	ysize(4.5) ///
	graphregion(margin(l-10 r-6 u-2 d-5)) ///
	plotr(m(zero)) ///
	
	
graph export "$dirpath_out/Figure_SI_robustness_cases.pdf", replace	
	
