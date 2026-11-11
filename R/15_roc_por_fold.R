# Demo piece: ROC curves with pROC, all the data and 5 folds (phase 2b, issue #45, Mark)
#
# How to run it in RStudio, from the repo root (Session > Set Working Directory > To Project):
#   source("R/15_roc_por_fold.R")         # loads the code of the 48 regressions and the data (about 5 seconds)
#   resultado <- mostrar_roc_por_fold()   # runs the 3 steps below, all in less than 1 minute
# Or one step at a time (Cmd+Enter):
#   explicar_folds()          # step 1: how the 5 folds were made
#   roc_todos_los_datos()     # step 2: ROC curve with all the data
#   roc_cinco_folds()         # step 3: 5-fold cross-validation, 5 ROC curves and the table
#
# What the professor asked for (classes of 4/11 and 9/11): the AUC computed with pROC, first with
# all the data, then with a random 5-fold cross-validation, with the AUC of each fold.
#
# What is predicted (the response) and with what (the predictors):
#   response   : won = 1 if the model won the vote, 0 if it lost (votes with a winner only)
#   predictors : the 11 characteristics of the question (is_code, math, creative_writing, ...),
#                all known BEFORE the model writes its answer. The length of the answer is never used.
#   model      : 1 logistic regression per model, glm(won ~ 11 characteristics, family = binomial),
#                48 regressions in total (R/02, fitted by fit_set() of R/11)
#
# The AUC is computed here, on screen, with pROC::roc() and pROC::auc(). Per vote:
#   P(model A wins) = plogis(score_A - score_B)
#   score = the logit given by the regression of that model for the characteristics of the question.
# It is compared with the general ranking (the % of votes each model wins, all types of question
# together): plogis(logit(rate_A) - logit(rate_B)).
#
# The fits and the folds are the same ones as in R/11_auc_proc.R and R/resultados/auc/folds_5.csv,
# so the numbers are the ones of the report (docs/05). This file does not write anything.

library(pROC)

# ---- 1. Load the code of the 48 regressions (R/11) and the data -----------------------------
# correr_11 = FALSE: load only the functions and the data. No fits, no files written.
message("Loading the 48 regressions and the data ...")
opciones_antes <- options(correr_11 = FALSE)
ancho_antes    <- options(width = getOption("width"))   # R/11 widens the console; we put it back
roc11 <- new.env()
invisible(capture.output(sys.source("R/11_auc_proc.R", envir = roc11)))   # R/11 prints its own notes: hidden here
options(opciones_antes)
options(ancho_antes)
rm(opciones_antes, ancho_antes)
message("Ready. Run: resultado <- mostrar_roc_por_fold()")

# ---- 2. Small helpers ---------------------------------------------------------------------------

# P(model A wins) for each vote, from the regressions and from the general ranking.
# `ajuste` = the 48 regressions + the general win rate of each model (made by fit_set() of R/11).
puntajes_por_voto <- function(ajuste, ev) {
  votos <- ev[ev$lado == "model_a", ]                  # 1 row per vote (the row of model A)
  votos <- votos[votos$model %in% names(ajuste$fits) & votos$rival %in% names(ajuste$fits), ]
  x <- votos[roc11$predictors]                         # the 11 characteristics of the question
  score_A <- roc11$linear_predictor(ajuste$fits, votos$model, x)   # logit, regression of model A
  score_B <- roc11$linear_predictor(ajuste$fits, votos$rival, x)   # logit, regression of model B
  data.frame(
    won           = votos$y,                           # 1 = model A won, 0 = model A lost
    p_regressions = plogis(score_A - score_B),
    p_ranking     = unname(plogis(qlogis(ajuste$rate[votos$model]) - qlogis(ajuste$rate[votos$rival]))))
}

# The ROC curve of pROC. levels = c(0, 1): 0 = lost, 1 = won. direction = "<": a higher P(win)
# should go with winning.
roc_de <- function(won, p) {
  pROC::roc(response = won, predictor = p, levels = c(0, 1), direction = "<", quiet = TRUE)
}

