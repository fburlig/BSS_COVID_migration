# Burlig, Sudarshan, and Schlauch (2020) replication archive
This repository contains all data and code required to replicate Burlig, Sudarshan, and Schlauch (2020): "Quantifying the effect of domestic travel bans on COVID-19 infections". The main text of the paper can be found in [`BSS_COVID_migration.pdf`](LINK), and the Supplementary Information can be found in [`BSS_COVID_migration_SI.pdf`](LINK) (note that these are currently blank; we will update when permitted by the journal).

### Software
This repository uses both `Stata` and `R`. All code has been validated to run on `Stata 16 MP` and `R 4.02`, as of October 2020. We also utilize a variety of user-written packages for both programs, listed here:
* Stata:
  * `gsort`, `missings`, `reclink`, `strgroup`, `rangestat`, `dm88_1`. All of these files are available from `ssc`.
  * `scheme-fb2.scheme` is required for proper figure aesthetics. It is included in this repository. Users should install it into their `ado` folder.
  
* R: 
  * `sf`, `dplyr`, `haven`, `plyr`, `tidyverse`, `readxl`, `readr`, `stringr`, `tidyr`, `nngeo`, `rlist`, `rjson`, `jsonlite`, `lubridate`, `rmapshaper`, `grDevices`, `rgdal`, and `sp` are all available from CRAN. 
  * `covoid` is available from Github, using the following code snippet:
  ```
  # if necessary, install devtools:
  install.packages("devtools")
  # install covoid:
  devtools::install_github("cbdrh/covoid",build_vignettes = TRUE)]
  ```
* Illustrator:
  * The final Figure 1, Panel A and Figure 2, Panel A in the main text were assembled in Adobe Illustrator.

### Code and data
Due to a non-disclosure agreement between the financial services firm that provided the remittances data, we are unable to provide the raw data publicly. Our non-disclosure agreement does permit us to share aggregated data. As a result, this repository contains all data required to reproduce our empirical estimates and all figures/tables in the main paper and SI, but contains only the code for the early-stage data cleaning. 

The full project, starting from raw data and ending with figures and tables, can be replicated by running `MASTER_run_full_project.do`. This calls all required `.do` files and `.R` scripts in order. 

Replicators should run the `MASTER_run_replication.do` file, which fully replicates the results starting from the cleaned (and publicly available) data. These two files call various subprograms, contained in the `/Code` folder. 

Note that prior to running the `MASTER` file, researchers must set the indicated file paths at the top of this `.do` file. In addition, replicators must change the directory path (the `setwd()` step) at the top of _each_ included `.R` script that they intend to run. 

The public data is in [`BSS_COVID_migration_data_public.zip`](https://github.com/fburlig/BSS_COVID_migration/blob/master/BSS_COVID_migration_data_public.zip). Researchers should unzip this folder and assemble the replication folder structure as described below. The public ZIP folder populates all datasets required for researchers to run `MASTER_run_replication.do`, though some folders remain empty for the aforementioned confidentiality reasons.

```
MAIN PROJECT FOLDER
|-- Code
|   |-- Analyze
|   |-- Build
|   |-- Merge
|   |-- PO
|-- Data
|   |-- Raw
|       |--  Banks
|       |--  Census11
|            |--  D1
|            |--  D11
|       |--  Covid
|       |--  Misc
|       |--  Remittances
|       |--  Shapefiles
|            |--  Districts
|            |--  Pincodes
|            |--  Villages
|   |-- Generated
|       |--  Intermediate
|            |--  Banks
|                 |--  Geocoded
|                 |--  Remit_matched
|                 |--  SolID_pin
|            |--  Census
|            |--  Covid
|            |--  Map
|            |--  Remittances
|            |--  Shapefiles
|                 |--  Districts
|                 |--  Villages
|       |--  Final
|            |--  Regression_inputs
|            |--  Results
|            |--  Shapefiles
|            |--  Transaction_volume
```



### Contact
If you have remaining questions about the code described here, please contact [Fiona Burlig](mailto:burlig@uchicago.edu).
