# LIVE PROJECT DEMO IN RSTUDIO ----
# Open Capstone.Rproj, then this file. Run each section with Cmd/Ctrl + Enter.
# Fits the models in memory; does not overwrite data, deliveries or saved results.
# Group workflow: Nessim/Jaime (models), Mark (test), Marco (price), Eli (context).
# Prepared with ChatGPT/Codex, 2 November 2026.

# 1. Load the existing data and functions ----
stopifnot(file.exists("Capstone.Rproj"),
          file.exists("data/derivados/votos_filtrados.csv"))
opciones <- options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")
options(opciones)
source("R/03b_evaluar.R")

mostrar_tabla <- function(x, titulo) {
  print(utils::head(x, 10), row.names = FALSE)
  if (interactive()) utils::View(x, title = titulo)
  invisible(x)
}

votos <- read.csv("data/derivados/votos_filtrados.csv")
base_larga <- cargar_base()
datos_completos <- preparar_respuesta(base_larga, politica = "medio_punto")
mostrar_tabla(data.frame(
  Stage = c("Filtered votes", "Model-side rows", "Votes used in regressions"),
  Rows = c(nrow(votos), nrow(base_larga), nrow(datos_completos) / 2)),
  "Data: votes and model-side rows")
mostrar_tabla(votos[c("model_a", "model_b", "winner", predictores)],
              "Question features and actual votes")

# 2. RUN ALL 48 REGRESSIONS: April-July descriptive fit ----
# The actual glm() is in R/02, inside ajustar_modelos(). No existing fit is loaded.
# Response: win=1, loss=0, tie/both_bad=0.5. Features are known before the answer.
ajustes_completos <- ajustar_modelos(datos_completos, lambda = 0)
stopifnot(length(ajustes_completos) == 48L)
modelos_48 <- data.frame(
  Model = names(ajustes_completos),
  Votes = vapply(ajustes_completos, function(m) m$n_votos, numeric(1)),
  Converged = vapply(ajustes_completos, function(m) m$converged, logical(1)))
mostrar_tabla(modelos_48, "All 48 regressions actually fitted now")

# Select ANY model here. Its full R summary appears in Console.
print(summary(ajustes_completos[["gemini-2.5-pro"]]))
print(summary(ajustes_completos[["claude-opus-4-20250514"]]))
print(summary(ajustes_completos[["grok-4-0709"]]))
# All summaries are available in Environment -> resumenes_48.
resumenes_48 <- lapply(ajustes_completos, summary)
coeficientes_48 <- tabla_coeficientes(ajustes_completos)
mostrar_tabla(coeficientes_48, "All 576 coefficients, standard errors and p-values")

# 3. SEE ALL 48 MODELS IN THE PLOTS PANE ----
# These are log-odds effects, NOT percentages or causal effects.
# Every fitted model appears. Use Zoom in the RStudio Plots pane.
heatmap_48 <- function(coeficientes) {
  efectos <- coeficientes[coeficientes$termino != "(Intercept)", ]
  modelos <- sort(unique(efectos$modelo))
  matriz <- matrix(NA_real_, length(modelos), length(predictores),
                   dimnames = list(modelos, predictores))
  matriz[cbind(match(efectos$modelo, modelos),
    match(sub("TRUE$", "", efectos$termino), predictores))] <- efectos$estimado
  stopifnot(!anyNA(matriz))
  limite <- max(abs(matriz))
  paleta <- colorRampPalette(c("#B54B43", "white", "#24679B"))(101)
  anterior <- par(no.readonly = TRUE)
  on.exit(par(anterior))
  par(mar = c(10, 18, 4, 1))
  image(seq_along(predictores), seq_along(modelos),
    t(matriz[rev(seq_along(modelos)), , drop = FALSE]),
    zlim = c(-limite, limite), col = paleta, axes = FALSE,
    xlab = "", ylab = "", main = "All 48 models: question-feature effects")
  axis(1, seq_along(predictores), predictores, las = 2, cex.axis = 0.8)
  axis(2, seq_along(modelos), rev(modelos), las = 1, cex.axis = 0.65)
  mtext(paste0("Red < 0 | White = 0 | Blue > 0; scale +/- ",
               round(limite, 2), " log-odds"), 3, line = 0.4, cex = 0.65)
  invisible(matriz)
}
matriz_coeficientes <- heatmap_48(coeficientes_48)

