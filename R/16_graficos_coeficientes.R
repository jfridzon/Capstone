# Eli, issue #46: graficos y tabla para la demo del 16/11/2026.
# Preparado con asistencia de ChatGPT/Codex (OpenAI). Solo R base.
# Desde la raiz del repo:
#   source("R/16_graficos_coeficientes.R")  # define funciones; no ajusta ni escribe
#   grafico_coeficientes("o3-2025-04-16")
#   heatmap_48()                           # usar Zoom en el panel Plots
#   tabla_sensibilidad()                   # o View(tabla_sensibilidad())
# Rscript R/16_graficos_coeficientes.R guarda ejemplos y controles propios.

# Nombres tecnicos y etiquetas para el profesor (mismo orden que R/02).
.eli16_etiquetas <- c(is_code = "Code", math = "Math",
  creative_writing = "Creative writing", instruction_following = "Following instructions",
  complexity = "Complexity", creativity = "Creativity", domain_knowledge = "Expert knowledge",
  problem_solving = "Problem solving", real_world = "Real-world tasks",
  specificity = "Specific requests", technical_accuracy = "Technical accuracy")

# Lee los resultados binomiales publicados; no ejecuta scripts de otros.
.eli16_coeficientes <- function() {
  archivo <- "R/resultados/coeficientes_por_modelo.csv"
  if (!file.exists(archivo)) stop("Run from the repository root; missing ", archivo)
  d <- read.csv(archivo, stringsAsFactors = FALSE)
  stopifnot(all(c("modelo", "termino", "estimado", "error_estandar") %in% names(d)),
            length(unique(d$modelo)) == 48L, nrow(d) == 576L,
            !anyDuplicated(paste(d$modelo, d$termino)),
            all(is.finite(d$estimado)), all(is.finite(d$error_estandar)),
            all(d$error_estandar >= 0))
  predictores <- names(.eli16_etiquetas)
  stopifnot(all(vapply(split(d$termino, d$modelo), function(x)
    setequal(x, c("(Intercept)", paste0(predictores, "TRUE"))), logical(1))))
  # Confirmar que estos son los coeficientes BINOMIALES, no los de medio punto.
  ref <- read.csv("R/resultados/sensibilidad_2026-11-09/coeficientes.csv")
  e <- d[d$termino != "(Intercept)", ]
  clave <- paste(e$modelo, sub("TRUE$", "", e$termino))
  b <- ref$binomial[match(clave, paste(ref$modelo, ref$predictor))]
  stopifnot(!anyNA(b), max(abs(e$estimado - b)) < 1e-10)
  d
}

# 1. ONE MODEL: 11 feature effects with 95% confidence intervals ----
grafico_coeficientes <- function(modelo) {
  if (!is.character(modelo) || length(modelo) != 1L || is.na(modelo))
    stop("modelo must be one exact model ID, for example 'o3-2025-04-16'.")
  d <- .eli16_coeficientes()
  if (!(modelo %in% d$modelo)) stop("Unknown model ID: ", modelo)
  d <- d[d$modelo == modelo & d$termino != "(Intercept)", ]
  d$feature <- unname(.eli16_etiquetas[sub("TRUE$", "", d$termino)])
  # IC de Wald: beta +/- 1.96 * SE; no se llama confint() (que haria profiling).
  d$ci_low <- d$estimado - qnorm(0.975) * d$error_estandar
  d$ci_high <- d$estimado + qnorm(0.975) * d$error_estandar
  d <- d[order(d$estimado, d$feature), ]
  rownames(d) <- NULL
  anterior <- par(no.readonly = TRUE)
  on.exit(par(anterior))
  par(mar = c(6.2, 10, 5.2, 1.5), las = 1)
  limite <- max(abs(c(d$ci_low, d$ci_high))) * 1.13
  y <- seq_len(nrow(d))
  plot(d$estimado, y, type = "n", xlim = c(-limite, limite), ylim = c(.5, 11.5),
       axes = FALSE, xlab = "", ylab = "")
  abline(h = y, col = "#E9EDF2")
  abline(v = 0, col = "#526176", lty = 2, lwd = 1.5)
  colores <- ifelse(d$estimado >= 0, "#146C94", "#BC4B42")
  segments(d$ci_low, y, d$ci_high, y, col = colores, lwd = 2)
  segments(d$ci_low, y - .09, d$ci_low, y + .09, col = colores)
  segments(d$ci_high, y - .09, d$ci_high, y + .09, col = colores)
  points(d$estimado, y, pch = 19, col = colores, cex = 1.1)
  axis(1); axis(2, at = y, labels = d$feature, tick = FALSE, cex.axis = .85)
  title(main = "Which question features change this model's win odds?", line = 3, cex.main = 1)
  mtext(modelo, side = 3, line = 1.5, cex = .8)
  mtext("Feature effect on log-odds of winning", side = 1, line = 2.5)
  mtext("Negative: lower win odds                 Positive: higher win odds",
        side = 1, line = 4, cex = .76)
  mtext("Bars: nominal 95% Wald intervals. Other features held fixed; not causal effects.",
        side = 1, line = 5.1, cex = .68)
  invisible(d)
}

