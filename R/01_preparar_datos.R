# Base larga para Jaime y Mark, segun docs/07 (plan del 28/10).
# Ejecutar desde la raiz: Rscript R/01_preparar_datos.R
# Requiere readr y dplyr. No instala paquetes ni cambia el CSV original.
# Empates/both_bad se conservan con won = NA; su politica sigue pendiente.
# Preparado con asistencia de ChatGPT/Codex; revisar antes de modelar.

library(readr)
library(dplyr)

preparar_datos <- function(
    entrada = "data/lmarena_votes.csv",
    nombre = paste0("preparacion_", format(
      Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"
    )),
    min_votos = 1000L) {
  if (length(nombre) != 1L || is.na(nombre) ||
      !grepl("^[A-Za-z0-9_-]+$", nombre)) {
    stop("nombre debe ser un nombre simple, sin rutas ni espacios.")
  }
  archivo <- file.path("data", "derivados", paste0(nombre, ".csv.gz"))
  reporte <- file.path("R", "resultados", nombre)
  if (file.exists(archivo) || file.exists(reporte)) {
    stop("La salida ya existe. Usa otro nombre; no se sobrescribe nada.")
  }
  # Reusar la auditoria, incluido el control del hash y de entradas invalidas.
  entorno <- new.env(parent = environment())
  sys.source("R/auditar_limpieza.R", envir = entorno)
  auditoria <- entorno$auditar_limpieza(entrada, reporte, min_votos)
  if (auditoria$bloqueado) {
    stop("Auditoria bloqueante: revisar controles antes de generar la base.")
  }
  hash_antes <- unname(tools::md5sum(entrada))
  votos <- read_csv(
    entrada, col_types = cols(.default = col_character()),
    na = "NA", trim_ws = FALSE, show_col_types = FALSE, progress = FALSE
  )
  etiquetas <- c(
    "is_code", "math", "creative_writing", "instruction_following",
    "complexity", "creativity", "domain_knowledge", "problem_solving",
    "real_world", "specificity", "technical_accuracy"
  )
  # Para los predictores requeridos, un faltante o booleano invalido bloquea
  # la generacion, en lugar de imputar o borrar observaciones sin acuerdo.
  for (columna in etiquetas) {
    if (any(is.na(votos[[columna]]) |
            !votos[[columna]] %in% c("TRUE", "FALSE"))) {
      stop("Caracteristica faltante o invalida: ", columna)
    }
  }
  fechas <- suppressWarnings(parse_datetime(
    votos$timestamp, locale = locale(tz = "UTC")
  ))
  if (anyNA(fechas)) stop("Hay fechas invalidas o faltantes; revisar auditoria.")
  votos <- votos |>
    mutate(
      evaluation_order = as.integer(evaluation_order),
      timestamp = fechas,
      across(all_of(etiquetas), ~ .x == "TRUE"),
      month = as.integer(format(timestamp, "%m", tz = "UTC")),
      mismo_modelo = model_a == model_b
    )
  # Reproduce el universo documentado, no un umbral estimado para evaluar.
  # Mark debe fijar elegibilidad de train sin aprenderla usando julio.
  conteos <- tibble(model = c(votos$model_a, votos$model_b)) |>
    count(model, name = "participaciones_original") |>
    mutate(elegible = participaciones_original >= min_votos)
  elegibles <- conteos$model[conteos$elegible]
  primeros <- votos |> filter(evaluation_order == 1L)
  sesiones_repetidas <- primeros |>
    count(evaluation_session_id, name = "primeros_en_sesion") |>
    filter(primeros_en_sesion > 1L) |>
    pull(evaluation_session_id)
  seleccion <- primeros |>
    filter(model_a %in% elegibles, model_b %in% elegibles) |>
    mutate(
      sesion_primer_voto_repetido =
        evaluation_session_id %in% sesiones_repetidas,
      requiere_revision = mismo_modelo | sesion_primer_voto_repetido,
      es_decisivo = winner %in% c("model_a", "model_b")
    )
  # El lado identifica la victoria; no comparar solo nombres de modelo.
  larga <- bind_rows(
    seleccion |> mutate(model = model_a, rival = model_b, lado = "model_a"),
    seleccion |> mutate(model = model_b, rival = model_a, lado = "model_b")
  ) |>
    mutate(
      won = if_else(es_decisivo, as.integer(winner == lado), NA_integer_),
      # Alternativa solicitada por el grupo, etiquetada como escenario.
      # No usar esta columna como respuesta sin acuerdo previo.
      won_medio_punto_escenario = if_else(es_decisivo, as.double(won), 0.5)
    ) |>
    select(
      id, evaluation_session_id, evaluation_order, timestamp,
      model, rival, lado, winner, es_decisivo, won,
      won_medio_punto_escenario, all_of(etiquetas), month,
      mismo_modelo, sesion_primer_voto_repetido, requiere_revision
    ) |>
    arrange(timestamp, id, lado)
  comprobacion <- larga |>
    group_by(id) |>
    summarise(
      filas = n(), lados = n_distinct(lado),
      decisivo = all(es_decisivo),
      suma_won = sum(won), .groups = "drop"
    )
  stopifnot(
    nrow(larga) == 2L * nrow(seleccion),
    all(comprobacion$filas == 2L), all(comprobacion$lados == 2L),
    all(comprobacion$suma_won[comprobacion$decisivo] == 1L),
    all(is.na(larga$won[!larga$es_decisivo])),
    all(larga$won[larga$es_decisivo] %in% c(0L, 1L)),
    all(larga$won_medio_punto_escenario[!larga$es_decisivo] == 0.5),
    identical(hash_antes, unname(tools::md5sum(entrada)))
  )
  resumen <- tibble(
    etapa = c("original", "primer_voto", "modelos_elegibles",
              "votos_decisivos", "filas_base_larga", "modelos_base_larga",
              "votos_requieren_revision"),
    cantidad = c(nrow(votos), nrow(primeros), nrow(seleccion),
                 sum(seleccion$es_decisivo), nrow(larga),
                 n_distinct(larga$model), sum(seleccion$requiere_revision))
  )
  dir.create(file.path("data", "derivados"), recursive = TRUE,
             showWarnings = FALSE)
  write_csv(larga, archivo, na = "NA")
  write_csv(conteos, file.path(reporte, "elegibilidad.csv"))
  write_csv(resumen, file.path(reporte, "resumen_preparacion.csv"))
  write_csv(tibble(
    columna = etiquetas, tipo = "logical", uso = "predictor"
  ), file.path(reporte, "predictores.csv"))
  writeLines(c(
    "# Base larga: contrato de uso", "",
    "Generador: R/01_preparar_datos.R. No editar a mano el CSV derivado.",
    "Cada voto genera dos filas: model y rival se invierten entre lados.",
    "won: 1 gana, 0 pierde; NA en tie y both_bad mientras no haya acuerdo.",
    "won_medio_punto_escenario: alternativa de 0.5 para tie y both_bad.",
    "Esa columna no constituye una decision del grupo ni un predictor.",
    "Antes de glm se debe elegir explicitamente una politica de respuesta.",
    "Propuesta a discutir: excluir tie y both_bad del ajuste binario principal",
    "y conservarlos para un analisis de sensibilidad. No esta aprobada.",
    "both_bad no es necesariamente un empate de calidad; conviene separarlo.",
    "Si se usa 0.5, no describirlo como una victoria binaria observada.",
    "Predictores acordados: las 11 columnas de predictores.csv.",
    "month queda disponible como metadato; su uso no se impone.",
    "No se incluyen tokens, precios ni formato de las respuestas.",
    "rival es identidad, no fuerza del rival. Ese control sigue abierto.",
    "No agrupar versiones ni construir thinking sin decision del grupo.",
    "requiere_revision senala casos para revisar, no autoriza eliminarlos.",
    "No entrenar automaticamente con esos casos sin revisarlos.",
    "Mark debe conservar juntas las dos filas de cada voto y cada sesion",
    "en train/test, y aprender umbrales/fuerzas del rival solo con train.",
    "La seleccion de modelos reproduce el universo descriptivo documentado.",
    "No se ajustaron regresiones ni se eligio una particion.",
    "Archivo original intacto: hash MD5 verificado en integridad.csv."
  ), file.path(reporte, "CONTRATO_BASE.md"))
  stopifnot(identical(hash_antes, unname(tools::md5sum(entrada))))
  message("Base generada: ", archivo)
  invisible(list(archivo = archivo, reporte = reporte, resumen = resumen))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 1L) stop("Uso: Rscript R/01_preparar_datos.R [nombre]")
  if (length(args)) preparar_datos(nombre = args[[1L]]) else preparar_datos()
}
