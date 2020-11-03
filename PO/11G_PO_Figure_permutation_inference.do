* Plot permutation inference results

*****************************************************************************
*****************************************************************************
* Set paths
global dirpath_in "$dirpath/data/generated/final/results"
global dirpath_out "$dirpath/outputs/figures"


*****************************************************************************
*****************************************************************************

* Load data
use "$dirpath_in/RESULTS_permutation_inference.dta", clear


* Convert to thousands
replace beta = beta / 1000


* Get empirical estimate from actual data
preserve
gsort -beta
keep if beta > beta[1]
local pval = _N / 10000
di `pval'
restore
gsort -true_beta 
local true_beta_val = 551.62


* Plot
twoway ///
	(pci 13.5 `true_beta_val' 13.5 `=`true_beta_val'-55', ///
		lcolor(black) lwidth(medium) ///
		text(13.5 `=`true_beta_val'-150' ///
		"Observed point" "estimate in" "real data:" "551,620", ///
		size(medium) color(black))) ///
	(pci 9.5 `=`true_beta_val'-1' 9.5 `=`true_beta_val'-25', ///
		lcolor(white) lwidth(medium) ///
		text(9.5 `=`true_beta_val'-150' ///
		"Permutation" "inference" "p-value:" "< 0.0001", ///
		size(medium) color(black))) ///
	(histogram beta, percent color(midblue*0.5) ///
		lcolor(white%50)) ///
	, ///
	legend(off) ///
	xline(`true_beta_val', lcolor(black) lp(solid)) ///
	xlabel(, format(%9.0fc) labsize(medlarge)) ///
	ylabel(, labsize(medlarge)) ///
	ytitle("Percent of draws with scrambled cases", size(medlarge)) ///
	xtitle("Excess cases by September 30th (thousands)", size(medlarge))

	
graph export "$dirpath_out/Figure_SI_permutation_inference.pdf", replace

