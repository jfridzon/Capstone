# AUC with pROC: the 48 binomial regressions vs the general ranking (phase 2b, task B, Mark)
# Issue #32. Run from the repo root: source("R/11_auc_proc.R")   (needs the pROC package)
#
# What the professor asked on 4/11 (docs/14-fase-2b.md): AUC computed with pROC, first with
# ALL the data, then train/test (April to June / July) to see if it is similar, then 5-fold
# cross-validation with the AUC of each fold. Logistic regression, family = binomial.
#
# Model: the same 48 regressions of R/02 (1 per model, 11 characteristics of the question),
#   glm(y ~ is_code + math + ... + technical_accuracy, family = binomial)
# fitted on DECISIVE votes only (y = 1 if the model won, 0 if it lost). Ties and both_bad are
# not used here. The 28 votes Nessim flagged for review stay out, like in R/02 and R/03.
#
# 2 kinds of AUC, both with pROC::roc() and pROC::auc():
#   per model: the AUC of each regression on its own rows (that model won = 1 / lost = 0).
#              Score = the regression's own P(win) for that question.
#   per vote : P(model_a wins) = plogis(score_A - score_B), where each score is that model's
#              own regression evaluated with the characteristics of the question. It is
#              compared with whether model_a really won.
#
# Baseline in all cases: the general ranking = general win rate of each model (votes won /
# votes played, all types of question together), computed in the same rows used to fit the
# regressions. Per vote it is plogis(logit(rate_A) - logit(rate_B)), the same baseline as
# R/03. Per model, the baseline score of a row is logit(rate_model) - logit(rate_rival): the
# general ranking's own P(that model beats that rival). (The model's own rate is the same in
# all its rows, so alone it would give AUC = 0.5 by construction.)
#
# 3 scenarios, in this order:
#   all_data   : fit and measure on all the decisive votes (April to July). In-sample.
#   train_test : fit on train (before 1/7/2025) and measure in train (in-sample) and in
#                July (never seen). Same split and same 20,416 July votes as R/03.
#   cv5        : 5-fold cross-validation over ALL the data, folds made by session (a session
#                is never split), same fold rule and seed as the ridge CV in R/03. The AUC of
#                each fold is measured on the held-out fold, with the regressions and the
#                baseline fitted on the other 4 folds.
#
# Output (R/resultados/auc/):
#   por_voto.csv    AUC per vote: regression vs baseline, DeLong 95% CI and paired DeLong test
#   por_modelo.csv  AUC per model (48 rows per scenario/set; NA if it cannot be computed)
#   folds.csv       AUC of each fold of cv5 (per vote and mean of the per-model AUCs) + mean, sd
#   curva_roc_julio.png / curva_roc_julio.csv   ROC curve of the July votes (per vote)
#
# p-values and CIs are nominal: the same models repeat in many votes and every vote is used
# twice when fitting (the professor knows, docs/04). Base R + pROC only.

library(pROC)
options(width = 200)   # wider console output, so the tables printed at the end do not wrap

# ---- Settings ---------------------------------------------------------------

in_split   <- "R/resultados/split_train_test.csv"   # split of R/03 (train < 1/7/2025)
out_folder <- "R/resultados/auc"
k_folds    <- 5
seed       <- 1          # same seed and fold rule as cv_lambda() in R/03_evaluacion.R
dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)

# ---- 1. Functions of R/02 (loaded without refitting everything) --------------------
# R/02 is loaded into its own environment so its objects do not overwrite ours.
# `correr_02 = FALSE` loads only its functions.

env02   <- new.env()
old_opt <- options(correr_02 = FALSE)
sys.source("R/02_regresiones_por_modelo.R", envir = env02)
options(old_opt)

predictors <- env02$predictores   # the 11 characteristics, all known BEFORE the answer

# ---- 2. Data ----------------------------------------------------------------------
# Nessim's long base (docs/10): 2 rows per vote, 1 per model (lado = model_a / model_b).

long_base <- env02$cargar_base()
split     <- read.csv(in_split, stringsAsFactors = FALSE)
long_base$split <- split$split[match(long_base$id, split$id)]
stopifnot(!anyNA(long_base$split))

# Decisive votes only, y = won (1/0). The 28 flagged votes are left out (all in train).
d <- env02$preparar_respuesta(long_base, politica = "excluir")
stopifnot(all(d$y %in% c(0, 1)), all(d$es_decisivo))

all_models <- sort(unique(d$model))
cat("Decisive vote rows:", nrow(d), "=", nrow(d) / 2, "votes |",
    "models:", length(all_models), "\n")
cat("Train votes:", sum(d$split == "train") / 2, "| July votes:", sum(d$split == "test") / 2, "\n")

# ---- 3. Fit, score, AUC ------------------------------------------------------------

