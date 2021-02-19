
* Create tables

**** Setup
clear all
macro drop _all

global dirpath_data "$dirpath/data"
global dirpath_raw "$dirpath_data/raw"
global dirpath_raw_census "$dirpath_raw/census"
global dirpath_raw_covid "$dirpath_raw/covid"
global dirpath_raw_misc "$dirpath_raw/misc"
global dirpath_gen "$dirpath_data/generated"
global dirpath_int "$dirpath_gen/intermediate"
global dirpath_int_census "$dirpath_int/census"
global dirpath_int_covid "$dirpath_int/covid"
global dirpath_int_map "$dirpath_int/map"
global dirpath_int_temp "$dirpath_int/temp"
global dirpath_int_worldpop "$dirpath_int/World pop"
global dirpath_int_shapefiles "$dirpath_int/shapefiles"
global dirpath_final "$dirpath_gen/final"
global dirpath_final_reg_inputs "$dirpath_final/Regression inputs"
global dirpath_final_results "$dirpath_final/results"
global dirpath_outputs "$dirpath/outputs"
global dirpath_outputs_figs "$dirpath_outputs/figures"
global dirpath_outputs_tables "$dirpath_outputs/tables"

******************************************************************
* SEIR model parameters
******************************************************************

* Macro for creating a standalone table
//local standalone = "_standalone"

// make sure there isn't already a file with your chosen name open
capture file close myfile

// final destination of the table
file open myfile using "$dirpath_outputs_tables/Table_SEIR_model_parameters.tex", write replace

// this generates the preamble for the standalone version
if "`standalone'" == "_standalone" {
 file write myfile "\documentclass[12pt]{article}" _n
 file write myfile "\usepackage{amsmath}" _n
 file write myfile "\usepackage{tabularx}" _n
 file write myfile "\usepackage{booktabs}" _n
 file write myfile "\begin{document}" _n
 file write myfile "\pagenumbering{gobble}" _n
 file write myfile _n
}	


// Number of columns
local ncol 3

// set up the tabular environment and define the number of columns
 file write myfile "\begin{savenotes}" _n
 file write myfile "\begin{table}[h]" _n
 file write myfile "\centering" _n
 file write myfile "\small" _n
 file write myfile "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} " 
forvalues i = 1(1)`ncol' {
	file write myfile "l"
}
file write myfile "}" _n ///
"\toprule " _n

// Column headers
file write myfile "\multicolumn{1}{c}{Parameter} & \multicolumn{1}{c}{Value} & \multicolumn{1}{c}{Source} \\" _n
file write myfile "\midrule " _n

//Parameters/variables/values
file write myfile "Source population & 13,702,964 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "Sink population & 16,642,462 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "Number of migrants & 40,184 $\times$ 1.25 & 2011 Census$^{\ref{fn:census_in}}$,  WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "Source positivity rate (July 15th) & 32.7\% & Kolthur-Seetharam, U. et al, 2020\footnote{\label{tata_ft}\href{https://www.tifr.res.in/TSN/article/Mumbai-Serosurvey\%20Technical\%20report-NITI.pdf}{Kolthur-Seetharam, U. et al. SARS-CoV2 serological survey in Mumbai by NITIBMC-TIFR tech. rep. (NITI-Aayog, Municipal Corporation of Greater Mumbai and the Tata Institute of Fundamental Research, 2020).}} \\" _n
file write myfile "Seed infections on March 25th & 500 & Assumed \\" _n
file write myfile "$R_{0}$ source & 3.75 & Calibrated to match$^{\ref{tata_ft}}$ \\" _n
file write myfile "$R_{0}$ sink & $0.5 \times R_0$ source & Similar to Marimuthu, S. et al, 2020\footnote{Marimuthu, S. et al. Modelling of reproduction number for COVID-19 in India and high incidence states. Clinical Epidemiology and Global Health. Preprint, \url{https://www.sciencedirect.com/science/article/pii/S221339842030169X} (2020).} \\" _n
file write myfile "Latent period ($1/ \omega$) & 10 days & Churches, T. \& Jorm, L, 2020\footnote{\label{covid_article_ft}Churches, T. \& Jorm, L. Flexible, freely available stochastic individual contact model for exploring COVID-19 intervention and control strategies: Development and simulation. JMIR Public Health and Surveillance 3, e18965 (2020).} \\" _n
file write myfile "& & Fitzgerald et al, 2020\footnote{\label{covid_package_ft}Fitzgerald, O., Hanly, M. \& Churches, T. covoid: COVID-19 open-source infection dynamics (2020).} \\" _n
file write myfile "Infectious period ($1/ \lambda$) & 10 days & Churches, T. \& Jorm, L, 2020$^{\ref{covid_article_ft}}$ \\ " _n
file write myfile "& & Fitzgerald et al, 2020$^{\ref{covid_package_ft}}$ \\" _n

file write myfile "\bottomrule " _n 
file write myfile "\end{tabular*}" _n
file write myfile "\caption{\footnotesize \textbf{$\vert$ SEIR model parameters}. This table lists the parameter values used to calibrate our SEIR model, where source refers to Mumbai and sink refers to Phase 2 districts. Citations are included where applicable.}" _n
file write myfile "\label{si_tab:seir}" _n
file write myfile "\end{table}" _n
file write myfile "\end{savenotes}" _n

if "`standalone'" == "_standalone" {
 file write myfile "\end{document}" _n
}

