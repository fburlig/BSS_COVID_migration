*****************************************************************************
*****************************************************************************

***** Clean remittance daily transaction volume

*****************************************************************************
*****************************************************************************

***** SETUP:
global dirpath_remittances "$dirpath/data/raw/remittances"
global dirpath_xr_infl "$dirpath/data/raw/misc"
global dirpath_out "$dirpath/data/generated/intermediate/remittances"

*****************************************************************************
*****************************************************************************

** read in raw data from remittance
insheet using "$dirpath_remittances/remittances_daywise_DMT.csv", comma clear

** convert date to stata format
gen date_stata = date(hive, "YMD")
format date_stata %td

** other data prep
drop hive
sort date_stata

preserve

** prep INR <--> USD exchange rate data
* https://fred.stlouisfed.org/series/DEXINUS
insheet using "$dirpath_xr_infl/dexinus.csv", comma clear

** convert date to stata format
gen date_stata = date(date, "YMD")
format date_stata %td

** other data prep
drop date
sort date_stata

rename dexinus usd_inr_exchange_rate

tempfile exchangerate
save `exchangerate'

restore

merge 1:1 date_stata using `exchangerate', keep(1 3) nogen

** interpolate exchange rate where exchange rate is missing
ipolate usd_inr_exchange_rate date_stata, gen(usd_inr_exchange_rate_interp)

replace usd_inr_exchange_rate = usd_inr_exchange_rate_interp if usd_inr_exchange_rate == .
drop usd_inr_exchange_rate_interp


** fill in the beginning / end of the time series with exchange rates
sum usd_inr_exchange_rate if date_stata == date("2016-01-04", "YMD")
replace usd_inr_exchange_rate = `r(mean)' if date_stata <  date("2016-01-04", "YMD") ///
   & usd_inr_exchange_rate == . & date_stata != .
   
sum usd_inr_exchange_rate if date_stata == date("2020-07-02", "YMD")
replace usd_inr_exchange_rate = `r(mean)' if date_stata >  date("2020-07-02", "YMD") ///
   & usd_inr_exchange_rate == . & date_stata != .
   

** generate gross transaction value in USD
rename gtv gtv_inr
gen gtv_usd = gtv / usd_inr_exchange_rate


* Remove the first few days in march to have complete data for each month
keep if date_stata < date("2020/07/01", "YMD")


* Create month/year variables for matching onto CPI data
gen year = year(date_stata)
gen month = month(date_stata)
tempfile usd_exch_vol
save `usd_exch_vol'

* Load and clean inflation data
//https://data.bls.gov/pdq/SurveyOutputServlet
import excel "$dirpath_xr_infl/SeriesReport-20201007192705_27075b.xlsx", clear

drop if missing(A)
drop A
rename B year
rename C month
rename D cpi
drop in 1/10

drop if substr(month, 1, 1) == "S"
replace month = substr(month, 2, 2)

foreach var of varlist year month cpi {
	destring `var', replace
}


// get cpi in august 2020
preserve
keep if year == 2020 & month == 8
local cpi_y2020_m8 = cpi[1]
restore

drop if year == 2020 & month >= 7

tempfile inflation
save `inflation'

use `usd_exch_vol', clear
merge m:1 year month using `inflation', nogen


* Adjust daily transaction volume for inflation
gen gtv_usd_infl = gtv_usd * (`cpi_y2020_m8' / cpi)


* Convert to millions
gen gtv_usd_infl_millions = gtv_usd_infl / 1000000


* Format date for plotting later
format date_stata %tdCY


* Output
save "$dirpath_out/daily_transaction_volume_cleaned.dta", replace