# The 48 regressions (R/02) + the general win rate of each model, from the same rows.
# R/02 chooses binomial by itself when y is only 0/1; here it is checked.
fit_set <- function(rows) {
  fits <- env02$ajustar_modelos(rows)   # lambda = 0 -> plain glm()
  stopifnot(all(vapply(fits, function(f) f$converged && f$family$family == "binomial",
                       logical(1))))
  list(fits = fits, rate = tapply(rows$y, rows$model, mean))
}

# Scores for the rows `ev` (long rows). Rows where the model or its rival has no regression
# are dropped (they are the July-only models when fitting on train).
score_rows <- function(m, ev) {
  ev <- ev[ev$model %in% names(m$fits) & ev$rival %in% names(m$fits), ]
  x  <- ev[predictors]
  p_own   <- env02$probabilidad(m$fits, ev$model, x)   # P(this model wins), its own regression
  p_rival <- env02$probabilidad(m$fits, ev$rival, x)   # rival's regression, same question
  stopifnot(!anyNA(p_own), !anyNA(p_rival), p_own > 0, p_own < 1, p_rival > 0, p_rival < 1)
  ev$p_own      <- p_own
  ev$score_vote <- qlogis(p_own) - qlogis(p_rival)     # logit of P(model_a wins)
  ev$score_base <- qlogis(m$rate[ev$model]) - qlogis(m$rate[ev$rival])
  ev
}

# pROC with the direction fixed: higher score = more likely to win (cases = 1).
roc_of <- function(y, score) {
  if (length(y) < 2 || length(unique(y)) < 2) return(NULL)
  pROC::roc(response = y, predictor = score, levels = c(0, 1), direction = "<", quiet = TRUE)
}
auc_of <- function(r) if (is.null(r)) NA_real_ else as.numeric(pROC::auc(r))

# AUC per vote: rows with lado == "model_a" (1 row per vote).
auc_per_vote <- function(m, ev, scenario, set, fold = NA) {
  votes <- ev[ev$lado == "model_a", ]
  v     <- score_rows(m, votes)
  r_reg  <- roc_of(v$y, plogis(v$score_vote))   # P(model_a wins) = plogis(score_A - score_B)
  r_base <- roc_of(v$y, plogis(v$score_base))
  ci_reg  <- as.numeric(pROC::ci.auc(r_reg,  method = "delong"))   # low, auc, high
  ci_base <- as.numeric(pROC::ci.auc(r_base, method = "delong"))
  test    <- pROC::roc.test(r_reg, r_base, method = "delong", paired = TRUE)
  list(row = data.frame(scenario = scenario, set = set, fold = fold,
                        n_votes = nrow(v), n_votes_left_out = nrow(votes) - nrow(v),
                        auc_regression = auc_of(r_reg),
                        auc_regression_ci_low = ci_reg[1], auc_regression_ci_high = ci_reg[3],
                        auc_baseline = auc_of(r_base),
                        auc_baseline_ci_low = ci_base[1], auc_baseline_ci_high = ci_base[3],
                        auc_difference = auc_of(r_reg) - auc_of(r_base),
                        p_delong_paired = as.numeric(test$p.value),
                        correct_regression = sum((v$score_vote > 0) == (v$y == 1)),
                        correct_baseline   = sum((v$score_base > 0) == (v$y == 1))),
       roc_regression = r_reg, roc_baseline = r_base)
}

# AUC per model: all the rows of each model (both sides), 1 row per model in the output.
auc_per_model <- function(m, ev, scenario, set, fold = NA) {
  s <- score_rows(m, ev)
  do.call(rbind, lapply(all_models, function(mod) {
    r <- s[s$model == mod, ]
    data.frame(scenario = scenario, set = set, fold = fold, model = mod,
               n_rows = nrow(r), n_wins = sum(r$y),
               auc_regression = auc_of(roc_of(r$y, r$p_own)),
               auc_baseline   = auc_of(roc_of(r$y, r$score_base)))
  }))
}

vote_rows  <- list()   # pieces of por_voto.csv
model_rows <- list()   # pieces of por_modelo.csv
add <- function(m, ev, scenario, set, fold = NA) {
  pv <- auc_per_vote(m, ev, scenario, set, fold)
  vote_rows[[length(vote_rows) + 1]]   <<- pv$row
  model_rows[[length(model_rows) + 1]] <<- auc_per_model(m, ev, scenario, set, fold)
  pv
}

# ---- 4. Scenario 1: all the data (in-sample) ----------------------------------------

cat("\nScenario 1: all data (April to July)\n")
m_all <- fit_set(d)
s1    <- add(m_all, d, "all_data", "all")
cat("Regressions fitted:", length(m_all$fits), "\n")

# ---- 5. Scenario 2: train (April to June) / test (July) -------------------------------

