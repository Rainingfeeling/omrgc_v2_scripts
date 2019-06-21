# OM-RGC v2
This repository is associated with the OM-RGC v2 / Tara prok metaT paper. It contains the script for the analyses of the paper. 

## Structure

Folders and relevant subfolders of the repository:

```
.
├── data*
    ├── raw
    ├── preliminary
    ├── release
    └── processed
├── analysis
    ├── lib
    ├── data_prep
    ├── preliminary
    └── paper_scripts
├── results
    ├── tables
    ├── figures
    ├── paper_tables
    └── paper_figures
└── README.md 
 
* not synced on GitHub (due to the size).
```

* **data**: The data used for the project, organised in different typres.
	- **raw**: Raw data generated by processing the metagenomes and metatranscriptomes.
	- **preliminary**: Steps between the raw data and the final release of the catalog and associated tables.
	- **release**: The data avalaible on the [website](https://ocean-microbiome.org/).
	- **processed**: Secondary data produced by the R script, uses only the release as input and is used to produce the figures and table for the paper.
* [**analysis**](https://github.com/SushiLab/omrgc_v2_scripts/tree/master/analysis): Folder containing the scripts and external resources to produce data, tables and figures. This folder can be accessed [here](https://polybox.ethz.ch/index.php/s/TUcdAkkKYaIjDRq) to directly enter the productive state of the repo (must be placed under 'omgrc_v2_scripts/data/'). 
	- **lib**: Contains some R functions and external resources used by the scripts.
	- **data_prep**: Scripts to go from the raw data to the released data and from the released data to the processed data, used for tables and figures. 
	- **preliminary**: Scripts for preliminary analyses that did not make it to the paper.
	- **paper_scripts**: Scripts to produce the tables and figures of the paper.
* [**results**](https://github.com/SushiLab/omrgc_v2_scripts/tree/master/results): Folder containing the tables and figures produced by the analysis scripts.
	- **tables**: Contains the preliminary tables. 
	- **figures**: Contains the preliminary figures.
	- **paper_tables**: Contains the tables and suppl. tables of the paper. 
	- **paper_figures**: Contains the figures and suppl. figures of the paper. 

