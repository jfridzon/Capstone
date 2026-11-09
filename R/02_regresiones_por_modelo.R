# The 48 regressions: 1 logistic regression per model
# Actualizado para Nessim (issue #17) con asistencia de ChatGPT/Codex, 2/11/2026.
# Fase 2b (issue #31): binomial por defecto; medio punto y ridge opcionales.
# Tarea 1 de Nessim, fase 2 (codigo original de Jaime). Desde la raiz: source("R/02_regresiones_por_modelo.R")
#
# The question: for a given type of question (code, math, creative writing...),
# which model is most likely to win?
#
# For EACH model separately:
#   Data:       decisive votes where the model appeared (one row per vote for this model)
#   Response:   y = 1 if it won, 0 if it lost
#               Optional half-point fit: y = 0.5 for tie or both_bad
#   Predictors: the 11 TRUE/FALSE characteristics of the question
#               (all known BEFORE the model writes its answer)
#
#   glm(y ~ is_code + math + creative_writing + instruction_following + complexity +
#             creativity + domain_knowledge + problem_solving + real_world +
#             specificity + technical_accuracy, family = binomial)
#
# Then, for any combination of characteristics (for example code + math), each model's
# regression gives its expected preference score; sorting those gives the ranking.
#
# What this script leaves for others:
#   ajustar_modelos(datos)            -> Mark calls it with the train votes only (R/03)
#   probabilidad(ajustes, modelos, x) -> expected preference score (API name retained)
#   ranking(caracteristicas, ajustes) -> models sorted from most to least likely to win
#
# Known limitation (the professor knows and said not to worry for now): every vote is
# used twice, once for each model, so the 48 regressions are not independent.
#
# Base R only, no packages needed.

# ---- Settings ---------------------------------------------------------------

in_file    <- "data/derivados/base_regresiones_2026-10-28_v2.csv.gz"   # Nessim, docs/10
out_folder <- "R/resultados"

predictores <- c("is_code", "math", "creative_writing", "instruction_following",
                 "complexity", "creativity", "domain_knowledge", "problem_solving",
                 "real_world", "specificity", "technical_accuracy")

# Fase 2b, docs/14: excluir empates y both_bad del ajuste principal.
politica_empates <- "excluir"

# Sin rival en las 48. Se conserva la opcion para los chequeos de Mark.
con_rival <- FALSE

# Nessim flagged 28 votes for review (docs/10): 10 where a model played itself and
# 18 from sessions with more than 1 "first" vote. A model playing itself always wins
# and loses the same vote, so it says nothing about its strength. TRUE = leave them out.
excluir_revision <- TRUE

# ---- 1. Load the data ---------------------------------------------------------

cargar_base <- function(path = in_file) {
  base <- read.csv(gzfile(path), stringsAsFactors = FALSE)
  for (p in predictores) base[[p]] <- as.logical(base[[p]])
  base
}

# Pick the response explicitly (Nessim asks not to rely on glm silently dropping NA)
preparar_respuesta <- function(base, politica = politica_empates, sin_revision = excluir_revision) {
  stopifnot(politica %in% c("excluir", "medio_punto"))
  if (sin_revision) base <- base[!base$requiere_revision, ]
  if (politica == "excluir") {
    base <- base[base$es_decisivo, ]
    base$y <- base$won
  } else {
    base$y <- base$won_medio_punto_escenario
  }
  stopifnot(!anyNA(base$y))
  base
}

# Ridge opcional: ajuste logit con penalizacion L2 en los 11 efectos.
# Minimiza sum(log(1 + exp(eta)) - y * eta) + lambda/2 * sum(beta_efectos^2).
# El intercepto y un eventual control del rival NO se penalizan.
# lambda lo elige Mark dentro de train; este archivo no lo selecciona.
ajustar_ridge <- function(X, y, penalizar, lambda, max_iter = 100L,
                          tolerancia = 1e-8) {
  b <- rep(0, ncol(X))
  pen <- lambda * penalizar
  perdida <- function(beta) {
    eta <- drop(X %*% beta)
    sum(pmax(eta, 0) - y * eta + log1p(exp(-abs(eta)))) +
      sum(pen * beta^2) / 2
  }
  valor <- perdida(b)
  for (iter in seq_len(max_iter)) {
    mu <- plogis(drop(X %*% b))
    w <- pmax(mu * (1 - mu), 1e-12)
    grad <- drop(crossprod(X, mu - y)) + pen * b
    if (max(abs(grad)) / nrow(X) < tolerancia) break
    h <- crossprod(X, X * w) + diag(pen, ncol(X))
    paso <- drop(solve(h, grad))
    escala <- 1
    repeat {
      candidato <- b - escala * paso
      nuevo <- perdida(candidato)
      if (is.finite(nuevo) && nuevo <= valor + 1e-9) break
      escala <- escala / 2
      if (escala < 2^-20) stop("Ridge no encuentra un paso descendente.")
    }
    b <- candidato
    valor <- nuevo
  }
  grad <- drop(crossprod(X, plogis(drop(X %*% b)) - y)) + pen * b
  if (max(abs(grad)) / nrow(X) >= tolerancia) stop("Ridge no convergio.")
  list(coefficients = setNames(b, colnames(X)), converged = TRUE,
       iteraciones = iter, gradiente = max(abs(grad)) / nrow(X))
}

