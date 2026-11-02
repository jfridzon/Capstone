# Entrega de Nessim: dos exportaciones con el esquema de docs/tareas/nessim.md.
# Desde la raiz: Rscript R/01_preparar_datos.R
# Paquetes: install.packages(c("readr", "dplyr")) si faltan.
# Nunca sobrescribe entradas ni salidas existentes. Asistencia: ChatGPT/Codex.
library(readr)
library(dplyr)

preparar_datos <- function(
    entrada = "data/lmarena_votes.csv",
    nombre = paste0("preparacion_", format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")),
    min_votos = 1000L,
    salida = "data/derivados") {
  if (length(nombre) != 1L || is.na(nombre) ||
      !grepl("^[A-Za-z0-9_-]+$", nombre)) stop("nombre invalido.")
  if (length(salida) != 1L || is.na(salida) || !nzchar(salida)) {
    stop("salida debe ser una carpeta.")
  }
  archivos <- file.path(salida, c("votos_filtrados.csv", "votos_largo.csv"))
  reporte <- file.path("R", "resultados", nombre)
  # Comprobar ambos destinos ANTES de crear reportes o escribir datos.
  if (any(file.exists(archivos)) || file.exists(reporte)) {
    stop("Ya existe una salida. Usa otra carpeta/otro nombre; no se sobrescribe.")
  }
  if (!file.exists(entrada)) stop("No existe el CSV de entrada.")
  hash_antes <- unname(tools::md5sum(entrada))
  on.exit({
    if (!identical(hash_antes, unname(tools::md5sum(entrada)))) {
      stop("El CSV original cambio durante la preparacion.")
    }
  }, add = TRUE)
  entorno <- new.env(parent = environment())
  sys.source("R/auditar_limpieza.R", envir = entorno)
  auditoria <- entorno$auditar_limpieza(entrada, reporte, min_votos)
  if (auditoria$bloqueado) stop("Auditoria bloqueante: revisar controles.csv.")
  # Leer como texto conserva los valores y campos del original en la base ancha.
  votos <- read_csv(entrada, col_types = cols(.default = col_character()),
                    na = "NA", trim_ws = FALSE, show_col_types = FALSE,
                    progress = FALSE)
  etiquetas <- c("is_code", "math", "creative_writing", "instruction_following",
    "complexity", "creativity", "domain_knowledge", "problem_solving",
    "real_world", "specificity", "technical_accuracy")
  for (columna in etiquetas) {
    if (any(is.na(votos[[columna]]) |
            !votos[[columna]] %in% c("TRUE", "FALSE"))) {
      stop("Caracteristica faltante o invalida: ", columna)
    }
  }
  fechas <- suppressWarnings(parse_datetime(votos$timestamp,
                                            locale = locale(tz = "UTC")))
  tokens <- suppressWarnings(as.numeric(votos$sum_user_tokens))
  if (anyNA(fechas)) stop("Hay fechas invalidas o faltantes.")
  if (any(!is.finite(tokens) | tokens < 0 | tokens != floor(tokens))) {
    stop("sum_user_tokens debe contener enteros no negativos, sin faltantes.")
  }
  conteos <- tibble(modelo = c(votos$model_a, votos$model_b)) |>
    count(modelo, name = "participaciones") |>
    mutate(elegible = participaciones >= min_votos)
  elegibles <- conteos$modelo[conteos$elegible]
  primeros <- votos |> filter(as.integer(evaluation_order) == 1L)
  # Mantener los campos originales, su orden y sus valores. No agregar banderas.
  filtrados <- primeros |>
    filter(model_a %in% elegibles, model_b %in% elegibles)
  fecha_filtrada <- suppressWarnings(parse_datetime(filtrados$timestamp,
                                                   locale = locale(tz = "UTC")))
  contexto <- filtrados |>
    mutate(timestamp = fecha_filtrada,
           mes = as.integer(format(timestamp, "%m", tz = "UTC")),
           across(all_of(etiquetas), ~ .x == "TRUE"),
           sum_user_tokens = as.numeric(sum_user_tokens))
  largo <- bind_rows(
    contexto |> mutate(modelo = model_a, rival = model_b, lado = "a"),
    contexto |> mutate(modelo = model_b, rival = model_a, lado = "b")
  ) |>
    mutate(
      resultado = case_when(
        winner == "tie" ~ "empate",
        winner == "both_bad" ~ "ambos_malos",
        (winner == "model_a" & lado == "a") |
          (winner == "model_b" & lado == "b") ~ "gano",
        TRUE ~ "perdio"
      ),
      won = case_when(resultado == "gano" ~ 1L,
                      resultado == "perdio" ~ 0L, TRUE ~ NA_integer_)
    ) |>
    select(id, evaluation_session_id, timestamp, mes, modelo, rival, lado,
           resultado, won, all_of(etiquetas), sum_user_tokens, language) |>
    arrange(timestamp, id, lado)
  pares <- largo |> group_by(id) |>
    summarise(filas = n(), lados = n_distinct(lado),
              suma_won = sum(won), .groups = "drop")
  decisivos <- filtrados$winner %in% c("model_a", "model_b")
  stopifnot(
    identical(names(filtrados), names(votos)),
    nrow(largo) == 2L * nrow(filtrados),
    all(pares$filas == 2L), all(pares$lados == 2L),
    all(na.omit(pares$suma_won) == 1L),
    all(is.na(largo$won[largo$resultado %in% c("empate", "ambos_malos")])),
    all(largo$won[largo$resultado == "gano"] == 1L),
    all(largo$won[largo$resultado == "perdio"] == 0L)
  )
  # Los casos senalados se conservan en las bases y se documentan aparte.
  sesiones <- primeros |> count(evaluation_session_id) |> filter(n > 1L)
  banderas <- filtrados |>
    transmute(id, mismo_modelo = model_a == model_b,
      sesion_primer_voto_repetido = evaluation_session_id %in% sesiones$evaluation_session_id) |>
    mutate(requiere_revision = mismo_modelo | sesion_primer_voto_repetido)
  resumen <- tibble(etapa = c("original", "primer_voto", "votos_filtrados",
    "votos_largo", "modelos", "votos_decisivos", "votos_requieren_revision"),
    cantidad = c(nrow(votos), nrow(primeros), nrow(filtrados), nrow(largo),
                 n_distinct(largo$modelo), sum(decisivos), sum(banderas$requiere_revision)))
  dir.create(salida, recursive = TRUE, showWarnings = FALSE)
  write_csv(filtrados, archivos[1], na = "NA")
  write_csv(largo, archivos[2], na = "NA")
  write_csv(resumen, file.path(reporte, "resumen_preparacion.csv"))
  write_csv(conteos, file.path(reporte, "elegibilidad.csv"))
  write_csv(banderas, file.path(reporte, "banderas_por_voto.csv"))
  write_csv(tibble(archivo = basename(archivos),
                   md5 = unname(tools::md5sum(archivos))),
            file.path(reporte, "huellas_salidas.csv"))
  writeLines(c(
    "# Contrato vigente de la base de Nessim",
    "votos_filtrados.csv conserva todos los campos y valores originales.",
    "votos_largo.csv usa exactamente las columnas de docs/tareas/nessim.md.",
    "lado: a/b. resultado: gano/perdio/empate/ambos_malos.",
    "won: 1/0 para victoria/derrota; NA para empate o ambos_malos.",
    "No se eligio una politica final para los resultados no decisivos.",
    "Propuesta pendiente: ajuste binario con decisivos y sensibilidad aparte.",
    "No se agrupan versiones ni se elige control del rival o particion.",
    "sum_user_tokens y language se conservan por la ficha; no se agregan",
    "automaticamente como predictores. Las 11 caracteristicas siguen acordadas.",
    "Las bases conservan casos senalados; ver banderas_por_voto.csv.",
    "No usar esas banderas como predictores ni eliminar casos sin revision.",
    "Las 2 filas de un voto y las sesiones deben permanecer juntas al evaluar.",
    "La base larga comprimida de octubre se mantiene intacta como historico.",
    "Original verificado con MD5. Codigo preparado con asistencia de IA."
  ), file.path(reporte, "CONTRATO_BASE.md"))
  message("Generados: ", paste(archivos, collapse = ", "))
  invisible(list(archivo = archivos[2], filtrados = archivos[1],
                 reporte = reporte, resumen = resumen))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 2L) stop("Uso: Rscript R/01_preparar_datos.R [nombre] [carpeta_salida]")
  opciones <- list()
  if (length(args) >= 1L) opciones$nombre <- args[1]
  if (length(args) >= 2L) opciones$salida <- args[2]
  do.call(preparar_datos, opciones)
}
