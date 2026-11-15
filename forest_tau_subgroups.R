# forest_tau_subgroups.R
#
# Proper doubly-robust gap-by-marital-status estimates from the saved PUMS causal forest, for the HILDA comparison.
#
# The figure in Supplementary_3 (and the PUMS side of HILDA/compare_plots.R) used the *group means of tau.hat* with an
# interval of sd(tau.hat)/sqrt(n). That interval describes only the spread of the per-person predictions within a
# group; it ignores the estimation error of the forest, so it is far too narrow. The honest subgroup estimate is the
# AIPW average treatment effect on that subset -- average_treatment_effect(forest.tau, subset = <group>) -- which is
# what the HILDA side computes for its own subgroups. This script produces those, so the two sides are compared like
# for like.
#
# Run it where forest_tau.rds lives and there is enough memory to load it (about 4 GB on disk, more in memory -- the
# HPC, not a laptop). It needs only grf and the forest; it does not refit anything (average_treatment_effect reuses the
# stored Y.hat/W.hat/predictions, so it is quick once the forest is loaded).
#
#   Rscript forest_tau_subgroups.R [forest_tau.rds] [forest_tau_subgroups.rds]
#   FOREST_TAU=~/forest_tau.rds Rscript forest_tau_subgroups.R      # path also via env
#
# Output: forest_tau_subgroups.rds -- a small list(marital, importance, overall, meta). scp it back to the laptop and
# Supplementary_3_figures_for_comparison.R folds it into pums_plot_data_cmp.rds.

suppressMessages(library(grf))

args     <- commandArgs(trailingOnly = TRUE)
in_path  <- if (length(args) >= 1) args[1] else Sys.getenv("FOREST_TAU", "forest_tau.rds")
out_path <- if (length(args) >= 2) args[2] else "forest_tau_subgroups.rds"
in_path  <- path.expand(in_path)

cat("Loading", in_path, "...\n"); flush.console()
t0 <- Sys.time()
f  <- readRDS(in_path)
cat("  loaded in", round(difftime(Sys.time(), t0, units = "secs"), 1), "s; n =", nrow(f$X.orig), "rows\n")
stopifnot("marital" %in% colnames(f$X.orig))

mar     <- f$X.orig[, "marital"]
tau.hat <- f$predictions                      # the per-person CATE, as the old figure used
labs    <- c("Never married", "Separated", "Widowed", "Divorced", "Married")   # marital codes 1..5
codes   <- 1:5

# --- doubly-robust ATE on each marital subset (the honest estimate), with the plug-in shown alongside for contrast ---
rows <- lapply(seq_along(codes), function(i) {
  k   <- codes[i]
  sel <- mar == k
  a   <- average_treatment_effect(f, target.sample = "all", subset = sel)   # AIPW, proper SE
  n_k <- sum(sel)
  plug_est <- mean(tau.hat[sel])                       # old point estimate: group mean of tau.hat
  plug_se  <- sd(tau.hat[sel]) / sqrt(n_k)             # old (too-narrow) SE
  data.frame(status = labs[i], marital_code = k, n = n_k,
             estimate = unname(a["estimate"]), se = unname(a["std.err"]),
             plugin_estimate = plug_est, plugin_se = plug_se)
})
marital <- do.call(rbind, rows)
marital$ci_lower <- marital$estimate - 1.96 * marital$se
marital$ci_upper <- marital$estimate + 1.96 * marital$se

# --- variable importance from this final run (live, to replace the copied numbers in the comparison script) ---
vi <- as.numeric(variable_importance(f))
names(vi) <- colnames(f$X.orig)
importance <- sort(vi, decreasing = TRUE)

# --- overall ATEs, for the record / sanity (report: control 0.126, overlap 0.133, all 0.138) ---
overall <- sapply(c("all", "control", "overlap"),
                  function(s) average_treatment_effect(f, target.sample = s))
colnames(overall) <- c("all", "control", "overlap")

meta <- sprintf("forest_tau.rds, %d rows, 2000 trees; average_treatment_effect(subset) per marital group; %s",
                nrow(f$X.orig), format(Sys.Date()))

saveRDS(list(marital = marital, importance = importance, overall = overall, meta = meta), out_path)

cat("\n--- overall ATE (sanity vs report: all 0.138, control 0.126, overlap 0.133) ---\n")
print(round(overall, 4))
cat("\n--- gap by marital status: doubly-robust vs the old plug-in interval ---\n")
show <- data.frame(status = marital$status, n = marital$n,
                   DR_est = round(marital$estimate, 4),  DR_se = round(marital$se, 4),
                   plugin_est = round(marital$plugin_estimate, 4), plugin_se = round(marital$plugin_se, 5))
show$se_ratio <- round(show$DR_se / show$plugin_se, 1)
print(show, row.names = FALSE)
cat("\nThe DR standard error is", round(mean(show$se_ratio), 0),
    "x the plug-in one on average -- that is how much too narrow the old interval was.\n")
cat("\nWrote", out_path, "\n")
