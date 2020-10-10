* Run main empirical specifications and robustness
clear all
macro drop _all

global dirpath "/Users/garyschlauch/desktop/covid_india_migrants"
global dirpath_in = "$dirpath/data/Generated/final/regression_inputs"
global dirpath_out = "$dirpath/data/Generated/Final/Results"
	
* Generate weights for remit only phase2/non_phase2_instate migrants
use "$dirpath_in/covid19india_migrants_remittance.dta", clear
duplicates drop state district, force
keep if in_state == 1
replace T5m_Dremittance = round(T5m_Dremittance)
rename T5m_Dremittance num_migrants

collapse (sum) num_migrants, by(phase2)
sort phase2

local phase2_migrants_remittance = num_migrants[2]
local phase3_migrants_remittance = num_migrants[1]

egen tot_is_migrants = total(num_migrants)
local phase2_wt_remittance = num_migrants[2] / tot_is_migrants
local phase3_wt_remittance = num_migrants[1] / tot_is_migrants

clear

* Generate weights for remit&census phase2/non_phase2_instate migrants
use "$dirpath_in/covid19india_migrants_remittance.dta", clear
duplicates drop state district, force
keep if in_state == 1
replace T5m_TSsbth_DSsremittance = round(T5m_TSsbth_DSsremittance)
rename T5m_TSsbth_DSsremittance num_migrants

collapse (sum) num_migrants, by(phase2)
sort phase2

local phase2_migrants_remittancecn = num_migrants[2]
local phase3_migrants_remittancecn = num_migrants[1]

egen tot_is_migrants = total(num_migrants)
local phase2_wt_remittancecn = num_migrants[2] / tot_is_migrants
local phase3_wt_remittancecn = num_migrants[1] / tot_is_migrants

clear

* Generate weights for census only only phase2/non_phase2_instate migrants
use "$dirpath_in/covid19india_migrants_census_only.dta", clear
duplicates drop state district, force
keep if in_state == 1

replace T5m_TSsbth_DScns = round(T5m_TSsbth_DScns)
rename T5m_TSsbth_DScns num_migrants

collapse (sum) num_migrants, by(phase2)
sort phase2

local phase2_migrants_cns = num_migrants[2]
local phase3_migrants_cns = num_migrants[1]

egen tot_is_migrants = total(num_migrants)
local phase2_wt_cns = num_migrants[2] / tot_is_migrants
local phase3_wt_cns = num_migrants[1] / tot_is_migrants

clear


* Create terms to store regression output
forval t = 77/230 {
	
	// weighted average
	gen beta_phase2_phase3_wavg_`t' = .
	gen se_phase2_phase3_wavg_`t' = .
	
	// phase 1 only
	gen beta_phase1_`t' = .
	gen se_phase1_`t' = .
		
	// phase 2 only
	gen beta_phase2_`t' = .
	gen se_phase2_`t' = .
		
	//phase 3 only
	gen beta_phase3_`t' = .
	gen se_phase3_`t' = .
}

gen beta_tot_phase2_phase3_wavg_100 = .
gen se_tot_phase2_phase3_wavg_100 = .

gen feset = .
gen fe = ""
gen nobs = .
gen r2 = .
set obs 200
local row = 1

