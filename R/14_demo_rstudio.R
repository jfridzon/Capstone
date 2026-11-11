# Live RStudio demo for Monday 16 November 2026 (Nessim, issue #44).
# Open Capstone.Rproj; run sections with Cmd+Enter, or source this file.
# Inputs: the existing long base, shared folds and saved comparison results.
# Output: console tables and plots. This script does not write result files.
# Prepared with ChatGPT/Codex assistance; explain each section before class.

# ---- Setup: load existing functions without running their export scripts ----
if (!file.exists("R/02_regresiones_por_modelo.R")) {
  stop("Open Capstone.Rproj and run this script from the repository root.")
}

# Each teammate gets a separate environment so names do not overwrite ours.
cargar_pieza_demo <- function(path) {
  pieza <- new.env()
  # Keep nested source() calls (Marco loads R/02) in this environment too.
  pieza$source <- function(file, ...) base::source(file, local = pieza, ...)
  anteriores <- options(correr_02 = FALSE, correr_11 = FALSE)
  on.exit(options(anteriores))
  sys.source(path, envir = pieza)
  pieza
}

demo_14 <- new.env()
demo_14$model_name <- "o3-2025-04-16"
demo_14$models <- cargar_pieza_demo("R/02_regresiones_por_modelo.R")

# ---- 1. Predict a win or a loss using only the question's 11 features --------
cat("\n1. What do we predict, and with what?\n")
demo_14$votes <- demo_14$models$preparar_respuesta(
  demo_14$models$cargar_base(), politica = "excluir"
)
demo_14$features <- demo_14$models$predictores
stopifnot(all(demo_14$votes$won %in% c(0, 1)),
          !anyNA(demo_14$votes[c("won", demo_14$features)]))
cat("Response: won = 1 if the model won, 0 if it lost.\n")
cat("We use votes with a winner; flagged votes stay out.\n")
print(data.frame(
  feature = demo_14$features,
  meaning = c(
    "Code", "Math", "Creative writing", "Following instructions",
    "Complexity", "Creativity", "Domain knowledge", "Problem solving",
    "Real-world use", "Specificity", "Technical accuracy"
  )
), row.names = FALSE)
cat("Answer length and formatting are not predictors: they come later.\n")
cat("Decisive votes:", nrow(demo_14$votes) / 2,
    "| Models:", length(unique(demo_14$votes$model)), "\n")

# ---- 2. Fit one binomial regression; read its intercept and odds ratios -----
cat("\n2. One logistic regression, with the code visible\n")
demo_14$one_model <- demo_14$votes[
  demo_14$votes$model == demo_14$model_name, ]
if (!nrow(demo_14$one_model)) stop("The example model has no votes.")

# The same 11 features as R/02; no opponent or answer features.
demo_14$fit <- glm(
  won ~ is_code + math + creative_writing + instruction_following +
    complexity + creativity + domain_knowledge + problem_solving +
    real_world + specificity + technical_accuracy,
  family = binomial, data = demo_14$one_model
)
stopifnot(demo_14$fit$converged, all(is.finite(coef(demo_14$fit))))
cat("Model:", demo_14$model_name, "\n")
print(summary(demo_14$fit))

demo_14$odds_ratios <- data.frame(
  term = names(coef(demo_14$fit)),
  coefficient = unname(coef(demo_14$fit)),
  odds_ratio = unname(exp(coef(demo_14$fit)))
)
print(transform(demo_14$odds_ratios,
                coefficient = round(coefficient, 4),
                odds_ratio = round(odds_ratio, 4)), row.names = FALSE)
cat("Intercept: log-odds of winning when all 11 features are FALSE.\n")
cat("A feature coefficient changes log-odds, holding the others fixed.\n")
cat("exp(coef) is an odds ratio, not a change in probability.\n")
cat("These are associations, not causal effects.\n")
cat("Each vote appears twice across the 48 fits; p-values are indicative.\n")

# ---- 3. Use Mark's pROC code to draw the ROC curve with all the data --------
cat("\n3. AUC with all the data (in sample)\n")
demo_14$mark <- NULL
if (file.exists("R/15_roc_por_fold.R")) {
  # R/11 can create folds if missing: require the shared file before loading.
  if (!file.exists("R/resultados/auc/folds_5.csv")) {
    stop("The shared folds_5.csv is missing. Download it; do not make folds.")
  }
  if (!requireNamespace("pROC", quietly = TRUE)) {
    stop("Install pROC before the demo: install.packages('pROC').")
  }
  demo_14$mark <- cargar_pieza_demo("R/15_roc_por_fold.R")
  demo_14$auc_all <- demo_14$mark$roc_todos_los_datos()
  cat("These votes were also used to fit: this is descriptive.\n")
} else {
  cat("Pending Mark (#45): R/15_roc_por_fold.R is not here yet.\n")
}