# Draws ROC curves from the objects of pROC::roc(): x = 1 - specificity, y = sensitivity.
# The axes are drawn here, so the labels look the same in any size of the Plots panel.
dibujar_roc <- function(rocs, colores, lwd, lty, titulo) {
  margen <- par(mar = c(4.5, 4.5, 4.5, 1.5), pty = "s"); on.exit(par(margen))
  plot(NA, xlim = c(0, 1), ylim = c(0, 1), xlab = "False positive rate (1 - specificity)",
       ylab = "True positive rate (sensitivity)", main = titulo)
  abline(0, 1, col = "grey70")                       # a coin flip: AUC = 0.5
  for (i in seq_along(rocs))
    lines(1 - rocs[[i]]$specificities, rocs[[i]]$sensitivities, col = colores[i], lwd = lwd, lty = lty[i])
}

# Does what we just computed match the file of the report (R/resultados/auc/por_voto.csv)?
coincide_con_csv <- function(escenario, fold, auc_regresiones, auc_ranking) {
  archivo <- "R/resultados/auc/por_voto.csv"
  if (!file.exists(archivo)) return(NA)
  csv <- read.csv(archivo, stringsAsFactors = FALSE)
  fila <- csv[csv$scenario == escenario & csv$fold == fold, ]
  nrow(fila) == 1 && isTRUE(all.equal(fila$auc_regression, round(auc_regresiones, 4))) &&
    isTRUE(all.equal(fila$auc_baseline, round(auc_ranking, 4)))
}

# ---- 3. Step 1: how the 5 folds were made ---------------------------------------------------------

explicar_folds <- function() {
  base  <- roc11$long_base
  votos <- base[base$lado == "model_a", c("id", "evaluation_session_id")]   # 1 row per vote
  votos$fold <- roc11$folds5$fold[match(votos$id, roc11$folds5$id)]
  decisivos  <- roc11$d[roc11$d$lado == "model_a", ]                        # votes with a winner
  sesiones   <- tapply(votos$evaluation_session_id, votos$fold, function(s) length(unique(s)))
  por_fold <- data.frame(fold = names(sesiones), sessions = as.integer(sesiones),
                         votes = as.integer(table(votos$fold)),
                         votes_with_winner = as.integer(table(decisivos$fold)))

  cat("\n=== Step 1: how the 5 folds were made (file R/resultados/auc/folds_5.csv) ===\n")
  cat("- The unit is the SESSION (evaluation_session_id), not the row.\n")
  cat("- Why: every vote makes 2 rows, 1 per model. If the 2 rows fell in different folds, the\n")
  cat("  fit would have seen the vote that the test is about. A session never gets split.\n")
  cat("- The", format(length(unique(votos$evaluation_session_id)), big.mark = ","), "sessions got the labels 1 to 5 in equal numbers,\n")
  cat("  shuffled with set.seed(", roc11$seed, "). The code that does it (make_folds in R/11):\n\n", sep = "")
  writeLines(paste0("    ", deparse(body(roc11$make_folds))))
  cat("\nSessions that are in more than one fold:",
      sum(tapply(votos$fold, votos$evaluation_session_id, function(f) length(unique(f))) > 1), "\n")
  rehecho <- roc11$make_folds(base)
  cat("Making the folds again from the seed gives the same file:",
      identical(rehecho$id, roc11$folds5$id) && identical(rehecho$fold, as.integer(roc11$folds5$fold)), "\n\n")
  print(por_fold, row.names = FALSE)
  invisible(por_fold)
}

# ---- 4. Step 2: ROC curve with ALL the data -------------------------------------------------------

roc_todos_los_datos <- function() {
  d <- roc11$d
  cat("\n=== Step 2: ROC curve with ALL the data ===\n")
  ajuste <- roc11$fit_set(d)          # the 48 regressions, fitted with all the votes that have a winner
  cat(length(ajuste$fits), "regressions fitted with", nrow(d) / 2, "votes that have a winner.\n\n")
  v <- puntajes_por_voto(ajuste, d)

  roc_regresiones <- roc_de(v$won, v$p_regressions)   # the 48 regressions
  roc_ranking     <- roc_de(v$won, v$p_ranking)       # the general ranking
  print(roc_regresiones)
  auc_regresiones <- as.numeric(pROC::auc(roc_regresiones))
  auc_ranking     <- as.numeric(pROC::auc(roc_ranking))
  cat("\nAUC, 48 regressions :", format(round(auc_regresiones, 4), nsmall = 4), "\n")
  cat("AUC, general ranking:", format(round(auc_ranking, 4), nsmall = 4), "\n")
  cat("Same as R/resultados/auc/por_voto.csv:", coincide_con_csv("all_data", "all", auc_regresiones, auc_ranking), "\n")

  dibujar_roc(list(roc_regresiones, roc_ranking), c("#0072B2", "#D55E00"), lwd = 3, lty = c(1, 2),
              titulo = sprintf("ROC curve, all the data\n%s votes with a winner (AUC per vote)", format(nrow(v), big.mark = ",")))
  legend("bottomright", bty = "n", lwd = 3, lty = c(1, 2), col = c("#0072B2", "#D55E00"),
         legend = c(sprintf("48 regressions (AUC = %.4f)", auc_regresiones),
                    sprintf("General ranking (AUC = %.4f)", auc_ranking)))
  invisible(list(roc_regressions = roc_regresiones, roc_ranking = roc_ranking,
                 auc_regressions = auc_regresiones, auc_ranking = auc_ranking))
}

