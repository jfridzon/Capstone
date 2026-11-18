# Nessim, demo preparation for 18/11; full integration pending.
# Prepared with ChatGPT/Codex assistance. Existing interfaces unchanged.

# ---- 1. Response and predictors ----
cat("\n=== 1. Response: won (1 = win, 0 = loss); question predictors ===\n")
library(pROC)

base <- read.csv(gzfile(
  "data/derivados/base_regresiones_2026-10-28_v2.csv.gz"
), stringsAsFactors = FALSE)
features <- c("is_code", "math", "creative_writing", "instruction_following",
              "complexity", "creativity", "domain_knowledge", "problem_solving",
              "real_world", "specificity", "technical_accuracy")
print(features)
cat("Response: an AI model wins (1) or loses (0), given a decisive vote.\n")
cat("Each regression model uses the same eleven question features.\n")
cat("AUC 0.5 means chance-level discrimination, like a coin flip.\n")
cat("AUC is not accuracy; in-sample AUC is not held-out performance.\n")
cat("18/11 preparation only: opponent and Bradley-Terry variants\n",
    "still await Eli and Mark; Marco is available without opponent strength.\n")
for (x in features) base[[x]] <- as.logical(base[[x]])
votes <- base[!base$requiere_revision & base$es_decisivo, ]
stopifnot(!anyNA(votes[c("won", features)]), all(votes$won %in% c(0, 1)))
print(data.frame(votes = length(unique(votes$id)),
                 models = length(unique(votes$model))))

# ---- 2. The 48 logistic regressions ----
cat("\n=== 2. The 48 binomial GLMs; o3 summary and odds ratios ===\n")
fit_48 <- function(data) {
  models <- sort(unique(data$model))
  fits <- setNames(vector("list", length(models)), models)
  for (m in models) {
    fits[[m]] <- glm(
      won ~ is_code + math + creative_writing + instruction_following +
        complexity + creativity + domain_knowledge + problem_solving +
        real_world + specificity + technical_accuracy,
      family = binomial, data = data[data$model == m, ]
    )
  }
  stopifnot(length(fits) == 48L,
            all(vapply(fits, function(f) f$converged, logical(1))))
  fits
}

fits <- fit_48(votes)
print(length(fits))
print(summary(fits[["o3-2025-04-16"]]))
print(data.frame(odds_ratio = exp(coef(fits[["o3-2025-04-16"]]))))
coefficients_48 <- do.call(rbind, lapply(fits, coef))

# ---- 3. AUC for each of the 48 regressions ----
cat("\n=== 3. In-sample AUC for each model, calculated with pROC ===\n")
auc_by_model <- function(fits, data) {
  do.call(rbind, lapply(names(fits), function(m) {
    rows <- data[data$model == m, ]
    score <- predict(fits[[m]], newdata = rows, type = "link")
    auc <- NA_real_
    if (length(unique(rows$won)) == 2L) {
      roc <- pROC::roc(rows$won, score, levels = c(0, 1),
                       direction = "<", quiet = TRUE)
      auc <- as.numeric(pROC::auc(roc))
    }
    data.frame(model = m, rows = nrow(rows), AUC = auc)
  }))
}

auc_models_all <- auc_by_model(fits, votes)
print(transform(auc_models_all, AUC = round(AUC, 4)), row.names = FALSE)

# ---- 4. The professor's 48 x 7 table, from Mark's saved CSV ----
cat("\n=== 4. AUC per model: folds 1-5, mean CV and all data ===\n")
auc_saved <- read.csv("R/resultados/auc/por_modelo.csv",
                      stringsAsFactors = FALSE)
stopifnot(all(c("scenario", "fold", "model", "n_rows", "n_wins",
                "auc", "status") %in% names(auc_saved)))
auc_columns <- c(paste0("Fold_", 1:5), "Mean_CV", "All_data")
auc_saved$column <- ifelse(
  auc_saved$scenario == "all_data" & auc_saved$fold == "all", "All_data",
  ifelse(auc_saved$scenario == "cv5" & auc_saved$fold == "mean", "Mean_CV",
         ifelse(auc_saved$scenario == "cv5" & auc_saved$fold %in% 1:5,
                paste0("Fold_", auc_saved$fold), NA_character_)))
auc_long <- auc_saved[!is.na(auc_saved$column), c("model", "column", "auc")]
stopifnot(setequal(auc_long$model, names(fits)),
          !anyDuplicated(auc_long[c("model", "column")]),
          all(table(auc_long$model) == length(auc_columns)),
          all(is.na(auc_long$auc) | auc_long$auc >= 0 & auc_long$auc <= 1))
