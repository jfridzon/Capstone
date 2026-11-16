# Stepwise variable selection by AIC inside each training fold (Mark). Starts the step the professor
# asked for AFTER the 48 x 7 table: "variable selection because of the risk of overfitting".
# It is NOT part of the demo of 16/11. It does not change any other file or function.
#
# How to run it in RStudio, from the repo root (Session > Set Working Directory > To Project):
#   source("R/18_stepwise.R")      # about 1 to 2 minutes
#
# What is predicted (the response) and with what (the predictors), the same as the 48 x 7 table:
#   response   : won = 1 if the model won the vote, 0 if it lost (votes with a winner only)
#   predictors : the 11 characteristics of the question, all known BEFORE the model answers.
#                The length of the answer is never used.
#   model      : 1 logistic regression per model, 48 in total.
#
# What this script does, for each of the 48 models and for each of the 5 folds:
#   1. Fit the full regression, glm(won ~ 11 characteristics, family = binomial), with the 4 training folds.
#   2. Run step() on it: backward selection by AIC (k = 2). It drops one characteristic at a time
#      while the AIC gets lower. step() only sees the training folds.
#   3. Measure the AUC with pROC on the fold left out, with the same folds as the 48 x 7 table
#      (R/resultados/auc/folds_5.csv, made by session, set.seed(2026)). The test fold is never used to choose.
#   4. Count how many characteristics stay.
# For comparison, the full regression (no selection) is also measured on the same test fold. Its AUC must
# match the saved table R/resultados/auc/por_modelo.csv: the script checks it.
#
# Not here (the professor asked for it later): one single model with the same variables for all.

library(pROC)

# ---- 1. Data: the same votes as R/14 and R/15 ---------------------------------------------------------
features <- c("is_code", "math", "creative_writing", "instruction_following",
              "complexity", "creativity", "domain_knowledge", "problem_solving",
              "real_world", "specificity", "technical_accuracy")
base <- read.csv(gzfile("data/derivados/base_regresiones_2026-10-28_v2.csv.gz"), stringsAsFactors = FALSE)
for (x in features) base[[x]] <- as.logical(base[[x]])
votes <- base[!base$requiere_revision & base$es_decisivo, ]        # votes with a winner
stopifnot(!anyNA(votes[c("won", features)]), all(votes$won %in% c(0, 1)))

folds <- read.csv("R/resultados/auc/folds_5.csv", stringsAsFactors = FALSE)   # made once, not remade here
votes$fold <- folds$fold[match(votes$id, folds$id)]
stopifnot(!anyNA(votes$fold))

models <- sort(unique(votes$model))
stopifnot(length(models) == 48L)
cat("Votes with a winner:", length(unique(votes$id)), "| models:", length(models), "| folds: 5\n")

full_formula <- as.formula(paste("won ~", paste(features, collapse = " + ")))

# ---- 2. Small helpers ----------------------------------------------------------------------------------
n_warnings <- 0L   # glm() can warn when a fit gets close to perfect; we count them instead of hiding them
quietly <- function(expr) withCallingHandlers(expr, warning = function(w) {
  n_warnings <<- n_warnings + 1L
  invokeRestart("muffleWarning")
})

# AUC of a fitted glm on the test rows, with pROC. NA if the test has only 1 class (pROC cannot do it).
auc_on <- function(fit, test) {
  if (length(unique(test$won)) < 2L) return(NA_real_)
  score <- predict(fit, newdata = test, type = "link")
  as.numeric(pROC::auc(pROC::roc(test$won, score, levels = c(0, 1), direction = "<", quiet = TRUE)))
}

# ---- 3. The loop: 48 models x 5 folds -------------------------------------------------------------------
cat("\n=== Stepwise by AIC inside each training fold: 48 models x 5 folds = 240 fits ===\n")
filas <- vector("list", length(models) * 5L)
k <- 0L
for (m in models) {
  d <- votes[votes$model == m, ]
  for (f in 1:5) {
    train <- d[d$fold != f, ]          # the 4 other folds: the regression and step() learn here
    test  <- d[d$fold == f, ]          # the fold left out: only used to measure
    stopifnot(length(intersect(train$evaluation_session_id, test$evaluation_session_id)) == 0L)

    full <- quietly(glm(full_formula, family = binomial, data = train))
    sw   <- quietly(step(full, direction = "backward", k = 2, trace = 0))   # AIC, on the training folds only
    stopifnot(full$converged, sw$converged)

    kept <- setdiff(names(coef(sw)), "(Intercept)")
    # glm() names a logical predictor "<name>TRUE"; take the TRUE off to get the characteristic
    kept <- sub("TRUE$", "", kept)
    k <- k + 1L
    filas[[k]] <- data.frame(model = m, fold = f, n_train = nrow(train), n_test = nrow(test),
                             variables_kept = length(kept),
                             kept = paste(kept, collapse = " "),
                             auc_stepwise = auc_on(sw, test),
                             auc_full = auc_on(full, test),
                             stringsAsFactors = FALSE)
  }
}
by_fold <- do.call(rbind, filas)
cat("Done.", nrow(by_fold), "fits. glm() warnings counted (not shown):", n_warnings, "\n")
cat("Model/fold pairs with no AUC (test with 1 class):", sum(is.na(by_fold$auc_stepwise)), "\n")

