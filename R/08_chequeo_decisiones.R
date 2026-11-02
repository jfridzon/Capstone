# Chequeo para cerrar las decisiones abiertas de docs/07 (2/11/2026)
# Run from the repo root: source("R/08_chequeo_decisiones.R")   (base R only, ~2 min)
#
# Answers, with the same July test votes Mark uses (R/03, split_train_test.csv):
#   1. Ties and both_bad: exclude, half point, or tie = 0.5 and both_bad = 0?
#   2. Group the 3 versions of Gemini 2.5 Pro or not?
#   4. Models that only appear in July: what does a random split by session say?
#   5. Control for the rival's strength or not?
#   + Does a ridge penalty (shrinking the 11 effects toward 0) help the models with few votes?
#
# Method in every case: the 48 regressions of R/02 (1 logistic regression per model,
# won ~ 11 characteristics), fitted on train only. For each decisive July vote, the model
# with the higher predicted strength is predicted to win. Baseline: overall win rate in train.
# Results are a CHECK to support decisions, not the official evaluation (that is Mark's R/03).
#
# Prepared with Claude (Anthropic), 2/11/2026.

in_base  <- "data/derivados/base_regresiones_2026-10-28_v2.csv.gz"
in_split <- "R/resultados/split_train_test.csv"
out_dir  <- "R/resultados/decisiones_2026-11-02"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

pred <- c("is_code", "math", "creative_writing", "instruction_following", "complexity",
          "creativity", "domain_knowledge", "problem_solving", "real_world",
          "specificity", "technical_accuracy")

# ---- Data -------------------------------------------------------------------------
base  <- read.csv(gzfile(in_base), stringsAsFactors = FALSE)
split <- read.csv(in_split, stringsAsFactors = FALSE)
base  <- merge(base, split[, c("id", "split")], by = "id")
base  <- base[!as.logical(base$mismo_modelo), ]          # same as Mark: a model vs itself says nothing
for (p in pred) base[[p]] <- as.numeric(as.logical(base[[p]]))
base$es_decisivo <- as.logical(base$es_decisivo)

respuesta <- function(d, politica) {
  if (politica == "excluir") { d <- d[d$es_decisivo, ]; d$y <- d$won }
  if (politica == "medio_punto") d$y <- ifelse(d$es_decisivo, d$won, 0.5)
  if (politica == "empate_medio_bothbad_cero")
    d$y <- ifelse(d$es_decisivo, d$won, ifelse(d$winner == "tie", 0.5, 0))
  d$y <- as.numeric(d$y)
  d
}

# ---- Fit: logistic regression by IRLS, with optional ridge on the 11 effects -------
# lambda = 0 gives exactly the same coefficients as glm(). The intercept is never penalized.
ajustar <- function(X, y, lambda = 0) {
  b <- rep(0, ncol(X)); pen <- c(0, rep(lambda, ncol(X) - 1))
  for (it in 1:50) {
    mu <- plogis(drop(X %*% b)); w <- mu * (1 - mu)
    paso <- solve(crossprod(X, X * w) + diag(pen, ncol(X)), crossprod(X, y - mu) - pen * b)
    b <- b + drop(paso)
    if (max(abs(paso)) < 1e-8) break
  }
  b
}

