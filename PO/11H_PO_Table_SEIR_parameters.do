
* Create table of SEIR model parameters

*****************************************************************************
*****************************************************************************

* Set paths
global dirpath_out "$dirpath/outputs/tables"

*****************************************************************************
*****************************************************************************


* Macro for creating a standalone table
//local standalone = "_standalone"

// make sure there isn't already a file with your chosen name open
capture file close myfile

// final destination of the table
file open myfile using "$dirpath_out/Table_SI_SEIR_model_parameters.tex", write replace

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
 file write myfile "\begin{table}" _n
 file write myfile "\centering" _n
 file write myfile "\small" _n
 file write myfile "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}} " 
forvalues i = 1(1)`ncol' {
	file write myfile " c "
}
file write myfile "}" _n ///
"\toprule " _n

// Column headers
file write myfile "Parameter & Value & Source"
file write myfile " \\ \midrule " _n

//Parameters/variables/values
file write myfile "Source (Mumbai) population & 12,442,373 &\supercite{census2011,mahapop2020} \\" _n
file write myfile "Number of departing migrants (Phase 2) & 258,399 &\supercite{5m_left,3m_left,nytwalk,2m_returning} \\" _n
file write myfile "Population (Phase 2 destinations) & 13,694,348 &\supercite{census2011,mahapop2020} \\" _n
file write myfile "Number of departing migrants (Phase 3) & 333,884 &\supercite{5m_left,3m_left,nytwalk,2m_returning} \\" _n
file write myfile "Population (Phase 3 destinations) & 76,808,204 &\supercite{census2011,mahapop2020} \\" _n
file write myfile "Mumbai positivity rate (July 15th) & 32.7 percent &\supercite{tata2020} \\" _n
file write myfile "Seed infections on March 25th & 500 & Assumed \\" _n
file write myfile "$R_{0}$ Mumbai & 3.83 & Calibrated to match\supercite{tata2020} \\" _n
file write myfile "$R_{0}$ Phase 2 destinations & 1.91 & 50\% of $R_{0}$ source \\" _n
file write myfile "$R_{0}$ Phase 3 destinations & 1.45 & Maharashtra estimate from\supercite{marimuthu2020} \\" _n
file write myfile "Latent period ($1/ \omega$) & 10 days &\supercite{covoidarticle,covoidpackage} \\" _n
file write myfile "Infectious period ($1/ \lambda$) & 10 days &\supercite{covoidarticle,covoidpackage} \\" _n


file write myfile "\bottomrule " _n 
file write myfile "\end{tabular*}" _n
file write myfile "\label{si_tab:seir}" _n
file write myfile "\caption[SEIR model parameters.]{\footnotesize SEIR model parameters. This table lists the parameter values we use in our SEIR model, described in Section~\ref{si_sec:seir}, including citations where applicable.}" _n
file write myfile "\label{si_tab:seir}" _n
file write myfile "\end{table}" _n
file write myfile _n

if "`standalone'" == "_standalone" {
 file write myfile "\end{document}" _n
}

file close myfile



