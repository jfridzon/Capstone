# Matriz de confusión por voto, umbral 0.5 (Marco, docs/18, miércoles 18/11)
#
# Lo que pidió el profesor el 16/11 (punto 6 de docs/18): matriz de confusión y umbral
# (accuracy, recall). Aquí se hace POR VOTO, con los mismos folds de siempre.
#
# Qué se predice (variable de respuesta): en cada voto, y = 1 si ganó el modelo de IA del
# lado A (model_a), y = 0 si ganó el del lado B. Solo votos con ganador (77,843).
#
# Tres formas de predecir (las 2 primeras, las mismas de R/11 de Mark, sin cambiar nada):
#   - 48 regresiones: p = plogis(score_A - score_B). score = predictor lineal (logit) de la
#     regresión glm(..., binomial) de ese modelo de IA con las 11 etiquetas de la pregunta.
#   - 48 regresiones + fuerza del rival: igual, pero cada regresión añade fuerza_rival.
#   - Ranking general (línea base): p = plogis(logit(%vict. A) - logit(%vict. B)), con el
#     % de victorias calculado solo con los folds de entrenamiento.
# Umbral: si p > 0.5 se predice "gana A" (1); si no, "gana B" (0). Es la misma regla que
# R/11 usa para contar aciertos (score > 0), así que la accuracy se puede comprobar contra
# R/resultados/auc/por_voto.csv.
#
# Escenarios: 5-fold CV con R/resultados/auc/folds_5.csv (ajustar con 4 folds, medir en el
# que sobra) y, como referencia, todos los datos (dentro de muestra).
#
# Uso:
#   source("R/21_matriz_confusion.R")              # corre todo, imprime y guarda los CSV
#   options(correr_21 = FALSE); source("R/21_matriz_confusion.R")   # solo carga la función
#   res <- matriz_confusion()                      # umbral 0.5 por defecto
#
# Variante con la fuerza del rival (desde el 18/11): 48 regresiones con las 11 etiquetas +
# fuerza_rival, con las funciones de R/19_fuerza_rival.R (Eli). La fuerza del rival se
# calcula solo con los folds de entrenamiento.
# Necesita pROC solo porque R/11 lo carga en sus funciones.


# ---- 1. Datos, folds y funciones de R/11 (sin ajustar ni escribir nada) ------------------

env21   <- new.env()
old_opt <- options(correr_11 = FALSE)
suppressPackageStartupMessages(
  invisible(capture.output(sys.source("R/11_auc_proc.R", envir = env21))))
options(old_opt)

# Funciones de Eli (R/19) para la fuerza del rival. sys.source() solo las define; no corre
# su análisis ni escribe nada.
env19_21 <- new.env()
sys.source("R/19_fuerza_rival.R", envir = env19_21)

archivo_folds_21 <- "R/resultados/auc/folds_5.csv"
carpeta_21       <- "R/resultados/matriz_confusion"


# ---- 2. Probabilidad por voto para cada escenario (se calcula 1 vez y se guarda) ---------

.cache_21 <- new.env()

