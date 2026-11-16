# Eli: confirmacion de su pieza para la demo del 16/11/2026.
# Ejecutar desde la raiz: Rscript --vanilla R/validar_demo_eli_16_nov.R
# Solo R base. No ajusta modelos, no ejecuta piezas de otros ni genera folds.
# Preparado con asistencia de ChatGPT/Codex (OpenAI).
options(warn = 2, width = 160)
salida <- "R/resultados/eli_validacion_demo_2026-11-16"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
protegidos <- unlist(lapply(c("data", "entregas", "R/resultados"), function(p)
  list.files(p, recursive = TRUE, full.names = TRUE, all.files = TRUE)), use.names = FALSE)
protegidos <- protegidos[!startsWith(protegidos, paste0(salida, "/"))]
huellas <- tools::md5sum(protegidos)

cat("CLEAN R SESSION\n")
cat(R.version.string, "\n")
stopifnot(!exists("grafico_coeficientes", inherits = FALSE),
          !exists("heatmap_48", inherits = FALSE),
          !exists("tabla_sensibilidad", inherits = FALSE))
archivos_antes <- list.files(".", recursive = TRUE, all.files = FALSE)
dispositivo_antes <- dev.cur()
opciones_antes <- options()
pieza <- new.env()
sys.source("R/16_graficos_coeficientes.R", envir = pieza)
stopifnot(identical(archivos_antes, list.files(".", recursive = TRUE, all.files = FALSE)),
          identical(dispositivo_antes, dev.cur()), identical(opciones_antes, options()),
          identical(names(formals(pieza$grafico_coeficientes)), "modelo"),
          length(formals(pieza$heatmap_48)) == 0L,
          length(formals(pieza$tabla_sensibilidad)) == 0L)
cat("PASS: source without file, device or option changes; original interfaces.\n")

publicados <- read.csv("R/resultados/coeficientes_por_modelo.csv", stringsAsFactors = FALSE)
modelos <- sort(unique(publicados$modelo))
stopifnot(length(modelos) == 48L)
pdf(file.path(salida, "coeficientes_48_modelos.pdf"), width = 10, height = 7)
margen <- par("mar")
max_diferencia <- 0
for (modelo in modelos) {
  d <- pieza$grafico_coeficientes(modelo)
  ref <- publicados[publicados$modelo == modelo, ]
  ref <- ref[match(d$termino, ref$termino), ]
  stopifnot(nrow(d) == 11L, all(diff(d$estimado) >= 0),
            all(d$termino != "(Intercept)"), !anyNA(ref),
            identical(par("mar"), margen))
  diferencia <- max(abs(d$estimado - ref$estimado),
                    abs(d$ci_low - (ref$estimado - qnorm(.975) * ref$error_estandar)),
                    abs(d$ci_high - (ref$estimado + qnorm(.975) * ref$error_estandar)))
  stopifnot(diferencia < 1e-12)
  max_diferencia <- max(max_diferencia, diferencia)
}
invisible(dev.off())
cat("PASS: all 48 coefficient plots, 11 effects and nominal 95% intervals.\n")

pdf(file.path(salida, "heatmap_48.pdf"), width = 13, height = 12)
margen <- par("mar")
matriz <- pieza$heatmap_48()
stopifnot(identical(dim(matriz), c(48L, 11L)), !anyNA(matriz),
          setequal(rownames(matriz), modelos), identical(par("mar"), margen))
invisible(dev.off())
efectos <- publicados[publicados$termino != "(Intercept)", ]
stopifnot(max(abs(matriz[cbind(match(efectos$modelo, rownames(matriz)),
  match(sub("TRUE$", "", efectos$termino), colnames(matriz)))] - efectos$estimado)) < 1e-12)
# Tamano aproximado del panel de RStudio con Zoom disponible.
pdf(file.path(salida, "panel_7x7.pdf"), width = 7, height = 7)
pieza$grafico_coeficientes("o3-2025-04-16")
pieza$heatmap_48()
invisible(dev.off())
cat("PASS: heatmap 48 x 11; plots also work on a 7 x 7 inch device.\n")

tabla <- pieza$tabla_sensibilidad()
ref <- read.csv("R/resultados/sensibilidad_auc_2026-11-09/resumen.csv", stringsAsFactors = FALSE)
columnas <- c("auc_all_votes", paste0("auc_fold", 1:5), "auc_cv_mean")
stopifnot(identical(dim(tabla), c(4L, 8L)),
          identical(tabla$Method, c("Binomial", "Quasibinomial", "Ordinal", "General ranking")),
          max(abs(as.matrix(tabla[-1]) - round(as.matrix(ref[columnas]), 4))) < 1e-12)
print(tabla, row.names = FALSE)
write.csv(tabla, file.path(salida, "tabla_sensibilidad.csv"), row.names = FALSE)
protegidos_despues <- unlist(lapply(c("data", "entregas", "R/resultados"), function(p)
  list.files(p, recursive = TRUE, full.names = TRUE, all.files = TRUE)), use.names = FALSE)
protegidos_despues <- protegidos_despues[!startsWith(protegidos_despues, paste0(salida, "/"))]
stopifnot(identical(protegidos, protegidos_despues),
          identical(tools::md5sum(protegidos), huellas))
cat("\nPASS: sensitivity table matches stored results; protected input hashes unchanged.\n")
cat("Maximum coefficient/interval difference:", max_diferencia, "\n")
cat("Protected files checked:", length(protegidos), "\n")
print(sessionInfo())
cat("ALL ELI DEMO CHECKS PASSED. No RStudio GUI or full Nessim demo was tested here.\n")
writeLines(c("PASS: all Eli functions executed in a clean R process.",
             paste("Protected files checked:", length(protegidos)),
             paste("Maximum coefficient/interval difference:", max_diferencia),
             capture.output(sessionInfo())), file.path(salida, "verificacion.txt"))
