# Fase 2b, tarea E (#14): Bradley-Terry con covariables de la pregunta.
# Desde la raíz: Rscript R/07_bradley_terry_covariables.R
# Paquetes: Matrix, glmnet y pROC. Preparado con asistencia de ChatGPT/Codex.

library(Matrix)
library(glmnet)
library(pROC)

modelos_48 <- new.env()
opciones <- options(correr_02 = FALSE)
tryCatch(sys.source("R/02_regresiones_por_modelo.R", envir = modelos_48),
         finally = options(opciones))
source("R/03b_evaluar.R")

# Los folds oficiales cubren toda la base, incluidos los votos de medio punto.
base <- modelos_48$cargar_base()
base_a <- base[base$lado == "model_a", ]
folds <- read.csv("R/resultados/auc/folds_5.csv", colClasses = c("character", "integer"))
stopifnot(identical(names(folds), c("id", "fold")),
          !anyNA(folds), !anyDuplicated(folds$id), !anyDuplicated(base_a$id),
          setequal(folds$id, base_a$id), setequal(folds$fold, 1:5),
          !anyNA(base_a$evaluation_session_id))
base_a$fold <- folds$fold[match(base_a$id, folds$id)]
stopifnot(!anyDuplicated(unique(base_a[c("evaluation_session_id", "fold")])$evaluation_session_id))

votos <- modelos_48$preparar_respuesta(base_a, politica = "medio_punto")
caracteristicas <- modelos_48$predictores
stopifnot(all(votos$y %in% c(0, 0.5, 1)), !anyNA(votos[caracteristicas]),
          all(votos$model != votos$rival), all(votos$es_decisivo == (votos$y != 0.5)))
referencia <- "claude-opus-4-20250514"
modelos <- sort(unique(c(votos$model, votos$rival)))
stopifnot(referencia %in% modelos)
efectos <- setdiff(modelos, referencia)

# x_m vale +1 para A, -1 para B y 0 si m no aparece. La referencia vale cero.
# Cada bloque adicional es x_m por una característica de la pregunta.
columnas <- match(c(votos$model, votos$rival), efectos)
incluidas <- !is.na(columnas)
x <- sparseMatrix(i = rep(seq_len(nrow(votos)), 2)[incluidas],
                  j = columnas[incluidas],
                  x = rep(c(1, -1), each = nrow(votos))[incluidas],
                  dims = c(nrow(votos), length(efectos)),
                  dimnames = list(NULL, efectos))
interacciones <- lapply(caracteristicas, function(k) {
  z <- drop0(x * as.numeric(votos[[k]]))
  colnames(z) <- paste(efectos, k, sep = ":")
  z
})
X <- do.call(cbind, c(list(x), interacciones))
penalizacion <- c(rep(0, ncol(x)), rep(1, ncol(X) - ncol(x)))
lambdas <- 10^seq(-5, -0.5, by = 0.5)

ajustar <- function(filas, lambda) {
  # Dos proporciones con suma 1 por voto. El objetivo logístico de medio
  # punto equivale al de quasibinomial con enlace logit, más el término ridge.
  y <- votos$y[filas]
  ajuste <- glmnet(X[filas, , drop = FALSE], cbind(1 - y, y),
                   family = "binomial", alpha = 0, lambda = lambda,
                   intercept = FALSE, standardize = FALSE,
                   penalty.factor = penalizacion)
  stopifnot(ajuste$jerr == 0L, identical(ajuste$lambda, lambda), all(ajuste$a0 == 0))
  ajuste
}

elegir_lambda <- function(folds_train) {
  # Reusar los folds de Mark dentro del train. El fold externo nunca entra
  # en el ajuste ni en la validación que elige lambda. Validar en decisivos.
  perdida <- numeric(length(lambdas))
  for (f in folds_train) {
    train <- which(votos$fold %in% setdiff(folds_train, f))
    val <- which(votos$fold == f & votos$es_decisivo)
    ajuste <- ajustar(train, rev(lambdas))
    eta <- predict(ajuste, X[val, , drop = FALSE], s = lambdas, type = "link")
    perdida <- perdida + colSums(pmax(eta, 0) - votos$y[val] * eta +
                                   log1p(exp(-abs(eta))))
  }
  lambdas[which.min(perdida)]
}

medir <- function(ajuste, filas, scenario, fold, lambda) {
  p <- drop(predict(ajuste, X[filas, , drop = FALSE], type = "response"))
  y <- votos$y[filas]
  stopifnot(all(y %in% c(0, 1)), all(is.finite(p)))
  roc_votos <- roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE)
  metricas <- evaluar(p, ifelse(y == 1, "model_a", "model_b"),
                       "bradley_terry_covariables", "half")
  data.frame(scenario, fold, n_votes = length(y), lambda,
             auc_bradley_terry = as.numeric(auc(roc_votos)), correct = metricas$correct,
             logloss = -mean(ifelse(y == 1, log(p), log1p(-p))))
}