file close myfile

******************************************************************
* Travel bans
******************************************************************

* Macro for creating a standalone table
//local standalone = "_standalone"

// make sure there isn't already a file with your chosen name open
capture file close myfile

// final destination of the table
file open myfile using "$dirpath_outputs_tables/Table_travel_ban_info.tex", write replace

// this generates the preamble for the standalone version
if "`standalone'" == "_standalone" {
 file write myfile "\documentclass[12pt]{article}" _n
 file write myfile "\usepackage{amsmath}" _n
 file write myfile "\usepackage{tabularx}" _n
 file write myfile "\usepackage{booktabs}" _n
 file write myfile "\begin{document}" _n
 file write myfile "\pagenumbering{gobble}" _n
 file write myfile _n
}	


// Number of columns
local ncol 5

// set up the tabular environment and define the number of columns
 file write myfile "\begin{savenotes}" _n
 file write myfile "\begin{table}[h]" _n
 file write myfile "\centering" _n
 file write myfile "\small" _n
 file write myfile "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} " 
forvalues i = 1(1)`ncol' {
	file write myfile "l"
}
file write myfile "}" _n ///
"\toprule " _n

// Column headers
file write myfile " & & \multicolumn{1}{c}{Travel ban} & \multicolumn{1}{c}{Travel ban} & \multicolumn{1}{c}{Travel ban} \\" _n
file write myfile " \multicolumn{1}{c}{Country} & \multicolumn{1}{c}{Hotspot(s)} & \multicolumn{1}{c}{initiation} & \multicolumn{1}{c}{relaxation} & \multicolumn{1}{c}{duration} \\" _n
file write myfile " \midrule " _n

//Parameters/variables/values
file write myfile "Indonesia & Jakarta$^{\ref{fn:covid19open}}$ & Apr 24th$^{\ref{ft:id_lockdown}}$ & May 7th$^{\ref{ft:id_lift}}$ & 13 days \\" _n
file write myfile "South Africa & Cape Town$^{\ref{fn:covid19open}}$ & Mar 26th$^{\ref{ft:za_lockdown}}$ & May 1st$^{\ref{za:lockdown_lift}}$ & 36 days \\" _n
file write myfile "India (Phase 1) & Mumbai$^{\ref{fn:covid_in}}$ & Mar 25th$^{\ref{ft:india_lockdown}}$ & May 8th$^{\ref{ft:india_p1_release}}$ & 44 days \\" _n
file write myfile "China & Wuhan (Hubei) & Jan 23rd$^{\ref{ft:china_lockdown}}$ & Apr 8th$^{\ref{ft:china_lift},*}$ & 76 days \\" _n
file write myfile "Philippines & NCR$^{\dag}$ \& Cebu$^{\ref{fn:covid19open}}$ & Mar 15th$^{\ref{ft:lockdown_ph_ncr}}$ \& 18th$^{\ref{ft:lockdown_ph_other}}$ & May 30th$^{\ref{ft:lift_ph_1},\ref{ft:lift_ph_2}}$ & 76 days \\" _n
file write myfile "Kenya & Nairobi \& Mombasa$^{\ref{fn:covid19open}}$ & Apr 6th \& 8th$^{\ref{ft:ke_lockdown}}$ & Jul 7th$^{\ref{ft:ke_lift}\ddag}$ & 92 days \\" _n

file write myfile "\bottomrule " _n 
file write myfile "\end{tabular*}" _n
file write myfile "\caption{\footnotesize \textbf{$\vert$ Travel ban information by country}. For each country, this table lists the region(s) we designate as hotspots, the dates of travel ban initiations and relaxations, and the durations of travel bans, including citations where applicable. Where two travel ban initiation dates are listed for a single country, we use the earlier one to calculate travel ban duration. \\
$^*$Since the data are only available at the Admin 1 level, we use the Wuhan lockdown lift date rather than that for other regions of Hubei, which allowed travel two weeks earlier. \\
$^{\dag}$ National Capital Region\\
$^{\ddag}$Although the travel ban from Mandera was also relaxed at this time, Mandera does not report any COVID-19 cases in our data prior to July 7th.}" _n
file write myfile "\label{si_tab:travelban_info}" _n
file write myfile "\end{table}" _n
file write myfile "\end{savenotes}" _n
file write myfile _n

if "`standalone'" == "_standalone" {
 file write myfile "\end{document}" _n
}

