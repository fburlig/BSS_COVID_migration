# BSS_COVID_migration
This repository contains all data and code required to replicate Burlig, Sudarshan, and Schlauch (2020): "Quantifying the effect of domestic travel bans on COVID-19 infections". The main text of the paper can be found in [`BSS_COVID_migration.pdf`](LINK), and the Supplementary Information can be found in [`BSS_COVID_migration_SI.pdf`](LINK) (note that these are currently blank; we will update when permitted by the journal).

### Required data and file structure
Due to a non-disclosure agreement between the financial services firm that provided the remittances data, we are unable to provide the raw data publicly. Academic researchers wishing to replicate our results from scratch can contact us for details on how to obtain the remittances data. Our non-disclosure agreement does permit us to share aggregated data, so this repository contains all data required to reproduce our empirical estimates and all figures/tables in the main paper and SI. As a result, we leave the `Data/Raw` data folder empty. We provide the required data in the `XXX` folder.

The file structure for this project is as follows (OBVIOUSLY UPDATE ME TO MATCH FOR THIS PROJECT):
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
|       |--  District-level covid
|       |--  Eko Sample Data
|       |--  Eko Totals
|       |--  IFSC
|       |--  Misc
|       |--  Mumbai Full
|       |--  Shapefiles
|   |-- Generated
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
Researchers who obtain the raw data for this project can replicate our results by running the `MASTER_run_full_project.do` file. This calls all required `.do` files and `.R` scripts in order. We have provided all data required to produce the final outputs. Any replicator can run the `MASTER_run_full_project.do` file, including the initialization steps, and then starting from Step 9, to fully replicate our results. The included `scheme-fb.scheme` is required for figures to have the same aesthetics as in the main paper.

Note that prior to running this file, researchers must set the indicated file paths at the top of this `.do` file. In addition, replicators must change the directory path (the `setwd()` step) at the top of _each_ included `.R` script that they intend to run. 

The final Figure 1, Panel A and Figure 2, Panel A in the main text were assembled in Adobe Illustrator.

### Contact
If you have remaining questions about the code described here, please contact [Fiona Burlig](mailto:burlig@uchicago.edu).
