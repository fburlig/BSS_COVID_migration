* Prepare empirical estimates

global dirpath_in "$dirpath/data/generated/final/regression_inputs"
global dirpath_out "$dirpath/data/generated/final/regression_inputs"
	
* Load data
use "$dirpath_in/covid19india_migrants_remittance.dta", clear

// select migrant counts
rename T5m_Dremittance num_migrants
			
* Round migrant counts
replace num_migrants = round(num_migrants)

// 1) create calendar day dummy
//  date_state = 1 first day of data, 68 on may 8: the day inter-state opened up
qui gen T = 100 + date_stata - 68
tab T, gen(T_)
// rename dummies to be centered on may8 = 100
forval i = 213(-1)1 {
	local j = `i' + (100 - 68)
	rename T_`i' T_`j'
}
drop T_33-T_77 
gen T_77 = 0
replace T_77 = 1 if date <= date("2020/04/15", "YMD")

drop T_230-T_245
gen T_230 = 0
replace T_230 = 1 if date >= date("2020/09/15", "YMD")

// 2) create terms 1-3:
forval t = 77/230 {
	gen Tmig_phase2_`t' = T_`t' * phase2 * num_migrants
	gen Tmig_phase3_`t' = T_`t' * phase3 * num_migrants
	gen Tmig_phase1_`t' = T_`t' * (1 - in_state) * num_migrants
	drop T_`t'
}

// 3) set out-of-state release date (may8) to be omitted
order Tmig_phase2_100 Tmig_phase3_100 Tmig_phase1_100, last

* Keep necessary variables
keep state district district_id date week week2 num_cases ///
	num_tested_1wk num_cases_date_control ///
	Tmig_phase1* Tmig_phase2* Tmig_phase3*


save "$dirpath_out/event_study_dataset_permtest.dta", replace