auc_wide <- reshape(auc_long, idvar = "model", timevar = "column",
                    direction = "wide")
auc_wide <- auc_wide[match(names(fits), auc_wide$model), ]
AUC_48x7 <- auc_wide[paste0("auc.", auc_columns)]
names(AUC_48x7) <- auc_columns
rownames(AUC_48x7) <- auc_wide$model
stopifnot(identical(dim(AUC_48x7), c(48L, 7L)))
# Mean_CV is the saved mean of unrounded AUCs, not a mean of rounded cells.
print(AUC_48x7, digits = 4)
if (interactive()) View(AUC_48x7, title = "AUC per model: 48 x 7")

# ---- 5. AUC per vote: all data vs general ranking ----
cat("\n=== 5. In-sample AUC per vote: regressions vs general ranking ===\n")
score_votes <- function(fits, train, test) {
  a <- test[test$lado == "model_a", ]
  score_A <- score_B <- rep(NA_real_, nrow(a))
  for (m in names(fits)) {
    i <- which(a$model == m)
    j <- which(a$rival == m)
    if (length(i)) score_A[i] <- predict(
      fits[[m]], newdata = a[i, ], type = "link")
    if (length(j)) score_B[j] <- predict(
      fits[[m]], newdata = a[j, ], type = "link")
  }
  win_rate <- tapply(train$won, train$model, mean)
  p_48 <- plogis(score_A - score_B)
  p_general <- plogis(qlogis(win_rate[a$model]) - qlogis(win_rate[a$rival]))
  stopifnot(all(is.finite(p_48)), all(is.finite(p_general)))
  data.frame(won = a$won, p_48 = p_48, p_general = unname(p_general))
}

scores <- score_votes(fits, train = votes, test = votes)
roc_48 <- pROC::roc(scores$won, scores$p_48,
                     levels = c(0, 1), direction = "<", quiet = TRUE)
roc_general <- pROC::roc(scores$won, scores$p_general,
                          levels = c(0, 1), direction = "<", quiet = TRUE)
auc_all <- data.frame(
  evaluation = "All data (in sample)", votes = nrow(scores),
  AUC_48 = as.numeric(pROC::auc(roc_48)),
  AUC_general = as.numeric(pROC::auc(roc_general))
)
print(transform(auc_all, AUC_48 = round(AUC_48, 4),
                AUC_general = round(AUC_general, 4)), row.names = FALSE)
plot(roc_48, col = "blue", legacy.axes = TRUE, main = "All data")
lines(roc_general, col = "red", lty = 2)
legend("bottomright", c("48 regressions", "General ranking"),
       col = c("blue", "red"), lty = c(1, 2), bty = "n")

# ---- 6. Random folds by session: verify Mark's shared file ----
cat("\n=== 6. Verify the official random folds by session ===\n")
folds <- read.csv("R/resultados/auc/folds_5.csv", stringsAsFactors = FALSE)
sessions <- sort(unique(base$evaluation_session_id))
set.seed(2026)
session_fold <- setNames(sample(rep_len(1:5, length(sessions))), sessions)
saved_sessions <- base$evaluation_session_id[match(folds$id, base$id)]
stopifnot(!anyDuplicated(folds$id), setequal(folds$id, base$id),
          all(folds$fold == unname(session_fold[saved_sessions])))
votes$fold <- folds$fold[match(votes$id, folds$id)]
stopifnot(!anyNA(votes$fold),
          all(tapply(votes$fold, votes$evaluation_session_id,
                     function(f) length(unique(f))) == 1L))
print(table(votes$fold[votes$lado == "model_a"]))

# ---- 7. Five-fold cross-validation ----
cat("\n=== 7. Refit on four folds; calculate AUC on the held-out fold ===\n")
fold_results <- model_results <- roc_folds <- vector("list", 5)
for (f in 1:5) {
  train <- votes[votes$fold != f, ]
  test <- votes[votes$fold == f, ]
  stopifnot(length(intersect(train$evaluation_session_id,
                             test$evaluation_session_id)) == 0L)
  fits_fold <- fit_48(train)
  scores_fold <- score_votes(fits_fold, train, test)
  roc_fold <- pROC::roc(scores_fold$won, scores_fold$p_48,
                         levels = c(0, 1), direction = "<", quiet = TRUE)
  roc_baseline <- pROC::roc(scores_fold$won, scores_fold$p_general,
                             levels = c(0, 1), direction = "<", quiet = TRUE)
  fold_results[[f]] <- data.frame(
    fold = as.character(f), votes = nrow(scores_fold),
    AUC_48 = as.numeric(pROC::auc(roc_fold)),
    AUC_general = as.numeric(pROC::auc(roc_baseline))
  )
  model_results[[f]] <- data.frame(fold = f,
                                  auc_by_model(fits_fold, test))
  roc_folds[[f]] <- roc_fold
}