# ---- 2. The 48 regressions -----------------------------------------------------

# datos: rows from the long base (1 row per model per vote) with the response in y.
# lambda = 0: una lista de glm. lambda > 0: ajustes ridge, sin inferencia glm.
ajustar_modelos <- function(datos, rival = con_rival, min_votos = 100,
                            lambda = 0) {
  if (length(lambda) != 1L || !is.finite(lambda) || lambda < 0) {
    stop("lambda debe ser un numero finito no negativo.")
  }
  if (!all(c("model", "y", predictores) %in% names(datos)) ||
      anyNA(datos[c("model", "y", predictores)]) ||
      !all(datos$y >= 0 & datos$y <= 1)) stop("Datos de ajuste invalidos.")
  formula <- reformulate(c(predictores, if (rival) "fuerza_rival"), response = "y")

  if (rival) {
    # Overall win rate of each model in these same data (train only, if Mark passes train)
    tasa <- tapply(datos$y, datos$model, mean)
    datos$fuerza_rival <- unname(tasa[datos$rival])
  }

  familia <- if (all(datos$y %in% c(0, 1))) binomial() else quasibinomial()
  modelos <- sort(unique(datos$model))
  ajustes <- list()

  for (m in modelos) {
    filas <- datos[datos$model == m, ]
    if (nrow(filas) < min_votos) next          # too few votes to estimate 11 effects
    if (lambda == 0) {
      fit <- glm(formula, family = familia, data = filas)
    } else {
      X <- model.matrix(formula, filas)
      efectos <- which(attr(terms(formula), "term.labels") %in% predictores)
      penalizar <- as.numeric(attr(X, "assign") %in% efectos)
      fit <- ajustar_ridge(X, filas$y, penalizar, lambda)
      fit$formula <- formula
      fit$terms <- terms(formula)
      fit$familia <- familia$family
      fit$lambda <- lambda
      class(fit) <- "ridge_48"
    }
    if (!fit$converged) warning("Regression did not converge for ", m)
    fit$n_votos <- nrow(filas)
    ajustes[[m]] <- fit
  }
  # Distribucion de preguntas usada por el ajuste: train si Mark pasa train.
  columnas <- c(intersect("id", names(datos)), predictores)
  preguntas <- datos[, columnas, drop = FALSE]
  if ("id" %in% names(preguntas)) {
    preguntas <- preguntas[!duplicated(preguntas$id), , drop = FALSE]
  }
  attr(ajustes, "preguntas") <- preguntas
  attr(ajustes, "lambda") <- lambda
  ajustes
}

# ---- 3. Predictions and ranking ------------------------------------------------

# Builds 1 question from a list of characteristics, e.g. c("is_code", "math").
# Everything not listed is FALSE.
pregunta <- function(caracteristicas = character(0)) {
  stopifnot(all(caracteristicas %in% predictores))
  x <- as.data.frame(setNames(as.list(rep(FALSE, length(predictores))), predictores))
  x[caracteristicas] <- TRUE
  x
}

