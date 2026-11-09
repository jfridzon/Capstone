# AUC with pROC: the 48 binomial regressions vs the general ranking (phase 2b, task B, Mark)
# Issue #32. Run from the repo root: source("R/11_auc_proc.R")   (needs the pROC package)
#
# What the professor asked (docs/14-fase-2b.md, classes of 4/11 and 9/11): AUC computed with
# pROC, FIRST with all the data, THEN 5-fold cross-validation with the AUC of each fold.
# The folds are random (by session), not "train = April to June / test = July": July is no
# longer the main exam (R/03 stays as a historical result and is not repeated here).
#
# Model: the same 48 regressions of R/02 (1 per model, 11 characteristics of the question),
#   glm(y ~ is_code + math + ... + technical_accuracy, family = binomial)
# fitted on DECISIVE votes only (y = 1 if the model won, 0 if it lost). Ties and both_bad are
# not used. The 28 votes Nessim flagged for review stay out, like in R/02 and R/03.
#
# 2 kinds of AUC, both with pROC::roc() and pROC::auc():
#   per model: the AUC of each of the 48 regressions on its own rows (that model won = 1 /
#              lost = 0). Score = the linear predictor (logit) of that model's regression.
#              There is NO baseline here: the general ranking gives a model the same score in
#              all its rows, so it has no AUC (docs/14, decision 5).
#   per vote : P(model_a wins) = plogis(score_A - score_B), where score = the linear predictor
#              (logit) of each model's own regression evaluated with the characteristics of
#              the question. It is compared with whether model_a really won.
#
# Baseline (per vote only): the general ranking = general win rate of each model (votes won /
# votes played, all types of question together), computed ONLY with the rows used to fit the
# regressions (the 4 training folds, in the 5-fold CV). Per vote it is
# plogis(logit(rate_A) - logit(rate_B)), the same baseline as R/03.
#
# 2 scenarios, in this order:
#   1. all_data: fit and measure with all the decisive votes (in-sample).
#   2. cv5     : 5-fold cross-validation. 5 random groups of sessions: fit with 4, measure in
#                the 1 left out, 5 times. The AUC of each fold, its mean and its sd.
#
# THE FOLDS (R/resultados/auc/folds_5.csv, columns id, fold) are made ONCE, here, and then
# everybody uses the file (Nessim for Bradley-Terry, Eli for the sensitivity): nobody makes
# their own folds. They are made by SESSION (evaluation_session_id): the 2 rows of a vote and
# all the votes of a session fall in the same fold, so the test never sees a vote (or a
# session) that the fit already saw. They cover ALL the votes of the base (also ties, both_bad
# and the flagged ones), so the file also works for fits that use them. set.seed(2026).
# If the file already exists it is READ (never overwritten) and checked.
#
# Output (R/resultados/auc/):
#   folds_5.csv     the folds: 1 row per vote (id, fold)
#   por_voto.csv    AUC per vote: regression vs baseline, DeLong 95% CI and paired DeLong test
#   por_modelo.csv  AUC per model: 48 rows per scenario / fold (NA if it cannot be computed)
#   folds.csv       AUC of each fold of cv5 + mean, sd and the count of NA per fold
#   curva_roc_cv5.png / curva_roc_cv5.csv   ROC curve (per vote), regressions vs baseline,
#                   with the predictions of all the folds together
#   versiones.txt   R and pROC versions
#
# p-values and CIs are nominal: the same models repeat in many votes and every vote is used
# twice when fitting (the professor knows, docs/04). Base R + pROC only.

library(pROC)
options(width = 200)   # wider console output, so the tables printed at the end do not wrap

# ---- Settings ---------------------------------------------------------------

out_folder <- "R/resultados/auc"
folds_file <- file.path(out_folder, "folds_5.csv")
k_folds    <- 5
seed       <- 2026
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
stopifnot(all(table(long_base$id) == 2))

# ---- 3. The folds (folds_5.csv) ------------------------------------------------------
# Random folds by session: the sessions (sorted, so the result does not depend on the order
# of the rows) get the labels 1..5 in equal numbers, shuffled with set.seed(2026).

make_folds <- function(base) {
  votes    <- base[base$lado == "model_a", c("id", "evaluation_session_id")]
  sessions <- sort(unique(votes$evaluation_session_id))
  set.seed(seed)
  fold_of_session <- setNames(sample(rep_len(1:k_folds, length(sessions))), sessions)
  out <- data.frame(id = votes$id, fold = unname(fold_of_session[votes$evaluation_session_id]))
  out[order(out$id), ]
}