* Regression versions
foreach feset of numlist 1/10 {
		  
//polyweek, control district cases, tests
if "`feset'" == "1" {
	local fes = "district_id"
	replace fe = "polyweek, control district cases, tests" in `row'
}
if "`feset'" == "2" {
	local fes = "district_id"
	replace fe = "nowek, control district cases, tests" in `row'
}
if "`feset'" == "3" {
	local fes = "district_id"
	replace fe = "weekfe, control district cases, tests" in `row'
}
if "`feset'" == "4" {
	local fes = "district_id"
	replace fe = "deaths, polyweek, control district cases, tests" in `row'
}
if "`feset'" == "5" {
	local fes = "district_id"
	replace fe = "migrant weights, polyweek, control district cases, tests" in `row'
}
if "`feset'" == "6" {
	local fes = "district_id"
	replace fe = "pop weights, polyweek, control district cases, tests" in `row'
}
if "`feset'" == "7" {
	local fes = "district_id"
	replace fe = "polyweek tests" in `row'
}
if "`feset'" == "8" {
	local fes = "district_id"
	replace fe = "polyweek, control district cases" in `row'
}
if "`feset'" == "9" {
	local fes = "district_id"
	replace fe = "remitonly, polyweek, control district cases, tests" in `row'
}
if "`feset'" == "10" {
	local fes = "district_id"
	replace fe = "census, polyweek, tests" in `row'
}

di "`row'"

* Begin regressions
preserve
	
* Load data
// non-aggregated to 2011, remittances
if "`feset'" == "1" | "`feset'" == "2" | "`feset'" == "3" | ///
	"`feset'" == "4" | "`feset'" == "5" | "`feset'" == "7" | ///
	"`feset'" == "8" | "`feset'" == "9" {
		// load data
		use "$dirpath_in/covid19india_migrants_remittance.dta", clear
		
		if "`feset'" != "9" {
			// select migrant calculation
			rename T5m_Dremittance num_migrants
			
		}
		if "`feset'" == "9" {
			rename T5m_TSsbth_DSsremittance num_migrants
		}
	}
	
// aggregated to 2011, pop weight
if "`feset'" == "6" {
		// load data
		use "$dirpath_in/covid19india_migrants_remittance_2011_pop.dta", clear
		
		// select migrant calculation
		rename T5m_Dremittance num_migrants
	}
	
// census only
if "`feset'" == "10" {
		// load data
		use "$dirpath_in/covid19india_migrants_census_only.dta", clear
		
		// select migrant calculation
		rename T5m_TSsbth_DScns num_migrants
	}
	
* Round migrant counts to match the frequency-weighted versions
replace num_migrants = round(num_migrants)

* Create terms for the regression below:
* cases_dt = \sum_{t = 0}^{tmax} 
* term 1: beta^t 1[time = t] * phase2_migrants + 
* term 2: gamma^t 1[time = t] * phase3_migrants + 
* term 3: delta^t 1[time = t] * phase1_migrants +
* controls + FE + epsilon

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

* Run regressions
if "`feset'" == "1" | "`feset'" == "4" | "`feset'" == "9" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control num_tested_1wk week week2, ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "2" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control num_tested_1wk, ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "3" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control num_tested_1wk i.week, ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "4" {
areg num_deaths Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control num_tested_1wk week week2, ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "5" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control num_tested_1wk week week2 ///
	[fweight = num_migrants], ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "6" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control num_tested_1wk week week2 ///
	[fweight = population], ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "7" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_cases_date_control week week2, ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "8" {
areg num_cases Tmig_phase1* Tmig_phase2* Tmig_phase3* ///
	num_tested_1wk week week2, ///
	absorb(district_id) vce(cluster district_id)
}
if "`feset'" == "10" {
areg num_cases Tmig_phase2* Tmig_phase3* ///
	num_tested_1wk num_cases_date_control ///
	week week2, ///
	absorb(district_id) vce(cluster district_id)
}


restore

* Store phase2-phase1 and phase3-phase1 coefficients
forval t = 77/230 {
	
	if "`feset'" == "1" | "`feset'" == "4" {
	
	* Take the weighted average by the number of migrants of the two
	* differences and sum them, so
	* 1) phase2 - out_of_state
	* 2) non_phase2 - out_of_state
	* 3) = (1) + (2)
	lincom (((Tmig_phase2_`t' - Tmig_phase1_`t') * `phase2_wt_remittance') + ///
			((Tmig_phase3_`t' - Tmig_phase1_`t') * `phase3_wt_remittance'))
	qui replace beta_phase2_phase3_wavg_`t' = r(estimate) in `row'
	qui replace se_phase2_phase3_wavg_`t' = r(se) in `row'
	
	}
	
	* Series of Phase 1, Phase 2, Phase 3 districts separately
	if "`feset'" == "1"  {
		// phase 1 only
	replace beta_phase1_`t' = ///
		_b[Tmig_phase1_`t'] in `row'
	replace se_phase1_`t' = ///
		_se[Tmig_phase1_`t'] in `row'
		
		// phase 2 only
	replace beta_phase2_`t' = ///
		_b[Tmig_phase2_`t'] in `row'
	replace se_phase2_`t' = ///
		_se[Tmig_phase2_`t'] in `row'
		
		//phase 3 only
	replace beta_phase3_`t' = ///
		_b[Tmig_phase3_`t'] in `row'
	replace se_phase3_`t' = ///
		_se[Tmig_phase3_`t'] in `row'
		
	}
	
}


if "`feset'" == "1" | "`feset'" == "2" | "`feset'" == "3" | ///
	"`feset'" == "4" | "`feset'" == "5" | "`feset'" == "6" | ///
	"`feset'" == "7" | "`feset'" == "8" {
	
		lincom((((((Tmig_phase2_128 - Tmig_phase1_128) + (Tmig_phase2_129 - Tmig_phase1_129) + (Tmig_phase2_130 - Tmig_phase1_130) + (Tmig_phase2_131 - Tmig_phase1_131) + (Tmig_phase2_132 - Tmig_phase1_132) + (Tmig_phase2_133 - Tmig_phase1_133) + (Tmig_phase2_134 - Tmig_phase1_134) + (Tmig_phase2_135 - Tmig_phase1_135) + (Tmig_phase2_136 - Tmig_phase1_136) + (Tmig_phase2_137 - Tmig_phase1_137) + (Tmig_phase2_138 - Tmig_phase1_138) + (Tmig_phase2_139 - Tmig_phase1_139) + (Tmig_phase2_140 - Tmig_phase1_140) + (Tmig_phase2_141 - Tmig_phase1_141) + (Tmig_phase2_142 - Tmig_phase1_142) + (Tmig_phase2_143 - Tmig_phase1_143) + (Tmig_phase2_144 - Tmig_phase1_144) + (Tmig_phase2_145 - Tmig_phase1_145) + (Tmig_phase2_146 - Tmig_phase1_146) + (Tmig_phase2_147 - Tmig_phase1_147) + (Tmig_phase2_148 - Tmig_phase1_148) + (Tmig_phase2_149 - Tmig_phase1_149) + (Tmig_phase2_150 - Tmig_phase1_150) + (Tmig_phase2_151 - Tmig_phase1_151) + (Tmig_phase2_152 - Tmig_phase1_152) + (Tmig_phase2_153 - Tmig_phase1_153) + (Tmig_phase2_154 - Tmig_phase1_154) + (Tmig_phase2_155 - Tmig_phase1_155) + (Tmig_phase2_156 - Tmig_phase1_156) + (Tmig_phase2_157 - Tmig_phase1_157) + (Tmig_phase2_158 - Tmig_phase1_158) + (Tmig_phase2_159 - Tmig_phase1_159) + (Tmig_phase2_160 - Tmig_phase1_160) + (Tmig_phase2_161 - Tmig_phase1_161) + (Tmig_phase2_162 - Tmig_phase1_162) + (Tmig_phase2_163 - Tmig_phase1_163) + (Tmig_phase2_164 - Tmig_phase1_164) + (Tmig_phase2_165 - Tmig_phase1_165) + (Tmig_phase2_166 - Tmig_phase1_166) + (Tmig_phase2_167 - Tmig_phase1_167) + (Tmig_phase2_168 - Tmig_phase1_168) + (Tmig_phase2_169 - Tmig_phase1_169) + (Tmig_phase2_170 - Tmig_phase1_170) + (Tmig_phase2_171 - Tmig_phase1_171) + (Tmig_phase2_172 - Tmig_phase1_172) + (Tmig_phase2_173 - Tmig_phase1_173) + (Tmig_phase2_174 - Tmig_phase1_174) + (Tmig_phase2_175 - Tmig_phase1_175) + (Tmig_phase2_176 - Tmig_phase1_176) + (Tmig_phase2_177 - Tmig_phase1_177) + (Tmig_phase2_178 - Tmig_phase1_178) + (Tmig_phase2_179 - Tmig_phase1_179) + (Tmig_phase2_180 - Tmig_phase1_180) + (Tmig_phase2_181 - Tmig_phase1_181) + (Tmig_phase2_182 - Tmig_phase1_182) + (Tmig_phase2_183 - Tmig_phase1_183) + (Tmig_phase2_184 - Tmig_phase1_184) + (Tmig_phase2_185 - Tmig_phase1_185) + (Tmig_phase2_186 - Tmig_phase1_186) + (Tmig_phase2_187 - Tmig_phase1_187) + (Tmig_phase2_188 - Tmig_phase1_188) + (Tmig_phase2_189 - Tmig_phase1_189) + (Tmig_phase2_190 - Tmig_phase1_190) + (Tmig_phase2_191 - Tmig_phase1_191) + (Tmig_phase2_192 - Tmig_phase1_192) + (Tmig_phase2_193 - Tmig_phase1_193) + (Tmig_phase2_194 - Tmig_phase1_194) + (Tmig_phase2_195 - Tmig_phase1_195) + (Tmig_phase2_196 - Tmig_phase1_196) + (Tmig_phase2_197 - Tmig_phase1_197) + (Tmig_phase2_198 - Tmig_phase1_198) + (Tmig_phase2_199 - Tmig_phase1_199) + (Tmig_phase2_200 - Tmig_phase1_200) + (Tmig_phase2_201 - Tmig_phase1_201) + (Tmig_phase2_202 - Tmig_phase1_202) + (Tmig_phase2_203 - Tmig_phase1_203) + (Tmig_phase2_204 - Tmig_phase1_204) + (Tmig_phase2_205 - Tmig_phase1_205) + (Tmig_phase2_206 - Tmig_phase1_206) + (Tmig_phase2_207 - Tmig_phase1_207) + (Tmig_phase2_208 - Tmig_phase1_208) + (Tmig_phase2_209 - Tmig_phase1_209) + (Tmig_phase2_210 - Tmig_phase1_210) + (Tmig_phase2_211 - Tmig_phase1_211) + (Tmig_phase2_212 - Tmig_phase1_212) + (Tmig_phase2_213 - Tmig_phase1_213) + (Tmig_phase2_214 - Tmig_phase1_214) + (Tmig_phase2_215 - Tmig_phase1_215) + (Tmig_phase2_216 - Tmig_phase1_216) + (Tmig_phase2_217 - Tmig_phase1_217) + (Tmig_phase2_218 - Tmig_phase1_218) + (Tmig_phase2_219 - Tmig_phase1_219) + (Tmig_phase2_220 - Tmig_phase1_220) + (Tmig_phase2_221 - Tmig_phase1_221) + (Tmig_phase2_222 - Tmig_phase1_222) + (Tmig_phase2_223 - Tmig_phase1_223) + (Tmig_phase2_224 - Tmig_phase1_224) + (Tmig_phase2_225 - Tmig_phase1_225) + (Tmig_phase2_226 - Tmig_phase1_226) + (Tmig_phase2_227 - Tmig_phase1_227) + (Tmig_phase2_228 - Tmig_phase1_228) + (Tmig_phase2_229 - Tmig_phase1_229) + ((Tmig_phase2_230 - Tmig_phase1_230)*16)) - (((Tmig_phase2_77 - Tmig_phase1_77)*45) + (Tmig_phase2_78 - Tmig_phase1_78) + (Tmig_phase2_79 - Tmig_phase1_79) + (Tmig_phase2_80 - Tmig_phase1_80) + (Tmig_phase2_81 - Tmig_phase1_81) + (Tmig_phase2_82 - Tmig_phase1_82) + (Tmig_phase2_83 - Tmig_phase1_83) + (Tmig_phase2_84 - Tmig_phase1_84) + (Tmig_phase2_85 - Tmig_phase1_85) + (Tmig_phase2_86 - Tmig_phase1_86) + (Tmig_phase2_87 - Tmig_phase1_87) + (Tmig_phase2_88 - Tmig_phase1_88) + (Tmig_phase2_89 - Tmig_phase1_89) + (Tmig_phase2_90 - Tmig_phase1_90) + (Tmig_phase2_91 - Tmig_phase1_91) + (Tmig_phase2_92 - Tmig_phase1_92) + (Tmig_phase2_93 - Tmig_phase1_93) + (Tmig_phase2_94 - Tmig_phase1_94) + (Tmig_phase2_95 - Tmig_phase1_95) + (Tmig_phase2_96 - Tmig_phase1_96) + (Tmig_phase2_97 - Tmig_phase1_97) + (Tmig_phase2_98 - Tmig_phase1_98) + (Tmig_phase2_99 - Tmig_phase1_99) + (Tmig_phase2_100 - Tmig_phase1_100) + (Tmig_phase2_101 - Tmig_phase1_101) + (Tmig_phase2_102 - Tmig_phase1_102) + (Tmig_phase2_103 - Tmig_phase1_103) + (Tmig_phase2_104 - Tmig_phase1_104) + (Tmig_phase2_105 - Tmig_phase1_105) + (Tmig_phase2_106 - Tmig_phase1_106) + (Tmig_phase2_107 - Tmig_phase1_107) + (Tmig_phase2_108 - Tmig_phase1_108) + (Tmig_phase2_109 - Tmig_phase1_109) + (Tmig_phase2_110 - Tmig_phase1_110) + (Tmig_phase2_111 - Tmig_phase1_111) + (Tmig_phase2_112 - Tmig_phase1_112) + (Tmig_phase2_113 - Tmig_phase1_113) + (Tmig_phase2_114 - Tmig_phase1_114) + (Tmig_phase2_115 - Tmig_phase1_115) + (Tmig_phase2_116 - Tmig_phase1_116) + (Tmig_phase2_117 - Tmig_phase1_117) + (Tmig_phase2_118 - Tmig_phase1_118) + (Tmig_phase2_119 - Tmig_phase1_119) + (Tmig_phase2_120 - Tmig_phase1_120) + (Tmig_phase2_121 - Tmig_phase1_121) + (Tmig_phase2_122 - Tmig_phase1_122) + (Tmig_phase2_123 - Tmig_phase1_123) + (Tmig_phase2_124 - Tmig_phase1_124) + (Tmig_phase2_125 - Tmig_phase1_125) + (Tmig_phase2_126 - Tmig_phase1_126) + (Tmig_phase2_127 - Tmig_phase1_127))) * `phase2_migrants_remittance') + ///
	((((Tmig_phase3_203 - Tmig_phase1_203) + (Tmig_phase3_204 - Tmig_phase1_204) + (Tmig_phase3_205 - Tmig_phase1_205) + (Tmig_phase3_206 - Tmig_phase1_206) + (Tmig_phase3_207 - Tmig_phase1_207) + (Tmig_phase3_208 - Tmig_phase1_208) + (Tmig_phase3_209 - Tmig_phase1_209) + (Tmig_phase3_210 - Tmig_phase1_210) + (Tmig_phase3_211 - Tmig_phase1_211) + (Tmig_phase3_212 - Tmig_phase1_212) + (Tmig_phase3_213 - Tmig_phase1_213) + (Tmig_phase3_214 - Tmig_phase1_214) + (Tmig_phase3_215 - Tmig_phase1_215) + (Tmig_phase3_216 - Tmig_phase1_216) + (Tmig_phase3_217 - Tmig_phase1_217) + (Tmig_phase3_218 - Tmig_phase1_218) + (Tmig_phase3_219 - Tmig_phase1_219) + (Tmig_phase3_220 - Tmig_phase1_220) + (Tmig_phase3_221 - Tmig_phase1_221) + (Tmig_phase3_222 - Tmig_phase1_222) + (Tmig_phase3_223 - Tmig_phase1_223) + (Tmig_phase3_224 - Tmig_phase1_224) + (Tmig_phase3_225 - Tmig_phase1_225) + (Tmig_phase3_226 - Tmig_phase1_226) + (Tmig_phase3_227 - Tmig_phase1_227) + (Tmig_phase3_228 - Tmig_phase1_228) + (Tmig_phase3_229 - Tmig_phase1_229) + ((Tmig_phase3_230 - Tmig_phase1_230)*16)) - (((Tmig_phase3_77 - Tmig_phase1_77)*45) + (Tmig_phase3_78 - Tmig_phase1_78) + (Tmig_phase3_79 - Tmig_phase1_79) + (Tmig_phase3_80 - Tmig_phase1_80) + (Tmig_phase3_81 - Tmig_phase1_81) + (Tmig_phase3_82 - Tmig_phase1_82) + (Tmig_phase3_83 - Tmig_phase1_83) + (Tmig_phase3_84 - Tmig_phase1_84) + (Tmig_phase3_85 - Tmig_phase1_85) + (Tmig_phase3_86 - Tmig_phase1_86) + (Tmig_phase3_87 - Tmig_phase1_87) + (Tmig_phase3_88 - Tmig_phase1_88) + (Tmig_phase3_89 - Tmig_phase1_89) + (Tmig_phase3_90 - Tmig_phase1_90) + (Tmig_phase3_91 - Tmig_phase1_91) + (Tmig_phase3_92 - Tmig_phase1_92) + (Tmig_phase3_93 - Tmig_phase1_93) + (Tmig_phase3_94 - Tmig_phase1_94) + (Tmig_phase3_95 - Tmig_phase1_95) + (Tmig_phase3_96 - Tmig_phase1_96) + (Tmig_phase3_97 - Tmig_phase1_97) + (Tmig_phase3_98 - Tmig_phase1_98) + (Tmig_phase3_99 - Tmig_phase1_99) + (Tmig_phase3_100 - Tmig_phase1_100) + (Tmig_phase3_101 - Tmig_phase1_101) + (Tmig_phase3_102 - Tmig_phase1_102) + (Tmig_phase3_103 - Tmig_phase1_103) + (Tmig_phase3_104 - Tmig_phase1_104) + (Tmig_phase3_105 - Tmig_phase1_105) + (Tmig_phase3_106 - Tmig_phase1_106) + (Tmig_phase3_107 - Tmig_phase1_107) + (Tmig_phase3_108 - Tmig_phase1_108) + (Tmig_phase3_109 - Tmig_phase1_109) + (Tmig_phase3_110 - Tmig_phase1_110) + (Tmig_phase3_111 - Tmig_phase1_111) + (Tmig_phase3_112 - Tmig_phase1_112) + (Tmig_phase3_113 - Tmig_phase1_113) + (Tmig_phase3_114 - Tmig_phase1_114) + (Tmig_phase3_115 - Tmig_phase1_115) + (Tmig_phase3_116 - Tmig_phase1_116) + (Tmig_phase3_117 - Tmig_phase1_117) + (Tmig_phase3_118 - Tmig_phase1_118) + (Tmig_phase3_119 - Tmig_phase1_119) + (Tmig_phase3_120 - Tmig_phase1_120) + (Tmig_phase3_121 - Tmig_phase1_121) + (Tmig_phase3_122 - Tmig_phase1_122) + (Tmig_phase3_123 - Tmig_phase1_123) + (Tmig_phase3_124 - Tmig_phase1_124) + (Tmig_phase3_125 - Tmig_phase1_125) + (Tmig_phase3_126 - Tmig_phase1_126) + (Tmig_phase3_127 - Tmig_phase1_127) + (Tmig_phase3_128 - Tmig_phase1_128) + (Tmig_phase3_129 - Tmig_phase1_129) + (Tmig_phase3_130 - Tmig_phase1_130) + (Tmig_phase3_131 - Tmig_phase1_131) + (Tmig_phase3_132 - Tmig_phase1_132) + (Tmig_phase3_133 - Tmig_phase1_133) + (Tmig_phase3_134 - Tmig_phase1_134) + (Tmig_phase3_135 - Tmig_phase1_135) + (Tmig_phase3_136 - Tmig_phase1_136) + (Tmig_phase3_137 - Tmig_phase1_137) + (Tmig_phase3_138 - Tmig_phase1_138) + (Tmig_phase3_139 - Tmig_phase1_139) + (Tmig_phase3_140 - Tmig_phase1_140) + (Tmig_phase3_141 - Tmig_phase1_141) + (Tmig_phase3_142 - Tmig_phase1_142) + (Tmig_phase3_143 - Tmig_phase1_143) + (Tmig_phase3_144 - Tmig_phase1_144) + (Tmig_phase3_145 - Tmig_phase1_145) + (Tmig_phase3_146 - Tmig_phase1_146) + (Tmig_phase3_147 - Tmig_phase1_147) + (Tmig_phase3_148 - Tmig_phase1_148) + (Tmig_phase3_149 - Tmig_phase1_149) + (Tmig_phase3_150 - Tmig_phase1_150) + (Tmig_phase3_151 - Tmig_phase1_151) + (Tmig_phase3_152 - Tmig_phase1_152) + (Tmig_phase3_153 - Tmig_phase1_153) + (Tmig_phase3_154 - Tmig_phase1_154) + (Tmig_phase3_155 - Tmig_phase1_155) + (Tmig_phase3_156 - Tmig_phase1_156) + (Tmig_phase3_157 - Tmig_phase1_157) + (Tmig_phase3_158 - Tmig_phase1_158) + (Tmig_phase3_159 - Tmig_phase1_159) + (Tmig_phase3_160 - Tmig_phase1_160) + (Tmig_phase3_161 - Tmig_phase1_161) + (Tmig_phase3_162 - Tmig_phase1_162) + (Tmig_phase3_163 - Tmig_phase1_163) + (Tmig_phase3_164 - Tmig_phase1_164) + (Tmig_phase3_165 - Tmig_phase1_165) + (Tmig_phase3_166 - Tmig_phase1_166) + (Tmig_phase3_167 - Tmig_phase1_167) + (Tmig_phase3_168 - Tmig_phase1_168) + (Tmig_phase3_169 - Tmig_phase1_169) + (Tmig_phase3_170 - Tmig_phase1_170) + (Tmig_phase3_171 - Tmig_phase1_171) + (Tmig_phase3_172 - Tmig_phase1_172) + (Tmig_phase3_173 - Tmig_phase1_173) + (Tmig_phase3_174 - Tmig_phase1_174) + (Tmig_phase3_175 - Tmig_phase1_175) + (Tmig_phase3_176 - Tmig_phase1_176) + (Tmig_phase3_177 - Tmig_phase1_177) + (Tmig_phase3_178 - Tmig_phase1_178) + (Tmig_phase3_179 - Tmig_phase1_179) + (Tmig_phase3_180 - Tmig_phase1_180) + (Tmig_phase3_181 - Tmig_phase1_181) + (Tmig_phase3_182 - Tmig_phase1_182) + (Tmig_phase3_183 - Tmig_phase1_183) + (Tmig_phase3_184 - Tmig_phase1_184) + (Tmig_phase3_185 - Tmig_phase1_185) + (Tmig_phase3_186 - Tmig_phase1_186) + (Tmig_phase3_187 - Tmig_phase1_187) + (Tmig_phase3_188 - Tmig_phase1_188) + (Tmig_phase3_189 - Tmig_phase1_189) + (Tmig_phase3_190 - Tmig_phase1_190) + (Tmig_phase3_191 - Tmig_phase1_191) + (Tmig_phase3_192 - Tmig_phase1_192) + (Tmig_phase3_193 - Tmig_phase1_193) + (Tmig_phase3_194 - Tmig_phase1_194) + (Tmig_phase3_195 - Tmig_phase1_195) + (Tmig_phase3_196 - Tmig_phase1_196) + (Tmig_phase3_197 - Tmig_phase1_197) + (Tmig_phase3_198 - Tmig_phase1_198) + (Tmig_phase3_199 - Tmig_phase1_199) + (Tmig_phase3_200 - Tmig_phase1_200) + (Tmig_phase3_201 - Tmig_phase1_201) + (Tmig_phase3_202 - Tmig_phase1_202))) * `phase3_migrants_remittance')))
	qui replace beta_tot_phase2_phase3_wavg_100 = r(estimate) in `row'
	qui replace se_tot_phase2_phase3_wavg_100 = r(se) in `row'
	
	}
	
	
	if "`feset'" == "9" {

			lincom((((((Tmig_phase2_128 - Tmig_phase1_128) + (Tmig_phase2_129 - Tmig_phase1_129) + (Tmig_phase2_130 - Tmig_phase1_130) + (Tmig_phase2_131 - Tmig_phase1_131) + (Tmig_phase2_132 - Tmig_phase1_132) + (Tmig_phase2_133 - Tmig_phase1_133) + (Tmig_phase2_134 - Tmig_phase1_134) + (Tmig_phase2_135 - Tmig_phase1_135) + (Tmig_phase2_136 - Tmig_phase1_136) + (Tmig_phase2_137 - Tmig_phase1_137) + (Tmig_phase2_138 - Tmig_phase1_138) + (Tmig_phase2_139 - Tmig_phase1_139) + (Tmig_phase2_140 - Tmig_phase1_140) + (Tmig_phase2_141 - Tmig_phase1_141) + (Tmig_phase2_142 - Tmig_phase1_142) + (Tmig_phase2_143 - Tmig_phase1_143) + (Tmig_phase2_144 - Tmig_phase1_144) + (Tmig_phase2_145 - Tmig_phase1_145) + (Tmig_phase2_146 - Tmig_phase1_146) + (Tmig_phase2_147 - Tmig_phase1_147) + (Tmig_phase2_148 - Tmig_phase1_148) + (Tmig_phase2_149 - Tmig_phase1_149) + (Tmig_phase2_150 - Tmig_phase1_150) + (Tmig_phase2_151 - Tmig_phase1_151) + (Tmig_phase2_152 - Tmig_phase1_152) + (Tmig_phase2_153 - Tmig_phase1_153) + (Tmig_phase2_154 - Tmig_phase1_154) + (Tmig_phase2_155 - Tmig_phase1_155) + (Tmig_phase2_156 - Tmig_phase1_156) + (Tmig_phase2_157 - Tmig_phase1_157) + (Tmig_phase2_158 - Tmig_phase1_158) + (Tmig_phase2_159 - Tmig_phase1_159) + (Tmig_phase2_160 - Tmig_phase1_160) + (Tmig_phase2_161 - Tmig_phase1_161) + (Tmig_phase2_162 - Tmig_phase1_162) + (Tmig_phase2_163 - Tmig_phase1_163) + (Tmig_phase2_164 - Tmig_phase1_164) + (Tmig_phase2_165 - Tmig_phase1_165) + (Tmig_phase2_166 - Tmig_phase1_166) + (Tmig_phase2_167 - Tmig_phase1_167) + (Tmig_phase2_168 - Tmig_phase1_168) + (Tmig_phase2_169 - Tmig_phase1_169) + (Tmig_phase2_170 - Tmig_phase1_170) + (Tmig_phase2_171 - Tmig_phase1_171) + (Tmig_phase2_172 - Tmig_phase1_172) + (Tmig_phase2_173 - Tmig_phase1_173) + (Tmig_phase2_174 - Tmig_phase1_174) + (Tmig_phase2_175 - Tmig_phase1_175) + (Tmig_phase2_176 - Tmig_phase1_176) + (Tmig_phase2_177 - Tmig_phase1_177) + (Tmig_phase2_178 - Tmig_phase1_178) + (Tmig_phase2_179 - Tmig_phase1_179) + (Tmig_phase2_180 - Tmig_phase1_180) + (Tmig_phase2_181 - Tmig_phase1_181) + (Tmig_phase2_182 - Tmig_phase1_182) + (Tmig_phase2_183 - Tmig_phase1_183) + (Tmig_phase2_184 - Tmig_phase1_184) + (Tmig_phase2_185 - Tmig_phase1_185) + (Tmig_phase2_186 - Tmig_phase1_186) + (Tmig_phase2_187 - Tmig_phase1_187) + (Tmig_phase2_188 - Tmig_phase1_188) + (Tmig_phase2_189 - Tmig_phase1_189) + (Tmig_phase2_190 - Tmig_phase1_190) + (Tmig_phase2_191 - Tmig_phase1_191) + (Tmig_phase2_192 - Tmig_phase1_192) + (Tmig_phase2_193 - Tmig_phase1_193) + (Tmig_phase2_194 - Tmig_phase1_194) + (Tmig_phase2_195 - Tmig_phase1_195) + (Tmig_phase2_196 - Tmig_phase1_196) + (Tmig_phase2_197 - Tmig_phase1_197) + (Tmig_phase2_198 - Tmig_phase1_198) + (Tmig_phase2_199 - Tmig_phase1_199) + (Tmig_phase2_200 - Tmig_phase1_200) + (Tmig_phase2_201 - Tmig_phase1_201) + (Tmig_phase2_202 - Tmig_phase1_202) + (Tmig_phase2_203 - Tmig_phase1_203) + (Tmig_phase2_204 - Tmig_phase1_204) + (Tmig_phase2_205 - Tmig_phase1_205) + (Tmig_phase2_206 - Tmig_phase1_206) + (Tmig_phase2_207 - Tmig_phase1_207) + (Tmig_phase2_208 - Tmig_phase1_208) + (Tmig_phase2_209 - Tmig_phase1_209) + (Tmig_phase2_210 - Tmig_phase1_210) + (Tmig_phase2_211 - Tmig_phase1_211) + (Tmig_phase2_212 - Tmig_phase1_212) + (Tmig_phase2_213 - Tmig_phase1_213) + (Tmig_phase2_214 - Tmig_phase1_214) + (Tmig_phase2_215 - Tmig_phase1_215) + (Tmig_phase2_216 - Tmig_phase1_216) + (Tmig_phase2_217 - Tmig_phase1_217) + (Tmig_phase2_218 - Tmig_phase1_218) + (Tmig_phase2_219 - Tmig_phase1_219) + (Tmig_phase2_220 - Tmig_phase1_220) + (Tmig_phase2_221 - Tmig_phase1_221) + (Tmig_phase2_222 - Tmig_phase1_222) + (Tmig_phase2_223 - Tmig_phase1_223) + (Tmig_phase2_224 - Tmig_phase1_224) + (Tmig_phase2_225 - Tmig_phase1_225) + (Tmig_phase2_226 - Tmig_phase1_226) + (Tmig_phase2_227 - Tmig_phase1_227) + (Tmig_phase2_228 - Tmig_phase1_228) + (Tmig_phase2_229 - Tmig_phase1_229) + ((Tmig_phase2_230 - Tmig_phase1_230)*16)) - (((Tmig_phase2_77 - Tmig_phase1_77)*45) + (Tmig_phase2_78 - Tmig_phase1_78) + (Tmig_phase2_79 - Tmig_phase1_79) + (Tmig_phase2_80 - Tmig_phase1_80) + (Tmig_phase2_81 - Tmig_phase1_81) + (Tmig_phase2_82 - Tmig_phase1_82) + (Tmig_phase2_83 - Tmig_phase1_83) + (Tmig_phase2_84 - Tmig_phase1_84) + (Tmig_phase2_85 - Tmig_phase1_85) + (Tmig_phase2_86 - Tmig_phase1_86) + (Tmig_phase2_87 - Tmig_phase1_87) + (Tmig_phase2_88 - Tmig_phase1_88) + (Tmig_phase2_89 - Tmig_phase1_89) + (Tmig_phase2_90 - Tmig_phase1_90) + (Tmig_phase2_91 - Tmig_phase1_91) + (Tmig_phase2_92 - Tmig_phase1_92) + (Tmig_phase2_93 - Tmig_phase1_93) + (Tmig_phase2_94 - Tmig_phase1_94) + (Tmig_phase2_95 - Tmig_phase1_95) + (Tmig_phase2_96 - Tmig_phase1_96) + (Tmig_phase2_97 - Tmig_phase1_97) + (Tmig_phase2_98 - Tmig_phase1_98) + (Tmig_phase2_99 - Tmig_phase1_99) + (Tmig_phase2_100 - Tmig_phase1_100) + (Tmig_phase2_101 - Tmig_phase1_101) + (Tmig_phase2_102 - Tmig_phase1_102) + (Tmig_phase2_103 - Tmig_phase1_103) + (Tmig_phase2_104 - Tmig_phase1_104) + (Tmig_phase2_105 - Tmig_phase1_105) + (Tmig_phase2_106 - Tmig_phase1_106) + (Tmig_phase2_107 - Tmig_phase1_107) + (Tmig_phase2_108 - Tmig_phase1_108) + (Tmig_phase2_109 - Tmig_phase1_109) + (Tmig_phase2_110 - Tmig_phase1_110) + (Tmig_phase2_111 - Tmig_phase1_111) + (Tmig_phase2_112 - Tmig_phase1_112) + (Tmig_phase2_113 - Tmig_phase1_113) + (Tmig_phase2_114 - Tmig_phase1_114) + (Tmig_phase2_115 - Tmig_phase1_115) + (Tmig_phase2_116 - Tmig_phase1_116) + (Tmig_phase2_117 - Tmig_phase1_117) + (Tmig_phase2_118 - Tmig_phase1_118) + (Tmig_phase2_119 - Tmig_phase1_119) + (Tmig_phase2_120 - Tmig_phase1_120) + (Tmig_phase2_121 - Tmig_phase1_121) + (Tmig_phase2_122 - Tmig_phase1_122) + (Tmig_phase2_123 - Tmig_phase1_123) + (Tmig_phase2_124 - Tmig_phase1_124) + (Tmig_phase2_125 - Tmig_phase1_125) + (Tmig_phase2_126 - Tmig_phase1_126) + (Tmig_phase2_127 - Tmig_phase1_127))) * `phase2_migrants_remittancecn') + ///
	((((Tmig_phase3_203 - Tmig_phase1_203) + (Tmig_phase3_204 - Tmig_phase1_204) + (Tmig_phase3_205 - Tmig_phase1_205) + (Tmig_phase3_206 - Tmig_phase1_206) + (Tmig_phase3_207 - Tmig_phase1_207) + (Tmig_phase3_208 - Tmig_phase1_208) + (Tmig_phase3_209 - Tmig_phase1_209) + (Tmig_phase3_210 - Tmig_phase1_210) + (Tmig_phase3_211 - Tmig_phase1_211) + (Tmig_phase3_212 - Tmig_phase1_212) + (Tmig_phase3_213 - Tmig_phase1_213) + (Tmig_phase3_214 - Tmig_phase1_214) + (Tmig_phase3_215 - Tmig_phase1_215) + (Tmig_phase3_216 - Tmig_phase1_216) + (Tmig_phase3_217 - Tmig_phase1_217) + (Tmig_phase3_218 - Tmig_phase1_218) + (Tmig_phase3_219 - Tmig_phase1_219) + (Tmig_phase3_220 - Tmig_phase1_220) + (Tmig_phase3_221 - Tmig_phase1_221) + (Tmig_phase3_222 - Tmig_phase1_222) + (Tmig_phase3_223 - Tmig_phase1_223) + (Tmig_phase3_224 - Tmig_phase1_224) + (Tmig_phase3_225 - Tmig_phase1_225) + (Tmig_phase3_226 - Tmig_phase1_226) + (Tmig_phase3_227 - Tmig_phase1_227) + (Tmig_phase3_228 - Tmig_phase1_228) + (Tmig_phase3_229 - Tmig_phase1_229) + ((Tmig_phase3_230 - Tmig_phase1_230)*16)) - (((Tmig_phase3_77 - Tmig_phase1_77)*45) + (Tmig_phase3_78 - Tmig_phase1_78) + (Tmig_phase3_79 - Tmig_phase1_79) + (Tmig_phase3_80 - Tmig_phase1_80) + (Tmig_phase3_81 - Tmig_phase1_81) + (Tmig_phase3_82 - Tmig_phase1_82) + (Tmig_phase3_83 - Tmig_phase1_83) + (Tmig_phase3_84 - Tmig_phase1_84) + (Tmig_phase3_85 - Tmig_phase1_85) + (Tmig_phase3_86 - Tmig_phase1_86) + (Tmig_phase3_87 - Tmig_phase1_87) + (Tmig_phase3_88 - Tmig_phase1_88) + (Tmig_phase3_89 - Tmig_phase1_89) + (Tmig_phase3_90 - Tmig_phase1_90) + (Tmig_phase3_91 - Tmig_phase1_91) + (Tmig_phase3_92 - Tmig_phase1_92) + (Tmig_phase3_93 - Tmig_phase1_93) + (Tmig_phase3_94 - Tmig_phase1_94) + (Tmig_phase3_95 - Tmig_phase1_95) + (Tmig_phase3_96 - Tmig_phase1_96) + (Tmig_phase3_97 - Tmig_phase1_97) + (Tmig_phase3_98 - Tmig_phase1_98) + (Tmig_phase3_99 - Tmig_phase1_99) + (Tmig_phase3_100 - Tmig_phase1_100) + (Tmig_phase3_101 - Tmig_phase1_101) + (Tmig_phase3_102 - Tmig_phase1_102) + (Tmig_phase3_103 - Tmig_phase1_103) + (Tmig_phase3_104 - Tmig_phase1_104) + (Tmig_phase3_105 - Tmig_phase1_105) + (Tmig_phase3_106 - Tmig_phase1_106) + (Tmig_phase3_107 - Tmig_phase1_107) + (Tmig_phase3_108 - Tmig_phase1_108) + (Tmig_phase3_109 - Tmig_phase1_109) + (Tmig_phase3_110 - Tmig_phase1_110) + (Tmig_phase3_111 - Tmig_phase1_111) + (Tmig_phase3_112 - Tmig_phase1_112) + (Tmig_phase3_113 - Tmig_phase1_113) + (Tmig_phase3_114 - Tmig_phase1_114) + (Tmig_phase3_115 - Tmig_phase1_115) + (Tmig_phase3_116 - Tmig_phase1_116) + (Tmig_phase3_117 - Tmig_phase1_117) + (Tmig_phase3_118 - Tmig_phase1_118) + (Tmig_phase3_119 - Tmig_phase1_119) + (Tmig_phase3_120 - Tmig_phase1_120) + (Tmig_phase3_121 - Tmig_phase1_121) + (Tmig_phase3_122 - Tmig_phase1_122) + (Tmig_phase3_123 - Tmig_phase1_123) + (Tmig_phase3_124 - Tmig_phase1_124) + (Tmig_phase3_125 - Tmig_phase1_125) + (Tmig_phase3_126 - Tmig_phase1_126) + (Tmig_phase3_127 - Tmig_phase1_127) + (Tmig_phase3_128 - Tmig_phase1_128) + (Tmig_phase3_129 - Tmig_phase1_129) + (Tmig_phase3_130 - Tmig_phase1_130) + (Tmig_phase3_131 - Tmig_phase1_131) + (Tmig_phase3_132 - Tmig_phase1_132) + (Tmig_phase3_133 - Tmig_phase1_133) + (Tmig_phase3_134 - Tmig_phase1_134) + (Tmig_phase3_135 - Tmig_phase1_135) + (Tmig_phase3_136 - Tmig_phase1_136) + (Tmig_phase3_137 - Tmig_phase1_137) + (Tmig_phase3_138 - Tmig_phase1_138) + (Tmig_phase3_139 - Tmig_phase1_139) + (Tmig_phase3_140 - Tmig_phase1_140) + (Tmig_phase3_141 - Tmig_phase1_141) + (Tmig_phase3_142 - Tmig_phase1_142) + (Tmig_phase3_143 - Tmig_phase1_143) + (Tmig_phase3_144 - Tmig_phase1_144) + (Tmig_phase3_145 - Tmig_phase1_145) + (Tmig_phase3_146 - Tmig_phase1_146) + (Tmig_phase3_147 - Tmig_phase1_147) + (Tmig_phase3_148 - Tmig_phase1_148) + (Tmig_phase3_149 - Tmig_phase1_149) + (Tmig_phase3_150 - Tmig_phase1_150) + (Tmig_phase3_151 - Tmig_phase1_151) + (Tmig_phase3_152 - Tmig_phase1_152) + (Tmig_phase3_153 - Tmig_phase1_153) + (Tmig_phase3_154 - Tmig_phase1_154) + (Tmig_phase3_155 - Tmig_phase1_155) + (Tmig_phase3_156 - Tmig_phase1_156) + (Tmig_phase3_157 - Tmig_phase1_157) + (Tmig_phase3_158 - Tmig_phase1_158) + (Tmig_phase3_159 - Tmig_phase1_159) + (Tmig_phase3_160 - Tmig_phase1_160) + (Tmig_phase3_161 - Tmig_phase1_161) + (Tmig_phase3_162 - Tmig_phase1_162) + (Tmig_phase3_163 - Tmig_phase1_163) + (Tmig_phase3_164 - Tmig_phase1_164) + (Tmig_phase3_165 - Tmig_phase1_165) + (Tmig_phase3_166 - Tmig_phase1_166) + (Tmig_phase3_167 - Tmig_phase1_167) + (Tmig_phase3_168 - Tmig_phase1_168) + (Tmig_phase3_169 - Tmig_phase1_169) + (Tmig_phase3_170 - Tmig_phase1_170) + (Tmig_phase3_171 - Tmig_phase1_171) + (Tmig_phase3_172 - Tmig_phase1_172) + (Tmig_phase3_173 - Tmig_phase1_173) + (Tmig_phase3_174 - Tmig_phase1_174) + (Tmig_phase3_175 - Tmig_phase1_175) + (Tmig_phase3_176 - Tmig_phase1_176) + (Tmig_phase3_177 - Tmig_phase1_177) + (Tmig_phase3_178 - Tmig_phase1_178) + (Tmig_phase3_179 - Tmig_phase1_179) + (Tmig_phase3_180 - Tmig_phase1_180) + (Tmig_phase3_181 - Tmig_phase1_181) + (Tmig_phase3_182 - Tmig_phase1_182) + (Tmig_phase3_183 - Tmig_phase1_183) + (Tmig_phase3_184 - Tmig_phase1_184) + (Tmig_phase3_185 - Tmig_phase1_185) + (Tmig_phase3_186 - Tmig_phase1_186) + (Tmig_phase3_187 - Tmig_phase1_187) + (Tmig_phase3_188 - Tmig_phase1_188) + (Tmig_phase3_189 - Tmig_phase1_189) + (Tmig_phase3_190 - Tmig_phase1_190) + (Tmig_phase3_191 - Tmig_phase1_191) + (Tmig_phase3_192 - Tmig_phase1_192) + (Tmig_phase3_193 - Tmig_phase1_193) + (Tmig_phase3_194 - Tmig_phase1_194) + (Tmig_phase3_195 - Tmig_phase1_195) + (Tmig_phase3_196 - Tmig_phase1_196) + (Tmig_phase3_197 - Tmig_phase1_197) + (Tmig_phase3_198 - Tmig_phase1_198) + (Tmig_phase3_199 - Tmig_phase1_199) + (Tmig_phase3_200 - Tmig_phase1_200) + (Tmig_phase3_201 - Tmig_phase1_201) + (Tmig_phase3_202 - Tmig_phase1_202))) * `phase3_migrants_remittancecn')))
	qui replace beta_tot_phase2_phase3_wavg_100 = r(estimate) in `row'
	qui replace se_tot_phase2_phase3_wavg_100 = r(se) in `row'
	}

if "`feset'" == "10" {
	
lincom((((Tmig_phase2_128 + Tmig_phase2_129 + Tmig_phase2_130 + Tmig_phase2_131 + Tmig_phase2_132 + Tmig_phase2_133 + Tmig_phase2_134 + Tmig_phase2_135 + Tmig_phase2_136 + Tmig_phase2_137 + Tmig_phase2_138 + Tmig_phase2_139 + Tmig_phase2_140 + Tmig_phase2_141 + Tmig_phase2_142 + Tmig_phase2_143 + Tmig_phase2_144 + Tmig_phase2_145 + Tmig_phase2_146 + Tmig_phase2_147 + Tmig_phase2_148 + Tmig_phase2_149 + Tmig_phase2_150 + Tmig_phase2_151 + Tmig_phase2_152 + Tmig_phase2_153 + Tmig_phase2_154 + Tmig_phase2_155 + Tmig_phase2_156 + Tmig_phase2_157 + Tmig_phase2_158 + Tmig_phase2_159 + Tmig_phase2_160 + Tmig_phase2_161 + Tmig_phase2_162 + Tmig_phase2_163 + Tmig_phase2_164 + Tmig_phase2_165 + Tmig_phase2_166 + Tmig_phase2_167 + Tmig_phase2_168 + Tmig_phase2_169 + Tmig_phase2_170 + Tmig_phase2_171 + Tmig_phase2_172 + Tmig_phase2_173 + Tmig_phase2_174 + Tmig_phase2_175 + Tmig_phase2_176 + Tmig_phase2_177 + Tmig_phase2_178 + Tmig_phase2_179 + Tmig_phase2_180 + Tmig_phase2_181 + Tmig_phase2_182 + Tmig_phase2_183 + Tmig_phase2_184 + Tmig_phase2_185 + Tmig_phase2_186 + Tmig_phase2_187 + Tmig_phase2_188 + Tmig_phase2_189 + Tmig_phase2_190 + Tmig_phase2_191 + Tmig_phase2_192 + Tmig_phase2_193 + Tmig_phase2_194 + Tmig_phase2_195 + Tmig_phase2_196 + Tmig_phase2_197 + Tmig_phase2_198 + Tmig_phase2_199 + Tmig_phase2_200 + Tmig_phase2_201 + Tmig_phase2_202 + Tmig_phase2_203 + Tmig_phase2_204 + Tmig_phase2_205 + Tmig_phase2_206 + Tmig_phase2_207 + Tmig_phase2_208 + Tmig_phase2_209 + Tmig_phase2_210 + Tmig_phase2_211 + Tmig_phase2_212 + Tmig_phase2_213 + Tmig_phase2_214 + Tmig_phase2_215 + Tmig_phase2_216 + Tmig_phase2_217 + Tmig_phase2_218 + Tmig_phase2_219 + Tmig_phase2_220 + Tmig_phase2_221 + Tmig_phase2_222 + Tmig_phase2_223 + Tmig_phase2_224 + Tmig_phase2_225 + Tmig_phase2_226 + Tmig_phase2_227 + Tmig_phase2_228 + Tmig_phase2_229 + (Tmig_phase2_230*16)) - ((Tmig_phase2_77*45) + Tmig_phase2_78 + Tmig_phase2_79 + Tmig_phase2_80 + Tmig_phase2_81 + Tmig_phase2_82 + Tmig_phase2_83 + Tmig_phase2_84 + Tmig_phase2_85 + Tmig_phase2_86 + Tmig_phase2_87 + Tmig_phase2_88 + Tmig_phase2_89 + Tmig_phase2_90 + Tmig_phase2_91 + Tmig_phase2_92 + Tmig_phase2_93 + Tmig_phase2_94 + Tmig_phase2_95 + Tmig_phase2_96 + Tmig_phase2_97 + Tmig_phase2_98 + Tmig_phase2_99 + Tmig_phase2_100 + Tmig_phase2_101 + Tmig_phase2_102 + Tmig_phase2_103 + Tmig_phase2_104 + Tmig_phase2_105 + Tmig_phase2_106 + Tmig_phase2_107 + Tmig_phase2_108 + Tmig_phase2_109 + Tmig_phase2_110 + Tmig_phase2_111 + Tmig_phase2_112 + Tmig_phase2_113 + Tmig_phase2_114 + Tmig_phase2_115 + Tmig_phase2_116 + Tmig_phase2_117 + Tmig_phase2_118 + Tmig_phase2_119 + Tmig_phase2_120 + Tmig_phase2_121 + Tmig_phase2_122 + Tmig_phase2_123 + Tmig_phase2_124 + Tmig_phase2_125 + Tmig_phase2_126 + Tmig_phase2_127))*`phase2_migrants_cns') + ///
(((Tmig_phase3_203 + Tmig_phase3_204 + Tmig_phase3_205 + Tmig_phase3_206 + Tmig_phase3_207 + Tmig_phase3_208 + Tmig_phase3_209 + Tmig_phase3_210 + Tmig_phase3_211 + Tmig_phase3_212 + Tmig_phase3_213 + Tmig_phase3_214 + Tmig_phase3_215 + Tmig_phase3_216 + Tmig_phase3_217 + Tmig_phase3_218 + Tmig_phase3_219 + Tmig_phase3_220 + Tmig_phase3_221 + Tmig_phase3_222 + Tmig_phase3_223 + Tmig_phase3_224 + Tmig_phase3_225 + Tmig_phase3_226 + Tmig_phase3_227 + Tmig_phase3_228 + Tmig_phase3_229 + (Tmig_phase3_230*16)) - ((Tmig_phase3_77*45) + Tmig_phase3_78 + Tmig_phase3_79 + Tmig_phase3_80 + Tmig_phase3_81 + Tmig_phase3_82 + Tmig_phase3_83 + Tmig_phase3_84 + Tmig_phase3_85 + Tmig_phase3_86 + Tmig_phase3_87 + Tmig_phase3_88 + Tmig_phase3_89 + Tmig_phase3_90 + Tmig_phase3_91 + Tmig_phase3_92 + Tmig_phase3_93 + Tmig_phase3_94 + Tmig_phase3_95 + Tmig_phase3_96 + Tmig_phase3_97 + Tmig_phase3_98 + Tmig_phase3_99 + Tmig_phase3_100 + Tmig_phase3_101 + Tmig_phase3_102 + Tmig_phase3_103 + Tmig_phase3_104 + Tmig_phase3_105 + Tmig_phase3_106 + Tmig_phase3_107 + Tmig_phase3_108 + Tmig_phase3_109 + Tmig_phase3_110 + Tmig_phase3_111 + Tmig_phase3_112 + Tmig_phase3_113 + Tmig_phase3_114 + Tmig_phase3_115 + Tmig_phase3_116 + Tmig_phase3_117 + Tmig_phase3_118 + Tmig_phase3_119 + Tmig_phase3_120 + Tmig_phase3_121 + Tmig_phase3_122 + Tmig_phase3_123 + Tmig_phase3_124 + Tmig_phase3_125 + Tmig_phase3_126 + Tmig_phase3_127 + Tmig_phase3_128 + Tmig_phase3_129 + Tmig_phase3_130 + Tmig_phase3_131 + Tmig_phase3_132 + Tmig_phase3_133 + Tmig_phase3_134 + Tmig_phase3_135 + Tmig_phase3_136 + Tmig_phase3_137 + Tmig_phase3_138 + Tmig_phase3_139 + Tmig_phase3_140 + Tmig_phase3_141 + Tmig_phase3_142 + Tmig_phase3_143 + Tmig_phase3_144 + Tmig_phase3_145 + Tmig_phase3_146 + Tmig_phase3_147 + Tmig_phase3_148 + Tmig_phase3_149 + Tmig_phase3_150 + Tmig_phase3_151 + Tmig_phase3_152 + Tmig_phase3_153 + Tmig_phase3_154 + Tmig_phase3_155 + Tmig_phase3_156 + Tmig_phase3_157 + Tmig_phase3_158 + Tmig_phase3_159 + Tmig_phase3_160 + Tmig_phase3_161 + Tmig_phase3_162 + Tmig_phase3_163 + Tmig_phase3_164 + Tmig_phase3_165 + Tmig_phase3_166 + Tmig_phase3_167 + Tmig_phase3_168 + Tmig_phase3_169 + Tmig_phase3_170 + Tmig_phase3_171 + Tmig_phase3_172 + Tmig_phase3_173 + Tmig_phase3_174 + Tmig_phase3_175 + Tmig_phase3_176 + Tmig_phase3_177 + Tmig_phase3_178 + Tmig_phase3_179 + Tmig_phase3_180 + Tmig_phase3_181 + Tmig_phase3_182 + Tmig_phase3_183 + Tmig_phase3_184 + Tmig_phase3_185 + Tmig_phase3_186 + Tmig_phase3_187 + Tmig_phase3_188 + Tmig_phase3_189 + Tmig_phase3_190 + Tmig_phase3_191 + Tmig_phase3_192 + Tmig_phase3_193 + Tmig_phase3_194 + Tmig_phase3_195 + Tmig_phase3_196 + Tmig_phase3_197 + Tmig_phase3_198 + Tmig_phase3_199 + Tmig_phase3_200 + Tmig_phase3_201 + Tmig_phase3_202))*`phase3_migrants_cns'))
	qui replace beta_tot_phase2_phase3_wavg_100 = r(estimate) in `row'
	qui replace se_tot_phase2_phase3_wavg_100 = r(se) in `row'
	}



qui replace feset = `feset' in `row'
qui replace nobs = e(N)  in `row'
qui replace r2 = e(r2) in `row'
local row = `row' + 1

}

* Make dataset long
drop nobs r2
drop if fe == ""
greshape long beta se, by(fe feset) keys(T) string
drop if missing(beta)

* Indicator for migrant type 
gen migrant_counts = "" 
replace migrant_counts = "T5m_Dremittance" if feset <= 8
replace migrant_counts = "T5m_TSsbth_DSsremittance" if feset == 9
replace migrant_counts = "T5m_TSsbth_DScns" if feset == 10

* Indicator for time controls
gen time_controls = "poly_week"
replace time_controls = "none" if feset == 2
replace time_controls = "week_fe" if feset == 3

* Indicator for other controls
gen controls = "cases+tests"
replace controls = "cases" if feset == 7
replace controls = "tests" if feset == 8

* Indicator for dropping thane
gen depvar = "num_cases"
replace depvar = "num_deaths" if feset == 4

* Indicator for weight
gen weight = "none"
replace weight = "migrants" if feset == 5
replace weight = "population" if feset == 6

* Identifiers for point estimates
gen phase2_phase3_wavg = 0
replace phase2_phase3_wavg = 1 if substr(T, 2, 18) == "phase2_phase3_wavg"

gen tot_phase2_phase3_wavg = 0
replace tot_phase2_phase3_wavg = 1 if substr(T, 2, 22) == "tot_phase2_phase3_wavg"

gen phase1 = 0
replace phase1 = 1 if substr(T, 2, 6) == "phase1"

gen phase2 = 0
replace phase2 = 1 if substr(T, 2, 6) == "phase2" & ///
	substr(T, 2, 18) != "phase2_phase3_wavg"

gen phase3 = 0
replace phase3 = 1 if substr(T, 2, 6) == "phase3"

* Destring daily coefficients
replace T = substr(T, -3, 3) 
replace T = substr(T, -2, 2) if substr(T, 1, 1) == "_"
destring T, replace

* 95% confidence intervals
gen ci95_lo = beta - 1.96*se
gen ci95_hi = beta + 1.96*se
  
* 90% confidence intervals
gen ci90_lo = beta - 1.645*se
gen ci90_hi = beta + 1.645*se 


save "$dirpath_out/RESULTS_event_study_phase1_phase2_phase3.dta", replace


