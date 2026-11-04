# Eli, fase 2: asignacion y cobertura. Asistencia de ChatGPT/OpenAI.
# Desde la raiz: source("R/09_chequeos_datos.R")
ejecutar_chequeos <- function(carpeta = file.path("R/resultados", paste0("eli_chequeos_", Sys.Date()))) {
  input <- "data/lmarena_votes.csv"
  v <- read.csv(input, stringsAsFactors = FALSE)
  features <- c("is_code", "math", "creative_writing", "instruction_following",
    "complexity", "creativity", "domain_knowledge", "problem_solving",
    "real_world", "specificity", "technical_accuracy")
  stopifnot(!anyNA(v[c("id", "model_a", "model_b", "timestamp", "evaluation_order", features)]),
            !anyDuplicated(v$id))
  for (f in features) {
    x <- toupper(as.character(v[[f]]))
    stopifnot(all(x %in% c("TRUE", "FALSE")))
    v[[f]] <- x == "TRUE"
  }
  # Solo para reproducir el chequeo historico. hard NO entra a las regresiones.
  v$hard <- rowSums(v[features[5:11]]) >= 6
  checks <- c(features, "hard")
  dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
  save <- function(x, name) write.csv(x, file.path(carpeta, name), row.names = FALSE)
  rows <- extrema <- coverage <- list()
  cohorts <- list(todos = v, primer_voto = v[v$evaluation_order == 1, ],
                  junio = v[substr(v$timestamp, 1, 7) == "2025-06", ])
  for (scope in names(cohorts)) {
    d <- cohorts[[scope]]
    # Una participacion por lado. Un voto con el mismo modelo a ambos lados
    # cuenta dos participaciones, explicitamente, como la tabla historica.
    z <- rbind(data.frame(modelo = d$model_a, d[checks]),
               data.frame(modelo = d$model_b, d[checks]))
    counts <- table(z$modelo)
    eligible <- names(counts[counts >= 1000])
    stopifnot(length(eligible) > 0)
    for (f in checks) {
      rates <- tapply(z[[f]], z$modelo, mean)[eligible]
      for (m in eligible) rows[[length(rows)+1L]] <- data.frame(
        cohorte = scope, modelo = m, caracteristica = f,
        participaciones = unname(counts[m]), proporcion = unname(rates[m]))
      extrema[[length(extrema)+1L]] <- data.frame(cohorte = scope,
        caracteristica = f, votos = nrow(d), modelos = length(eligible),
        proporcion_total = mean(d[[f]]), minimo = min(rates),
        modelos_minimo = paste(names(rates)[rates == min(rates)], collapse = "; "),
        maximo = max(rates),
        modelos_maximo = paste(names(rates)[rates == max(rates)], collapse = "; "))
    }
    # Cada voto tiene una combinacion de las 11 etiquetas; se incluyen las 2^11.
    bits <- as.matrix(d[features]) %*% (2^(0:10))
    freq <- tabulate(as.integer(bits) + 1L, nbins = 2^length(features))
    tab <- data.frame(combinacion = 0:(length(freq)-1L), votos = freq)
    tab <- tab[order(-tab$votos, tab$combinacion), ]
    tab$proporcion_acumulada <- cumsum(tab$votos)/nrow(d)
    stopifnot(sum(tab$votos) == nrow(d), tail(tab$proporcion_acumulada, 1) == 1)
    n90 <- which(tab$proporcion_acumulada >= .9)[1]
    stopifnot(sum(tab$votos[seq_len(n90)]) >= .9*nrow(d),
              n90 == 1 || sum(tab$votos[seq_len(n90-1)]) < .9*nrow(d))
    coverage[[scope]] <- data.frame(cohorte = scope, votos = nrow(d),
      posibles = length(freq), observadas = sum(freq > 0),
      combinaciones_90_por_ciento = n90)
    save(tab, paste0("cobertura_", scope, ".csv"))
  }
  save(do.call(rbind, rows), "asignacion_por_modelo.csv")
  save(do.call(rbind, extrema), "asignacion_extremos.csv")
  save(do.call(rbind, coverage), "cobertura_resumen.csv")
  writeLines(c("Cada cohorte aplica su propio umbral de 1,000 participaciones por modelo.",
    "Proporcion total: votos, sin filtro de modelos. Extremos: modelos con 1,000+ participaciones.",
    "Las etiquetas se solapan. Cobertura: las 11 etiquetas originales, sin hard.",
    "Son chequeos descriptivos: no prueban asignacion aleatoria ni causalidad.",
    "No se reproduce la afirmacion historica 1.2-2.7 veces el azar: no habia definicion ni codigo.",
    "No se cambian las reglas de limpieza ni se ajustan modelos.",
    paste("MD5 de datos:", unname(tools::md5sum(input)))), file.path(carpeta, "notas.txt"))
  capture.output(sessionInfo(), file = file.path(carpeta, "sessionInfo.txt"))
  print(do.call(rbind, coverage)); invisible(carpeta)
}
if (isTRUE(getOption("correr_09", TRUE))) ejecutar_chequeos()
