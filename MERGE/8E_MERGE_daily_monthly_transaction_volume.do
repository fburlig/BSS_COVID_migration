*****************************************************************************
*****************************************************************************

***** Combine daily and monthly transaction volume to get the share of total daily volume originating from Mumbai

*****************************************************************************
*****************************************************************************

***** SETUP:
global dirpath_in "$dirpath/data/generated/intermediate/remittances"
global dirpath_out "$dirpath/data/generated/final/transaction_volume"

*****************************************************************************
*****************************************************************************

* Load Mumbai monthly transaction volume data
use "$dirpath_in/monthly_transaction_volume_cleaned.dta", clear


* Keep from April 2019 through June 2020 since July is incomplete
keep if month <= date("2020/06/30", "YMD")


* Count of transactions outside mumbai
preserve
collapse (sum) sum_amt if dtname != "MUMBAI" 
local vol_not_mumbai = sum_amt[1]
restore


* Count of transactions from Mumbai
collapse (sum) sum_amt if dtname == "MUMBAI" 
local vol_mumbai = sum_amt[1]


* Share of transactions from Mumbai
local share_mumbai = `vol_mumbai' / (`vol_mumbai' + `vol_not_mumbai')


* Load daily flows data
use "$dirpath_in/daily_transaction_volume_cleaned.dta", clear


* Estimate daily transaction volume originating from Mumbai
gen gtv_usd_infl_millions_mumbai = gtv_usd_infl_millions * `share_mumbai'


* Output
save "$dirpath_out/daily_transaction_volume_mumbai.dta", replace