votos_con_probabilidad <- function() {
  if (!is.null(.cache_21$votos)) return(.cache_21$votos)
  d <- env21$d
  pred <- env21$predictors
  # Variante con rival (docs/18, R/19 de Eli): por modelo de IA,
  # glm(won ~ 11 etiquetas + fuerza_rival, binomial). fuerza_rival = % de victorias del rival
  # calculado SOLO con el entrenamiento. Devuelve el logit de cada fila de `test`.
  formula_rival <- reformulate(c(pred, "fuerza_rival"), response = "won")
  score_con_rival <- function(train, test) {
    tasas <- env19_21$.eli19_tasas(train)
    train <- env19_21$.eli19_con_rival(train, tasas)
    test  <- env19_21$.eli19_con_rival(test, tasas)
    s <- rep(NA_real_, nrow(test))
    for (mod in unique(test$model)) {
      fit <- glm(formula_rival, family = binomial(), data = train[train$model == mod, ])
      stopifnot(fit$converged)
      i <- which(test$model == mod)
      s[i] <- predict(fit, newdata = test[i, ], type = "link")
    }
    stopifnot(is.finite(s))
    s
  }

  un_escenario <- function(m, train, ev, escenario, fold) {
    # Logit con rival para las 2 filas de cada voto, y P(A gana) = plogis(score_A - score_B)
    s_rival <- score_con_rival(train, ev)
    clave <- paste(ev$id, ev$lado)
    v <- ev[ev$lado == "model_a", ]
    v <- v[v$model %in% names(m$fits) & v$rival %in% names(m$fits), ]
    x <- v[pred]
    score_reg  <- env21$linear_predictor(m$fits, v$model, x) -
                  env21$linear_predictor(m$fits, v$rival, x)
    score_base <- qlogis(m$rate[v$model]) - qlogis(m$rate[v$rival])
    score_riv  <- s_rival[match(paste(v$id, "model_a"), clave)] -
                  s_rival[match(paste(v$id, "model_b"), clave)]
    stopifnot(is.finite(score_reg), is.finite(score_base), is.finite(score_riv))
    list(votos = data.frame(escenario = escenario, fold = fold, id = v$id, y = v$y,
                            p_regresiones = plogis(score_reg),
                            p_ranking = unname(plogis(score_base)),
                            p_rival = plogis(score_riv)),
         filas = data.frame(escenario = escenario, fold = fold, model = ev$model,
                            y = ev$y, score_rival = s_rival))
  }
  partes <- list(un_escenario(env21$fit_set(d), d, d, "all_data", "all"))
  for (f in 1:5) {
    train <- d[d$fold != f, ]
    test  <- d[d$fold == f, ]
    stopifnot(length(intersect(train$evaluation_session_id, test$evaluation_session_id)) == 0)
    partes[[f + 1]] <- un_escenario(env21$fit_set(train), train, test, "cv5", as.character(f))
  }
  .cache_21$filas_rival <- do.call(rbind, lapply(partes, `[[`, "filas"))
  partes <- lapply(partes, `[[`, "votos")
  .cache_21$votos <- do.call(rbind, partes)
  .cache_21$votos
}


# ---- 3. La función: matriz_confusion() ---------------------------------------------------
# umbral: se predice "gana A" si p > umbral. Por defecto 0.5.
# Devuelve (invisible) una lista con:
#   $tabla    1 fila por escenario x fold x método: TP, FP, FN, TN, accuracy, precision, recall.
#             En cv5, la fila fold = "total" suma los 5 folds (cada voto se prueba 1 sola vez).
#   $matrices las 3 matrices de confusión (2 x 2) del total de los 5 folds.
# Métodos: 48 regresiones (11 etiquetas), 48 regresiones + fuerza del rival (R/19, Eli),
# y ranking general (línea base).
# Imprime una versión limpia en la consola.

matriz_confusion <- function(umbral = 0.5) {
  stopifnot(is.numeric(umbral), length(umbral) == 1, umbral > 0, umbral < 1)
  v <- votos_con_probabilidad()
  metodos <- c("48 regressions" = "p_regresiones",
               "48 regressions + opponent strength" = "p_rival",
               "General ranking" = "p_ranking")

  contar <- function(y, p) {
    pred <- as.integer(p > umbral)
    tp <- sum(pred == 1 & y == 1); fp <- sum(pred == 1 & y == 0)
    fn <- sum(pred == 0 & y == 1); tn <- sum(pred == 0 & y == 0)
    data.frame(n_votes = length(y), TP = tp, FP = fp, FN = fn, TN = tn,
               accuracy  = (tp + tn) / length(y),
               precision = tp / (tp + fp),
               recall    = tp / (tp + fn))
  }

  grupos <- list(c("all_data", "all"), c("cv5", "1"), c("cv5", "2"), c("cv5", "3"),
                 c("cv5", "4"), c("cv5", "5"), c("cv5", "total"))
  tabla <- do.call(rbind, lapply(grupos, function(g) {
    s <- if (g[2] == "total") v[v$escenario == "cv5", ] else
      v[v$escenario == g[1] & v$fold == g[2], ]
    do.call(rbind, lapply(names(metodos), function(nm)
      cbind(data.frame(scenario = g[1], fold = g[2], method = nm), contar(s$y, s[[metodos[nm]]]))))
  }))
  rownames(tabla) <- NULL

  cv <- v[v$escenario == "cv5", ]
  matrices <- lapply(metodos, function(col)
    table(Predicted = factor(ifelse(cv[[col]] > umbral, "A wins", "B wins"),
                             levels = c("A wins", "B wins")),
          Actual    = factor(ifelse(cv$y == 1, "A wins", "B wins"),
                             levels = c("A wins", "B wins"))))

  # Impresión
  cat("\n=== Confusion matrix per vote (threshold ", umbral, ") ===\n", sep = "")
  cat("- Response: y = 1 if the AI model on side A won the vote, 0 if side B won.\n")
  cat("- Predict 'A wins' when P(A wins) > ", umbral, ". Decisive votes only.\n", sep = "")
  cat("- 5-fold CV with ", archivo_folds_21, ": fit on 4 folds, test on the 5th.\n\n", sep = "")
  op <- options(width = max(getOption("width"), 120))
  on.exit(options(op))
  for (nm in names(matrices)) {
    cat(nm, " - all 5 test folds together (", format(nrow(cv), big.mark = ","), " votes):\n", sep = "")
    print(matrices[[nm]])
    cat("\n")
  }
  ver <- tabla[tabla$scenario == "cv5", c("fold", "method", "n_votes", "accuracy", "precision", "recall")]
  ver[c("accuracy", "precision", "recall")] <- round(ver[c("accuracy", "precision", "recall")], 4)
  cat("Accuracy, precision and recall per fold (positive class = 'A wins'):\n\n")
  print(ver, row.names = FALSE, right = FALSE)
  ref <- tabla[tabla$scenario == "all_data", c("method", "accuracy", "precision", "recall")]
  ref[-1] <- round(ref[-1], 4)
  cat("\nFor reference, all data (in-sample):\n\n")
  print(ref, row.names = FALSE, right = FALSE)

  invisible(list(tabla = tabla, matrices = matrices, umbral = umbral))
}