# ---- 5. Step 3: 5-fold cross-validation ---------------------------------------------------------------

# For each fold: fit the 48 regressions WITHOUT it (4 folds), predict the votes of that fold,
# and compute the AUC with pROC. Returns the table: 1 row per fold + the mean.
roc_cinco_folds <- function() {
  d <- roc11$d
  cat("\n=== Step 3: 5-fold cross-validation (each fold is predicted without being used to fit) ===\n")
  colores <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00")
  rocs <- list(); filas <- list()
  for (f in 1:5) {
    entrenar <- d[d$fold != f, ]        # the 4 other folds: the regressions and the ranking learn here
    probar   <- d[d$fold == f, ]        # the fold left out: only used to measure
    stopifnot(length(intersect(entrenar$evaluation_session_id, probar$evaluation_session_id)) == 0)
    ajuste <- roc11$fit_set(entrenar)
    v <- puntajes_por_voto(ajuste, probar)
    rocs[[f]]       <- roc_de(v$won, v$p_regressions)
    roc_ranking     <- roc_de(v$won, v$p_ranking)
    filas[[f]] <- data.frame(fold = as.character(f), votes = nrow(v),
                             auc_regressions = as.numeric(pROC::auc(rocs[[f]])),
                             auc_general_ranking = as.numeric(pROC::auc(roc_ranking)))
    cat("  fold", f, ": fitted with", nrow(entrenar) / 2, "votes, tested on", nrow(v), "votes, AUC",
        format(round(filas[[f]]$auc_regressions, 4), nsmall = 4), "\n")
  }

  tabla <- do.call(rbind, filas)
  tabla$difference <- tabla$auc_regressions - tabla$auc_general_ranking
  promedio <- data.frame(fold = "mean", votes = sum(tabla$votes),
                         auc_regressions = mean(tabla$auc_regressions),
                         auc_general_ranking = mean(tabla$auc_general_ranking),
                         difference = mean(tabla$difference))
  tabla <- rbind(tabla, promedio)
  coincide <- vapply(seq_len(nrow(tabla)), function(i)
    isTRUE(coincide_con_csv("cv5", tabla$fold[i], tabla$auc_regressions[i], tabla$auc_general_ranking[i])),
    logical(1))
  tabla[2:5] <- lapply(tabla[2:5], function(x) if (is.double(x)) round(x, 4) else x)
  cat("\nSame as R/resultados/auc/por_voto.csv in all the rows:", all(coincide), "\n")

  dibujar_roc(rocs, colores, lwd = 2, lty = rep(1, 5),
              titulo = "ROC curves, 5-fold cross-validation\nEach fold predicted by regressions fitted without it")
  legend("bottomright", bty = "n", lwd = 2, col = colores,
         legend = sprintf("Fold %d (AUC = %.4f)", 1:5, tabla$auc_regressions[1:5]))
  tabla
}

# ---- 6. All the steps, in order ----------------------------------------------------------------------------

# Runs the 3 steps, prints the table and returns it (invisible, so it is not printed twice).
mostrar_roc_por_fold <- function() {
  inicio <- proc.time()[["elapsed"]]
  explicar_folds()
  roc_todos_los_datos()
  tabla <- roc_cinco_folds()
  cat("\n=== AUC per vote, by fold (regressions vs general ranking) ===\n")
  print(tabla, row.names = FALSE)
  cat("\nDone in", round(proc.time()[["elapsed"]] - inicio), "seconds.\n")
  invisible(tabla)
}