# 1. Ajuste descriptivo sobre todo el período y AUC en sus votos decisivos.
# 2. AUC fuera de muestra sobre cada fold decisivo, con ridge elegido en train.
grupos <- sort(unique(folds$fold))
lambda_total <- elegir_lambda(grupos)
ajuste_total <- ajustar(seq_len(nrow(votos)), lambda_total)
resultados <- medir(ajuste_total, which(votos$es_decisivo), "all_data", "all", lambda_total)
for (f in grupos) {
  folds_train <- setdiff(grupos, f)
  lambda <- elegir_lambda(folds_train)
  ajuste <- ajustar(which(votos$fold %in% folds_train), lambda)
  test <- which(votos$fold == f & votos$es_decisivo)
  resultados <- rbind(resultados, medir(ajuste, test, "cv5", as.character(f), lambda))
}
cv <- resultados[resultados$scenario == "cv5", ]
resultados <- rbind(resultados, data.frame(
  scenario = "cv5", fold = "mean", n_votes = sum(cv$n_votes), lambda = NA_real_,
  auc_bradley_terry = mean(cv$auc_bradley_terry), correct = sum(cv$correct),
  logloss = weighted.mean(cv$logloss, cv$n_votes)
))
resultados$accuracy_percent <- 100 * resultados$correct / resultados$n_votes
mark <- read.csv("R/resultados/auc/por_voto.csv")
mark <- mark[match(resultados$fold, mark$fold), ]
stopifnot(identical(mark$scenario, resultados$scenario),
          all(mark$n_votes == resultados$n_votes), all(mark$n_votes_left_out == 0))
resultados$auc_48_regresiones <- mark$auc_regression
resultados$auc_ranking_general <- mark$auc_baseline

# Comparación descriptiva sobre las mismas preguntas reales y la misma
# elegibilidad de top3() (100 votos en julio). BT usa un rival común, Claude.
coeficientes <- matrix(as.numeric(coef(ajuste_total))[-1], nrow = length(efectos),
                       dimnames = list(efectos, c("fuerza_base", caracteristicas)))
coeficientes <- rbind(coeficientes, setNames(rep(0, ncol(coeficientes)), colnames(coeficientes)))
rownames(coeficientes)[nrow(coeficientes)] <- referencia
julio <- read.csv("R/resultados/decisiones_2026-11-02/votos_por_mes.csv")
elegibles <- intersect(julio$modelo[julio$mes_7 >= 100], modelos)
escenarios <- list(codigo = "is_code", math = "math",
                   escritura_creativa = "creative_writing", instrucciones = "instruction_following",
                   codigo_y_math = c("is_code", "math"), todas = character())
top_48 <- read.csv("R/resultados/regresiones_48_2026-11-09/top3_por_tarea.csv")
top <- do.call(rbind, lapply(names(escenarios), function(escenario) {
  tags <- escenarios[[escenario]]
  filas <- votos$es_decisivo & rowSums(votos[tags]) == length(tags)
  perfil <- cbind(1, as.matrix(votos[filas, caracteristicas]))
  score <- colMeans(plogis(perfil %*% t(coeficientes[elegibles, , drop = FALSE])))
  mejores <- head(order(-score, elegibles), 3)
  anterior <- top_48[top_48$escenario == escenario, ]
  stopifnot(identical(anterior$rank, 1:3))
  data.frame(escenario, preguntas = sum(filas), rank = 1:3,
             modelo_bradley_terry = elegibles[mejores],
             puntaje_contra_referencia = unname(score[mejores]),
             modelo_48_regresiones = anterior$modelo)
}))

salida <- "R/resultados/bradley_terry"
dir.create(salida, showWarnings = FALSE, recursive = TRUE)
resultados$auc_bradley_terry <- round(resultados$auc_bradley_terry, 4)
resultados$accuracy_percent <- round(resultados$accuracy_percent, 2)
resultados$logloss <- round(resultados$logloss, 4)
top$puntaje_contra_referencia <- round(top$puntaje_contra_referencia, 4)
write.csv(resultados, file.path(salida, "por_voto.csv"), row.names = FALSE)
write.csv(top, file.path(salida, "top3_por_tarea.csv"), row.names = FALSE)
cat("Votos de ajuste:", nrow(votos), "| Coeficientes estimados:", ncol(X), "\n")
print(resultados, row.names = FALSE)
print(top, row.names = FALSE)