# ---- 4. Correr, comprobar y guardar (se salta con options(correr_21 = FALSE)) -----------

if (isTRUE(getOption("correr_21", TRUE))) {
  res_21 <- matriz_confusion()

  # Comprobación: los aciertos a 0.5 tienen que ser los mismos que R/11 guardó
  oficial <- read.csv("R/resultados/auc/por_voto.csv", stringsAsFactors = FALSE)
  t21 <- res_21$tabla
  for (f in c("all", as.character(1:5))) {
    o <- oficial[oficial$fold == f, ]
    a <- t21[t21$fold == f, ]
    stopifnot(o$n_votes == a$n_votes[1],
              o$correct_regression == with(a[a$method == "48 regressions", ], TP + TN),
              o$correct_baseline   == with(a[a$method == "General ranking", ], TP + TN))
  }
  vv <- votos_con_probabilidad()
  empates <- sum(vv$p_ranking == 0.5 | vv$p_regresiones == 0.5 | vv$p_rival == 0.5)
  cat("\nCheck 1: correct votes match R/resultados/auc/por_voto.csv in all 6 runs.",
      "Votes with P exactly 0.5:", empates, "\n")

  # Comprobación 2: con los mismos scores con rival, el AUC por modelo de IA y fold tiene que
  # ser el de Eli (R/resultados/fuerza_rival/auc_por_modelo_fold.csv, labels_opponent).
  eli <- read.csv("R/resultados/fuerza_rival/auc_por_modelo_fold.csv", stringsAsFactors = FALSE)
  eli <- eli[eli$variant == "labels_opponent", ]
  fr  <- .cache_21$filas_rival
  dif <- vapply(seq_len(nrow(eli)), function(i) {
    r <- fr[fr$fold == eli$fold[i] & fr$model == eli$model[i], ]
    abs(env21$auc_of(env21$roc_of(r$y, r$score_rival)) - eli$auc[i])
  }, numeric(1))
  stopifnot(nrow(eli) == 48 * 6, max(dif) < 1e-9)
  cat("Check 2: opponent-strength scores give the same", nrow(eli),
      "AI-model AUCs as Eli's R/19 (max difference", signif(max(dif), 2), ").\n")

  dir.create(carpeta_21, showWarnings = FALSE, recursive = TRUE)
  out <- t21
  out[c("accuracy", "precision", "recall")] <- round(out[c("accuracy", "precision", "recall")], 4)
  write.csv(out, file.path(carpeta_21, "matriz_confusion_por_voto.csv"), row.names = FALSE)
  cat("Saved:", file.path(carpeta_21, "matriz_confusion_por_voto.csv"), "\n")
}
