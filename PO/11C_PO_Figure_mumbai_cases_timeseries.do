
* Plot Mumbai+Mumbai Suburban cases time series

***************************************************************************
***************************************************************************
**** SETUP
global dirpath_in "$dirpath/data/generated/intermediate/covid"
global dirpath_out "$dirpath/outputs/figures"

***************************************************************************
***************************************************************************

* Load data
use "$dirpath_in/covid19india_data_cleaned.dta", clear


* Keep Mumbai from March 2nd to July 25th
keep if district == "MUMBAI"
gen cum_cases = sum(num_cases)


* Local macros for key dates
local mar1 = date("2020/03/01", "YMD")
local apr1 = date("2020/04/01", "YMD")
local may1 = date("2020/05/01", "YMD")
local may8 = date("2020/05/08", "YMD")
local jun1 = date("2020/06/01", "YMD")
local jun5 = date("2020/06/05", "YMD")
local jul1 = date("2020/07/01", "YMD")
local aug1 = date("2020/08/01", "YMD")
local aug19 = date("2020/08/19", "YMD")
local sep1 = date("2020/09/01", "YMD")


* Plot
replace cum_cases = cum_cases / 1000

twoway ///
	(pci 180 `may8' 180 `=`may8'-12', lcolor(gs8) lwidth(medium) ///
		 text(180 `=`may8'-32' "May 8:" "Phase 1" "restrictions lifted", color(black))) ///
	(pci 150 `jun5' 150 `=`jun5'+12', lcolor(gs8) lwidth(medium) ///
		 text(150 `=`jun5'+32' "Jun 5:" "Phase 2" "restrictions lifted" ///
			, color(black))) ///
	(pci 40 `aug19' 40 `=`aug19'-12', lcolor(gs8) lwidth(medium) ///
		 text(40 `=`aug19'-32' "Aug 19:" "Phase 3" "restrictions lifted" ///
			, color(black))) ///
	(line cum_cases date, lwidth(medthick) lcolor(midblue) lp(solid)) ///
	, ///
	ytitle("Cumulative cases (thousands)", size(large)) ///
	xlabel(`mar1' "Mar 1" `apr1' "Apr 1" `may1' "May 1" `jun1' "Jun 1" `jul1' "Jul 1" `aug1' "Aug 1" `sep1' "Sep 1", labsize(medlarge)) ///
	ylabel(, format(%9.0fc) labsize(medlarge)) ///
	xline(`may8' `jun5' `aug19', lcolor(gs8)) ///
	legend(off) ///
	title("{bf: {fontface Arial: A}}", pos(10) size(vhuge))
	
	
graph export "$dirpath_out/Figure_mumbai_cum_cases_ts.pdf", replace