# 4. FIT ON TRAIN ONLY; PREDICT THE SAME JULY VOTES AS MARK ----
# The all-month fit above is descriptive. It is NOT the test model.
particion <- read.csv("R/resultados/split_train_test.csv")
base_larga$split <- particion$split[match(base_larga$id, particion$id)]
stopifnot(!anyNA(base_larga$split))
train <- preparar_respuesta(base_larga[base_larga$split == "train", ],
                            politica = "medio_punto")
ajustes_train <- ajustar_modelos(train, lambda = 0)
julio <- read.csv("R/resultados/test_julio_votos.csv")
preguntas_julio <- base_larga[match(julio$id, base_larga$id), predictores]
stopifnot(!anyNA(preguntas_julio))

probabilidad_del_par <- function(ajustes, pares, preguntas) {
  p_a <- probabilidad(ajustes, pares$model_a, preguntas)
  p_b <- probabilidad(ajustes, pares$model_b, preguntas)
  plogis(qlogis(p_a) - qlogis(p_b))
}
p_48 <- probabilidad_del_par(ajustes_train, julio, preguntas_julio)
resultado_48 <- evaluar(p_48, julio$winner,
  method = "regressions_48_half_point", tie_handling = "half")
mostrar_tabla(resultado_48, "LIVE: unseen July votes, no ridge")

# Mark already chose lambda using cross-validation INSIDE train. Read his choice.
validacion_train <- read.csv("R/resultados/ridge_validacion_cruzada.csv")
lambda_mark <- validacion_train$lambda[which.min(validacion_train$cv_logloss)]
mostrar_tabla(validacion_train, "Mark: lambda chosen inside train, not July")
ajustes_ridge_train <- ajustar_modelos(train, lambda = lambda_mark)
p_ridge <- probabilidad_del_par(ajustes_ridge_train, julio, preguntas_julio)
resultado_ridge <- evaluar(p_ridge, julio$winner,
  method = "regressions_48_ridge_half_point", tie_handling = "half")

# 5. RUN THE GENERAL BRADLEY-TERRY BASELINE ----
# Same decisive training votes and reference model as Mark; 1 row per vote.
votos$split <- particion$split[match(votos$id, particion$id)]
train_bt <- votos[votos$split == "train" &
  votos$winner %in% c("model_a", "model_b") & votos$model_a != votos$model_b, ]
referencia <- "claude-opus-4-20250514"
modelos_train <- sort(unique(c(train_bt$model_a, train_bt$model_b)))
otros <- setdiff(modelos_train, referencia)
X <- matrix(0, nrow(train_bt), length(otros), dimnames = list(NULL, otros))
a <- match(train_bt$model_a, otros)
b <- match(train_bt$model_b, otros)
X[cbind(which(!is.na(a)), a[!is.na(a)])] <- 1
X[cbind(which(!is.na(b)), b[!is.na(b)])] <- -1
baseline <- glm.fit(X, as.numeric(train_bt$winner == "model_a"),
                    family = binomial())
stopifnot(baseline$converged)
fuerza <- c(setNames(0, referencia), baseline$coefficients)
p_baseline <- plogis(fuerza[julio$model_a] - fuerza[julio$model_b])
resultado_baseline <- evaluar(unname(p_baseline), julio$winner,
  method = "general_bradley_terry", tie_handling = "exclude")

# Mark's half-point win-rate baseline, calculated on the same train rows.
tasa <- tapply(train$y, train$model, mean)
p_tasa <- plogis(qlogis(tasa[julio$model_a]) - qlogis(tasa[julio$model_b]))
resultado_tasa <- evaluar(unname(p_tasa), julio$winner,
  method = "general_win_rate_half_point", tie_handling = "half")
comparacion <- rbind(resultado_baseline, resultado_tasa,
                     resultado_48, resultado_ridge)
# Confirm that today's live run reproduces the group's saved evaluation.
evaluacion_guardada <- read.csv("R/resultados/evaluacion.csv")
control <- evaluacion_guardada[match(comparacion$method,
                                     evaluacion_guardada$method), ]
stopifnot(identical(comparacion$correct, control$correct),
  isTRUE(all.equal(comparacion$logloss, control$logloss, tolerance = 1e-8)))
