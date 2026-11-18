# Big regression (Bradley-Terry of R/07) with 5-fold cross-validation: 0/1 versus 0.5 (Mark, 18/11).
# What the professor asked on 16/11 (docs/18): fit the big regression with 5-fold in two ways,
# 0/1 and 0.5, and if they give a similar result, keep the 0/1 one (the correct model for a 0/1 outcome).
# Then compare its AUC per vote with the 48 regression models and with the general ranking.
#
# How to run it in RStudio, from the repo root (Session > Set Working Directory > To Project):
#   source("R/20_regresion_grande_cv.R")      # recomputes everything, about 30 seconds
# To only SHOW the saved result (instant, for the demo):
#   options(correr_20 = FALSE); source("R/20_regresion_grande_cv.R")
#   tabla_regresion_grande(); explicar_regresion_grande()
#
# What is predicted (the response) and with what (the predictors):
#   response   : did AI model A win the vote against AI model B (1 = yes, 0 = no)
#   predictors : the strength of each AI model and, for each AI model, its strength in each of the 11
#                characteristics of the question (all known BEFORE the models answer).
#                The length of the answer is never used. One single regression model for all the votes.
#
# The two versions (same regression, same ridge, same 5 folds of R/resultados/auc/folds_5.csv):
#   0/1 : trained only with the votes that have a winner (the response is 1 or 0). binomial.
#   0.5 : trained with those votes AND the tie / both_bad votes, each counted as 0.5. quasibinomial.
#         (With a response of only 0 and 1, binomial and quasibinomial are the same fit. The only real
#          difference between the two versions is whether the tie votes enter the training.)
# Both are TESTED on the same votes: the votes with a winner of the fold left out. So the two AUC and
# the AUC of the 48 regression models and of the general ranking (R/11) are measured on the same votes.
# The ridge penalty and its lambda are chosen as in R/07: inside the training folds, never with the test fold.
# The 0.5 version must give the same numbers saved by R/07; the script checks it.
#
# Output (R/resultados/regresion_grande_cv_2026-11-18/):
#   por_voto_01_vs_05.csv      the two versions, fold by fold: AUC, difference, paired DeLong test, accuracy, log-loss
#   comparacion_por_voto.csv   AUC per vote side by side: big regression 0/1, big regression 0.5, 48 models, general ranking
# R/07, R/11, R/14 to R/18 and their results are NOT touched: this script only reads them.

salida_20 <- "R/resultados/regresion_grande_cv_2026-11-18"

