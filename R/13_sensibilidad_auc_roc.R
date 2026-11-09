# Eli, C1b/C2, issue #33. Preparado con asistencia de ChatGPT/Codex.
# Entrada completa: Rscript R/12_sensibilidad.R (C1 + C1b + C2).
# Este archivo por separado: Rscript R/13_sensibilidad_auc_roc.R (solo C1b/C2).
# Requiere MASS y pROC; no ejecuta R/11 ni genera folds.

ejecutar_auc_sensibilidad <- function() {
  stopifnot(requireNamespace("MASS", quietly = TRUE), requireNamespace("pROC", quietly = TRUE))
  entrada <- "data/derivados/base_regresiones_2026-10-28_v2.csv.gz"
  folds_file <- "R/resultados/auc/folds_5.csv"
  salida <- "R/resultados/sensibilidad_auc_2026-11-09"
  protegidos <- c(entrada, list.files("R/resultados/auc", full.names = TRUE))
  hashes <- tools::md5sum(protegidos)
  base <- read.csv(gzfile(entrada), stringsAsFactors = FALSE)
  folds <- read.csv(folds_file, stringsAsFactors = FALSE)
  stopifnot(identical(names(folds), c("id", "fold")), !anyNA(folds),
            !anyDuplicated(folds$id), setequal(folds$id, base$id),
            setequal(folds$fold, 1:5), all(table(base$id) == 2L))
  base$fold <- folds$fold[match(base$id, folds$id)]
  stopifnot(!anyNA(base$fold),
            all(tapply(base$fold, base$evaluation_session_id, function(f) length(unique(f))) == 1L))
  base <- base[!base$requiere_revision, ]
  predictores <- c("is_code", "math", "creative_writing", "instruction_following",
                   "complexity", "creativity", "domain_knowledge", "problem_solving",
                   "real_world", "specificity", "technical_accuracy")
  for (p in predictores) base[[p]] <- as.integer(base[[p]])
  base$y <- base$won_medio_punto_escenario
  base$ordinal <- ordered(ifelse(!base$es_decisivo, "empate",
                                ifelse(base$won == 1, "mejor", "peor")),
                          levels = c("peor", "empate", "mejor"))
  stopifnot(!anyNA(base[c(predictores, "y", "ordinal")]), length(unique(base$model)) == 48L)
  modelos <- sort(unique(base$model))
  metodos <- c("binomial", "quasibinomial", "ordinal")
  fg <- reformulate(predictores, response = "y")
  fo <- reformulate(predictores, response = "ordinal")
  roc <- function(y, p) {
    stopifnot(length(y) == length(p), !anyNA(y), all(is.finite(p)))
    if (length(unique(y)) < 2L) return(NULL)
    pROC::roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE)
  }
  auc <- function(y, p) {
    r <- roc(y, p)
    if (is.null(r)) return(NA_real_)
    valor <- as.numeric(pROC::auc(r))
    n1 <- sum(y == 1); n0 <- sum(y == 0)
    rango <- (sum(rank(p)[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
    stopifnot(abs(valor - rango) < 1e-10)
    valor
  }
  votos <- por_modelo <- controles <- oof <- list()
  for (f in c(0L, 1:5)) {
    escenario <- if (f == 0L) "all_data" else "cv5"
    etiqueta <- if (f == 0L) "all" else as.character(f)
    train <- if (f == 0L) base else base[base$fold != f, ]
    test <- if (f == 0L) base else base[base$fold == f, ]
    if (f > 0L) stopifnot(!length(intersect(train$id, test$id)),
                          !length(intersect(train$evaluation_session_id, test$evaluation_session_id)))
    # Todas las variantes se evalúan sobre EXACTAMENTE las mismas filas decisivas.
    test <- test[test$es_decisivo, ]
    puntajes <- matrix(NA_real_, nrow(test), length(metodos), dimnames = list(NULL, metodos))
    tasas <- tapply(train$won[train$es_decisivo], train$model[train$es_decisivo], mean)
    for (m in modelos) {
      d <- train[train$model == m, ]
      dd <- d[d$es_decisivo, ]; dd$y <- dd$won
      stopifnot(nrow(dd) >= 100L, all(table(d$ordinal) > 0L))
      fits <- list(binomial = glm(fg, family = binomial(), data = dd, na.action = na.fail),
                   quasibinomial = glm(fg, family = quasibinomial(), data = d, na.action = na.fail),
                   ordinal = MASS::polr(fo, data = d, method = "logistic", na.action = na.fail,
                                        control = list(maxit = 1000, reltol = 1e-10)))
      stopifnot(fits$binomial$converged, fits$quasibinomial$converged,
                fits$ordinal$convergence == 0L,
                fits$binomial$rank == 12L, fits$quasibinomial$rank == 12L,
                all(is.finite(coef(fits$ordinal))))
      i <- which(test$model == m)
      for (tipo in metodos) {
        if (tipo == "ordinal") {
          # Score comparable al medio punto: E[preferencia] = P(mejor) + 0.5 P(empate).
          # No se interpreta como probabilidad pura de victoria ni como el eta de polr.
          probs <- predict(fits[[tipo]], newdata = test[i, , drop = FALSE], type = "probs")
          stopifnot(all(abs(rowSums(probs) - 1) < 1e-10))
          p <- probs[, "mejor"] + 0.5 * probs[, "empate"]
          stopifnot(all(p > 0 & p < 1))
          s <- qlogis(p)
        } else s <- predict(fits[[tipo]], newdata = test[i, , drop = FALSE], type = "link")
        stopifnot(all(is.finite(s)))
        puntajes[i, tipo] <- s
        k <- paste(escenario, etiqueta, m, tipo)
        una_clase <- length(unique(test$won[i])) < 2L
        por_modelo[[k]] <- data.frame(scenario = escenario, fold = etiqueta, model = m,
                                      method = tipo, n = length(i), auc = auc(test$won[i], s),
                                      status = if (una_clase) "one_class" else "ok")
      }
    }
    ia <- which(test$lado == "model_a")
    ib <- match(test$id[ia], test$id[test$lado == "model_b"])
    ib <- which(test$lado == "model_b")[ib]
    stopifnot(!anyNA(ib), identical(test$rival[ia], test$model[ib]))
    y <- test$won[ia]
    for (tipo in c(metodos, "general_ranking")) {
      if (tipo == "general_ranking") {
        p <- plogis(qlogis(tasas[test$model[ia]]) - qlogis(tasas[test$rival[ia]]))
      } else p <- plogis(puntajes[ia, tipo] - puntajes[ib, tipo])
      k <- paste(escenario, etiqueta, tipo)
      votos[[k]] <- data.frame(scenario = escenario, fold = etiqueta, method = tipo,
                               n_votes = length(y), auc = auc(y, p))
      if (f > 0L) oof[[k]] <- data.frame(id = test$id[ia], fold = f, y = y, method = tipo, p = p)
    }
    controles[[etiqueta]] <- data.frame(fold = etiqueta, train_votes_all = nrow(train) / 2,
                                       train_votes_decisive = sum(train$es_decisivo) / 2,
                                       test_votes_decisive = length(ia), models = length(modelos),
                                       converged_fits = length(modelos) * length(metodos))
    message("OK ", escenario, " ", etiqueta, ": 144 ajustes; ", length(ia), " votos evaluados")
  }
  unir <- function(x) { z <- do.call(rbind, x); rownames(z) <- NULL; z }
  votos <- unir(votos); por_modelo <- unir(por_modelo); controles <- unir(controles); oof <- unir(oof)
  stopifnot(!anyNA(oof), all(table(oof$id) == 4L),
            all(vapply(split(oof$fold, oof$id), function(f) length(unique(f)) == 1L, logical(1))),
            sum(controles$test_votes_decisive[controles$fold != "all"]) == sum(base$es_decisivo) / 2)
  # Reproduce los AUC binomial/base y los 48 AUC por modelo publicados por Mark.
  mark_v <- read.csv("R/resultados/auc/por_voto.csv")
  mark_m <- read.csv("R/resultados/auc/por_modelo.csv")
  diferencias <- numeric()
  for (i in seq_len(nrow(votos))) {
    z <- votos[i, ]
    if (!(z$method %in% c("binomial", "general_ranking"))) next
    ref <- mark_v[mark_v$scenario == z$scenario & mark_v$fold == z$fold, ]
    col <- if (z$method == "binomial") "auc_regression" else "auc_baseline"
    stopifnot(nrow(ref) == 1L, ref$n_votes == z$n_votes)
    diferencias <- c(diferencias, abs(z$auc - ref[[col]]))
  }
  bm <- por_modelo[por_modelo$method == "binomial", ]
  claves <- function(z) paste(z$scenario, z$fold, z$model)
  ref <- mark_m[match(claves(bm), claves(mark_m)), ]
  stopifnot(identical(is.na(bm$auc), is.na(ref$auc)))
  diferencias <- c(diferencias, abs(bm$auc - ref$auc))
  stopifnot(all(diferencias[!is.na(diferencias)] <= 0.000050001))
  medias <- unir(lapply(unique(por_modelo$method), function(tipo) {
    z <- por_modelo[por_modelo$scenario == "cv5" & por_modelo$method == tipo, ]
    unir(lapply(modelos, function(m) {
      r <- z[z$model == m, ]
      data.frame(model = m, method = tipo, folds_validos = sum(!is.na(r$auc)),
                 auc_mean = if (any(!is.na(r$auc))) mean(r$auc, na.rm = TRUE) else NA_real_)
    }))
  }))
  resumen <- unir(lapply(c(metodos, "general_ranking"), function(tipo) {
    v <- votos[votos$method == tipo, ]; cv <- v[v$scenario == "cv5", ]
    mm <- medias[medias$method == tipo, ]
    data.frame(method = tipo, auc_all_votes = v$auc[v$scenario == "all_data"],
               auc_fold1 = cv$auc[cv$fold == "1"], auc_fold2 = cv$auc[cv$fold == "2"],
               auc_fold3 = cv$auc[cv$fold == "3"], auc_fold4 = cv$auc[cv$fold == "4"],
               auc_fold5 = cv$auc[cv$fold == "5"], auc_cv_mean = mean(cv$auc),
               auc_cv_sd = sd(cv$auc), auc_model_cv_mean = if (nrow(mm)) mean(mm$auc_mean, na.rm = TRUE) else NA_real_,
               model_fold_na = if (nrow(mm)) sum(por_modelo$method == tipo & por_modelo$scenario == "cv5" & is.na(por_modelo$auc)) else NA_integer_)
  }))
  dir.create(salida, recursive = TRUE, showWarnings = FALSE)
  guardar <- function(x, f) write.csv(x, file.path(salida, f), row.names = FALSE, na = "NA")
  guardar(votos, "auc_por_voto.csv"); guardar(por_modelo, "auc_por_modelo_fold.csv")
  guardar(medias, "auc_por_modelo_promedio.csv"); guardar(resumen, "resumen.csv")
  guardar(controles, "controles.csv")
  # Las predicciones OOF quedan en memoria; el generador y los folds permiten reproducirlas.
  tabla <- c("| Método | Todos (ajuste) | Fold 1 | Fold 2 | Fold 3 | Fold 4 | Fold 5 | Media CV |",
             "|---|---:|---:|---:|---:|---:|---:|---:|")
  for (i in seq_len(nrow(resumen))) tabla <- c(tabla, paste0("| ", resumen$method[i], " | ",
    paste(sprintf("%.4f", unlist(resumen[i, c("auc_all_votes", paste0("auc_fold", 1:5), "auc_cv_mean")])), collapse = " | "), " |"))
  writeLines(tabla, file.path(salida, "tabla_principal.md"), useBytes = TRUE)
  writeLines(c("# Eli: sensibilidad AUC y gráfico ROC (C1b/C2)", "",
    "Generador: R/13_sensibilidad_auc_roc.R. Entrada completa C1+C1b+C2: Rscript R/12_sensibilidad.R.",
    "Requiere MASS y pROC. Usa folds_5.csv de Mark tal cual, sin semilla propia ni folds nuevos.",
    "No ejecuta ni modifica R/11 ni sus salidas. Se excluyen las mismas banderas de revisión que R/02.", "",
    "Binomial se ajusta solo con votos decisivos. Quasibinomial y ordinal incluyen empate/both_bad del entrenamiento.",
    "Las tres variantes se evalúan solo con las mismas filas decisivas: 1 victoria, 0 derrota.",
    "Por modelo, binomial/quasibinomial usan el predictor lineal del glm.",
    "Ordinal: puntaje = logit(P(mejor) + 0.5 P(empate)), derivado de las probabilidades de polr.",
    "Es una extensión explícita del puntaje de medio punto al ordinal, no su predictor lineal ni P(victoria decisiva).",
    "La transformación es monótona en el predictor latente: conserva su AUC dentro de cada modelo.",
    "Por voto se usa plogis(puntaje_A - puntaje_B); el resultado ordinal depende de esta conversión documentada.",
    "La línea base solo existe por voto, con tasas de victoria calculadas en el entrenamiento decisivo.", "",
    tabla, "",
    "Todos = ajuste y evaluación en los mismos datos. CV = cada sesión evaluada sin participar en el ajuste.",
    "Se exportan 48 modelos por variante y escenario/fold. AUC=NA si el test tiene una sola clase; se cuentan los casos.",
    "Media CV es el promedio simple de los cinco AUC; el AUC de una curva agrupada puede diferir ligeramente.",
    "Se verifica binomial/base contra Mark con tolerancia de redondeo y cada AUC contra la fórmula de rangos.",
    "C2 redibuja las curvas oficiales curva_roc_cv5.csv; verifica sus puntos contra las predicciones binomiales OOF.",
    "El PDF vectorial es para la presentación; no muestra julio como evaluación principal.",
    "No se afirma equivalencia predictiva por correlación alta ni por diferencias pequeñas de AUC.",
    "No se cambia el método principal, que sigue siendo binomial. Sin inferencia causal ni p-valores nuevos.", "",
    "Código, gráfico y documentación preparados con asistencia de ChatGPT/Codex (OpenAI)."),
    file.path(salida, "LEEME.md"), useBytes = TRUE)
  # C2: figura de negocios usando SOLO las curvas oficiales de Mark, sin inventar puntos/AUC.
  curva <- read.csv("R/resultados/auc/curva_roc_cv5.csv")
  stopifnot(setequal(curva$curve, c("48_regressions", "general_ranking")))
  rocs <- lapply(c("binomial", "general_ranking"), function(tipo) {
    z <- oof[oof$method == tipo, ]; roc(z$y, z$p)
  })
  pooled <- vapply(rocs, function(r) as.numeric(pROC::auc(r)), numeric(1))
  guardar(data.frame(method = c("binomial", "general_ranking"), auc_pooled_oof = pooled), "auc_curva.csv")
  for (i in seq_along(rocs)) {
    z <- curva[curva$curve == c("48_regressions", "general_ranking")[i], ]
    esperado <- pROC::coords(rocs[[i]], x = 1 - z$false_positive_rate, input = "specificity",
                             ret = "sensitivity", transpose = FALSE)[, 1]
    stopifnot(max(abs(esperado - z$true_positive_rate)) < 0.000051)
  }
  dibujar <- function() {
    par(mar = c(5, 5, 6, 2), bg = "#FAFBFD", fg = "#172B4D", col.axis = "#172B4D",
        col.lab = "#172B4D", family = "sans", las = 1)
    plot(0:1, 0:1, type = "n", xlab = "False alarms: predict A wins when B won",
         ylab = "Winners identified: predict A wins when A won", xaxs = "i", yaxs = "i",
         axes = FALSE, cex.lab = 0.9)
    abline(h = seq(0, 1, .2), v = seq(0, 1, .2), col = "#E1E7EF")
    axis(1, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
    axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
    abline(0, 1, col = "#929EAF", lty = 3, lwd = 2)
    for (i in 1:2) {
      z <- curva[curva$curve == c("48_regressions", "general_ranking")[i], ]; z <- z[order(z$false_positive_rate), ]
      lines(z$false_positive_rate, z$true_positive_rate, col = c("#146C94", "#D97732")[i], lwd = 3, lty = i)
    }
    title(main = "Question features improve predictions slightly", adj = 0, line = 3.3, cex.main = 1.25)
    mtext("5-fold validation: every vote is predicted without its session", side = 3, line = 1.7, adj = 0, cex = .9)
    legend("bottomright", bty = "n", cex = .95, col = c("#146C94", "#D97732", "#929EAF"),
           lty = c(1, 2, 3), lwd = c(3, 3, 2),
           legend = c(sprintf("Question features | AUC %.3f", pooled[1]),
                      sprintf("General ranking | AUC %.3f", pooled[2]), "Random ordering | AUC 0.500"))
    mtext(paste0(format(nrow(oof) / 4, big.mark = ",", scientific = FALSE),
                 " votes with a winner. Higher curves separate winners better. AUC is not accuracy."),
          side = 1, line = 4, adj = 0, cex = .76)
  }
  pdf(file.path(salida, "roc_presentacion.pdf"), width = 10, height = 7.5)
  dibujar(); invisible(dev.off())
  stopifnot(identical(tools::md5sum(protegidos), hashes))
  writeLines(c(paste("folds_5.csv MD5:", hashes[folds_file]),
               paste("Máxima diferencia contra CSV redondeados de Mark:", max(diferencias, na.rm = TRUE)),
               trimws(capture.output(sessionInfo()), which = "right")), file.path(salida, "verificacion.txt"))
  cat(paste(tabla, collapse = "\n"), "\n")
  invisible(resumen)
}

if (sys.nframe() == 0L) ejecutar_auc_sensibilidad()
