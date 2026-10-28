# Auditoria de LMArena: no modifica ni exporta una base limpia definitiva.
# Desde la raiz: Rscript R/auditar_limpieza.R
# Opcional: Rscript R/auditar_limpieza.R entrada.csv carpeta_nueva [min_votos]
# Salidas: reportes agregados en R/resultados/auditoria_<fecha-hora-UTC>/.
# Requiere readr y dplyr: install.packages(c("readr", "dplyr"))
# Preparado con asistencia de IA (ChatGPT/Codex); requiere revision del grupo.

library(readr)
library(dplyr)

auditar_limpieza <- function(
    entrada = "data/lmarena_votes.csv",
    salida = file.path("R", "resultados", paste0(
      "auditoria_", format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
    )),
    min_votos = 1000L) {
  if (!file.exists(entrada)) stop("No existe el CSV de entrada.")
  if (length(min_votos) != 1L || is.na(min_votos) ||
      !is.finite(min_votos) || min_votos < 1 ||
      min_votos != floor(min_votos)) {
    stop("min_votos debe ser un entero positivo.")
  }
  # Una carpeta nueva evita sobrescribir resultados de ejecuciones anteriores.
  if (file.exists(salida) || dir.exists(salida)) {
    stop("La salida ya existe. Elige una carpeta nueva.")
  }
  if (!dir.create(salida, recursive = TRUE)) {
    stop("No se pudo crear la carpeta de resultados.")
  }
  hash_antes <- unname(tools::md5sum(entrada))
  if (is.na(hash_antes)) stop("No se pudo calcular el hash del CSV.")
  on.exit({
    hash_despues <- unname(tools::md5sum(entrada))
    if (!identical(hash_antes, hash_despues)) {
      stop("El CSV cambio durante la auditoria; resultados no validos.")
    }
  }, add = TRUE)

  guardar <- function(x, nombre) {
    write_csv(x, file.path(salida, paste0(nombre, ".csv")), na = "NA")
  }
  # Texto primero: no ocultar errores de tipo mediante conversiones a NA.
  datos <- read_csv(
    entrada, col_types = cols(.default = col_character()),
    na = "NA", trim_ws = FALSE, name_repair = "minimal",
    show_col_types = FALSE, progress = FALSE
  )
  problemas <- problems(datos)
  if (nrow(problemas) > 0L || anyDuplicated(names(datos))) {
    stop("CSV mal formado o columnas repetidas; no se aplicaron filtros.")
  }
  etiquetas <- c(
    "is_code", "math", "creative_writing", "instruction_following",
    "complexity", "creativity", "domain_knowledge", "problem_solving",
    "real_world", "specificity", "technical_accuracy"
  )
  enteros <- c(
    "evaluation_order", "sum_user_tokens", "turns", "answer_a_tokens",
    "answer_b_tokens", "headers_a", "headers_b", "lists_a", "lists_b",
    "bold_a", "bold_b"
  )
  requeridas <- c(
    "id", "model_a", "model_b", "winner", "evaluation_session_id",
    "timestamp", "language", etiquetas, enteros, "if_score"
  )
  guardar(tibble(
    columna = requeridas, presente = requeridas %in% names(datos)
  ), "esquema")
  if (length(setdiff(requeridas, names(datos))) > 0L) {
    stop("Faltan columnas requeridas; consulta esquema.csv.")
  }
  vacio <- function(x) is.na(x) | trimws(x) == ""
  perfil <- bind_rows(lapply(names(datos), function(nombre) {
    x <- datos[[nombre]]
    tibble(
      columna = nombre, filas = length(x), faltantes_na = sum(is.na(x)),
      vacios_texto = sum(!is.na(x) & trimws(x) == ""),
      espacios_extremos = sum(!is.na(x) & x != trimws(x)),
      distintos_no_na = n_distinct(x, na.rm = TRUE)
    )
  }))
  guardar(perfil, "perfil_columnas")
  controles <- tibble(
    control = character(), hallazgos = integer(),
    bloquea_escenarios = logical()
  )
  registrar <- function(nombre, condicion, bloquea = FALSE) {
    controles <<- bind_rows(controles, tibble(
      control = nombre, hallazgos = as.integer(sum(condicion, na.rm = TRUE)),
      bloquea_escenarios = bloquea
    ))
  }
  for (nombre in c("id", "model_a", "model_b", "winner",
                   "evaluation_session_id", "evaluation_order")) {
    registrar(paste0("faltante_", nombre), vacio(datos[[nombre]]), TRUE)
  }
  registrar("id_duplicado_filas_adicionales", duplicated(datos$id), TRUE)
  registrar("filas_identicas_adicionales", duplicated(datos), TRUE)
  registrar("mismo_modelo_en_ambos_lados",
            datos$model_a == datos$model_b)
  for (nombre in c("model_a", "model_b", "winner")) {
    registrar(paste0("espacios_", nombre),
              datos[[nombre]] != trimws(datos[[nombre]]), TRUE)
  }
  registrar("winner_no_reconocido", !vacio(datos$winner) &
              !datos$winner %in% c("model_a", "model_b", "tie", "both_bad"),
            TRUE)
  guardar(count(datos, winner, name = "votos"), "winner_original")
  guardar(count(datos, language, name = "votos"), "idiomas")
  registrar("idioma_no_detectado_und", datos$language == "und")
  # und es una etiqueta, no NA: se informa, no se elimina ni se imputa.
  for (nombre in etiquetas) {
    registrar(paste0("booleano_invalido_", nombre),
              !vacio(datos[[nombre]]) &
                !datos[[nombre]] %in% c("TRUE", "FALSE"))
  }
  numericos <- list()
  for (nombre in c(enteros, "if_score")) {
    x <- datos[[nombre]]
    n <- suppressWarnings(as.numeric(x))
    invalido <- !vacio(x) & (!is.finite(n) | n != floor(n) | n < 0)
    if (nombre %in% c("evaluation_order", "turns")) {
      invalido <- invalido | (!vacio(x) & !is.na(n) & n < 1)
    }
    if (nombre == "if_score") {
      invalido <- invalido | (!vacio(x) & !is.na(n) & n > 5)
    }
    registrar(paste0("numero_invalido_", nombre), invalido,
              nombre == "evaluation_order")
    numericos[[nombre]] <- n
  }
  fechas <- suppressWarnings(parse_datetime(
    datos$timestamp, format = "", na = c("", "NA"),
    locale = locale(tz = "UTC")
  ))
  registrar("timestamp_invalido", !vacio(datos$timestamp) & is.na(fechas))
  registrar("timestamp_faltante", vacio(datos$timestamp))
  validas <- fechas[!is.na(fechas)]
  guardar(tibble(
    fechas_validas = length(validas),
    primera_utc = if (length(validas)) format(
      min(validas), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
    ) else NA_character_,
    ultima_utc = if (length(validas)) format(
      max(validas), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
    ) else NA_character_
  ), "fechas")
  primer_voto <- !is.na(numericos$evaluation_order) &
    numericos$evaluation_order == 1
  registrar("primer_voto_repetido_por_sesion", duplicated(
    datos$evaluation_session_id[primer_voto]
  ))
  guardar(controles, "controles")

  bloqueado <- any(controles$bloquea_escenarios & controles$hallazgos > 0)
  contar_modelos <- function(df, nombre) {
    # Una participacion por lado; no contar victorias ni filas duplicadas long.
    tibble(modelo = c(df$model_a, df$model_b)) |>
      count(modelo, name = nombre)
  }
  etapas <- tibble()
  if (!bloqueado) {
    primeros <- datos[primer_voto, , drop = FALSE]
    modelos <- full_join(
      contar_modelos(datos, "votos_original"),
      contar_modelos(primeros, "votos_primer_voto"), by = "modelo"
    ) |>
      mutate(
        votos_primer_voto = coalesce(votos_primer_voto, 0L),
        elegible_original = votos_original >= min_votos,
        elegible_primer_voto = votos_primer_voto >= min_votos
      )
    guardar(modelos, "votos_por_modelo")
    # Ambas rutas son diagnosticos; ninguna fija el universo para train/test.
    # La elegibilidad de modelado se coordina con Mark usando solo train.
    resumen <- function(df, escenario, etapa) tibble(
      escenario = escenario, etapa = etapa, filas = nrow(df),
      modelos = n_distinct(c(df$model_a, df$model_b)),
      decisivos = sum(df$winner %in% c("model_a", "model_b")),
      empates = sum(df$winner == "tie"),
      both_bad = sum(df$winner == "both_bad")
    )
    won_comprobaciones <- list()
    for (base in c("original", "primer_voto")) {
      elegibles <- modelos$modelo[modelos[[paste0("elegible_", base)]]]
      filtrados <- primeros |>
        filter(model_a %in% elegibles, model_b %in% elegibles)
      decisivos <- filtrados |>
        filter(winner %in% c("model_a", "model_b"))
      etapas <- bind_rows(
        etapas, resumen(datos, base, "01_original"),
        resumen(primeros, base, "02_primer_voto"),
        resumen(filtrados, base, "03_ambos_modelos_elegibles"),
        resumen(decisivos, base, "04_solo_decisivos_escenario_historico")
      )
      # won para cada lado y y para una fila por comparacion decisiva.
      # Empates/both_bad quedan sin respuesta binaria, no se les asigna cero.
      won_a <- ifelse(filtrados$winner %in% c("model_a", "model_b"),
                      as.integer(filtrados$winner == "model_a"), NA_integer_)
      won_b <- ifelse(filtrados$winner %in% c("model_a", "model_b"),
                      as.integer(filtrados$winner == "model_b"), NA_integer_)
      y <- as.integer(decisivos$winner == "model_a")
      stopifnot(all(na.omit(won_a + won_b) == 1L))
      stopifnot(identical(as.integer(won_a[!is.na(won_a)]), y))
      won_comprobaciones[[base]] <- tibble(
        escenario = base, ganadores_a = sum(won_a == 1L, na.rm = TRUE),
        ganadores_b = sum(won_b == 1L, na.rm = TRUE),
        sin_respuesta_binaria = sum(is.na(won_a)),
        pares_con_suma_uno = sum(won_a + won_b == 1L, na.rm = TRUE)
      )
    }
    guardar(etapas, "etapas_filtros")
    guardar(bind_rows(won_comprobaciones), "verificacion_won")
  }
  hash_despues <- unname(tools::md5sum(entrada))
  stopifnot(identical(hash_antes, hash_despues))
  guardar(tibble(
    archivo = basename(entrada), md5_antes = hash_antes,
    md5_despues = hash_despues, original_intacto = TRUE,
    umbral_votos_diagnostico = min_votos,
    escenarios_bloqueados = bloqueado
  ), "integridad")
  writeLines(c(
    "# Auditoria de limpieza de LMArena", "",
    paste("Estado:", if (bloqueado) "ESCENARIOS BLOQUEADOS" else
      "reportes generados; revisar controles y perfil de faltantes"),
    "El CSV original conserva el mismo hash MD5.",
    "No se exporto una base limpia ni se entrenaron modelos.", "",
    "## Como interpretar los archivos",
    "- perfil_columnas.csv: NA, vacios y espacios por columna.",
    "- controles.csv: problemas detectados; no se reparan automaticamente.",
    "- idiomas.csv: und permanece separado de los faltantes.",
    "- votos_por_modelo.csv: elegibilidad segun dos universos de conteo.",
    "- etapas_filtros.csv: retencion de votos por cada escenario.",
    "- verificacion_won.csv: consistencia de respuestas en votos decisivos.",
    "Si hay controles bloqueantes no se generan escenarios de filtros.", "",
    "## Decisiones que siguen abiertas",
    "Excluir empates/both_bad es solo el escenario historico documentado.",
    "No se asigna medio punto ni se agrupan versiones de modelos.",
    "won_a, won_b e y se comprueban en memoria; no son una base final.",
    "No se imputa, deduplica ni elimina und o atipicos automaticamente.",
    "Las comparaciones de un modelo consigo mismo y los primeros votos",
    "repetidos por sesion se senalan, pero no se eliminan del diagnostico.",
    "Requieren revision del grupo antes de declarar una base apta para modelar.",
    "Los conteos con todos los datos no definen elegibilidad para modelar.",
    "Mark y el grupo deben acordar el universo del umbral usando train.",
    "No se decide modelo principal, thinking, dificultad ni particion.", "",
    "Referencias: docs/03-datos.md, docs/04-metodo.md y docs/07-pendientes-y-roles.md.",
    "Script preparado con asistencia de IA; revisarlo antes de usar resultados."
  ), file.path(salida, "LEEME.md"), useBytes = TRUE)
  # Evitar rutas del equipo en resultados destinados al repositorio publico.
  writeLines(c(
    R.version.string,
    paste("readr", packageVersion("readr")),
    paste("dplyr", packageVersion("dplyr"))
  ), file.path(salida, "versiones.txt"))
  message("Auditoria guardada en: ", salida)
  invisible(list(controles = controles, etapas = etapas,
                 bloqueado = bloqueado, salida = salida))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 3L) stop("Uso: script.R [entrada] [salida] [min_votos]")
  opciones <- list()
  if (length(args) >= 1L) opciones$entrada <- args[[1L]]
  if (length(args) >= 2L) opciones$salida <- args[[2L]]
  if (length(args) >= 3L) opciones$min_votos <- suppressWarnings(
    as.numeric(args[[3L]])
  )
  resultado <- do.call(auditar_limpieza, opciones)
  if (resultado$bloqueado) quit(status = 2L)
}