file close myfile


******************************************************************
* Data sources
******************************************************************

* Macro for creating a standalone table
//local standalone = "_standalone"

// make sure there isn't already a file with your chosen name open
capture file close myfile

// final destination of the table
file open myfile using "$dirpath_outputs_tables/Table_data_sources.tex", write replace

// this generates the preamble for the standalone version
if "`standalone'" == "_standalone" {
 file write myfile "\documentclass[12pt]{article}" _n
 file write myfile "\usepackage{amsmath}" _n
 file write myfile "\usepackage{tabularx}" _n
 file write myfile "\usepackage{booktabs}" _n
 file write myfile "\begin{document}" _n
 file write myfile "\pagenumbering{gobble}" _n
 file write myfile _n
}	


// Number of columns
local ncol 7

// set up the tabular environment and define the number of columns
 file write myfile "\begin{savenotes}"
 file write myfile "\begin{sidewaystable}"
 file write myfile "\centering" _n
 file write myfile "\small" _n
 file write myfile "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} " 
forvalues i = 1(1)`ncol' {
	file write myfile "l"
}
file write myfile "}" _n ///
"\toprule " _n

// Column headers
file write myfile "& \multicolumn{2}{c}{COVID-19 data} & \multicolumn{2}{c}{Migration data} & \multicolumn{2}{c}{Population data} \\" _n
file write myfile \cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7} "\multicolumn{1}{c}{Country} & \multicolumn{1}{c}{Admin level} & \multicolumn{1}{c}{Source} & \multicolumn{1}{c}{Year} & \multicolumn{1}{c}{Source} & \multicolumn{1}{c}{Year} & \multicolumn{1}{c}{Source} \\" _n
file write myfile "\midrule " _n

* Body
// Indonesia
file write myfile "Indonesia & 1 & COVID-19 Open-Data$^{\ref{fn:covid19open},}$ & 2010 & IPUMS$^{\ref{fn:ipums_int_id}}$ & 2020 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "& & ID Komite COVID-19$^{\ref{fn:id_covid}}$ & & Statistics Indonesia$^{\ref{fn:census_id}}$ & & \\[0.25cm] " _n
// South Africa
file write myfile "South Africa & 2 & COVID-19 Open-Data$^{\ref{fn:covid19open}}$ & 2011 & IPUMS$^{\ref{fn:ipums_int_za}}$ & 2020 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "& & Finmango$^{\ref{fn:finmango_za}}$ & & Statistics South Africa$^{\ref{fn:census_za}}$ & & \\[0.25cm]" _n
// India
file write myfile "India & 1 \& 2 & COVID19-India$^{\ref{fn:covid_in}}$ & 2011 & ORGI$^{\ref{fn:census_in},*}$ & 2020 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "& & & & & 2011 & ORGI$^{\ref{fn:census_in}}$ \\[0.25cm]" _n
// China
file write myfile "China & 1 & COVID-19 Open-Data$^{\ref{fn:covid19open}}$ & 2010 & Liu et al, 2014$^{\ref{ft:census_cn}}$ & 2020 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "& 1 & DXY COVID-19 Data$^{\ref{fn:cn_covid_source}}$ & & \\[0.25cm]" _n
// Philippines
file write myfile "Philippines & 2 & COVID-19 Open-Data$^{\ref{fn:covid19open}}$ & 2010 & IPUMS$^{\ref{fn:ipums_int_ph}}$ & 2020 & WorldPop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "& & Philippine Dept. of Health$^{\ref{ph:covid2}}$ & & Nat'l Statistics Office$^{\ref{fn:census_ph}}$  & &  \\[0.25cm]" _n
// Kenya
file write myfile "Kenya & 2$^{\dag}$ & COVID-19 Open-Data$^{\ref{fn:covid19open}}$ & 2009 & IPUMS$^{\ref{fn:ipums_int_ke}}$ & 2020 & Worldpop$^{\ref{fn:worldpop}}$ \\" _n
file write myfile "& & Finmango$^{\ref{fn:finmango_ke}}$ & 2009 & Nat'l Bureau of Statistics$^{\ref{fn:census_ke}}$ & & \\" _n

file write myfile "\bottomrule " _n 
file write myfile "\end{tabular*}" _n
file write myfile "\caption{\footnotesize \textbf{$\vert$ Data sources}. For each country, this table lists the primary (1st row) and, where applicable, secondary (2nd row) data sources for the COVID-19, migration, and population data used in our analysis. \\ $^{*}$Office of the Registrar General \& Census Commissioner, India \\ $^{\dag}$Interpolated; see our Supplementary Notes.}" _n
file write myfile "\label{si_tab:data_sources}" _n
file write myfile "\end{sidewaystable}" _n
file write myfile "\end{savenotes}" _n
file write myfile _n

if "`standalone'" == "_standalone" {
 file write myfile "\end{document}" _n
}

file close myfile


