# Pruebas artificiales de los dos contratos y de proteccion de archivos.
source("R/01_preparar_datos.R")
probar_preparacion <- function() {
  raiz <- getwd()
  destino <- tempfile("prueba_dos_exportaciones_")
  dir.create(file.path(destino, "R"), recursive = TRUE)
  dir.create(file.path(destino, "data"))
  file.copy("R/auditar_limpieza.R", file.path(destino, "R"))
  x <- read_csv("data/lmarena_votes.csv", n_max = 6,
                col_types = cols(.default = col_character()),
                show_col_types = FALSE)
  x$id <- paste0("artificial_", seq_len(6))
  x$evaluation_session_id <- paste0("sesion_", seq_len(6))
  x$model_a <- "A"
  x$model_b <- c(rep("B", 5), "C")
  x$evaluation_order <- c(rep("1", 4), "2", "1")
  x$timestamp <- "2025-06-01T00:00:00Z"
  x$sum_user_tokens <- "17"
  x$language <- "es"
  x$winner <- c("model_a", "model_b", "tie", "both_bad", "model_a", "model_b")
  ruta <- file.path(destino, "data", "lmarena_votes.csv")
  write_csv(x, ruta)
  original <- tools::md5sum(ruta)
  on.exit({setwd(raiz); unlink(destino, recursive = TRUE)}, add = TRUE)
  setwd(destino)
  res <- preparar_datos(nombre = "prueba", min_votos = 2L)
  largo <- read_csv(res$archivo, show_col_types = FALSE)
  ancho <- read_csv(res$filtrados, col_types = cols(.default = col_character()),
                    show_col_types = FALSE)
  esquema <- c("id", "evaluation_session_id", "timestamp", "mes", "modelo",
    "rival", "lado", "resultado", "won", "is_code", "math", "creative_writing",
    "instruction_following", "complexity", "creativity", "domain_knowledge",
    "problem_solving", "real_world", "specificity", "technical_accuracy",
    "sum_user_tokens", "language")
  stopifnot(identical(names(largo), esquema), nrow(largo) == 8L,
    identical(as.data.frame(ancho), as.data.frame(x[1:4, ])),
    all(largo$mes == 6L), all(largo$sum_user_tokens == 17),
    all(largo$language == "es"), sum(is.na(largo$won)) == 4L,
    setequal(largo$resultado, c("gano", "perdio", "empate", "ambos_malos")),
    setequal(largo$lado, c("a", "b")), sum(largo$won, na.rm = TRUE) == 2L,
    all(largo$rival != largo$modelo), identical(original, tools::md5sum(ruta)))
  hashes <- tools::md5sum(c(res$archivo, res$filtrados))
  stopifnot(inherits(try(preparar_datos(nombre = "otra", min_votos = 2L),
                        silent = TRUE), "try-error"),
    identical(hashes, tools::md5sum(c(res$archivo, res$filtrados))))
  # Si ya existe SOLO una salida, tampoco se escribe ni altera la otra.
  dir.create("data/parcial")
  writeLines("no tocar", "data/parcial/votos_largo.csv")
  stopifnot(inherits(try(preparar_datos(nombre = "parcial", min_votos = 2L,
                    salida = "data/parcial"), silent = TRUE), "try-error"),
    !file.exists("data/parcial/votos_filtrados.csv"),
    identical(readLines("data/parcial/votos_largo.csv"), "no tocar"))
  message("Pruebas de ambas exportaciones completadas correctamente.")
}
probar_preparacion()
