# Gender_Wage_Gap

Gender wage gap analysis using machine learning (generalized random forests) and causal inference methods, applied to the 2018 US Census PUMS/ACS data.
Authors: Rob Dunne, Ainura Tursunalieva.

## What we do

The raw gender wage gap compares the average wage of men and women. It does not say how much of the gap remains when men and women are compared who are alike in age,
education, marital status, children, occupation and so on, and in the part of the population where both genders are actually found. We treat gender as the "treatment"
(`W = 1` for male) and the log of the hourly wage as the outcome, and estimate the gap with causal forests (the `grf` package), including how it varies across people.
The estimates are checked against simpler tools: inverse-probability weighting, doubly robust (AIPW) estimates, and an Oaxaca-Blinder decomposition.

The data are 1,061,763 full-time employees from the 2018 American Community Survey (the analysis uses the 659,436 aged 26 to 53). The results are for the United States.

## Main results

- The raw (difference-in-means) gap in log wage is about 0.18, so men earn about 19% more.
- Where men and women can be compared directly (the middle propensity segment, about 87% of the sample), the covariate-adjusted gap from the causal forest is about 0.13, or about 14%.
- The gap is far from uniform. It is much smaller for people who have never married than for the married, it grows with age for the married and with the number of children (up to about three), and it is smaller for the more educated.
- An Oaxaca-Blinder decomposition explains only about 19% of the raw gap with all the covariates (including occupation and industry). The remainder is unexplained.
- The workforce is segregated: the low-propensity segment is 95% women and the high-propensity segment 97% men, and the segments differ in their occupations and industries (Supplementary 4).

The numbers come from the run of October 2026; the exact figures, with standard errors, are in `Supplementary_N_results.Rdata` and the reports.

## Main files

| File | What it is |
|------|------------|
| `report.Rmd` | The full report (numbers read from the saved results) |
| `report_brief.Rmd`, `report_beamer.Rmd` | A short report, and a slide deck |
| `Supplementary_1_...Rmd` | Reads the raw PUMS data and prepares the analysis data sets |
| `Supplementary_2_...Rmd` | The analysis sample, the weights, the first causal forest, and the propensity segments |
| `Supplementary_3_Analysis.Rmd` | The main causal analysis: estimators, calibration, heterogeneity of the gap |
| `Supplementary_4_segregated_workforce.Rmd` | The three propensity segments; occupation and industry segregation |
| `Supplementary_5_Oaxaca-Blinder_Decomposition.Rmd` | Oaxaca-Blinder decomposition, compared with the forest |
| `Supplementary_10_...Rmd` | Background on causal analysis (no computations) |
| `weights.Rmd`, `handling_categorical_variables.Rmd` | Side studies: do the Census weights matter; how to code the categorical variables |
| `Instructions.Rmd` | What every file and directory is, and how to run it all |
| `cleanup.Rmd` | Shell commands to clean up, archive, and regenerate everything in order |
| `Discussion.Rmd` | Review notes on the pipeline and open problems |

To regenerate the analysis, run Supplementary 1 and then 2, then 3, 4 and 5 (each with `Rscript -e 'rmarkdown::render("<file>")'`); the details, the HPC settings and the
unit tests are in `Instructions.Rmd`. The raw data file (`wage_data.Rdata`) is not in the repository.

## What happens to the data along the way

The categorical variables are coded once, in Supplementary 1 (chunk `order_levels`): the levels of race, citizenship, marital, economic_region, occupation
and industry are put in increasing order of mean log wage, on the full sample of 1,061,763, and replaced by the numbers 1, ..., k (hispanic_origin
and nativity become 0/1 in chunk `recode_binary`). No later file changes the codes. Because the order is set on the full sample, a higher code need not
mean a higher mean wage in the age-restricted or trimmed samples used later. The maps from code to level are in `variable_mappings.Rdata`.

| File | What it does to the data | What it saves (in `processing_files/`) |
|---|---|---|
| Supp 1 | Selects age 17 or more, more than 48 weeks, more than 16 hours, employed, not self-employed; drops `children == -1` (the missing-value code); builds `log_wage`; orders and codes the factors | `X_ordered_numeric_1061763_industry_269.Rdata` (the main data); `Xtrain_500000_20.Rdata` (a separate factor version: a sample of 500,000, 23 occupations, 20 industries, region "Abroad" dropped); the mapping files |
| Supp 2 | Caps the weights at the 95th percentile; keeps ages 26 to 53 (659,436 people); estimates the propensities and splits the sample into low / middle / high segments at 0.1 and 0.9 | `numeric_age_truncated_data.Rdata`, `capped_weights_segregated_workforce.Rdata`, `X_age_truncated_data.Rdata` (not loaded by any file) |
| Supp 3 | Uses the middle segment as it is | `forest_tau.rds` (in the project directory) and the results file |
| Supp 4 | Uses the three segments as they are | results and figures only |
| Supp 5 | Builds its regression variables in memory: age centred and scaled, children capped at 4, family size at 6, rare levels merged into "other" | results and figures only |
| `weights.Rmd`, `handling_categorical_variables.Rmd` | Apply the 26 to 53 age filter in memory | results only |

`processing_files/` is git-ignored and exists only where the pipeline has been run (the HPC). The region "Abroad" (place of work outside the US) is
dropped only from `Xtrain_500000_20.Rdata`; the main data keep it as one of the 9 levels of economic_region.

## Reference

Dunne, R. (2025). Gender wage gap analysis using machine learning methods. In S. M. Cuddy, K. Holland, J. Boland, S. Westra and O. Batelaan (eds),
*Proceedings of the 26th International Congress on Modelling and Simulation (MODSIM2025)*. Modelling and Simulation Society of Australia and New Zealand Inc. (MSSANZ), November 2025.
ISBN 978-0-9758400-0-9, ISSN 2981-8001. https://doi.org/10.36334/modsim2025.D01.dunne