if (file.exists(folds_file)) {
  folds5 <- read.csv(folds_file, stringsAsFactors = FALSE)
  cat("Using the existing", folds_file, "(not overwritten)\n")
  # The file has to match the same recipe (same R sampling); if it does not, say so, but keep
  # using the file: it is the one everybody uses.
  fresh <- make_folds(long_base)
  if (!identical(fresh$id, folds5$id) || !identical(fresh$fold, as.integer(folds5$fold)))
    warning("folds_5.csv is not what this script would make now (different R version?). ",
            "The file is used as it is.")
} else {
  folds5 <- make_folds(long_base)
  write.csv(folds5, folds_file, row.names = FALSE)
  cat("Created", folds_file, "\n")
}

# Checks: every vote of the base has exactly 1 fold in 1..5, and a session is never split
stopifnot(names(folds5) == c("id", "fold"),
          !anyDuplicated(folds5$id),
          setequal(folds5$id, long_base$id),
          all(folds5$fold %in% 1:k_folds))
base_fold <- folds5$fold[match(long_base$id, folds5$id)]
stopifnot(all(tapply(base_fold, long_base$evaluation_session_id, function(f) length(unique(f))) == 1))
cat("Folds: ", length(unique(long_base$id)), "votes in", length(unique(long_base$evaluation_session_id)),
    "sessions. Votes per fold:", paste(table(folds5$fold), collapse = " "), "\n")

# ---- 4. Decisive votes ---------------------------------------------------------------

# Decisive votes only, y = won (1/0). The 28 flagged votes are left out.
d <- env02$preparar_respuesta(long_base, politica = "excluir")
stopifnot(all(d$y %in% c(0, 1)), all(d$es_decisivo))
d$fold <- folds5$fold[match(d$id, folds5$id)]
stopifnot(!anyNA(d$fold))

all_models <- sort(unique(d$model))
cat("Decisive vote rows:", nrow(d), "=", nrow(d) / 2, "votes |",
    "models:", length(all_models), "\n")
cat("Decisive votes per fold:", paste(table(d$fold[d$lado == "model_a"]), collapse = " "), "\n")

# ---- 5. Fit, score, AUC ------------------------------------------------------------

# The 48 regressions (R/02) + the general win rate of each model, from the same rows.
# R/02 chooses binomial by itself when y is only 0/1; here it is checked. R/02 only fits a
# model with 100 rows or more (min_votos): a model with fewer has no regression.
fit_set <- function(rows) {
  fits <- env02$ajustar_modelos(rows)   # lambda = 0 -> plain glm()
  stopifnot(all(vapply(fits, function(f) f$converged && f$family$family == "binomial",
                       logical(1))))
  list(fits = fits, rate = tapply(rows$y, rows$model, mean))
}

# Linear predictor (the logit) of each model's own regression, for the questions in x
linear_predictor <- function(fits, models, x) {
  lp <- rep(NA_real_, length(models))
  for (m in intersect(unique(models), names(fits))) {
    i <- which(models == m)
    lp[i] <- predict(fits[[m]], newdata = x[i, , drop = FALSE], type = "link")
  }
  lp
}

# pROC with the direction fixed: higher score = more likely to win (cases = 1).
# NULL when there is only 1 class (pROC cannot compute the AUC).
roc_of <- function(y, score) {
  if (length(y) < 2 || length(unique(y)) < 2) return(NULL)
  pROC::roc(response = y, predictor = score, levels = c(0, 1), direction = "<", quiet = TRUE)
}
auc_of <- function(r) if (is.null(r)) NA_real_ else as.numeric(pROC::auc(r))

