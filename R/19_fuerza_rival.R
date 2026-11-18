# Eli: tarea del 18/11/2026 (docs/18, PR #63).
# Preparado con asistencia de ChatGPT/Codex (OpenAI).
# Desde la raiz: Rscript --vanilla R/19_fuerza_rival.R
# En la demo: source("R/19_fuerza_rival.R"); escalera_auc(); tabla_auc_rival()
# source() solo define funciones. No cambia interfaces de otros scripts.
# Respuesta: won 1/0, solo votos decisivos sin revision. Sin ridge ni stepwise.
# Tres variantes: mismas 11 etiquetas, solo rival, etiquetas + rival.
# Fuerza = victorias/participaciones del rival, SOLO en los datos de entrenamiento.
# Todos los datos es descriptivo dentro de muestra; no es validacion externa.

.eli19_dir <- "R/resultados/fuerza_rival"
.eli19_variantes <- c("labels_only", "opponent_only", "labels_opponent")

.eli19_datos <- function() {
  e <- new.env()
  anterior <- options(correr_02 = FALSE)
  on.exit(options(anterior))
  sys.source("R/02_regresiones_por_modelo.R", envir = e)
  base <- e$cargar_base()
  folds <- read.csv("R/resultados/auc/folds_5.csv", stringsAsFactors = FALSE)
  stopifnot(identical(names(folds), c("id", "fold")), !anyNA(folds),
            !anyDuplicated(folds$id), setequal(folds$id, base$id),
            all(folds$fold %in% 1:5), !anyNA(base$evaluation_session_id))
  base$fold <- folds$fold[match(base$id, folds$id)]
  stopifnot(all(tapply(base$fold, base$evaluation_session_id,
                      function(x) length(unique(x))) == 1L))
  d <- e$preparar_respuesta(base, politica = "excluir", sin_revision = TRUE)
  stopifnot(all(d$won %in% c(0, 1)), all(table(d$id) == 2L),
            !anyNA(d[c("won", "model", "rival", "fold", e$predictores)]),
            length(unique(d$model)) == 48L)
  a <- d[d$lado == "model_a", ]
  b <- d[d$lado == "model_b", ]
  b <- b[match(a$id, b$id), ]
  stopifnot(nrow(a) == nrow(b), !anyDuplicated(a$id),
            all(a$model == b$rival), all(a$rival == b$model),
            all(a$won + b$won == 1), all(a$fold == b$fold),
            identical(unname(as.matrix(a[e$predictores])),
                      unname(as.matrix(b[e$predictores]))))
  list(d = d, features = e$predictores)
}

# Funcion pura: solo recibe entrenamiento, nunca el fold de prueba.
.eli19_tasas <- function(train) {
  stopifnot(nrow(train) > 0L, !anyNA(train[c("won", "model")]),
            all(train$won %in% c(0, 1)))
  n <- table(train$model)
  wins <- tapply(train$won, train$model, sum)
  data.frame(model = names(n), n_train = as.integer(n),
             wins_train = unname(wins[names(n)]),
             strength = unname(wins[names(n)]) / as.integer(n))
}

.eli19_con_rival <- function(rows, rates) {
  rows$fuerza_rival <- rates$strength[match(rows$rival, rates$model)]
  if (anyNA(rows$fuerza_rival)) stop("Opponent missing from training data.")
  stopifnot(all(is.finite(rows$fuerza_rival)),
            all(rows$fuerza_rival >= 0 & rows$fuerza_rival <= 1))
  rows
}

