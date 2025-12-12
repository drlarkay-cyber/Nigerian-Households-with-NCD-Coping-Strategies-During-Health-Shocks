# Replication Code: Health Shocks and Coping Strategies in Nigeria

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)

## Paper Information

**Title:** Decisions and Dilemmas: Comparing How Nigerian Households with and without Non-communicable Diseases Combine Coping Strategies in Response to Health Shocks (2018-2019)

**Authors:** Adelakun Odunyemi¹*, Hamid Sohrabi², Khurshid Alam¹

**Affiliations:**
1. Murdoch Business School, Murdoch University, Perth, Western Australia
2. Centre for Healthy Ageing, Murdoch University, Perth, Western Australia

**Corresponding Author:** adelakun.odunyemi@murdoch.edu.au

**Journal:** [To be updated upon acceptance]

**DOI:** [To be updated upon publication]

---

## Abstract

Health shocks pose a significant threat to household welfare in developing countries, particularly for those managing non-communicable diseases (NCDs). This study examines how Nigerian households combine coping strategies during health shocks, comparing those with and without NCDs using the Nigeria Living Standards Survey 2018/2019 data (N=2,568). Results reveal 68.65% adopted coping strategies, with NCD-affected households using more strategies (3.65 vs 3.29, p<0.01) and showing greater vulnerability through maladaptive financial combinations. Access to credit, health insurance, and regional factors significantly influenced adoption. Findings suggest targeted interventions, including conditional cash transfers, expanded subsidised insurance, and geographically-tailored support programs.

---

## Repository Contents

```
.
├── README.md                          # This file
├── data/
│   ├── README_data_access.md          # Instructions to obtain NLSS data
│   └── variable_codebook.md           # Variable definitions
├── code/
│   ├── 01_data_cleaning.do            # Stata: Data preparation
│   ├── 02_variable_construction.do    # Stata: Create analysis variables
│   ├── 03_descriptive_analysis.do     # Stata: Tables 1-2
│   ├── 04_main_analysis.do            # Stata: Double-hurdle models (Table 3)
│   ├── 05_robustness_checks.do        # Stata: ZIP/ZINB, MICE, sensitivity
│   └── 06_upset_plots.R               # R: UpSet plots (Figures 1-2)
├── output/
│   ├── tables/                        # Generated tables
│   └── figures/                       # Generated figures
└── requirements/
    ├── stata_packages.txt             # Required Stata packages
    └── r_packages.txt                 # Required R packages
```

---

## Data Source

This analysis uses the **Nigeria Living Standards Survey (NLSS) 2018/2019**, conducted by Nigeria's National Bureau of Statistics with World Bank support.

### Access Instructions

1. **Register** (free) at World Bank Microdata Library: https://microdata.worldbank.org/
2. **Download** NLSS 2018/2019: https://microdata.worldbank.org/index.php/catalog/3827
3. **Extract** files to `data/raw/` folder in this repository
4. **Required files:**
   - Household roster
   - Health module
   - Shock module
   - Consumption module
   - Employment module

**Note:** Due to data use agreements, we cannot redistribute the raw NLSS data. You must download it directly from the World Bank.

---

## Software Requirements

### Stata
- **Version:** Stata 17 or higher (MP/SE recommended for faster processing)
- **Required packages:**
  ```stata
  ssc install outreg2
  ssc install coefplot
  net install spost13_ado, from("https://jslsoc.sitehost.iu.edu/stata")   
  ssc install missings
  ssc install countfit
  ```

### R
- **Version:** R 4.0 or higher
- **Required packages:**
  ```r
  install.packages(c("readxl", "dplyr", "UpSetR", "ggplot2", 
                     "tidyr", "haven"))
  ```

**Installation script provided in:** `requirements/install_packages.R`

---

## How to Run the Analysis

### Step 1: Download Data
1. Follow instructions in `data/README_data_access.md`
2. Place downloaded files in `data/raw/`