# Independent check of pROC's number (Mann-Whitney with average ranks). Only a check.
auc_rank <- function(y, score) {
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  (sum(rank(score)[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

# AUC per vote: rows with lado == "model_a" (1 row per vote). Votes where model_a or model_b
# has no regression are left out and counted.
auc_per_vote <- function(m, ev, scenario, fold) {
  votes <- ev[ev$lado == "model_a", ]
  v <- votes[votes$model %in% names(m$fits) & votes$rival %in% names(m$fits), ]
  x <- v[predictors]
  v$score_vote <- linear_predictor(m$fits, v$model, x) - linear_predictor(m$fits, v$rival, x)
  v$score_base <- qlogis(m$rate[v$model]) - qlogis(m$rate[v$rival])
  stopifnot(is.finite(v$score_vote), is.finite(v$score_base))
  p_reg  <- plogis(v$score_vote)   # P(model_a wins), regressions
  p_base <- plogis(v$score_base)   # P(model_a wins), general ranking
  r_reg  <- roc_of(v$y, p_reg)
  r_base <- roc_of(v$y, p_base)
  stopifnot(abs(auc_of(r_reg)  - auc_rank(v$y, p_reg))  < 1e-9,
            abs(auc_of(r_base) - auc_rank(v$y, p_base)) < 1e-9)
  ci_reg  <- as.numeric(pROC::ci.auc(r_reg,  method = "delong"))   # low, auc, high
  ci_base <- as.numeric(pROC::ci.auc(r_base, method = "delong"))
  test    <- pROC::roc.test(r_reg, r_base, method = "delong", paired = TRUE)
  list(row = data.frame(scenario = scenario, fold = fold,
                        n_votes = nrow(v), n_votes_left_out = nrow(votes) - nrow(v),
                        auc_regression = auc_of(r_reg),
                        auc_regression_ci_low = ci_reg[1], auc_regression_ci_high = ci_reg[3],
                        auc_baseline = auc_of(r_base),
                        auc_baseline_ci_low = ci_base[1], auc_baseline_ci_high = ci_base[3],
                        auc_difference = auc_of(r_reg) - auc_of(r_base),
                        p_delong_paired = as.numeric(test$p.value),
                        correct_regression = sum((v$score_vote > 0) == (v$y == 1)),
                        correct_baseline   = sum((v$score_base > 0) == (v$y == 1))),
       roc_regression = r_reg, roc_baseline = r_base,
       votes = data.frame(id = v$id, fold = fold, y = v$y,
                          score_vote = v$score_vote, score_base = v$score_base))
}

# AUC per model: all the rows of each model in `ev` (both sides), 1 row per model.
# status: ok | one_class (only wins or only losses in these rows: AUC = NA) |
#         no_regression (the model has no regression in this fit) | no_rows (no rows in `ev`)
auc_per_model <- function(m, ev, scenario, fold) {
  do.call(rbind, lapply(all_models, function(mod) {
    r <- ev[ev$model == mod, ]
    status <- if (!(mod %in% names(m$fits))) "no_regression"
              else if (nrow(r) == 0) "no_rows"
              else if (length(unique(r$y)) < 2) "one_class"
              else "ok"
    auc <- NA_real_
    if (status == "ok") {
      score <- linear_predictor(m$fits, r$model, r[predictors])
      stopifnot(is.finite(score))
      rr  <- roc_of(r$y, score)
      auc <- auc_of(rr)
      stopifnot(abs(auc - auc_rank(r$y, score)) < 1e-9)
    }
    data.frame(scenario = scenario, fold = fold, model = mod,
               n_rows = nrow(r), n_wins = sum(r$y), auc = auc, status = status)
  }))
}

run_set <- function(m, ev, scenario, fold) {
  pv <- auc_per_vote(m, ev, scenario, fold)
  pv$models <- auc_per_model(m, ev, scenario, fold)
  pv
}

# ---- 6. Scenario 1: all the data (in-sample) ----------------------------------------

cat("\nScenario 1: all data\n")
m_all <- fit_set(d)
cat("Regressions fitted:", length(m_all$fits), "\n")
res <- list(all = run_set(m_all, d, "all_data", "all"))

# ---- 7. Scenario 2: 5-fold cross-validation (random folds by session) -----------------

cat("\nScenario 2: 5-fold cross-validation, folds from", folds_file, "\n")
for (f in 1:k_folds) {
  train <- d[d$fold != f, ]
  test  <- d[d$fold == f, ]
  # No vote and no session is in both sets (so the test never sees what the fit saw)
  stopifnot(length(intersect(train$id, test$id)) == 0,
            length(intersect(train$evaluation_session_id, test$evaluation_session_id)) == 0)
  m_f <- fit_set(train)   # the regressions AND the baseline win rates use only the 4 train folds
  cat("  fold", f, "| regressions:", length(m_f$fits),
      "| train votes:", nrow(train) / 2, "| test votes:", nrow(test) / 2, "\n")
  res[[as.character(f)]] <- run_set(m_f, test, "cv5", as.character(f))
}
stopifnot(sum(sapply(res[as.character(1:k_folds)], function(r) r$row$n_votes + r$row$n_votes_left_out)) ==
            nrow(d) / 2)   # every decisive vote is the test of exactly 1 fold

# ---- 8. Tables ---------------------------------------------------------------------------

por_voto   <- do.call(rbind, lapply(res, `[[`, "row"))
por_modelo <- do.call(rbind, lapply(res, `[[`, "models"))
rownames(por_voto) <- rownames(por_modelo) <- NULL

# por_voto.csv: add the mean and the sd of the 5 folds (AUC columns only)
cv <- por_voto[por_voto$scenario == "cv5", ]
blank <- por_voto[1, ]; blank[1, ] <- NA
mean_row <- sd_row <- blank
mean_row$scenario <- sd_row$scenario <- "cv5"
mean_row$fold <- "mean"; sd_row$fold <- "sd"
for (col in c("auc_regression", "auc_baseline", "auc_difference")) {
  mean_row[[col]] <- mean(cv[[col]])
  sd_row[[col]]   <- sd(cv[[col]])
}
mean_row$n_votes <- sum(cv$n_votes); mean_row$n_votes_left_out <- sum(cv$n_votes_left_out)
mean_row$correct_regression <- sum(cv$correct_regression)
mean_row$correct_baseline   <- sum(cv$correct_baseline)
por_voto <- rbind(por_voto, mean_row, sd_row)

# por_modelo.csv: add the mean over the folds that have an AUC (and the sd) for each model
cv_models <- por_modelo[por_modelo$scenario == "cv5", ]
mean_models <- do.call(rbind, lapply(all_models, function(mod) {
  r <- cv_models[cv_models$model == mod, ]
  data.frame(scenario = "cv5", fold = "mean", model = mod,
             n_rows = sum(r$n_rows), n_wins = sum(r$n_wins),
             auc = if (any(!is.na(r$auc))) mean(r$auc, na.rm = TRUE) else NA_real_,
             status = paste0(sum(r$status == "ok"), "_of_", k_folds, "_folds"))
}))
por_modelo <- rbind(por_modelo, mean_models)

# folds.csv: 1 row per fold + mean, sd (AUC columns) and total (counts)
folds <- do.call(rbind, lapply(as.character(1:k_folds), function(f) {
  v <- por_voto[por_voto$scenario == "cv5" & por_voto$fold == f, ]
  m <- por_modelo[por_modelo$scenario == "cv5" & por_modelo$fold == f, ]
  data.frame(fold = f, n_test_votes = v$n_votes, n_test_votes_left_out = v$n_votes_left_out,
             auc_vote_regression = v$auc_regression, auc_vote_baseline = v$auc_baseline,
             auc_vote_difference = v$auc_regression - v$auc_baseline,
             auc_model_mean = mean(m$auc, na.rm = TRUE),
             models_with_auc = sum(m$status == "ok"),
             models_na_one_class = sum(m$status == "one_class"),
             models_na_no_regression = sum(m$status == "no_regression"),
             models_na_no_rows = sum(m$status == "no_rows"))
}))
auc_cols <- c("auc_vote_regression", "auc_vote_baseline", "auc_vote_difference", "auc_model_mean")
cnt_cols <- c("n_test_votes", "n_test_votes_left_out", "models_with_auc", "models_na_one_class",
              "models_na_no_regression", "models_na_no_rows")
blank_f <- folds[1, ]; blank_f[1, ] <- NA
mean_f <- sd_f <- total_f <- blank_f
mean_f$fold <- "mean"; sd_f$fold <- "sd"; total_f$fold <- "total"
for (col in auc_cols) { mean_f[[col]] <- mean(folds[[col]]); sd_f[[col]] <- sd(folds[[col]]) }
for (col in cnt_cols) total_f[[col]] <- sum(folds[[col]])
folds <- rbind(folds, mean_f, sd_f, total_f)

# AUCs to 4 decimals; p-values to 3 significant digits (many are far below 0.0001)
round_cols <- function(x) {
  for (col in names(x)) if (is.double(x[[col]]))
    x[[col]] <- if (startsWith(col, "p_")) signif(x[[col]], 3) else round(x[[col]], 4)
  x
}
write.csv(round_cols(por_voto),   file.path(out_folder, "por_voto.csv"),   row.names = FALSE)
write.csv(round_cols(por_modelo), file.path(out_folder, "por_modelo.csv"), row.names = FALSE)
write.csv(round_cols(folds),      file.path(out_folder, "folds.csv"),      row.names = FALSE)

# ---- 9. ROC curve: 48 regressions vs baseline, predictions of ALL the folds together -------
# Each vote is predicted by the regressions fitted WITHOUT its fold (out of fold), and the 5
# sets of predictions are put together in 1 curve per method.

oof <- do.call(rbind, lapply(res[as.character(1:k_folds)], `[[`, "votes"))
stopifnot(nrow(oof) == sum(por_voto$n_votes[por_voto$scenario == "cv5" & por_voto$fold %in% 1:k_folds]))
roc_reg  <- roc_of(oof$y, plogis(oof$score_vote))
roc_base <- roc_of(oof$y, plogis(oof$score_base))
pooled <- c(regression = auc_of(roc_reg), baseline = auc_of(roc_base))

png(file.path(out_folder, "curva_roc_cv5.png"), width = 1100, height = 900, res = 150)
par(mar = c(4.5, 4.5, 5, 1.5))   # room at the top for a 2-line title
plot(roc_reg, col = "#1f77b4", lwd = 3, legacy.axes = TRUE,
     xlab = "False positive rate (1 - specificity)", ylab = "True positive rate (sensitivity)",
     main = sprintf("ROC curve, 5-fold cross-validation (random folds by session)\n%s votes with a winner, each one predicted without its fold",
                    format(nrow(oof), big.mark = ",")))
lines(roc_base, col = "#d62728", lwd = 3, lty = 2)
legend("bottomright", bty = "n", lwd = 3, lty = c(1, 2), col = c("#1f77b4", "#d62728"),
       legend = c(sprintf("48 regressions (AUC = %.3f)", pooled["regression"]),
                  sprintf("General ranking (AUC = %.3f)", pooled["baseline"])))
invisible(dev.off())

# Same curves as data (101 points each), so the figure can be redrawn for the slides
grid <- seq(0, 1, by = 0.01)
curve_of <- function(r, name)
  data.frame(curve = name, false_positive_rate = 1 - grid,
             true_positive_rate = as.numeric(pROC::coords(r, x = grid, input = "specificity",
                                                          ret = "sensitivity", transpose = FALSE)[, 1]))
curvas <- rbind(curve_of(roc_reg, "48_regressions"), curve_of(roc_base, "general_ranking"))
write.csv(round_cols(curvas), file.path(out_folder, "curva_roc_cv5.csv"), row.names = FALSE)

writeLines(c(R.version.string, paste("pROC", as.character(packageVersion("pROC"))),
             paste("set.seed(", seed, ") for folds_5.csv; k =", k_folds)),
           file.path(out_folder, "versiones.txt"))

# ---- 10. What to read -----------------------------------------------------------------------

cat("\n=== AUC per vote (pROC): all data, then each fold of the 5-fold CV ===\n")
print(round_cols(por_voto[, c("scenario", "fold", "n_votes", "n_votes_left_out", "auc_regression",
                              "auc_baseline", "auc_difference", "p_delong_paired")]),
      row.names = FALSE)
cat("\nAll folds together (curve): regressions", round(pooled["regression"], 4),
    "| baseline", round(pooled["baseline"], 4), "\n")

cat("\n=== AUC per model: summary by scenario / fold ===\n")
pm <- por_modelo[por_modelo$fold != "mean", ]
grupo <- paste(pm$scenario, pm$fold)
resumen <- do.call(rbind, lapply(unique(grupo), function(g) {
  r <- pm[grupo == g, ]
  data.frame(scenario = r$scenario[1], fold = r$fold[1], models_with_auc = sum(r$status == "ok"),
             na_one_class = sum(r$status == "one_class"), na_no_regression = sum(r$status == "no_regression"),
             na_no_rows = sum(r$status == "no_rows"), mean_auc = mean(r$auc, na.rm = TRUE),
             min_auc = min(r$auc, na.rm = TRUE), max_auc = max(r$auc, na.rm = TRUE),
             above_05 = sum(r$auc > 0.5, na.rm = TRUE))
}))
print(round_cols(resumen), row.names = FALSE)

cat("\n=== AUC of each fold (cv5) ===\n")
print(round_cols(folds), row.names = FALSE)
cat("\nSaved in", out_folder, "\n")
