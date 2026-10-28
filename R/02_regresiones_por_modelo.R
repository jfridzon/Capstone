# The 48 regressions: 1 logistic regression per model
# Task 2 in docs/07 (Jaime). Run from the repo root: source("R/02_regresiones_por_modelo.R")
#
# The question: for a given type of question (code, math, creative writing...),
# which model is most likely to win?
#
# For EACH model separately:
#   Data:       every vote where that model appeared (1 row = 1 vote, from that model's side)
#   Response:   won = 1 if the model won the vote, 0 if it lost
#   Predictors: the 11 TRUE/FALSE characteristics of the question
#               (all known BEFORE the model writes its answer)
#
#   glm(won ~ is_code + math + creative_writing + instruction_following + complexity +
#             creativity + domain_knowledge + problem_solving + real_world +
#             specificity + technical_accuracy, family = binomial)
#
# Then, for any combination of characteristics (for example code + math), each model's
# regression gives its probability of winning, and sorting those gives the ranking.
#
# What this script leaves for others:
#   ajustar_modelos(datos)            -> Mark calls it with the train votes only (R/03)
#   probabilidad(ajustes, modelos, x) -> win probability for any model and question
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

# OPEN DECISION #1 in docs/07 (the group decides): ties and both_bad.
#   "excluir"     = only decisive votes, won is 1 or 0 (what has been used so far)
#   "medio_punto" = tie and both_bad count as 0.5 (Nessim's column won_medio_punto_escenario)
politica_empates <- "excluir"

# OPEN DECISION #5 in docs/07: control for the rival's strength or not.
# FALSE = the 11 characteristics only (what the task asks for first).
# TRUE  = also adds fuerza_rival = the rival's overall win rate in the same data, as a check.
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

# ---- 2. The 48 regressions -----------------------------------------------------

# datos: rows from the long base (1 row per model per vote) with the response in y.
# Returns a list with 1 fitted glm per model, named by model.
ajustar_modelos <- function(datos, rival = con_rival, min_votos = 100) {
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
    fit <- glm(formula, family = familia, data = filas)
    if (!fit$converged) warning("Regression did not converge for ", m)
    fit$n_votos <- nrow(filas)
    ajustes[[m]] <- fit
  }
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

# Win probability of each model in `modelos` for the question in the same row of `x`.
# x: data frame with the 11 characteristics (and fuerza_rival if the fits use it).
# Mark uses this on the July votes: once with model_a, once with model_b.
probabilidad <- function(ajustes, modelos, x) {
  stopifnot(length(modelos) == nrow(x))
  p <- rep(NA_real_, length(modelos))
  for (m in intersect(unique(modelos), names(ajustes))) {
    i <- which(modelos == m)
    p[i] <- predict(ajustes[[m]], newdata = x[i, , drop = FALSE], type = "response")
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
  q <- preguntas[!duplicated(preguntas$id), predictores]
  if (length(caracteristicas) > 0) q <- q[apply(q[caracteristicas], 1, all), , drop = FALSE]
  if ("fuerza_rival" %in% all.vars(formula(ajustes[[1]]))) q$fuerza_rival <- 0.5
  modelos <- names(ajustes)
  out <- data.frame(modelo     = modelos,
                    prob_ganar = sapply(modelos, function(m)
                      mean(predict(ajustes[[m]], newdata = q, type = "response"))),
                    votos      = sapply(ajustes, `[[`, "n_votos"),
                    row.names  = NULL)
  out <- out[order(-out$prob_ganar), ]
  out$rank <- seq_len(nrow(out))
  attr(out, "preguntas") <- nrow(q)
  out[, c("rank", "modelo", "prob_ganar", "votos")]
}

# Coefficient table: 1 row per model per term
tabla_coeficientes <- function(ajustes) {
  filas <- lapply(names(ajustes), function(m) {
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