### Step 2: Set Working Directory
Edit line 20 in each `.do` file:
```stata
cd "YOUR_PATH_HERE/health-shocks-coping-strategies"
```

### Step 3: Run Stata Scripts (In Order)
```stata
do code/01_data_cleaning.do
do code/02_variable_construction.do
do code/03_descriptive_analysis.do
do code/04_main_analysis.do
do code/05_robustness_checks.do
```

**Expected runtime:** ~45 minutes total on standard laptop (Intel i5, 8GB RAM)

### Step 4: Generate Figures (R)
```r
setwd("YOUR_PATH_HERE/health-shocks-coping-strategies")
source("code/06_upset_plots.R")
```

**Expected runtime:** ~5 minutes

---

## Detailed Script Descriptions

### 01_data_cleaning.do (~5 min runtime)
- Loads raw NLSS modules
- Merges household, health, shock, and consumption data
- Handles missing values
- Creates analytical sample of health shock-affected households
- **Output:** `data/processed/nlss_cleaned.dta`

### 02_other_variable_construction.do (~3 min)
- Identifies NCD-affected households using WHO ICD-10 classification
- Creates coping strategy binary variables (10 strategies)
- Constructs control variables (demographics, socioeconomic, regional)
- **Output:** `data/processed/nlss_analysis_ready.dta`

### 03_descriptive_analysis.do (~5 min)
- Generates Table 1 (household characteristics)
- Generates Table 2 (coping strategy counts by NCD status)
- Produces descriptive statistics by quintile and location
- **Outputs:** 
  - `output/tables/Table1_Characteristics.rtf`
  - `output/tables/Table2_Strategy_Count.rtf`

### 04_main_analysis.do (~15 min)
- Runs double-hurdle model with ERM endogeneity correction
- Generates Table 3 (main regression results)
- Produces Figure 3 (average marginal effects plot)
- **Outputs:**
  - `output/tables/Table3_Main_Results.rtf`
  - `output/figures/Figure3_Marginal_Effects.png`

### 05_robustness_checks.do (~20 min)
- ZIP/ZINB model comparison
- Multiple imputation (MICE) sensitivity
- Recall-restricted analysis
- Weighted model comparison
- **Outputs:** Multiple supplementary tables in `output/tables/supplementary/`

### 06_upset_plots.R (~5 min)
- Creates UpSet plots showing coping strategy combinations
- Separate plots for NCD vs non-NCD households
- **Outputs:**
  - `output/figures/Figure1_UpSet_All_Households.png`
  - `output/figures/Figure2A_UpSet_NCD_Households.png`
  - `output/figures/Figure2B_UpSet_NonNCD_Households.png`

---

## Key Variables

### Outcome Variables
- **coping_participation**: Binary (1=used any coping strategy)
- **coping_count**: Count (0-10 strategies used)

### Coping Strategies (Binary)
1. `redfood` - Reduced food consumption
2. `rednonfood` - Reduced non-food consumption  
3. `inf_ass` - Received informal assistance
4. `loan` - Obtained loans/credit
5. `work_add` - Engaged in additional work
6. `saving` - Financed from savings
7. `borrow` - Borrowed from family/friends
8. `sale` - Sold assets
9. `child_disp` - Withdrew children from school
10. `form_ass` - Received formal assistance

### Key Explanatory Variables
- **ncd**: Household has ≥1 member with NCD
- **cred_access**: Access to credit facilities
- **insur**: Contribution to NHIS
- **assist**: Received safety net assistance

See `data/variable_codebook.md` for complete variable definitions.

---

## Main Findings

### Participation Decision (First Hurdle)
- **68.65%** of households adopted coping strategies
- NCD households **8% more likely** to participate (p<0.01)
- Health insurance **reduced participation by 12%** (p<0.05)
- Access to credit **increased participation by 26%** (p<0.01)