evaluar <- function(tr, te, lambda = 0, rival = FALSE) {
  tasa <- tapply(tr$y, tr$model, mean)                       # overall win rate in train
  coefs <- list()
  for (m in sort(unique(tr$model))) {
    f <- tr[tr$model == m, ]
    X <- cbind(1, as.matrix(f[pred]))
    if (rival) X <- cbind(X, tasa[f$rival])
    coefs[[m]] <- ajustar(X, f$y, lambda)
  }
  t <- te[te$lado == "model_a" & te$es_decisivo & te$model %in% names(coefs) &
          te$rival %in% names(coefs), ]
  Xt <- cbind(1, as.matrix(t[pred]))
  fuerza <- function(mod, riv) sapply(seq_len(nrow(t)), function(i) {
    x <- Xt[i, ]; if (rival) x <- c(x, tasa[riv[i]]); sum(x * coefs[[mod[i]]]) })
  fa <- fuerza(t$model, t$rival); fb <- fuerza(t$rival, t$model)
  p  <- plogis(fa - fb)                                       # P(model_a wins)
  pb <- plogis(qlogis(tasa[t$model]) - qlogis(tasa[t$rival]))
  y  <- t$won
  ll <- function(q) -mean(y * log(q) + (1 - y) * log(1 - q))
  data.frame(votos_test = nrow(t), modelos = length(coefs),
             aciertos_48 = round(100 * mean((fa > fb) == y), 2),
             aciertos_base = round(100 * mean((tasa[t$model] > tasa[t$rival]) == y), 2),
             logloss_48 = round(ll(p), 4), logloss_base = round(ll(pb), 4))
}

# ---- 1, 5 and ridge: July test ------------------------------------------------------
grilla <- expand.grid(politica = c("excluir", "medio_punto", "empate_medio_bothbad_cero"),
                      rival = c(FALSE, TRUE), lambda = 0, stringsAsFactors = FALSE)
grilla <- rbind(grilla, data.frame(politica = "medio_punto", rival = FALSE,
                                   lambda = c(10, 30, 100, 300)))
julio <- do.call(rbind, lapply(seq_len(nrow(grilla)), function(i) {
  g <- grilla[i, ]; d <- respuesta(base, g$politica)
  cbind(g, evaluar(d[d$split == "train", ], d[d$split == "test", ], g$lambda, g$rival))
}))
julio$diferencia <- julio$aciertos_48 - julio$aciertos_base
print(julio); write.csv(julio, file.path(out_dir, "julio_politicas_rival_ridge.csv"), row.names = FALSE)

# ---- 2. Gemini 2.5 Pro grouped (3 versions -> 1) ------------------------------------
fam <- function(m) ifelse(startsWith(m, "gemini-2.5-pro"), "gemini-2.5-pro (3 versiones)", m)
d0 <- respuesta(base, "medio_punto")
d  <- d0; d$model <- fam(d$model); d$rival <- fam(d$rival)
gem <- rbind(cbind(version = "separadas", evaluar(d0[d0$split == "train", ], d0[d0$split == "test", ])),
             cbind(version = "agrupadas", evaluar(d[d$split == "train", ], d[d$split == "test", ])))
print(gem); write.csv(gem, file.path(out_dir, "gemini_agrupado.csv"), row.names = FALSE)

# ---- 4. Random split by session (80/20), includes the 4 July-only models ------------
d <- respuesta(base, "medio_punto"); sesiones <- unique(d$evaluation_session_id)
azar <- do.call(rbind, lapply(1:5, function(semilla) {
  set.seed(semilla); prueba <- sample(sesiones, round(0.2 * length(sesiones)))
  es_test <- d$evaluation_session_id %in% prueba
  do.call(rbind, lapply(c(0, 30), function(l)
    cbind(semilla = semilla, lambda = l, evaluar(d[!es_test, ], d[es_test, ], l))))
}))
azar$diferencia <- azar$aciertos_48 - azar$aciertos_base
print(azar); write.csv(azar, file.path(out_dir, "particion_aleatoria.csv"), row.names = FALSE)

# ---- Votes per model per month (for the rule "the tool only recommends models alive in July")
una <- base[!duplicated(paste(base$id, base$model)), ]
meses <- as.data.frame.matrix(table(una$model, una$month))
names(meses) <- paste0("mes_", names(meses)); meses$modelo <- rownames(meses)
meses <- meses[order(-meses$mes_7), c("modelo", grep("^mes_", names(meses), value = TRUE))]
write.csv(meses, file.path(out_dir, "votos_por_mes.csv"), row.names = FALSE)
cat("\nModelos con menos de 100 votos en julio:\n"); print(meses[meses$mes_7 < 100, ])