cat("\nScenario 2: train / test\n")
m_train <- fit_set(d[d$split == "train", ])
cat("Regressions fitted on train:", length(m_train$fits), "\n")
s2_train <- add(m_train, d[d$split == "train", ], "train_test", "train")
s2_test  <- add(m_train, d[d$split == "test", ],  "train_test", "test")

# ---- 6. Scenario 3: 5-fold cross-validation by session ---------------------------------

cat("\nScenario 3: 5-fold cross-validation by session (seed", seed, ")\n")
sessions <- unique(d$evaluation_session_id)
set.seed(seed)
fold_of <- setNames(sample(rep_len(1:k_folds, length(sessions))), sessions)
d$fold  <- unname(fold_of[as.character(d$evaluation_session_id)])
# A session is never split between folds (true by construction: the fold comes from the session)
stopifnot(!anyNA(d$fold),
          all(tapply(d$fold, d$evaluation_session_id, function(f) length(unique(f))) == 1))

for (f in 1:k_folds) {
  m_f <- fit_set(d[d$fold != f, ])
  add(m_f, d[d$fold == f, ], "cv5", "test", f)
}

# ---- 7. Checks against the existing results ---------------------------------------------
# The July votes and the regressions are the same as in R/03 (docs/05): with the same fit
# (exclude, decisive votes) the number of correct predictions must be the same as in
# R/resultados/evaluacion.csv. The baseline can differ by a few votes: R/03 computes the
# win rate with the 28 flagged votes included, here they are left out (like in R/02).
july <- s2_test$row
stopifnot(july$n_votes == 20416)
ev_ref <- read.csv("R/resultados/evaluacion.csv", stringsAsFactors = FALSE)
ref_reg  <- ev_ref$correct[ev_ref$method == "regressions_48_exclude"]
ref_base <- ev_ref$correct[ev_ref$method == "general_win_rate"]
cat("\nCheck vs R/resultados/evaluacion.csv (July, correct predictions):\n",
    "  regressions (exclude):", july$correct_regression, "| evaluacion.csv:", ref_reg, "\n",
    "  win-rate baseline    :", july$correct_baseline,   "| evaluacion.csv:", ref_base, "\n")
stopifnot(july$correct_regression == ref_reg, abs(july$correct_baseline - ref_base) <= 10)

# ---- 8. Tables ---------------------------------------------------------------------------

por_voto <- do.call(rbind, vote_rows)
por_voto$fold <- as.character(por_voto$fold)
cv_rows <- por_voto$scenario == "cv5"
mean_row <- data.frame(scenario = "cv5", set = "test", fold = "mean",
                       n_votes = sum(por_voto$n_votes[cv_rows]),
                       n_votes_left_out = sum(por_voto$n_votes_left_out[cv_rows]))
for (col in c("auc_regression", "auc_regression_ci_low", "auc_regression_ci_high",
              "auc_baseline", "auc_baseline_ci_low", "auc_baseline_ci_high",
              "auc_difference", "p_delong_paired"))
  mean_row[[col]] <- NA_real_
mean_row$auc_regression <- mean(por_voto$auc_regression[cv_rows])
mean_row$auc_baseline   <- mean(por_voto$auc_baseline[cv_rows])
mean_row$auc_difference <- mean_row$auc_regression - mean_row$auc_baseline
mean_row$correct_regression <- sum(por_voto$correct_regression[cv_rows])
mean_row$correct_baseline   <- sum(por_voto$correct_baseline[cv_rows])
por_voto <- rbind(por_voto, mean_row[names(por_voto)])

por_modelo <- do.call(rbind, model_rows)
por_modelo$fold <- as.character(por_modelo$fold)
cv_models <- por_modelo[por_modelo$scenario == "cv5", ]
mean_models <- do.call(rbind, lapply(all_models, function(mod) {
  r <- cv_models[cv_models$model == mod, ]
  data.frame(scenario = "cv5", set = "test", fold = "mean", model = mod,
             n_rows = sum(r$n_rows), n_wins = sum(r$n_wins),
             auc_regression = mean(r$auc_regression, na.rm = TRUE),
             auc_baseline   = mean(r$auc_baseline,   na.rm = TRUE))
}))
por_modelo <- rbind(por_modelo, mean_models)
por_modelo$auc_difference <- por_modelo$auc_regression - por_modelo$auc_baseline