# ---- 4. Check: the full regression must give the saved 48 x 7 table -------------------------------------
saved <- read.csv("R/resultados/auc/por_modelo.csv", stringsAsFactors = FALSE)
saved <- saved[saved$scenario == "cv5" & saved$fold %in% 1:5, ]
saved$key <- paste(saved$model, saved$fold)
by_fold$key <- paste(by_fold$model, by_fold$fold)
same <- all(abs(round(by_fold$auc_full, 4) - saved$auc[match(by_fold$key, saved$key)]) < 1e-9, na.rm = TRUE)
cat("The full regression gives the same AUC as R/resultados/auc/por_modelo.csv in all", nrow(by_fold), "cells:", same, "\n")
by_fold$key <- NULL
stopifnot(same)

# ---- 5. Tables ----------------------------------------------------------------------------------------------
# 48 x 7 for stepwise, like the table of the professor: folds 1 to 5, mean of the 5, and the same for the full model
wide <- function(col) {
  w <- reshape(by_fold[c("model", "fold", col)], idvar = "model", timevar = "fold", direction = "wide")
  w <- w[match(models, w$model), ]
  out <- w[paste0(col, ".", 1:5)]
  names(out) <- paste0("Fold_", 1:5)
  out$Mean_CV <- rowMeans(out)
  rownames(out) <- models
  out
}
auc_stepwise_48x6 <- wide("auc_stepwise")
auc_full_48x6     <- wide("auc_full")
kept_48x6         <- wide("variables_kept")
names(kept_48x6)[6] <- "Mean_kept"

summary_by_model <- data.frame(
  model = models,
  auc_cv_full     = round(auc_full_48x6$Mean_CV, 4),
  auc_cv_stepwise = round(auc_stepwise_48x6$Mean_CV, 4),
  difference      = round(auc_stepwise_48x6$Mean_CV - auc_full_48x6$Mean_CV, 4),
  variables_kept_mean = round(kept_48x6$Mean_kept, 2),
  variables_kept_min  = as.integer(tapply(by_fold$variables_kept, by_fold$model, min)[models]),
  variables_kept_max  = as.integer(tapply(by_fold$variables_kept, by_fold$model, max)[models]),
  row.names = NULL)

cat("\n=== 1. AUC per model in the 5 test folds: full regression vs stepwise, and how many of the 11 stay ===\n")
print(summary_by_model, row.names = FALSE)

cat("\n=== 2. Average over the 48 models ===\n")
resumen <- data.frame(
  auc_cv_full         = mean(auc_full_48x6$Mean_CV),
  auc_cv_stepwise     = mean(auc_stepwise_48x6$Mean_CV),
  variables_kept_mean = mean(by_fold$variables_kept),
  models_stepwise_better = sum(summary_by_model$difference > 0),
  models_stepwise_worse  = sum(summary_by_model$difference < 0),
  models_equal           = sum(summary_by_model$difference == 0))
print(transform(resumen, auc_cv_full = round(auc_cv_full, 4), auc_cv_stepwise = round(auc_cv_stepwise, 4),
                variables_kept_mean = round(variables_kept_mean, 2)), row.names = FALSE)

cat("\n=== 3. How often each characteristic stays (out of", nrow(by_fold), "stepwise fits) ===\n")
freq <- sapply(features, function(v) sum(vapply(strsplit(by_fold$kept, " ", fixed = TRUE), function(s) v %in% s, logical(1))))
freq_tab <- data.frame(characteristic = features, times_kept = as.integer(freq),
                       percent = round(100 * freq / nrow(by_fold), 1), row.names = NULL)
print(freq_tab[order(-freq_tab$times_kept), ], row.names = FALSE)

# ---- 6. Save ------------------------------------------------------------------------------------------------
out_dir <- "R/resultados/stepwise_2026-11-16"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(by_fold, file.path(out_dir, "por_modelo_y_fold.csv"), row.names = FALSE)
write.csv(summary_by_model, file.path(out_dir, "resumen_por_modelo.csv"), row.names = FALSE)
write.csv(freq_tab, file.path(out_dir, "frecuencia_variables.csv"), row.names = FALSE)
writeLines(c(R.version.string, paste("pROC", as.character(packageVersion("pROC"))),
             "stepwise: step(glm, direction = 'backward', k = 2), inside each training fold; folds from folds_5.csv"),
           file.path(out_dir, "versiones.txt"))
cat("\nSaved in", out_dir, "\n")
if (interactive()) View(summary_by_model, title = "Stepwise vs full regression, 48 models")
