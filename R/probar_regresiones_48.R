# Pruebas de la tarea 1 de Nessim (issue #17). Asistencia: ChatGPT/Codex.
options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")
error <- function(x) inherits(tryCatch(force(x), error = identity), "error")
set.seed(17)
n <- 700L
d <- data.frame(id = paste0("v", seq_len(n)), model = "prueba")
for (p in predictores) d[[p]] <- sample(c(TRUE, FALSE), n, TRUE)
d$y <- rbinom(n, 1, plogis(0.4 + 0.3 * d$math))
d$y[seq(1, n, by = 5)] <- 0.5
stopifnot(politica_empates == "excluir")
a <- ajustar_modelos(d, lambda = 0)
g <- glm(reformulate(predictores, response = "y"),
         family = quasibinomial(), data = d)
stopifnot(inherits(a[[1]], "glm"),
  max(abs(coef(a[[1]]) - coef(g))) < 1e-10,
  max(abs(probabilidad(a, d$model, d[predictores]) - fitted(g))) < 1e-10)

# Verificar ridge contra un optimizador independiente y el intercepto libre.
lambda <- 20
r <- ajustar_modelos(d, lambda = lambda)
X <- model.matrix(g)
pen <- c(0, rep(lambda, length(predictores)))
objetivo <- function(b) {
  eta <- drop(X %*% b)
  sum(pmax(eta, 0) - d$y * eta + log1p(exp(-abs(eta)))) +
    sum(pen * b^2) / 2
}
o <- optim(rep(0, ncol(X)), objetivo, method = "BFGS",
           control = list(reltol = 1e-12, maxit = 1000))
b <- r[[1]]$coefficients
mu <- probabilidad(r, d$model, d[predictores])
stopifnot(o$convergence == 0, max(abs(b - o$par)) < 1e-4,
  abs(sum(mu - d$y)) < 1e-5, # score del intercepto: sin penalizacion
  sum(b[-1]^2) < sum(coef(g)[-1]^2),
  all(is.na(tabla_coeficientes(r)$p_valor)),
  error(ajustar_modelos(d, lambda = -1)),
  error(ajustar_modelos(d, lambda = NA_real_)))

# No pierde la opcion excluir y no convierte empates silenciosamente a cero.
fake <- data.frame(requiere_revision = FALSE,
  es_decisivo = c(TRUE, TRUE, FALSE, FALSE), won = c(1, 0, NA, NA),
  won_medio_punto_escenario = c(1, 0, 0.5, 0.5))
stopifnot(identical(preparar_respuesta(fake)$y, c(1, 0)),
  identical(preparar_respuesta(fake, "medio_punto")$y, c(1, 0, 0.5, 0.5)),
  a[[1]]$family$family == "quasibinomial")

decisivos <- d[d$y %in% c(0, 1), ]
a_binomial <- ajustar_modelos(decisivos)
g_binomial <- glm(reformulate(predictores, response = "y"),
                  family = binomial(), data = decisivos)
stopifnot(a_binomial[[1]]$family$family == "binomial",
  max(abs(coef(a_binomial[[1]]) - coef(g_binomial))) < 1e-10)

# El top 3 usa exactamente ranking_real, permite menos de 3 y filtra julio/precio.
aj <- setNames(rep(a, 4), c("a", "b", "c", "d"))
for (i in seq_along(aj)) aj[[i]]$coefficients[1] <- 4 - i
attr(aj, "preguntas") <- d[c("id", predictores)]
meses <- tempfile(fileext = ".csv")
precios <- tempfile(fileext = ".csv")
write.csv(data.frame(modelo = names(aj), mes_7 = c(99, 100, 120, 150)),
          meses, row.names = FALSE)
write.csv(data.frame(modelo = names(aj),
  precio_salida_usd_por_millon = c(0.1, 2, NA, 1)), precios, row.names = FALSE)
t <- top3("math", aj, archivo_meses = meses, archivo_precios = precios)
esperado <- ranking_real("math", aj, attr(aj, "preguntas"))
esperado <- esperado[esperado$modelo != "a", ]
stopifnot(identical(t$modelo, esperado$modelo), !"a" %in% t$modelo,
  nrow(t) == 3, "b" %in% t$modelo, "c" %in% t$modelo)
t2 <- top3("math", aj, 1, archivo_meses = meses, archivo_precios = precios)
stopifnot(identical(t2$modelo, "d"),
  nrow(top3("math", aj, 0, archivo_meses = meses, archivo_precios = precios)) == 0,
  error(top3("math", aj, -1)), error(top3("no_existe", aj)))
unlink(c(meses, precios))
cat("OK: glm compatible, ridge, intercepto libre, politica, ranking real, julio y precio.\n")
