# Nessim, issue #44. Prepared with ChatGPT/Codex assistance.

# ---- 1. Data ----
library(pROC)

base <- read.csv(gzfile(
  "data/derivados/base_regresiones_2026-10-28_v2.csv.gz"
), stringsAsFactors = FALSE)
features <- c("is_code", "math", "creative_writing", "instruction_following",
              "complexity", "creativity", "domain_knowledge", "problem_solving",
              "real_world", "specificity", "technical_accuracy")
for (x in features) base[[x]] <- as.logical(base[[x]])
votes <- base[!base$requiere_revision & base$es_decisivo, ]
stopifnot(!anyNA(votes[c("won", features)]), all(votes$won %in% c(0, 1)))
print(data.frame(votes = length(unique(votes$id)),
                 models = length(unique(votes$model))))

# ---- 2. The 48 logistic regressions ----
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
coefficients_48 <- do.call(rbind, lapply(fits, coef))

# ---- 3. AUC for each of the 48 regressions ----
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

# ---- 4. AUC per vote: all data vs general ranking ----
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

# ---- 5. Random folds by session: verify Mark's shared file ----
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

# ---- 6. Five-fold cross-validation ----
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