auc_folds <- do.call(rbind, fold_results)
auc_folds <- rbind(auc_folds, data.frame(
  fold = "mean", votes = sum(auc_folds$votes),
  AUC_48 = mean(auc_folds$AUC_48),
  AUC_general = mean(auc_folds$AUC_general)
))
print(transform(auc_folds, AUC_48 = round(AUC_48, 4),
                AUC_general = round(AUC_general, 4)), row.names = FALSE)

auc_models_folds <- do.call(rbind, model_results)
auc_models_cv <- aggregate(AUC ~ model, auc_models_folds, mean,
                           na.action = na.pass)
AUC_48_models <- merge(auc_models_all, auc_models_cv, by = "model",
                       suffixes = c("_all", "_CV"))
print(transform(AUC_48_models, AUC_all = round(AUC_all, 4),
                AUC_CV = round(AUC_CV, 4)), row.names = FALSE)
print(data.frame(NA_model_fold_AUC = sum(is.na(auc_models_folds$AUC))))

plot(roc_folds[[1]], col = 1, legacy.axes = TRUE, main = "Five held-out folds")
for (f in 2:5) lines(roc_folds[[f]], col = f)
legend("bottomright", paste("Fold", 1:5), col = 1:5, lty = 1, bty = "n")

# Verify the saved 48 x 7 table against the pROC calculations above.
auc_recalculated <- sapply(1:5, function(f) {
  rows <- auc_models_folds[auc_models_folds$fold == f, ]
  rows$AUC[match(rownames(AUC_48x7), rows$model)]
})
auc_recalculated <- cbind(auc_recalculated,
  rowMeans(auc_recalculated),
  auc_models_all$AUC[match(rownames(AUC_48x7), auc_models_all$model)])
dimnames(auc_recalculated) <- dimnames(as.matrix(AUC_48x7))
stopifnot(identical(is.na(as.matrix(AUC_48x7)), is.na(auc_recalculated)),
          all(abs(as.matrix(AUC_48x7) - round(auc_recalculated, 4)) < 1e-10,
              na.rm = TRUE))
cat("\n48 x 7 saved AUC table matches recalculated pROC values.\n")

# ---- 8. Per-AI-model AUC ladder: awaiting Eli ----
cat("\n=== 8. Per-AI-model AUC ladder: pending Eli integration ===\n")
cat("Show together: coin flip, labels only, opponent only, labels + opponent.\n")
cat("No opponent AUC is presented until all four rows are available.\n")
cat("Report the opponent contribution and the extra gain from labels.\n")

# ---- 9. Per-vote Bradley-Terry: awaiting Mark ----
cat("\n=== 9. Per-vote Bradley-Terry: pending Mark integration ===\n")
cat("Compare decisive-vote binomial with half-point quasibinomial.\n")
cat("Evaluate A versus B on the same held-out decisive votes.\n")
cat("Do not compare a per-AI-model AUC directly with a per-vote AUC.\n")

# ---- 10. Per-vote confusion matrix: Marco, merged PR #65 ----
cat("\n=== 10. Per-vote confusion matrix: threshold 0.5 ===\n")
confusion_18nov <- local({
  piece <- new.env(parent = globalenv())
  old_options <- options(correr_21 = FALSE)
  tryCatch(sys.source("R/21_matriz_confusion.R", envir = piece),
           finally = options(old_options))
  piece$matriz_confusion(umbral = 0.5)
})
cat("Positive class: AI model A wins; predict A when P > 0.5.\n")
cat("No opponent-strength variant yet; it still awaits Eli.\n")
cat("AUC alone does not give these threshold-specific metrics.\n")

# File presence does not certify a merged, reviewed, compatible interface.
# Integrate only after the upstream PRs land in main; inspect their real APIs.
demo_18nov_dependencies <- data.frame(
  owner = c("Eli", "Mark", "Marco"),
  file = c("R/19_fuerza_rival.R", "R/20_regresion_grande_cv.R",
           "R/21_matriz_confusion.R"),
  status = c("Pending integration", "Pending integration",
             "Integrated: labels only, PR #65"),
  stringsAsFactors = FALSE
)
demo_18nov_dependencies$file_present <- file.exists(
  demo_18nov_dependencies$file
)
print(demo_18nov_dependencies, row.names = FALSE)
cat("\n18/11 integration and final team rehearsal: PENDING.\n")
