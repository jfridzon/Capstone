# Regenera la tarea 1 de Nessim, sin rehacer datos ni ejecutar R/03.
# Rscript R/generar_reporte_48.R
# Requiere rmarkdown, knitr, htmltools, ggplot2 y Pandoc para el HTML.
# Asistencia: ChatGPT/Codex, 2/11/2026.
protegidos <- c("data/lmarena_votes.csv",
  "data/derivados/base_regresiones_2026-10-28_v2.csv.gz",
  "data/derivados/precios_modelos_2026-10-28_v2.csv",
  "R/03_evaluacion.R", "R/resultados/evaluacion.csv")
hashes <- tools::md5sum(protegidos)
regenerar_48 <- function() {
  on.exit(stopifnot(identical(hashes, tools::md5sum(protegidos))), add = TRUE)
  e <- new.env(parent = globalenv())
  op <- options(correr_02 = TRUE)
  tryCatch(sys.source("R/02_regresiones_por_modelo.R", envir = e),
           finally = options(op))
  salida <- "R/resultados/regresiones_48_2026-11-02"
  dir.create(salida, recursive = TRUE, showWarnings = FALSE)
  guardar <- function(x, archivo) write.csv(x, file.path(salida, archivo),
                                           row.names = FALSE)
  modelos <- names(e$ajustes)
  n <- vapply(e$ajustes, function(x) x$n_votos, numeric(1))
  guardar(data.frame(modelo = modelos, votos = unname(n),
    convergio = vapply(e$ajustes, function(x) x$converged, logical(1))),
    "ajustes.csv")
  guardar(data.frame(campo = c("votos", "filas_largas", "modelos", "coeficientes",
    "empates_o_both_bad", "lambda"),
    valor = c(nrow(e$datos)/2, nrow(e$datos), length(e$ajustes), nrow(e$coefs),
      sum(!e$datos$es_decisivo)/2, 0)), "resumen.csv")
  escenarios <- list(codigo = "is_code", math = "math",
    escritura_creativa = "creative_writing",
    instrucciones = "instruction_following",
    codigo_y_math = c("is_code", "math"), todas = character())
  tops <- do.call(rbind, lapply(names(escenarios), function(nombre) {
    cbind(escenario = nombre, e$top3(escenarios[[nombre]], e$ajustes))
  }))
  guardar(tops, "top3_por_tarea.csv")
  presupuesto <- do.call(rbind, lapply(c(10, 2, 0.5), function(p) {
    do.call(rbind, lapply(names(escenarios), function(nombre) {
      t <- e$top3(escenarios[[nombre]], e$ajustes, precio_max = p)
      if (!nrow(t)) return(NULL)
      cbind(escenario = nombre, precio_max = p, t)
    }))
  }))
  guardar(presupuesto, "top3_presupuestos_ejemplo.csv")
  guardar(data.frame(archivo = names(hashes), md5_antes = unname(hashes),
    md5_despues = unname(tools::md5sum(protegidos))), "integridad.csv")
  writeLines(c(R.version.string,
    paste("rmarkdown", as.character(utils::packageVersion("rmarkdown"))),
    paste("ggplot2", as.character(utils::packageVersion("ggplot2")))),
    file.path(salida, "versiones.txt"))
  rmarkdown::render("reporte/01_regresiones_48.Rmd",
    envir = new.env(parent = globalenv()), knit_root_dir = normalizePath("."),
    quiet = TRUE)
  invisible(salida)
}
regenerar_48()
