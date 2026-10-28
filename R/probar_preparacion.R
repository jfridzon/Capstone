# Pruebas de la base larga con datos artificiales; ejecutar desde la raiz.
source("R/01_preparar_datos.R")

probar_preparacion <- function() {
  raiz <- getwd()
  destino <- tempfile("preparacion_prueba_")
  dir.create(file.path(destino, "R"), recursive = TRUE)
  dir.create(file.path(destino, "data"))
  file.copy("R/auditar_limpieza.R", file.path(destino, "R"))
  # Solo se toma el esquema. Todos los valores relevantes se fijan abajo.
  x <- read_csv("data/lmarena_votes.csv", n_max = 4,
                col_types = cols(.default = col_character()),
                show_col_types = FALSE)
  x$id <- paste0("artificial_", seq_len(4))
  x$evaluation_session_id <- paste0("sesion_", seq_len(4))
  x$model_a <- "modelo_A"
  x$model_b <- "modelo_B"
  x$evaluation_order <- "1"
  x$timestamp <- "2025-06-01T00:00:00Z"
  x$winner <- c("model_a", "model_b", "tie", "both_bad")
  write_csv(x, file.path(destino, "data", "lmarena_votes.csv"))
  on.exit({setwd(raiz); unlink(destino, recursive = TRUE)}, add = TRUE)
  setwd(destino)
  res <- preparar_datos(nombre = "prueba", min_votos = 1L)
  larga <- read_csv(res$archivo, show_col_types = FALSE)
  stopifnot(nrow(larga) == 8L, n_distinct(larga$model) == 2L)
  stopifnot(all(larga$month == 6L), sum(is.na(larga$won)) == 4L)
  stopifnot(all(larga$won_medio_punto_escenario[!larga$es_decisivo] == 0.5))
  stopifnot(all(larga$rival != larga$model))
  stopifnot(sum(larga$won, na.rm = TRUE) == 2L)
  stopifnot(!any(grepl("tokens|headers|lists|bold|price", names(larga))))
  stopifnot(inherits(try(preparar_datos(
    nombre = "prueba", min_votos = 1L
  ), silent = TRUE), "try-error"))
  stopifnot(inherits(try(preparar_datos(
    nombre = "../prohibido", min_votos = 1L
  ), silent = TRUE), "try-error"))
  message("Pruebas de preparacion completadas correctamente.")
}

probar_preparacion()