correr_regresion_grande <- function() {
  suppressPackageStartupMessages({ library(Matrix); library(glmnet); library(pROC) })

  # ---- 1. Data: the same votes and the same folds as R/07 ----------------------------------------------
  modelos_48 <- new.env()
  opciones <- options(correr_02 = FALSE)
  tryCatch(sys.source("R/02_regresiones_por_modelo.R", envir = modelos_48), finally = options(opciones))

  base <- modelos_48$cargar_base()
  base_a <- base[base$lado == "model_a", ]                       # 1 row per vote
  folds <- read.csv("R/resultados/auc/folds_5.csv", colClasses = c("character", "integer"))
  stopifnot(identical(names(folds), c("id", "fold")),
            !anyNA(folds), !anyDuplicated(folds$id), !anyDuplicated(base_a$id),
            setequal(folds$id, base_a$id), setequal(folds$fold, 1:5),
            !anyNA(base_a$evaluation_session_id))
  base_a$fold <- folds$fold[match(base_a$id, folds$id)]
  stopifnot(!anyDuplicated(unique(base_a[c("evaluation_session_id", "fold")])$evaluation_session_id))

  votos <- modelos_48$preparar_respuesta(base_a, politica = "medio_punto")     # y is 0, 0.5 or 1
  decisivos <- modelos_48$preparar_respuesta(base_a, politica = "excluir")     # y is 0 or 1
  caracteristicas <- modelos_48$predictores
  stopifnot(all(votos$y %in% c(0, 0.5, 1)), !anyNA(votos[caracteristicas]),
            all(votos$model != votos$rival), all(votos$es_decisivo == (votos$y != 0.5)),
            setequal(decisivos$id, votos$id[votos$es_decisivo]), all(decisivos$y %in% c(0, 1)),
            all(decisivos$y == votos$y[match(decisivos$id, votos$id)]))
  cat("Votes with a winner:", sum(votos$es_decisivo), "| tie and both_bad votes:", sum(!votos$es_decisivo),
      "| 48 AI models + 11 characteristics\n")

  referencia <- "claude-opus-4-20250514"
  modelos <- sort(unique(c(votos$model, votos$rival)))
  stopifnot(referencia %in% modelos)
  efectos <- setdiff(modelos, referencia)

  # x_m is +1 for A, -1 for B and 0 if m is not in the vote. The reference has no column.
  # Each extra block is x_m times a characteristic of the question (the same matrix as R/07).
  columnas <- match(c(votos$model, votos$rival), efectos)
  incluidas <- !is.na(columnas)
  x <- sparseMatrix(i = rep(seq_len(nrow(votos)), 2)[incluidas], j = columnas[incluidas],
                    x = rep(c(1, -1), each = nrow(votos))[incluidas],
                    dims = c(nrow(votos), length(efectos)), dimnames = list(NULL, efectos))
  interacciones <- lapply(caracteristicas, function(k) {
    z <- drop0(x * as.numeric(votos[[k]]))
    colnames(z) <- paste(efectos, k, sep = ":")
    z
  })
  X <- do.call(cbind, c(list(x), interacciones))
  penalizacion <- c(rep(0, ncol(x)), rep(1, ncol(X) - ncol(x)))   # ridge only on the characteristic blocks
  lambdas <- 10^seq(-5, -0.5, by = 0.5)

  # ---- 2. Fit, choose lambda, measure (same logic as R/07, but for any set of training rows) ------------
  ajustar <- function(filas, lambda) {
    y <- votos$y[filas]
    # Two proportions that add 1 per vote: with y = 0 or 1 this is the binomial fit; with y = 0.5 it is
    # the quasibinomial fit (same objective, logit link) plus the ridge term.
    ajuste <- glmnet(X[filas, , drop = FALSE], cbind(1 - y, y), family = "binomial", alpha = 0,
                     lambda = lambda, intercept = FALSE, standardize = FALSE, penalty.factor = penalizacion)
    stopifnot(ajuste$jerr == 0L, identical(ajuste$lambda, lambda), all(ajuste$a0 == 0))
    ajuste
  }

  # `universo` = the rows this version may use for training (all votes for 0.5, only votes with a winner for 0/1).
  # Inside the training folds, each fold takes a turn as validation (votes with a winner), as in R/07.
  elegir_lambda <- function(universo, folds_train) {
    perdida <- numeric(length(lambdas))
    for (f in folds_train) {
      train <- universo[votos$fold[universo] %in% setdiff(folds_train, f)]
      val <- which(votos$fold == f & votos$es_decisivo)
      ajuste <- ajustar(train, rev(lambdas))
      eta <- predict(ajuste, X[val, , drop = FALSE], s = lambdas, type = "link")
      perdida <- perdida + colSums(pmax(eta, 0) - votos$y[val] * eta + log1p(exp(-abs(eta))))
    }
    lambdas[which.min(perdida)]
  }

  universo_01 <- which(votos$es_decisivo)
  universo_05 <- seq_len(nrow(votos))

  medir <- function(fit_01, fit_05, test, scenario, fold, lambda_01, lambda_05, n_train_01, n_train_05) {
    y <- votos$y[test]
    stopifnot(all(y %in% c(0, 1)))
    p_01 <- drop(predict(fit_01, X[test, , drop = FALSE], type = "response"))
    p_05 <- drop(predict(fit_05, X[test, , drop = FALSE], type = "response"))
    stopifnot(all(is.finite(p_01)), all(is.finite(p_05)))
    roc_01 <- roc(y, p_01, levels = c(0, 1), direction = "<", quiet = TRUE)
    roc_05 <- roc(y, p_05, levels = c(0, 1), direction = "<", quiet = TRUE)
    logloss <- function(p) -mean(ifelse(y == 1, log(p), log1p(-p)))
    data.frame(scenario, fold, n_votes = length(y), n_train_01, n_train_05, lambda_01, lambda_05,
               auc_big_01 = as.numeric(auc(roc_01)), auc_big_05 = as.numeric(auc(roc_05)),
               auc_difference_05_minus_01 = as.numeric(auc(roc_05)) - as.numeric(auc(roc_01)),
               p_delong_paired = roc.test(roc_01, roc_05, method = "delong", paired = TRUE)$p.value,
               cor_linear_predictor = cor(qlogis(p_01), qlogis(p_05)),
               correct_01 = sum((p_01 > 0.5) == (y == 1)), correct_05 = sum((p_05 > 0.5) == (y == 1)),
               logloss_01 = logloss(p_01), logloss_05 = logloss(p_05))
  }

  # ---- 3. All the data first (in sample), then 5-fold ----------------------------------------------------
  grupos <- sort(unique(folds$fold))
  cat("\nChoosing lambda and fitting the two versions: all data, then 5 folds (about 30 seconds)...\n")
  lambda_01 <- elegir_lambda(universo_01, grupos); lambda_05 <- elegir_lambda(universo_05, grupos)
  resultados <- medir(ajustar(universo_01, lambda_01), ajustar(universo_05, lambda_05), universo_01,
                      "all_data", "all", lambda_01, lambda_05, length(universo_01), length(universo_05))
  for (f in grupos) {
    folds_train <- setdiff(grupos, f)
    tr_01 <- universo_01[votos$fold[universo_01] %in% folds_train]
    tr_05 <- universo_05[votos$fold[universo_05] %in% folds_train]
    stopifnot(!any(votos$fold[c(tr_01, tr_05)] == f))                 # the test fold never trains
    lambda_01 <- elegir_lambda(universo_01, folds_train); lambda_05 <- elegir_lambda(universo_05, folds_train)
    test <- which(votos$fold == f & votos$es_decisivo)
    resultados <- rbind(resultados, medir(ajustar(tr_01, lambda_01), ajustar(tr_05, lambda_05), test,
                                          "cv5", as.character(f), lambda_01, lambda_05, length(tr_01), length(tr_05)))
    cat("  fold", f, "done\n")
  }
  cv <- resultados[resultados$scenario == "cv5", ]
  resultados <- rbind(resultados, data.frame(
    scenario = "cv5", fold = "mean", n_votes = sum(cv$n_votes), n_train_01 = NA_integer_, n_train_05 = NA_integer_,
    lambda_01 = NA_real_, lambda_05 = NA_real_,
    auc_big_01 = mean(cv$auc_big_01), auc_big_05 = mean(cv$auc_big_05),
    auc_difference_05_minus_01 = mean(cv$auc_difference_05_minus_01), p_delong_paired = NA_real_,
    cor_linear_predictor = mean(cv$cor_linear_predictor),
    correct_01 = sum(cv$correct_01), correct_05 = sum(cv$correct_05),
    logloss_01 = weighted.mean(cv$logloss_01, cv$n_votes), logloss_05 = weighted.mean(cv$logloss_05, cv$n_votes)))
  resultados$accuracy_percent_01 <- 100 * resultados$correct_01 / resultados$n_votes
  resultados$accuracy_percent_05 <- 100 * resultados$correct_05 / resultados$n_votes

  # ---- 4. Side by side with the 48 regression models and the general ranking (R/11, only read here) ------
  r11 <- read.csv("R/resultados/auc/por_voto.csv")
  r11 <- r11[match(paste(resultados$scenario, resultados$fold), paste(r11$scenario, r11$fold)), ]
  stopifnot(!anyNA(r11$n_votes), all(r11$n_votes == resultados$n_votes), all(r11$n_votes_left_out == 0))
  comparacion <- data.frame(scenario = resultados$scenario, fold = resultados$fold, n_votes = resultados$n_votes,
                            auc_big_01 = resultados$auc_big_01, auc_big_05 = resultados$auc_big_05,
                            auc_48_regresiones = r11$auc_regression, auc_ranking_general = r11$auc_baseline)

  # ---- 5. Check: the 0.5 version must be the one R/07 already saved ---------------------------------------
  r07 <- read.csv("R/resultados/bradley_terry/por_voto.csv")
  r07 <- r07[match(paste(resultados$scenario, resultados$fold), paste(r07$scenario, r07$fold)), ]
  dif_auc <- abs(round(resultados$auc_big_05, 4) - r07$auc_bradley_terry)
  mismo_lambda <- all(abs(resultados$lambda_05 - r07$lambda) < 1e-12, na.rm = TRUE)
  cat("\nCheck against R/resultados/bradley_terry/por_voto.csv (made by R/07):\n")
  cat("  the 0.5 version has the same AUC, to 4 decimals, in all", nrow(resultados), "rows:",
      all(dif_auc < 1e-9), "| largest difference:", max(dif_auc), "| same lambda:", mismo_lambda, "\n")

  # ---- 6. Save ---------------------------------------------------------------------------------------------
  redondear <- function(d) { for (k in names(d)) if (is.double(d[[k]])) d[[k]] <- if (startsWith(k, "p_")) signif(d[[k]], 3) else round(d[[k]], 4); d }
  dir.create(salida_20, showWarnings = FALSE, recursive = TRUE)
  write.csv(redondear(resultados), file.path(salida_20, "por_voto_01_vs_05.csv"), row.names = FALSE)
  write.csv(redondear(comparacion), file.path(salida_20, "comparacion_por_voto.csv"), row.names = FALSE)
  writeLines(c(R.version.string, paste("glmnet", as.character(packageVersion("glmnet"))),
               paste("pROC", as.character(packageVersion("pROC"))), paste("Matrix", as.character(packageVersion("Matrix"))),
               "big regression = Bradley-Terry of R/07, ridge (alpha = 0) chosen inside the training folds; folds from folds_5.csv"),
             file.path(salida_20, "versiones.txt"))
  cat("Saved in", salida_20, "\n")
  invisible(list(resultados = resultados, comparacion = comparacion))
}