# 2. ALL 48 MODELS: same binomial coefficients, no intercepts ----
heatmap_48 <- function() {
  d <- .eli16_coeficientes()
  d <- d[d$termino != "(Intercept)", ]
  modelos <- sort(unique(d$modelo))
  predictores <- names(.eli16_etiquetas)
  matriz <- matrix(NA_real_, 48, 11, dimnames = list(modelos, predictores))
  matriz[cbind(match(d$modelo, modelos), match(sub("TRUE$", "", d$termino), predictores))] <- d$estimado
  stopifnot(!anyNA(matriz))
  limite <- max(abs(matriz))
  paleta <- colorRampPalette(c("#BC4B42", "#FFFFFF", "#146C94"))(101)
  anterior <- par(no.readonly = TRUE)
  on.exit(par(anterior))
  par(mar = c(9, 20, 4.5, 6), las = 1)
  # Un panel pequeno requiere Zoom para leer los 48 IDs completos.
  image(1:11, 1:48, t(matriz[48:1, , drop = FALSE]), col = paleta,
        zlim = c(-limite, limite), axes = FALSE, xlab = "", ylab = "")
  cex_modelos <- min(.65, max(.35, par("pin")[2] / 48 / strheight("M", units = "inches") * .75))
  axis(1, at = 1:11, labels = unname(.eli16_etiquetas), las = 2, tick = FALSE, cex.axis = .75)
  axis(2, at = 1:48, labels = rev(modelos), tick = FALSE, cex.axis = cex_modelos)
  title(main = "Question-feature effects across all 48 AI models", line = 2.7, cex.main = 1)
  mtext("Red: lower win odds | White: no change | Blue: higher win odds", 3, line = 1.1, cex = .72)
  # Leyenda numerica comun y simetrica en log-odds; no es un ranking ni porcentajes.
  valores <- seq(-limite, limite, length.out = 102)
  bordes <- seq(.5, 48.5, length.out = 102)
  rect(11.8, bordes[-102], 12.15, bordes[-1], col = paleta, border = NA, xpd = NA)
  text(12.4, c(.5, 24.5, 48.5), labels = sprintf("%.2f", c(-limite, 0, limite)),
       adj = 0, cex = .7, xpd = NA)
  text(11.8, 51, "Log-odds", adj = 0, cex = .7, xpd = NA)
  mtext("Descriptive binomial fits, all months. Other features held fixed; not causal effects.",
        1, line = 7.8, cex = .65)
  invisible(matriz)
}

# 3. SENSITIVITY: stored AUCs, no new fitting or folds ----
tabla_sensibilidad <- function() {
  archivo <- "R/resultados/sensibilidad_auc_2026-11-09/resumen.csv"
  if (!file.exists(archivo)) stop("Run from the repository root; missing ", archivo)
  d <- read.csv(archivo, stringsAsFactors = FALSE)
  metodos <- c("binomial", "quasibinomial", "ordinal", "general_ranking")
  columnas <- c("auc_all_votes", paste0("auc_fold", 1:5), "auc_cv_mean")
  stopifnot(all(c("method", columnas) %in% names(d)), nrow(d) == 4L,
            !anyDuplicated(d$method), setequal(d$method, metodos))
  d <- d[match(metodos, d$method), ]
  stopifnot(all(is.finite(as.matrix(d[columnas]))),
            max(abs(rowMeans(d[paste0("auc_fold", 1:5)]) - d$auc_cv_mean)) < 1e-12)
  salida <- data.frame(Method = c("Binomial", "Quasibinomial", "Ordinal", "General ranking"),
                       d[columnas], check.names = FALSE)
  names(salida) <- c("Method", "All data (in sample)", paste("Fold", 1:5), "Mean of 5 folds")
  salida[-1] <- lapply(salida[-1], round, digits = 4)
  rownames(salida) <- NULL
  # data.frame visible: funciona tanto en consola como con View(tabla_sensibilidad()).
  salida
}

# 4. EXAMPLES: execute line by line in RStudio ----
if (FALSE) {
  grafico_coeficientes("o3-2025-04-16")
  grafico_coeficientes("minimax-m1")
  heatmap_48() # Plots > Zoom para leer todos los nombres
  tabla_sensibilidad()
  # View(tabla_sensibilidad())
}

# Ejecucion directa: ejemplos y tablas para revision, en carpeta propia.
# source() desde la demo de Nessim solo define las funciones anteriores.
if (sys.nframe() == 0L) {
  salida <- "R/resultados/eli_demo_2026-11-11"
  dir.create(salida, recursive = TRUE, showWarnings = FALSE)
  pdf(file.path(salida, "coeficientes_o3.pdf"), width = 10, height = 7)
  ejemplo <- grafico_coeficientes("o3-2025-04-16")
  invisible(dev.off())
  pdf(file.path(salida, "heatmap_48.pdf"), width = 13, height = 12)
  matriz <- heatmap_48()
  invisible(dev.off())
  tabla <- tabla_sensibilidad()
  write.csv(ejemplo, file.path(salida, "coeficientes_o3.csv"), row.names = FALSE)
  write.csv(matriz, file.path(salida, "matriz_heatmap.csv"), row.names = TRUE)
  write.csv(tabla, file.path(salida, "tabla_sensibilidad.csv"), row.names = FALSE)
  print(tabla, row.names = FALSE)
  cat("\nOK: 11 feature effects with intervals; 48 x 11 heatmap; 4 sensitivity methods.\n")
}