.eli19_auc <- function(y, score) {
  stopifnot(length(y) == length(score), !anyNA(y), all(y %in% c(0, 1)),
            all(is.finite(score)))
  if (!length(y) || length(unique(y)) < 2L) return(NA_real_)
  auc <- as.numeric(pROC::auc(pROC::roc(y, score, levels = c(0, 1),
                                       direction = "<", quiet = TRUE)))
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  ranks <- (sum(rank(score)[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
  stopifnot(abs(auc - ranks) < 1e-10)
  auc
}

.eli19_tabla <- function(name) {
  file <- file.path(.eli19_dir, name)
  if (!file.exists(file)) stop("Run Rscript --vanilla R/19_fuerza_rival.R first: ", file)
  read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
}

# Promedio SIMPLE de los 48 AUC por modelo; nunca AUC por voto ni AUC agrupado.
# Devuelve SIEMPRE las cuatro filas juntas; los valores conservan precision.
escalera_auc <- function() {
  d <- .eli19_tabla("escalera_auc.csv")
  stopifnot(nrow(d) == 4L, identical(d$Method,
    c("Coin (constant score)", "Question labels only", "Opponent strength only",
      "Question labels + opponent strength")))
  cat("AUC per AI model; unweighted mean over the 48 models. AUC is not accuracy.\n",
      "All data is in sample; each CV fold contains unseen sessions.\n",
      "Compare the last two rows to see what the question labels add.\n", sep = "")
  d
}

# Exactamente 48 filas x 7 columnas numericas; IDs en rownames como AUC_48x7.
tabla_auc_rival <- function() {
  d <- .eli19_tabla("auc_rival_48x7.csv")
  stopifnot(nrow(d) == 48L, !anyDuplicated(d$model))
  rownames(d) <- d$model
  d$model <- NULL
  stopifnot(identical(dim(d), c(48L, 7L)))
  d
}

.eli19_correr <- function() {
  anterior <- options(warn = 2, width = 180)
  on.exit(options(anterior))
  if (!requireNamespace("pROC", quietly = TRUE)) stop("Install the pROC package first.")
  dir.create(.eli19_dir, recursive = TRUE, showWarnings = FALSE)
  protected_files <- function() {
    p <- unlist(lapply(c("data", "entregas", "R/resultados"), function(x)
      list.files(x, recursive = TRUE, full.names = TRUE, all.files = TRUE)), use.names = FALSE)
    p[!startsWith(p, paste0(.eli19_dir, "/"))]
  }
  protected <- protected_files()
  hashes <- tools::md5sum(protected)
  input <- .eli19_datos()
  d <- input$d
  features <- input$features
  models <- sort(unique(d$model))
  formulas <- list(labels_only = reformulate(features, "won"),
                   opponent_only = won ~ fuerza_rival,
                   labels_opponent = reformulate(c(features, "fuerza_rival"), "won"))
  auc_rows <- list(); fit_rows <- list(); rate_rows <- list(); control_rows <- list()
  predictions <- list()
  cat("Response: won (1 = win, 0 = loss), decisive votes only.\n")
  cat("AI models:", length(models), "| decisive votes:", length(unique(d$id)), "\n")
  cat("All 11 question labels retained. Opponent strength is a training-only win rate.\n")
  for (fold in 0:5) {
    scenario <- if (fold == 0) "all_data" else "cv5"
    label <- if (fold == 0) "all" else as.character(fold)
    train <- if (fold == 0) d else d[d$fold != fold, ]
    test <- if (fold == 0) d else d[d$fold == fold, ]
    overlap_votes <- length(intersect(train$id, test$id))
    overlap_sessions <- length(intersect(train$evaluation_session_id, test$evaluation_session_id))
    if (fold != 0) stopifnot(overlap_votes == 0L, overlap_sessions == 0L)
    rates <- .eli19_tasas(train)
    stopifnot(setequal(rates$model, models))
    rate_rows[[length(rate_rows) + 1L]] <- data.frame(scenario, fold = label, rates)
    control_rows[[length(control_rows) + 1L]] <- data.frame(scenario, fold = label,
      train_votes = length(unique(train$id)), test_votes = length(unique(test$id)),
      train_sessions = length(unique(train$evaluation_session_id)),
      test_sessions = length(unique(test$evaluation_session_id)),
      overlap_votes, overlap_sessions)
    train <- .eli19_con_rival(train, rates)
    test <- .eli19_con_rival(test, rates)
    for (model in models) {
      tr <- train[train$model == model, ]
      te <- test[test$model == model, ]
      stopifnot(nrow(tr) >= 100L, length(unique(tr$won)) == 2L, nrow(te) > 0L)
      for (variant in .eli19_variantes) {
        fit <- glm(formulas[[variant]], family = binomial(), data = tr)
        stopifnot(fit$converged, all(is.finite(coef(fit))))
        score <- as.numeric(predict(fit, newdata = te, type = "link"))
        auc <- .eli19_auc(te$won, score)
        auc_rows[[length(auc_rows) + 1L]] <- data.frame(scenario, fold = label,
          variant, model, n_train = nrow(tr), n_test = nrow(te),
          n_wins = sum(te$won), auc, status = if (is.na(auc)) "one_class" else "ok")
        fit_rows[[length(fit_rows) + 1L]] <- data.frame(scenario, fold = label,
          variant, model, term = names(coef(fit)), estimate = unname(coef(fit)),
          converged = fit$converged)
        if (variant == "labels_opponent" && fold != 0L) {
          predictions[[length(predictions) + 1L]] <- data.frame(
            id = te$id, fold = te$fold, model = te$model, rival = te$rival,
            lado = te$lado, won = te$won, opponent_strength = te$fuerza_rival,
            score = score, probability = plogis(score))
        }
      }
    }
    cat("Completed:", scenario, label, "| training votes:", length(unique(train$id)),
        "| evaluation votes:", length(unique(test$id)), "\n")
  }
  aucs <- do.call(rbind, auc_rows)
  fits <- do.call(rbind, fit_rows)
  controls <- do.call(rbind, control_rows)
  stopifnot(nrow(aucs) == 48L * 3L * 6L)
  # Reproduce el redondeo de los 288 AUC originales de Mark, sin modificarlos.
  saved <- read.csv("R/resultados/auc/por_modelo.csv", stringsAsFactors = FALSE)
  saved <- saved[saved$fold %in% c("all", as.character(1:5)), ]
  labels <- aucs[aucs$variant == "labels_only", ]
  key <- function(x) paste(x$scenario, x$fold, x$model)
  idx <- match(key(labels), key(saved))
  stopifnot(nrow(saved) == 288L, !anyNA(idx),
            identical(is.na(labels$auc), is.na(saved$auc[idx])))
  ok <- !is.na(labels$auc)
  stopifnot(max(abs(round(labels$auc[ok], 4) - saved$auc[idx][ok])) < 1e-9)
  # No na.rm: un AUC ausente mantiene NA y su conteo queda visible.
  table_for <- function(variant) {
    x <- aucs[aucs$variant == variant, ]
    z <- data.frame(model = models)
    for (f in 1:5) {
      r <- x[x$fold == as.character(f), ]
      z[[paste0("Fold_", f)]] <- r$auc[match(models, r$model)]
    }
    z$Mean_CV <- rowMeans(z[paste0("Fold_", 1:5)])
    r <- x[x$fold == "all", ]
    z$All_data <- r$auc[match(models, r$model)]
    z
  }
  tables <- lapply(.eli19_variantes, table_for)
  numeric_cols <- c("All_data", paste0("Fold_", 1:5), "Mean_CV")
  ladder <- data.frame(Method = c("Coin (constant score)", "Question labels only",
    "Opponent strength only", "Question labels + opponent strength"),
    rbind(rep(0.5, 7), do.call(rbind, lapply(tables,
      function(x) colMeans(x[numeric_cols])))), check.names = FALSE)
  names(ladder)[-1] <- numeric_cols
  delta <- data.frame(Comparison = c("Opponent vs labels", "Labels added to opponent"),
    All_data = c(ladder$All_data[3] - ladder$All_data[2], ladder$All_data[4] - ladder$All_data[3]),
    Mean_CV = c(ladder$Mean_CV[3] - ladder$Mean_CV[2], ladder$Mean_CV[4] - ladder$Mean_CV[3]))
  pred <- do.call(rbind, predictions)
  a <- pred[pred$lado == "model_a", ]
  b <- pred[pred$lado == "model_b", ]
  b <- b[match(a$id, b$id), ]
  stopifnot(nrow(pred) == nrow(d), !anyDuplicated(paste(pred$id, pred$model)),
            !anyDuplicated(a$id), identical(a$id, b$id), all(a$fold == b$fold),
            all(a$model == b$rival), all(a$won + b$won == 1))
  paired <- data.frame(id = a$id, fold = a$fold, model_a = a$model, model_b = b$model,
    y = a$won, score_A = a$score, score_B = b$score,
    p_A = plogis(a$score - b$score))
  save_csv <- function(x, file) write.csv(x, file.path(.eli19_dir, file), row.names = FALSE)
  save_csv(aucs, "auc_por_modelo_fold.csv")
  save_csv(fits, "coeficientes.csv")
  save_csv(do.call(rbind, rate_rows), "fuerzas_entrenamiento.csv")
  save_csv(controls, "controles_folds.csv")
  save_csv(ladder, "escalera_auc.csv")
  save_csv(delta, "incrementos_auc.csv")
  for (i in seq_along(tables)) save_csv(tables[[i]], paste0("auc_48x7_", .eli19_variantes[i], ".csv"))
  save_csv(tables[[3]], "auc_rival_48x7.csv")
  con <- gzfile(file.path(.eli19_dir, "predicciones_cv.csv.gz"), "wt")
  tryCatch(write.csv(pred, con, row.names = FALSE), finally = close(con))
  con <- gzfile(file.path(.eli19_dir, "predicciones_por_voto_cv.csv.gz"), "wt")
  tryCatch(write.csv(paired, con, row.names = FALSE), finally = close(con))
  cat("\nAUC PER AI MODEL: COMPLETE BASELINE LADDER\n")
  print(escalera_auc(), row.names = FALSE, digits = 7)
  cat("\nIncremental AUC (descriptive; no equivalence claim)\n")
  print(delta, row.names = FALSE, digits = 7)
  cat("\nAI model/fold AUCs missing:", sum(is.na(aucs$auc)), "\n")
  cat("All", nrow(aucs), "fits converged. Original label-only AUCs reproduced.\n")
  stopifnot(identical(protected, protected_files()),
            identical(hashes, tools::md5sum(protected)))
  cat("Protected file hashes and inventory unchanged:", length(protected), "\n")
  writeLines(c(capture.output(sessionInfo()),
    paste("pROC:", as.character(utils::packageVersion("pROC"))),
    paste("Protected files unchanged:", length(protected)),
    paste("Missing AUCs:", sum(is.na(aucs$auc)))), file.path(.eli19_dir, "verificacion.txt"))
  cat("PASS: completed Eli's opponent-strength analysis.\n")
  invisible(ladder)
}

if (sys.nframe() == 0L) .eli19_correr()
