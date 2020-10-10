# BSS_COVID_migration
This repository contains all data and code required to replicate Burlig, Sudarshan, and Schlauch (2020): "INSERT TITLE HERE." The main text of the paper can be found in [`BSS_COVID_migration.pdf`](LINK), and the Supplementary Information can be found in [`BSS_COVID_migration_SI.pdf`](LINK).

### Required data and file structure
Due to a non-disclosure agreement between the financial services firm that provided the remittances data, we are unable to provide the raw data publicly. Academic researchers wishing to replicate our results from scratch can contact us for details on how to obtain the remittances data. Our non-disclosure agreement does permit us to share aggregated data, so this repository contains all data required to reproduce our empirical estimates and all figures/tables in the main paper and SI. As a result, we leave the `Data/Raw` data folder empty. We provide the required data in the `XXX` folder.

The file structure for this project is as follows (OBVIOUSLY UPDATE ME TO MATCH FOR THIS PROJECT):
```
MAIN PROJECT FOLDER
|-- Code
|   |-- Analyze
|   |-- Build
|   |-- Produce_output
|-- Data
|   |-- Intermediate
|       |--  School specific
|                    |-- forest
|                    |-- double lasso
|                    |-- prediction
|       |--  Matching
|   |-- Other data
|       |--  CA school info
|       |--  SunriseSunsetHoliday
|       |--  MesoWest FINAL
|   |-- Raw
|       |-- PGE_energy_combined
|                    |-- Customer info
|                    |-- Unzipped electric 15 min
|                    |-- Unzipped electric 60 min
|       |--  PGE_Oct_2016
|   |-- Temp
|-- Results
|   |-- Appendix
```
Researchers who obtain the raw data for this project can replicate our results by running the code in the following order:

CHANGE THESE!!
1) `BKRRW_Schools/00_MASTER_set_paths.do` sets all paths for use in subsequent `Stata` .do files. Before using this, you will need to change the master paths to match your directory structure.

2) `BKRRW_Schools/Build/B00_MASTER_build_all.do` runs all code to build datasets in `Stata`. Note that some portions of this build are run in `R`. Researchers will have to run the 4 `.R` files in the `BKRRW_Schools/Build` folder at the appropriate time partway through the `BOO_MASTER_build_all.do` file. This code takes large amounts of memory and is quite slow (ie, may take several days to run), due to the use of interval electricity metering data.

3) `BKRRW_Schools/Analyze/A00_MASTER_analyze_all.do` runs all analysis code in Stata. 

4) `BKRRW_Schools/produce_output/PO00_MASTER_produce_output_all.do` generates all tables (in LaTeX format) and figures (in PDF format) in Stata for both the main text and the appendix. Appendix Figure C.1: "Locations of untreated and treated schools" must be built in `R` using the file `PO05_MASTER_make_map.R`.

The `BKRRW_Schools/Build`, `BKRRW_Schools/Analyze`, and `BKRRW_Schools/Produce_output` folders contain all required sub-programs. 

To replicate all empirical results, figures, and tables for the main paper and SI, researchers can run the code starting from this point, and continue in order:

Note that the final Figure 1, Panel A and Figure 2, Panel A in the main text underwent final assemblyin Adobe Illustrator.


### Contact
If you have remaining questions about the code described here, please contact [Fiona Burlig](mailto:burlig@uchicago.edu).
