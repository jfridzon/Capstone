# Eli, C1, fase 2b (issue #33). Preparado con asistencia de ChatGPT/Codex.
# Desde la raiz: Rscript R/12_sensibilidad.R
# Requiere MASS. Solo escribe sus resultados en R/resultados/sensibilidad_2026-11-09/.
# Comparacion DESCRIPTIVA abril-julio; no es evaluacion fuera de muestra ni AUC.

ejecutar_sensibilidad <- function() {
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("Falta MASS. Instala el paquete antes de ejecutar este script.")
  }
  entrada <- "data/derivados/base_regresiones_2026-10-28_v2.csv.gz"
  salida <- "R/resultados/sensibilidad_2026-11-09"
  predictores <- c("is_code", "math", "creative_writing", "instruction_following",
                   "complexity", "creativity", "domain_knowledge", "problem_solving",
                   "real_world", "specificity", "technical_accuracy")
  huella_antes <- unname(tools::md5sum(entrada))
  base <- read.csv(gzfile(entrada), stringsAsFactors = FALSE)
  requeridas <- c("id", "model", "rival", "lado", "winner", "es_decisivo", "won",
                 "won_medio_punto_escenario", "requiere_revision", predictores)
  stopifnot(all(requeridas %in% names(base)),
            !anyNA(base[setdiff(requeridas, "won")]),
            all(base$winner %in% c("model_a", "model_b", "tie", "both_bad")),
            all(base$lado %in% c("model_a", "model_b")))
  # Misma exclusion de casos marcados que R/02; no se decide limpieza nueva.
  revision <- sum(base$requiere_revision) / 2
  base <- base[!base$requiere_revision, ]
  stopifnot(all(table(base$id) == 2L), !anyDuplicated(paste(base$id, base$lado)),
            all(base$model != base$rival), length(unique(base$model)) == 48L)
  a <- base[base$lado == "model_a", ]
  b <- base[base$lado == "model_b", ]
  b <- b[match(a$id, b$id), ]
  stopifnot(identical(a$model, b$rival), identical(a$rival, b$model),
            identical(a$winner, b$winner),
            all(vapply(predictores, function(p) identical(a[[p]], b[[p]]), logical(1))))
  decisivo <- base$winner %in% c("model_a", "model_b")
  gano <- as.integer(base$winner == base$lado)
  stopifnot(identical(base$es_decisivo, decisivo),
            all(base$won[decisivo] == gano[decisivo]),
            all(is.na(base$won[!decisivo])),
            all(base$won_medio_punto_escenario == ifelse(decisivo, gano, 0.5)))
  for (p in predictores) {
    stopifnot(all(base[[p]] %in% c(TRUE, FALSE)))
    base[[p]] <- as.integer(base[[p]])
  }
  base$y <- ifelse(decisivo, gano, 0.5)
  # both_bad se trata como empate relativo: ninguna respuesta fue mejor.
  base$ordinal <- ordered(ifelse(!decisivo, "empate", ifelse(gano == 1, "mejor", "peor")),
                          levels = c("peor", "empate", "mejor"))
  formula_glm <- reformulate(predictores, response = "y")
  formula_ordinal <- reformulate(predictores, response = "ordinal")
  modelos <- sort(unique(base$model))
  coeficientes <- interceptos <- ajustes <- correlaciones <- list()
  comparar <- function(x, y, m, nombre) {
    stopifnot(length(x) == length(predictores), all(is.finite(c(x, y))),
              sd(x) > 0, sd(y) > 0)
    data.frame(modelo = m, comparacion = nombre, efectos = length(x),
               pearson = cor(x, y), spearman = cor(x, y, method = "spearman"),
               signos_iguales = sum(sign(x) == sign(y)),
               proporcion_signos_iguales = mean(sign(x) == sign(y)))
  }
  for (m in modelos) {
    d <- base[base$model == m, ]
    dd <- d[d$es_decisivo, ]
    stopifnot(all(table(d$ordinal) > 0), nrow(dd) >= 100L,
              all(vapply(d[predictores], function(x) length(unique(x)) == 2L, logical(1))))
    # Las tres formulas tienen exactamente las mismas 11 caracteristicas, sin rival ni ridge.
    bin <- glm(formula_glm, family = binomial(), data = dd, na.action = na.fail)
    quasi <- glm(formula_glm, family = quasibinomial(), data = d, na.action = na.fail)
    ord <- MASS::polr(formula_ordinal, data = d, method = "logistic",
                      na.action = na.fail, control = list(maxit = 1000, reltol = 1e-10))
    stopifnot(bin$converged, quasi$converged, ord$convergence == 0,
              bin$rank == length(predictores) + 1L,
              quasi$rank == length(predictores) + 1L,
              nobs(bin) == nrow(dd), nobs(quasi) == nrow(d), nobs(ord) == nrow(d))
    cb <- coef(bin)[predictores]
    cq <- coef(quasi)[predictores]
    co <- coef(ord)[predictores]
    stopifnot(all(is.finite(c(cb, cq, co, ord$zeta))), all(diff(ord$zeta) > 0))
    coeficientes[[m]] <- data.frame(modelo = m, predictor = predictores,
                                    binomial = unname(cb), quasibinomial = unname(cq),
                                    ordinal = unname(co))
    interceptos[[m]] <- data.frame(modelo = m, intercepto_binomial = coef(bin)[1],
                                   intercepto_quasibinomial = coef(quasi)[1],
                                   umbral_peor_empate = ord$zeta[1],
                                   umbral_empate_mejor = ord$zeta[2], row.names = NULL)
    ajustes[[m]] <- data.frame(modelo = m, filas_binomial = nrow(dd), filas_quasibinomial = nrow(d),
                               filas_ordinal = nrow(d), perdio = sum(d$ordinal == "peor"),
                               empate = sum(d$ordinal == "empate"), gano = sum(d$ordinal == "mejor"),
                               binomial_converge = bin$converged,
                               quasibinomial_converge = quasi$converged,
                               ordinal_convergencia = ord$convergence)
    correlaciones[[m]] <- rbind(
      comparar(cb, cq, m, "binomial_vs_quasibinomial"),
      comparar(cb, co, m, "binomial_vs_ordinal"),
      comparar(cq, co, m, "quasibinomial_vs_ordinal"))
  }
  unir <- function(x) { z <- do.call(rbind, x); rownames(z) <- NULL; z }
  coeficientes <- unir(coeficientes)
  interceptos <- unir(interceptos)
  ajustes <- unir(ajustes)
  correlaciones <- unir(correlaciones)
  resumen <- unir(lapply(unique(correlaciones$comparacion), function(tipo) {
    z <- correlaciones[correlaciones$comparacion == tipo, ]
    data.frame(comparacion = tipo, modelos = nrow(z), efectos_por_modelo = length(predictores),
               pearson_min = min(z$pearson), pearson_mediana = median(z$pearson),
               pearson_max = max(z$pearson), spearman_min = min(z$spearman),
               spearman_mediana = median(z$spearman), spearman_max = max(z$spearman),
               signos_iguales = sum(z$signos_iguales), efectos_totales = sum(z$efectos))
  }))
  stopifnot(nrow(coeficientes) == length(modelos) * length(predictores),
            nrow(correlaciones) == length(modelos) * 3L,
            identical(unname(tools::md5sum(entrada)), huella_antes))
  dir.create(salida, recursive = TRUE, showWarnings = FALSE)
  guardar <- function(x, nombre) write.csv(x, file.path(salida, nombre), row.names = FALSE, na = "")
  guardar(coeficientes, "coeficientes.csv")
  guardar(interceptos, "interceptos_y_umbrales.csv")
  guardar(ajustes, "ajustes.csv")
  guardar(correlaciones, "correlaciones_por_modelo.csv")
  guardar(resumen, "resumen.csv")
  guardar(data.frame(votos = length(unique(base$id)), votos_decisivos = sum(decisivo) / 2,
                     votos_no_decisivos = sum(!decisivo) / 2, votos_revision_excluidos = revision,
                     modelos = length(modelos), ajustes = length(modelos) * 3L,
                     md5_base = huella_antes, version_MASS = as.character(packageVersion("MASS"))),
          "controles.csv")
  tabla <- c("| Comparación (11 efectos por modelo) | Modelos | Pearson mín. | Mediana | Máx. | Spearman mediana | Signos iguales |",
             "|---|---:|---:|---:|---:|---:|---:|")
  for (i in seq_len(nrow(resumen))) {
    z <- resumen[i, ]
    tabla <- c(tabla, sprintf("| %s | %d | %.4f | %.4f | %.4f | %.4f | %d/%d |",
                             z$comparacion, z$modelos, z$pearson_min, z$pearson_mediana,
                             z$pearson_max, z$spearman_mediana, z$signos_iguales, z$efectos_totales))
  }
  notas <- c("# Eli, C1: sensibilidad de coeficientes (9/11/2026)", "",
    "Generador: `R/12_sensibilidad.R`. Requiere MASS. Ejecutar desde la raíz del repo.", "",
    "Ajuste descriptivo con todos los meses (abril–julio), los 48 modelos y las mismas 11 características de R/02.",
    "Se usa la base de Nessim y se excluyen sus casos de revisión, igual que R/02. Sin rival ni ridge.",
    "Binomial usa solo victorias/derrotas; quasibinomial usa también empate y both_bad como 0.5.",
    "Ordinal usa peor < empate < mejor; both_bad se agrupa con empate, sin cambiar los datos.", "",
    tabla, "",
    "Cada correlación compara los 11 efectos DENTRO de un modelo; el resumen abarca los 48 modelos.",
    "El ordinal usa logit P(Y <= k) = umbral_k - X beta: un beta positivo apunta hacia mejor.",
    "No se comparan interceptos con umbrales; se exportan aparte. No son parámetros equivalentes.",
    "Las escalas y respuestas son distintas: correlación alta no significa coeficientes idénticos ni equivalencia predictiva.",
    "No se calcula AUC, no se evalúa julio fuera de muestra y no se cambia el método principal binomial.",
    "Las filas de un mismo voto se usan para dos modelos. Las correlaciones son descriptivas, sin p-valores.",
    "C2 (gráfico ROC) sigue pendiente de que la tarea B de Mark (#32) esté fusionada en main.", "",
    "Código y documentación preparados con asistencia de ChatGPT/Codex (OpenAI).")
  writeLines(notas, file.path(salida, "LEEME.md"), useBytes = TRUE)
  writeLines(capture.output(sessionInfo()), file.path(salida, "sessionInfo.txt"))
  cat(paste(tabla, collapse = "\n"), "\n")
  message("OK: ", length(modelos) * 3L, " ajustes convergentes; resultados en ", salida)
  invisible(list(coeficientes = coeficientes, correlaciones = correlaciones, resumen = resumen))
}

if (sys.nframe() == 0L) ejecutar_sensibilidad()