# ---- 4. Hold out sessions at random; show each fold's AUC and the mean ------
cat("\n4. Five-fold cross-validation on unseen sessions\n")
if (!is.null(demo_14$mark)) {
  demo_14$fold_counts <- demo_14$mark$explicar_folds()
  demo_14$auc_folds <- demo_14$mark$roc_cinco_folds()
  print(demo_14$auc_folds, row.names = FALSE)
  cat("Fit on four folds, test on the fifth; repeat five times.\n")
  cat("The general ranking also learns only from the four training folds.\n")
  cat("AUC measures separation of wins and losses; it is not accuracy.\n")
  cat("The mean above is the mean of five AUCs, not a pooled-curve AUC.\n")
} else {
  cat("Pending Mark (#45): live fold evaluation was not run.\n")
}

# ---- 5. Use Eli's coefficient chart and the heatmap of all 48 models --------
cat("\n5. Coefficients and their uncertainty\n")
demo_14$eli <- NULL
if (file.exists("R/16_graficos_coeficientes.R")) {
  demo_14$eli <- cargar_pieza_demo("R/16_graficos_coeficientes.R")
  demo_14$eli$grafico_coeficientes(demo_14$model_name)
  demo_14$eli$heatmap_48()
} else {
  cat("Pending Eli (#46): R/16_graficos_coeficientes.R is not here yet.\n")
}

# ---- 6. Use Eli's sensitivity table to compare the three regression fits ---
cat("\n6. Binomial, quasibinomial and ordinal: sensitivity check\n")
if (!is.null(demo_14$eli)) {
  demo_14$sensitivity <- demo_14$eli$tabla_sensibilidad()
  print(demo_14$sensitivity, row.names = FALSE)
  cat("Similar AUCs are a sensitivity check, not proof of equivalence.\n")
} else {
  cat("Pending Eli (#46): the live sensitivity table was not loaded.\n")
}

# ---- 7. Read Bradley-Terry's saved AUC as a brief, secondary comparison -----
cat("\n7. Bradley-Terry: a comparison after the simple regressions\n")
demo_14$bt <- read.csv("R/resultados/bradley_terry/por_voto.csv",
                       stringsAsFactors = FALSE)
demo_14$bt_mean <- demo_14$bt[
  demo_14$bt$scenario == "cv5" & demo_14$bt$fold == "mean", ]
stopifnot(nrow(demo_14$bt_mean) == 1L,
          is.finite(demo_14$bt_mean$auc_bradley_terry),
          is.finite(demo_14$bt_mean$auc_48_regresiones),
          is.finite(demo_14$bt_mean$auc_ranking_general))
cat(sprintf(
  "Mean CV AUC: Bradley-Terry %.4f; 48 regressions %.4f; general ranking %.4f.\n",
  demo_14$bt_mean$auc_bradley_terry,
  demo_14$bt_mean$auc_48_regresiones,
  demo_14$bt_mean$auc_ranking_general
))
cat("Saved results on the same held-out votes; Bradley-Terry models both opponents.\n")
cat("Its fit includes half points for ties; the 48 fits use decisive votes.\n")

# ---- 8. Use Marco's live top-three examples, with and without a budget ------
cat("\n8. From predictions to a useful choice\n")
demo_14$marco <- NULL
if (file.exists("R/17_top3_en_vivo.R")) {
  # Marco's script defines top3_en_vivo() and runs its three examples on source.
  demo_14$marco <- cargar_pieza_demo("R/17_top3_en_vivo.R")
} else {
  cat("Pending Marco (#47): R/17_top3_en_vivo.R is not here yet.\n")
}
cat("Prices are the dataset's historical output-token prices, not a current quote.\n")

demo_14$integration <- data.frame(
  piece = c("Nessim", "Mark", "Eli", "Marco"),
  loaded = c(TRUE, !is.null(demo_14$mark),
             !is.null(demo_14$eli), !is.null(demo_14$marco))
)
cat("\nDemo integration status (missing pieces must be added before class)\n")
print(demo_14$integration, row.names = FALSE)
