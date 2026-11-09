# The 48 regressions, step by step (IDS 3000, phase 2b).
# Open Capstone.Rproj and run each block in order. Base R only.
# Updated by Nessim with ChatGPT/Codex assistance, based on the original demo.

# ---- 1. Decisive votes and question features --------------------------------
models <- new.env()
old_options <- options(correr_02 = FALSE)
tryCatch(sys.source("R/02_regresiones_por_modelo.R", envir = models),
         finally = options(old_options))
source("R/03b_evaluar.R")

votes <- models$preparar_respuesta(models$cargar_base())
split <- read.csv("R/resultados/split_train_test.csv")
votes$split <- split$split[match(votes$id, split$id)]
stopifnot(!anyNA(votes$split), all(votes$y %in% c(0, 1)))
# y = 1 for a win, 0 for a loss. The features describe the question.
print(head(votes[, c("model", "rival", "y", "is_code", "math",
                     "creative_writing", "complexity", "technical_accuracy")]))
print(table(votes$y))
cat("Decisive votes:", nrow(votes) / 2, "\n")

# ---- 2. Fit all 48 models to describe April through July ---------------------
# The formula has one term per feature. Show it and the full output for two models.
fits_all <- models$ajustar_modelos(votes)
stopifnot(length(fits_all) == 48L, all(vapply(fits_all, function(fit)
  fit$converged && fit$family$family == "binomial", logical(1))))
print(formula(fits_all[["o3-2025-04-16"]]))
print(summary(fits_all[["o3-2025-04-16"]]))
print(summary(fits_all[["minimax-m1"]]))
print(head(models$tabla_coeficientes(fits_all)))
print(models$top3("math", fits_all))

# ---- 3. AUC per vote on all data and Mark's five shared folds -----------------
# The main evaluation holds out sessions at random.
# AUC measures how well the scores separate wins from losses (0.5 is chance).
# Read Mark's saved pROC results. Each fold was predicted without its sessions.
auc_votes <- read.csv("R/resultados/auc/por_voto.csv")
auc_votes <- auc_votes[match(c("all", as.character(1:5), "mean"), auc_votes$fold), ]
stopifnot(!anyNA(auc_votes$auc_regression), !anyNA(auc_votes$auc_baseline))
auc_table <- data.frame(
  evaluation = c("All data (in sample)", paste("Held-out fold", 1:5), "Mean of held-out folds"),
  votes = auc_votes$n_votes,
  regressions_auc = auc_votes$auc_regression,
  general_ranking_auc = auc_votes$auc_baseline
)
cat("\nAUC per vote (pROC)\n")
print(auc_table, row.names = FALSE)

# ---- 4. Historical check: train on April-June and test on July --------------
cat("\nHistorical July test\n")
train <- votes[votes$split == "train", ]
fits_train <- models$ajustar_modelos(train)
july <- read.csv("R/resultados/test_julio_votos.csv")
questions <- votes[match(july$id, votes$id), models$predictores, drop = FALSE]
stopifnot(!anyNA(questions), all(c(july$model_a, july$model_b) %in% names(fits_train)))

score_a <- models$probabilidad(fits_train, july$model_a, questions)
score_b <- models$probabilidad(fits_train, july$model_b, questions)
p_model_a <- plogis(qlogis(score_a) - qlogis(score_b))
results <- evaluar(p_model_a, july$winner, "regressions_48_exclude", "exclude")

saved <- read.csv("R/resultados/evaluacion.csv")
reference <- saved[saved$method == results$method, ]
stopifnot(nrow(reference) == 1L, all(results == reference))
baseline <- saved[saved$method == "general_bradley_terry", ]
print(rbind(baseline, results)[, c("method", "test_votes_evaluated", "correct",
                                  "accuracy_percent", "logloss")], row.names = FALSE)

# ---- 5. Show a real July comparison -----------------------------------------
example <- which(questions$math & july$model_a != july$model_b &
  (p_model_a > 0.5) == (july$winner == "model_a"))[1L]
prediction <- ifelse(p_model_a[example] > 0.5, "model_a", "model_b")
print(cbind(july[example, c("model_a", "model_b", "winner")],
            predicted_winner = prediction, p_model_a = round(p_model_a[example], 3)))
print(questions[example, , drop = FALSE])