# Expected preference score for each model/question. With half points it is
# P(win) + 0.5 * P(tie or both_bad), not a pure decisive-win probability.
# API/column names probabilidad and prob_ganar remain for Mark/Marco compatibility.
# Scores across different models are not mutually exclusive and do not sum to 1.
# x: data frame with the 11 characteristics (and fuerza_rival if the fits use it).
# Mark uses this on the July votes: once with model_a, once with model_b.
probabilidad <- function(ajustes, modelos, x) {
  stopifnot(length(modelos) == nrow(x))
  p <- rep(NA_real_, length(modelos))
  for (m in intersect(unique(modelos), names(ajustes))) {
    i <- which(modelos == m)
    fit <- ajustes[[m]]
    if (inherits(fit, "ridge_48")) {
      X <- model.matrix(delete.response(fit$terms), x[i, , drop = FALSE])
      p[i] <- plogis(drop(X %*% fit$coefficients))
    } else {
      p[i] <- predict(fit, newdata = x[i, , drop = FALSE], type = "response")
    }
  }
  p
}

# Ranking for 1 type of question. With the rival control on, it assumes an average rival.
ranking <- function(caracteristicas = character(0), ajustes) {
  x <- pregunta(caracteristicas)
  if ("fuerza_rival" %in% all.vars(formula(ajustes[[1]]))) x$fuerza_rival <- 0.5
  modelos <- names(ajustes)
  x <- x[rep(1, length(modelos)), , drop = FALSE]
  out <- data.frame(modelo     = modelos,
                    prob_ganar = probabilidad(ajustes, modelos, x),
                    votos      = sapply(ajustes, `[[`, "n_votos"),
                    row.names  = NULL)
  out <- out[order(-out$prob_ganar), ]
  out$rank <- seq_len(nrow(out))
  out[, c("rank", "modelo", "prob_ganar", "votos")]
}

# Ranking over REAL questions: for every question in `preguntas` that has all the
# listed characteristics TRUE (the rest can be anything), compute each model's win
# probability and average it. Real questions rarely have only 1 characteristic: a code
# question is almost always also problem_solving, technical_accuracy, etc. This version
# ranks models on the questions people actually ask, not on a made-up "code only" one.
ranking_real <- function(caracteristicas = character(0), ajustes, preguntas) {
  stopifnot(all(caracteristicas %in% predictores))
  if (!length(ajustes)) stop("No hay modelos ajustados.")
  if (!all(predictores %in% names(preguntas))) stop("Faltan caracteristicas.")
  usar <- if ("id" %in% names(preguntas)) !duplicated(preguntas$id) else
    rep(TRUE, nrow(preguntas))
  q <- preguntas[usar, predictores, drop = FALSE]
  if (length(caracteristicas) > 0) q <- q[apply(q[caracteristicas], 1, all), , drop = FALSE]
  if (!nrow(q)) stop("No hay preguntas reales con esas caracteristicas.")
  if ("fuerza_rival" %in% all.vars(formula(ajustes[[1]]))) q$fuerza_rival <- 0.5
  modelos <- names(ajustes)
  out <- data.frame(modelo     = modelos,
                    prob_ganar = vapply(modelos, function(m)
                      mean(probabilidad(ajustes, rep(m, nrow(q)), q)), numeric(1)),
                    votos      = sapply(ajustes, `[[`, "n_votos"),
                    row.names  = NULL)
  out <- out[order(-out$prob_ganar), ]
  out$rank <- seq_len(nrow(out))
  attr(out, "preguntas") <- nrow(q)
  out[, c("rank", "modelo", "prob_ganar", "votos")]
}

# Top 3 para la herramienta: preguntas reales, vigencia en julio y presupuesto.
# precio_max es USD por millon de tokens DE SALIDA, no costo por respuesta.
top3 <- function(caracteristicas, ajustes, precio_max = NULL,
                 preguntas = attr(ajustes, "preguntas"),
                 archivo_meses = "R/resultados/decisiones_2026-11-02/votos_por_mes.csv",
                 archivo_precios = "data/derivados/precios_modelos_2026-10-28_v2.csv") {
  if (!is.null(precio_max) && (length(precio_max) != 1L ||
      !is.numeric(precio_max) || !is.finite(precio_max) || precio_max < 0)) {
    stop("precio_max debe ser NULL o un presupuesto no negativo.")
  }
  if (is.null(preguntas)) preguntas <- cargar_base()
  meses <- read.csv(archivo_meses, stringsAsFactors = FALSE)
  precios <- read.csv(archivo_precios, stringsAsFactors = FALSE)
  precio_col <- "precio_salida_usd_por_millon"
  if (!all(c("modelo", "mes_7") %in% names(meses)) ||
      !all(c("modelo", precio_col) %in% names(precios)) ||
      anyDuplicated(meses$modelo) || anyDuplicated(precios$modelo)) {
    stop("Tablas de julio o precios incompatibles.")
  }
  r <- ranking_real(caracteristicas, ajustes, preguntas)
  r$votos_julio <- meses$mes_7[match(r$modelo, meses$modelo)]
  r[[precio_col]] <- precios[[precio_col]][match(r$modelo, precios$modelo)]
  r <- r[!is.na(r$votos_julio) & r$votos_julio >= 100, , drop = FALSE]
  if (!is.null(precio_max)) {
    r <- r[is.finite(r[[precio_col]]) & r[[precio_col]] >= 0 &
             r[[precio_col]] <= precio_max, , drop = FALSE]
  }
  r <- r[order(-r$prob_ganar, r$modelo), , drop = FALSE]
  r$rank <- seq_len(nrow(r))
  rownames(r) <- NULL
  head(r, 3L) # Puede devolver menos de 3 si el presupuesto no alcanza.
}

