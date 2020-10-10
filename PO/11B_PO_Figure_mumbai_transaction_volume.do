*****************************************************************************
*****************************************************************************

***** Plot inferred daily transaction volume from Mumbai from 2016--20

*****************************************************************************
*****************************************************************************

***** SETUP:
global dirpath_in "$dirpath/data/generated/final/Transaction_volume"
global dirpath_out "$dirpath/outputs/figures"

*****************************************************************************
*****************************************************************************

* Load daily transaction volume inferred for Mumbai
use "$dirpath_in/daily_transaction_volume_mumbai.dta", clear


* Text label positions
local march25 = date("2020/03/25", "YMD")
local nov1 = date("2019/11/01", "YMD")
local jun1 = date("2019/06/25", "YMD")


* x-axis label positions
local jan2016 = date("2016/01/01", "YMD")
local jan2017 = date("2017/01/01", "YMD")
local jan2018 = date("2018/01/01", "YMD")
local jan2019 = date("2019/01/01", "YMD")
local jan2020 = date("2020/01/01", "YMD")


* x-axis labels
la def date_stata `jan2016' "2016" `jan2017' "2017" `jan2018' "2018" ///
	`jan2019' "2019" `jan2020' "2020"
la val date_stata date_stata


* Plot
twoway ///
	(line gtv_usd_infl_millions_mumbai date_stata, lcolor(midblue*0.9) lwidth(thin)) ///
	(pci 1.9 `march25' 1.9 `=`nov1'+50', lcolor(gs8) lwidth(medium) ///
		text(1.9 `jun1' "Nationwide" "lockdown" "begins", ///
			size(large) color(black))) ///
	, ///
	title("{bf: {fontface Arial: C}}", pos(10) size(vhuge)) ///
      xtitle("") ///
	  ytitle("Daily transaction volume (USD millions)", size(large)) ///
	  xlabel(`jan2016' `jan2017' `jan2018' `jan2019' `jan2020', valuelabel labsize(large)) ///
	  ylabel(, labsize(medlarge)) ///
	  xline(`march25', lcolor(gs8) lpattern(solid)) /// 
	  legend(off) ///
	  xsc(r(20454 22102))

	  
* Output
graph export "$dirpath_out/Figure_daily_transaction_volume_mumbai.pdf", replace