### Strategy Count (Second Hurdle)  
- Average **3.49 strategies** per household (SD±1.48)
- NCD households used **20% more strategies** (3.65 vs 3.29, p<0.05)
- Credit access **increased count by 53%** (p<0.01)
- Poorest households **42% fewer strategies** (p<0.001)

### Strategy Combinations
- Most common: Reduced food (61%), Informal assistance (57.8%), Reduced non-food (52.3%)
- NCD households showed greater diversification, often layering maladaptive financial strategies

---

## Computational Requirements

### Hardware
- **Minimum:** Intel i5 or equivalent, 8GB RAM, 10GB storage
- **Recommended:** Intel i7, 16GB RAM, SSD

### Software Licenses
- **Stata:** Commercial license required (SE/MP/IC versions supported)
- **R:** Free and open-source

### Runtime Summary
| Script | Time | CPU Intensive? |
|--------|------|----------------|
| Data cleaning | ~5 min | No |
| Variable construction | ~3 min | No |
| Descriptive analysis | ~5 min | No |
| Main models | ~15 min | Yes (ERM iterations) |
| Robustness checks | ~20 min | Yes (MI, bootstrapping) |
| UpSet plots | ~5 min | No |
| **TOTAL** | **~50 min** | |

---

## Troubleshooting

### Common Issues

**Problem:** "File not found" error  
**Solution:** Ensure working directory is set correctly and data files are in `data/raw/`

**Problem:** Missing Stata packages  
**Solution:** Run `ssc install [package_name]` for each required package

**Problem:** R packages won't install  
**Solution:** 
```r
# Update R to latest version
# Then try:
install.packages("remotes")
remotes::install_version("UpSetR", version = "1.4.0")
```

**Problem:** Memory error in Stata  
**Solution:** 
```stata
clear all
set maxvar 10000
set matsize 800
```

**Problem:** UpSet plots don't generate  
**Solution:** Check that `health_strategies.xls` exists in working directory

---

## Citation

If you use this code or data, please cite:

```bibtex
@article{odunyemi2024coping,
  title={Decisions and Dilemmas: Comparing How Nigerian Households with and without 
         Non-communicable Diseases Combine Coping Strategies in Response to Health Shocks},
  author={Odunyemi, Adelakun and Sohrabi, Hamid and Alam, Khurshid},
  journal={[Journal Name]},
  year={2024},
  note={Replication code available at: https://github.com/[username]/health-shocks-coping-nigeria}
}
```

And the data source:
```bibtex
@data{worldbank2020nlss,
  title={Nigeria Living Standards Survey 2018-2019},
  author={{National Bureau of Statistics Nigeria} and {World Bank}},
  year={2020},
  publisher={World Bank Microdata Library},
  url={https://microdata.worldbank.org/index.php/catalog/3827}
}
```

---

## License

This code is licensed under the **MIT License** - see LICENSE file for details.

**Summary:** You are free to use, modify, and distribute this code with attribution.

**Data:** The NLSS data is subject to World Bank data use terms. See data access instructions above.

---

## Contact

**Questions about the code or analysis:**
- **Email:** adelakun.odunyemi@murdoch.edu.au
- **GitHub Issues:** [Open an issue](https://github.com/[username]/health-shocks-coping-nigeria/issues)

**Questions about the paper:**
- Contact corresponding author (above)

---

## Acknowledgments

- Nigeria's National Bureau of Statistics for conducting the NLSS
- World Bank for providing data access
- Murdoch University for doctoral scholarship support
- Reviewers and editors for constructive feedback

---

## Version History

**v1.0.0** (December 2024)
- Initial release
- Includes all replication code for submitted manuscript

---

## Additional Resources

- **Paper preprint:** [Link when available]
- **Project OSF page:** [Link if applicable]
- **Related publications:** See author profiles on [Google Scholar](https://scholar.google.com/)

---

**Last Updated:** December 2024  
**Repository Status:** ✅ Active and maintained