# ---- Functions for the demo: they only READ the saved result, so they are instant ----------------------------
tabla_regresion_grande <- function(dir = salida_20) {
  comp <- read.csv(file.path(dir, "comparacion_por_voto.csv"))
  det <- read.csv(file.path(dir, "por_voto_01_vs_05.csv"))
  cat("\n=== AUC PER VOTE (AI model A vs AI model B), 5-fold, same test votes in every column ===\n")
  print(comp[comp$scenario == "cv5", ], row.names = FALSE)
  cat("\n=== Big regression model: 0/1 against 0.5, fold by fold ===\n")
  print(det[det$scenario == "cv5", c("fold", "auc_big_01", "auc_big_05", "auc_difference_05_minus_01",
                                     "p_delong_paired", "accuracy_percent_01", "accuracy_percent_05")], row.names = FALSE)
  invisible(comp)
}

explicar_regresion_grande <- function(dir = salida_20) {
  comp <- read.csv(file.path(dir, "comparacion_por_voto.csv"))
  m <- comp[comp$scenario == "cv5" & comp$fold == "mean", ]
  cat("The big regression model predicts if AI model A beats AI model B in one vote.\n")
  cat(sprintf("Counting ties as 0.5 its AUC per vote is %.4f. Leaving the ties out (0/1) it is %.4f.\n", m$auc_big_05, m$auc_big_01))
  cat(sprintf("On the same test votes, the 48 regression models give %.4f and the general ranking gives %.4f.\n",
              m$auc_48_regresiones, m$auc_ranking_general))
  cat("AUC per vote and AUC per AI model are different measures, so they cannot be compared with each other.\n")
  invisible(m)
}

if (isTRUE(getOption("correr_20", TRUE))) {
  correr_regresion_grande()
  tabla_regresion_grande()
  explicar_regresion_grande()
}