# Coefficient table: 1 row per model per term
tabla_coeficientes <- function(ajustes) {
  filas <- lapply(names(ajustes), function(m) {
    if (inherits(ajustes[[m]], "ridge_48")) {
      return(data.frame(modelo = m,
        termino = names(ajustes[[m]]$coefficients),
        estimado = unname(ajustes[[m]]$coefficients),
        error_estandar = NA_real_, p_valor = NA_real_))
    }
    s <- coef(summary(ajustes[[m]]))
    data.frame(modelo = m, termino = rownames(s),
               estimado = s[, 1], error_estandar = s[, 2], p_valor = s[, 4],
               row.names = NULL)
  })
  do.call(rbind, filas)
}

# ---- 4. Run it on all the votes and save the results ------------------------------
# To load only the functions (for example from R/03), run first:
#   options(correr_02 = FALSE); source("R/02_regresiones_por_modelo.R")

if (isTRUE(getOption("correr_02", TRUE))) {

  base  <- cargar_base()
  datos <- preparar_respuesta(base)

  cat("Rows in the long base:", nrow(base), "(docs/05: 213,260)\n")
  cat("Rows used (policy:", politica_empates, "):", nrow(datos),
      "=", nrow(datos) / 2, "votes\n")
  cat("Models:", length(unique(datos$model)), "\n")

  ajustes <- ajustar_modelos(datos)
  cat("Regressions fitted:", length(ajustes), "\n")

  coefs <- tabla_coeficientes(ajustes)
  write.csv(coefs, file.path(out_folder, "coeficientes_por_modelo.csv"), row.names = FALSE)

  escenarios <- list(
    "codigo"             = "is_code",
    "math"               = "math",
    "escritura_creativa" = "creative_writing",
    "codigo_y_math"      = c("is_code", "math"),
    "sin_caracteristicas" = character(0)
  )
  # How many real votes match each scenario exactly (only those characteristics TRUE)
  votos_unicos <- datos[!duplicated(datos$id), ]
  exactas <- function(car) {
    sum(apply(votos_unicos[predictores], 1, function(r) all(r == (predictores %in% car))))
  }
  conteo <- function(car) {
    if (length(car) == 0) return(nrow(votos_unicos))
    sum(apply(votos_unicos[car], 1, all))
  }

  # 2 versions of each scenario:
  #   solo_estas       = a question with ONLY these characteristics (what the task asked)
  #   preguntas_reales = average over all real questions that have them (more realistic)
  ejemplos <- do.call(rbind, lapply(names(escenarios), function(e) {
    car <- escenarios[[e]]
    a <- head(ranking(car, ajustes), 10)
    b <- head(ranking_real(car, ajustes, datos), 10)
    rbind(cbind(escenario = e, version = "solo_estas", votos_que_calzan = exactas(car), a),
          cbind(escenario = e, version = "preguntas_reales", votos_que_calzan = conteo(car), b))
  }))
  ejemplos$prob_ganar <- round(ejemplos$prob_ganar, 3)
  write.csv(ejemplos, file.path(out_folder, "rankings_ejemplo.csv"), row.names = FALSE)

  for (e in names(escenarios)) for (v in c("solo_estas", "preguntas_reales")) {
    t <- ejemplos[ejemplos$escenario == e & ejemplos$version == v, ]
    cat("\nTop 5,", e, "|", v, "| votes that match:", t$votos_que_calzan[1], "\n")
    print(head(t[, c("rank", "modelo", "prob_ganar", "votos")], 5), row.names = FALSE)
  }
}
