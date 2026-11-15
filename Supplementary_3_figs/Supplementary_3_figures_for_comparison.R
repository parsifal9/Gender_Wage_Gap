# Supplementary_3_figures_for_comparison.R
#
# Collects the numbers behind four Supplementary 3 figures in one small file, so that the HILDA project can draw the
# PUMS and HILDA versions side by side in the same style (HILDA/compare_plots.R). It does not draw or change any
# existing figure, and it does not run a forest.
#
# The numbers are copied from Supplementary_3_checks.txt (the run of 15 October 2026), because the objects they come
# from (variable_importance(forest.tau), the balance means, tau.hat) are not saved by Supplementary_3_Analysis.Rmd and
# the forest cannot be refitted on this machine. The figures in Supplementary_3_figs/ were drawn from the run of
# 20 October, whose importance values differ from these in the third decimal place (marital 0.634 in the report text,
# 0.637 here). To make the file from the final run, replace the three tables below with the objects from that run:
#   importance <- var_imp;  balance <- abs.mean.diff / std and abs.mean.diff.adj / std.adj;
#   marital    <- plot_data (estimate, ci_lower, ci_upper).
#
# Since 15 November 2026 the forest is saved (forest_tau.rds, see Supplementary_3_Analysis.Rmd). When
# Supplementary_3_figs/forest_tau_subgroups.rds (made from it by forest_tau_subgroups.R) is present, the marital gaps and
# the importance below are replaced by the doubly robust and live values from that forest; the balance table is still
# the copied one.
#
# The propensity score histogram is not here: its values are not recorded anywhere, so the comparison uses the existing
# figure Supplementary_3_figs/propensities_capped_weights_age_trimmed.png.
#
# Run from the repository root:  Rscript Supplementary_3_figs/Supplementary_3_figures_for_comparison.R
# Output: Supplementary_3_figs/pums_plot_data_cmp.rds

# variable importance of the causal forest (13 covariates, sums to 1)
importance <- c(marital = 0.6369, education_level = 0.1143, age = 0.1026, children = 0.0501, occupation = 0.0258,
                family_size = 0.0193, industry = 0.0148, race = 0.0120, economic_region = 0.0080,
                english_level = 0.0073, citizenship = 0.0040, hispanic_origin = 0.0037, nativity = 0.0011)

# absolute standardised mean differences, men against women (pooled SD), before and after propensity adjustment
balance <- data.frame(
  variable   = c("age", "race", "hispanic_origin", "citizenship", "nativity", "marital", "family_size", "children",
                 "education_level", "english_level", "economic_region", "occupation", "industry"),
  unadjusted = c(0.009, 0.055, 0.004, 0.066, 0.028, 0.032, 0.040, 0.067, 0.108, 0.011, 0.006, 0.133, 0.091),
  adjusted   = c(0.016, 0.020, 0.009, 0.024, 0.000, 0.006, 0.021, 0.038, 0.016, 0.009, 0.005, 0.008, 0.005))

# gap by marital status: group means of tau.hat, with the sd and n of tau.hat in each group
marital <- data.frame(
  status = c("Never married", "Separated", "Widowed", "Divorced", "Married"),
  estimate = c(0.06603899, 0.16009912, 0.16088139, 0.15360015, 0.17022057),
  sd = c(0.05468699, 0.05364603, 0.05479210, 0.05746995, 0.07620715),
  n = c(154932, 10703, 3603, 59152, 338476))
# the interval of Supplementary_3_Analysis.Rmd: the standard error of each mean is sd / sqrt(n), and that of a
# non-reference group is combined with the one of the reference group (never married): sqrt(se1^2 + se_k^2),
# where se_k is the standard error of the difference. It is a rough interval (it ignores the covariance).
se_mean <- marital$sd / sqrt(marital$n)
se_diff <- sqrt(se_mean[-1]^2 + se_mean[1]^2)
se_plot <- c(se_mean[1], sqrt(se_mean[1]^2 + se_diff^2))
marital$ci_lower <- marital$estimate - 1.96 * se_plot
marital$ci_upper <- marital$estimate + 1.96 * se_plot
pums_source <- "Supplementary_3_checks.txt, run of 2026-10-15; n = 566,866 (ages 26-53, propensity 0.1 to 0.9); marital interval is sd/sqrt(n) (too narrow)"

# If the doubly-robust subgroup file is present (made by forest_tau_subgroups.R on the saved forest), use its honest
# marital intervals -- average_treatment_effect(forest.tau, subset = group) -- and its live variable importance, in
# place of the copied numbers above. This is the apples-to-apples version: the HILDA side estimates its subgroups the
# same way. scp forest_tau_subgroups.rds into Supplementary_3_figs/ first; without it the script falls back to the copied numbers.
dr_path <- Sys.getenv("FOREST_TAU_SUBGROUPS", "Supplementary_3_figs/forest_tau_subgroups.rds")
if (file.exists(dr_path)) {
  dr <- readRDS(dr_path)
  marital <- data.frame(status = dr$marital$status, estimate = dr$marital$estimate, se = dr$marital$se,
                        n = dr$marital$n, ci_lower = dr$marital$ci_lower, ci_upper = dr$marital$ci_upper)
  importance  <- dr$importance                       # live, sorted, sums to 1
  pums_source <- paste0("marital and importance: doubly-robust / live from ", dr$meta,
                        "; balance: Supplementary_3_checks.txt, run of 2026-10-15 (n = 566,866)")
  cat("Using doubly-robust marital intervals and live importance from ", dr_path, "\n")
} else {
  cat("No ", dr_path, " found; using the copied (too-narrow) marital interval and copied importance.\n", sep = "")
}

# Never married has the smallest gap in both orderings. Married is the largest among the plug-in group means, but under
# the doubly-robust estimate the small "Separated" group edges above it (with a wide interval), so only the minimum is
# asserted here.
stopifnot(abs(sum(importance) - 1) < 0.002, all(names(importance) %in% balance$variable),
          which.min(marital$estimate) == 1)

saveRDS(list(importance = importance, balance = balance, marital = marital, source = pums_source),
        "Supplementary_3_figs/pums_plot_data_cmp.rds")
print(marital)