# Per fold: AUC per vote and the mean of the per-model AUCs (models where it can be computed)
folds <- do.call(rbind, lapply(as.character(1:k_folds), function(f) {
  v <- por_voto[por_voto$scenario == "cv5" & por_voto$fold == f, ]
  m <- por_modelo[por_modelo$scenario == "cv5" & por_modelo$fold == f, ]
  data.frame(fold = f, n_test_votes = v$n_votes,
             auc_vote_regression = v$auc_regression, auc_vote_baseline = v$auc_baseline,
             auc_model_mean_regression = mean(m$auc_regression, na.rm = TRUE),
             auc_model_mean_baseline   = mean(m$auc_baseline,   na.rm = TRUE),
             models_with_auc = sum(!is.na(m$auc_regression)))
}))
num <- c("auc_vote_regression", "auc_vote_baseline", "auc_model_mean_regression",
         "auc_model_mean_baseline", "models_with_auc")
folds <- rbind(folds,
               cbind(data.frame(fold = "mean", n_test_votes = sum(folds$n_test_votes)),
                     as.data.frame(lapply(folds[num], mean))),
               cbind(data.frame(fold = "sd", n_test_votes = NA_integer_),
                     as.data.frame(lapply(folds[num], sd))))
folds$auc_vote_difference <- folds$auc_vote_regression - folds$auc_vote_baseline

# AUCs to 4 decimals; p-values to 3 significant digits (many are far below 0.0001)
round_cols <- function(x) {
  for (col in names(x)) if (is.double(x[[col]]))
    x[[col]] <- if (startsWith(col, "p_")) signif(x[[col]], 3) else round(x[[col]], 4)
  x
}
write.csv(round_cols(por_voto),   file.path(out_folder, "por_voto.csv"),   row.names = FALSE)
write.csv(round_cols(por_modelo), file.path(out_folder, "por_modelo.csv"), row.names = FALSE)
write.csv(round_cols(folds),      file.path(out_folder, "folds.csv"),      row.names = FALSE)

# ---- 9. ROC curve of July (per vote): 48 regressions vs baseline ------------------------------

png(file.path(out_folder, "curva_roc_julio.png"), width = 1100, height = 900, res = 150)
par(mar = c(4.5, 4.5, 5, 1.5))   # room at the top for a 2-line title
plot(s2_test$roc_regression, col = "#1f77b4", lwd = 3, legacy.axes = TRUE,
     xlab = "False positive rate (1 - specificity)", ylab = "True positive rate (sensitivity)",
     main = sprintf("ROC curve, July votes (never seen in the fit)\n%s votes with a winner, AUC computed with pROC",
                    format(july$n_votes, big.mark = ",")))
lines(s2_test$roc_baseline, col = "#d62728", lwd = 3, lty = 2)
legend("bottomright", bty = "n", lwd = 3, lty = c(1, 2), col = c("#1f77b4", "#d62728"),
       legend = c(sprintf("48 regressions (AUC = %.3f)", july$auc_regression),
                  sprintf("General ranking (AUC = %.3f)", july$auc_baseline)))
invisible(dev.off())

# Same curves as data (101 points each), so the figure can be redrawn for the slides
grid <- seq(0, 1, by = 0.01)
curve_of <- function(r, name)
  data.frame(curve = name, false_positive_rate = 1 - grid,
             true_positive_rate = as.numeric(pROC::coords(r, x = grid, input = "specificity",
                                                          ret = "sensitivity", transpose = FALSE)[, 1]))
curvas <- rbind(curve_of(s2_test$roc_regression, "48_regressions"),
                curve_of(s2_test$roc_baseline,   "general_ranking"))
write.csv(round_cols(curvas), file.path(out_folder, "curva_roc_julio.csv"), row.names = FALSE)

# ---- 10. What to read -----------------------------------------------------------------------

cat("\n=== AUC per vote (pROC) ===\n")
print(round_cols(por_voto[, c("scenario", "set", "fold", "n_votes", "auc_regression",
                              "auc_baseline", "auc_difference", "p_delong_paired")]),
      row.names = FALSE)

cat("\n=== AUC per model: mean over models, and in how many the regression beats the baseline ===\n")
grupo <- factor(paste(por_modelo$scenario, por_modelo$set, ifelse(is.na(por_modelo$fold), "-", por_modelo$fold)),
                levels = unique(paste(por_modelo$scenario, por_modelo$set, ifelse(is.na(por_modelo$fold), "-", por_modelo$fold))))
resumen <- do.call(rbind, lapply(split(por_modelo, grupo), function(r) {
  ok <- !is.na(r$auc_regression) & !is.na(r$auc_baseline)
  data.frame(scenario = r$scenario[1], set = r$set[1], fold = r$fold[1], models_with_auc = sum(ok),
             mean_auc_regression = mean(r$auc_regression[ok]), mean_auc_baseline = mean(r$auc_baseline[ok]),
             regression_better_in = sum(r$auc_regression[ok] > r$auc_baseline[ok]))
}))
print(round_cols(resumen), row.names = FALSE)

cat("\n=== AUC of each fold (cv5) ===\n")
print(round_cols(folds), row.names = FALSE)
cat("\nSaved in", out_folder, "\n")
