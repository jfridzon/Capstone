# Pruebas sinteticas, sin descargar datos ni generar resultados del proyecto.
# Desde la raiz: Rscript R/probar_auditoria.R
source("R/auditar_limpieza.R")

probar_auditoria <- function() {
  carpeta <- tempfile("pruebas_auditoria_")
  dir.create(carpeta)
  on.exit(unlink(carpeta, recursive = TRUE), add = TRUE)
  etiquetas <- c(
    "is_code", "math", "creative_writing", "instruction_following",
    "complexity", "creativity", "domain_knowledge", "problem_solving",
    "real_world", "specificity", "technical_accuracy"
  )
  numeros <- c(
    "sum_user_tokens", "turns", "answer_a_tokens", "answer_b_tokens",
    "headers_a", "headers_b", "lists_a", "lists_b", "bold_a", "bold_b",
    "if_score"
  )
  x <- tibble(
    id = paste0("id", seq_len(6)), model_a = "A",
    model_b = c("B", "B", "C", "C", "C", "C"),
    winner = c("model_a", "model_b", "tie", "both_bad", "model_a", "model_b"),
    evaluation_session_id = paste0("sesion", seq_len(6)),
    evaluation_order = c("1", "1", "1", "2", "2", "2"),
    timestamp = "2025-04-17T00:20:51Z",
    language = c("und", "en", "en", "en", "en", "en")
  )
  for (nombre in etiquetas) x[[nombre]] <- "FALSE"
  for (nombre in numeros) x[[nombre]] <- "1"
  ejecutar <- function(df, nombre, umbral = 3L) {
    ruta <- file.path(carpeta, paste0(nombre, ".csv"))
    write_csv(df, ruta)
    antes <- tools::md5sum(ruta)
    res <- auditar_limpieza(ruta, file.path(carpeta, nombre), umbral)
    stopifnot(identical(antes, tools::md5sum(ruta)))
    res
  }
  res <- ejecutar(x, "valido")
  stopifnot(!res$bloqueado)
  stopifnot(identical(res$etapas$filas, c(6L, 3L, 1L, 0L, 6L, 3L, 0L, 0L)))
  r2 <- ejecutar(x, "umbral_dos", 2L)
  stopifnot(identical(r2$etapas$filas, c(6L, 3L, 3L, 2L, 6L, 3L, 2L, 2L)))
  comprobacion <- read_csv(
    file.path(r2$salida, "verificacion_won.csv"), show_col_types = FALSE
  )
  stopifnot(identical(comprobacion$sin_respuesta_binaria, c(1, 0)))
  stopifnot(all(comprobacion$pares_con_suma_uno == 2))
  # Datos invalidos no se convierten silenciosamente en una base filtrada.
  malo <- x
  malo$winner[1] <- "desconocido"
  stopifnot(ejecutar(malo, "winner_invalido")$bloqueado)
  malo <- x
  malo$evaluation_order[1] <- "1.5"
  stopifnot(ejecutar(malo, "orden_invalido")$bloqueado)
  stopifnot(ejecutar(bind_rows(x, x[1, ]), "duplicado")$bloqueado)
  malo <- x
  malo$model_a[1] <- NA_character_
  stopifnot(ejecutar(malo, "modelo_faltante")$bloqueado)
  # Los problemas cuya resolucion no esta acordada se reportan, no se borran.
  revisar <- x
  revisar$model_b[1] <- "A"
  revisar$evaluation_session_id[2] <- revisar$evaluation_session_id[1]
  rr <- ejecutar(revisar, "requiere_revision")
  stopifnot(!rr$bloqueado)
  stopifnot(rr$controles$hallazgos[
    rr$controles$control == "mismo_modelo_en_ambos_lados"
  ] == 1L)
  stopifnot(rr$controles$hallazgos[
    rr$controles$control == "primer_voto_repetido_por_sesion"
  ] == 1L)
  stopifnot(inherits(try(auditar_limpieza(
    file.path(carpeta, "valido.csv"), res$salida
  ), silent = TRUE), "try-error"))
  stopifnot(inherits(try(auditar_limpieza(
    file.path(carpeta, "valido.csv"), file.path(carpeta, "otro"), 0
  ), silent = TRUE), "try-error"))
  message("Pruebas sinteticas completadas correctamente.")
}

probar_auditoria()
