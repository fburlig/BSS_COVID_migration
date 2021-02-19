# Burlig, Sudarshan, and Schlauch (2021) replication archive
This repository contains all data and code required to replicate Burlig, Sudarshan, and Schlauch (2021): "The impact of domestic travel bans on COVID-19 cases is nonlinear in their duration". The main text of the paper can be found in [`BSS_COVID_migration.pdf`](LINK), and the Supplementary Information can be found in [`BSS_COVID_migration_SI.pdf`](LINK) (note that these are currently blank; we will update when permitted by the journal).

### Software
This repository uses both `Stata` and `R`. All code has been validated to run on `Stata 16 MP` and `R 4.02`, as of February 2021. We also utilize a variety of user-written packages for both programs, listed here:
* Stata:
  * `gsort`, `missings`, `reclink`, `strgroup`, `rangestat`, `dm88_1`, `gr0075`, `gtools`, and `reghdfe`. All of these files are available from `ssc`.
  * `scheme-fb2.scheme` is required for proper figure aesthetics. It is included in this repository. Users should install it into their `ado` folder.
  
* R: 
  * `sf`, `plyr`, `tidyverse`, `nngeo`, `rlist`, `rjson`, `rmapshaper`, `grDevices`, `rgdal`, `extrafont`, `stringi`, `exactextractr`, `raster`, `fasterize`, `maptools`, and `sp` are all available from CRAN. 
  * `covoid` is available from Github, using the following code snippet:
  ```
  # if necessary, install devtools:
  install.packages("devtools")
  # install covoid:
  devtools::install_github("cbdrh/covoid",build_vignettes = TRUE)]
  ```
* Inkscape:
  * Fig. 1 in the main text was partially assembled in Inkscape.

### Code and data
This repository contains all code and data required to reproduce our estimates, figures, and tables in the main paper and Supplementary Information.

The full project, starting from raw data and ending with figures and tables, can be replicated by running `MASTER_run_full_project.do`. This calls all required `.do` files and `.R` scripts in order. 

Replicators should run the `MASTER_run_replication.do` file, which fully replicates the results starting from the cleaned data. These two files call various subprograms, contained in the `/Code` folder. 

Prior to running the `MASTER` file, researchers must set the indicated file paths at the top of this `.do` file. In addition, replicators must change the directory path (the `setwd()` step) at the top of _each_ included `.R` script that they intend to run. 

All data are located in https://uchicago.box.com/s/f0ge88m9iab9u03lihimcmx6u6w9iu9c. Researchers should unzip this folder and assemble the replication folder structure as described below. The ZIP folder populates all datasets required for researchers to run `MASTER_run_full_project.do` and `MASTER_run_replication.do`.

```
MAIN PROJECT FOLDER
|-- Code
|   |-- Analyze
|   |-- Build
|   |-- Merge
|   |-- PO
|-- Data
|   |-- Raw
|       |--  Census
|            |--  India
|                 |--  D1
|                 |--  D2
|            |--  Indonesia
|            |--  Kenya
|            |--  Philippines
|            |--  South Africa
|       |--  Covid
|       |--  Misc
|       |--  Rasters
|                 |--  World pop
|       |--  Shapefiles
|            |--  Districts
|            |--  Non india
|                 |--  China
|                 |--  Indonesia
|                 |--  Kenya
|                      |--  adm1
|                      |--  adm2
|                      |--  county
|                 |--  Philippines
|                 |--  South Africa
|   |-- Generated
|       |--  Intermediate
|            |--  Census
|            |--  Covid
|            |--  Map
|            |--  Shapefiles
|                 |--  Districts
|                      |--  aggregated
|                      |--  combined
|                      |--  separated
|            |--  Temp
|            |--  World pop
|       |--  Final
|            |--  Regression inputs
|            |--  Results
|            |--  Shapefiles
|-- Outputs
|       |--  Figures
|       |--  Maps
|       |--  Tables
```



### Contact
If you have remaining questions about the code described here, please contact [Fiona Burlig](mailto:burlig@uchicago.edu).