mostrar_tabla(comparacion, "LIVE comparison: baseline, separate models and ridge")
predicciones_julio <- data.frame(julio, p_model_a_48 = p_48,
  p_model_a_ridge = p_ridge,
  predicted = ifelse(p_ridge > 0.5, "model_a", "model_b"))
mostrar_tabla(predicciones_julio, "Actual pairs, predicted probabilities and winners")

# 6. VISUAL TEST RESULTS AND MODEL RECOMMENDATIONS ----
# Go back/forward between charts using the Plots arrows.
comparar_graficamente <- function(tabla) {
  anterior <- par(no.readonly = TRUE)
  on.exit(par(anterior))
  etiquetas <- c("General BT", "General win rate", "48 regressions", "48 + ridge")
  y <- rev(seq_len(nrow(tabla)))
  par(mfrow = c(1, 2), mar = c(5, 10, 4, 2))
  plot(tabla$accuracy_percent, y, yaxt = "n", ylab = "", pch = 19,
    xlim = range(c(tabla$ci95_low_percent, tabla$ci95_high_percent)) + c(-0.2, 0.2),
    xlab = "Accuracy (%)", main = "Unseen July votes", col = "#24679B")
  axis(2, y, etiquetas, las = 1)
  segments(tabla$ci95_low_percent, y, tabla$ci95_high_percent, y,
            col = "#24679B")
  plot(tabla$logloss, y, yaxt = "n", ylab = "", pch = 19, col = "#B54B43",
       xlab = "Log-loss (lower is better)", main = "Probability quality")
  axis(2, y, etiquetas, las = 1)
}
comparar_graficamente(comparacion)

# The task ranking uses real questions, not an artificial one-feature question.
top_codigo <- top3("is_code", ajustes_completos)
top_math <- top3("math", ajustes_completos)
mostrar_tabla(top_codigo, "Code: top 3, at least 100 July votes")
mostrar_tabla(top_math, "Math: top 3, at least 100 July votes")

# Marco's prices; prefer the latest version already available in this checkout.
archivos_precios <- c("data/derivados/precios_modelos_2026-11-02_v4.csv",
  "data/derivados/precios_modelos_2026-11-02_v3.csv",
  "data/derivados/precios_modelos_2026-10-28_v2.csv")
archivo_precios <- archivos_precios[file.exists(archivos_precios)][1]
precios <- read.csv(archivo_precios)
mostrar_tabla(precios, "Marco: prices and sources")
top_math_presupuesto <- top3("math", ajustes_completos,
  precio_max = 2, archivo_precios = archivo_precios)
mostrar_tabla(top_math_presupuesto, "Math: output price at most USD 2 per million tokens")
# This is list price per output token, NOT actual cost per response.
top_presupuestos_grupo <- read.csv("R/resultados/top3_por_precio.csv")
mostrar_tabla(top_presupuestos_grupo, "Marco: task and budget comparisons")

# 7. ELI'S CONTEXT: ANSWER LENGTH AND EXTERNAL RANKING ----
# Descriptive context, not a predictor and not independent test validation.
carpetas_eli <- list.dirs("R/resultados", recursive = FALSE)
carpetas_eli <- carpetas_eli[grepl("/eli_contexto_", carpetas_eli)]
stopifnot(length(carpetas_eli) > 0L)
carpeta_eli <- tail(sort(carpetas_eli), 1)
largo <- read.csv(file.path(carpeta_eli, "largo_resumen.csv"))
ranking_externo <- read.csv(file.path(carpeta_eli, "comparacion_leaderboard.csv"))
mostrar_tabla(largo, "Eli: answer length and preference")
mostrar_tabla(ranking_externo, "Eli: descriptive comparison with LMArena")
seleccion <- largo[largo$cohort == "first_vote", ]
anterior <- par(no.readonly = TRUE)
par(mar = c(8, 5, 4, 2))
barplot(100 * seleccion$share_longer_wins, names.arg = seleccion$task,
        las = 2, ylim = c(0, 100), col = "#24679B",
        main = "Longer answers and user preference",
        ylab = "Votes won by the longer answer (%)")
abline(h = 50, lty = 2)
mtext("Descriptive association; length is NOT used as a predictor", 3, cex = 0.8)
par(anterior)

# What is NOT finished: combined BT with features (issue #14), Shiny and dashboards.
# This demo uses the existing phase-1 data; it does not repeat data preparation.
cat("\nLive run finished. Inspect Environment, Console, Data Viewer and Plots.\n")
