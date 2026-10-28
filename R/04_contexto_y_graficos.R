# Eli - contexto y graficos. Ejecutar desde la raiz del repositorio:
# source("R/04_contexto_y_graficos.R")
# Solo R base. Analisis descriptivo, NO es un modelo predictivo ni causal.
# Preparado con ayuda de ChatGPT (OpenAI), 28/10/2026.
# Borrador: requiere ejecucion con el CSV real y revision del grupo.

input <- "data/lmarena_votes.csv"
if (!file.exists(input)) stop("Abre el proyecto desde la raiz del repositorio.")
votes <- read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
tags <- c("is_code", "math", "creative_writing", "instruction_following")
required <- c("winner", "evaluation_order", "answer_a_tokens",
              "answer_b_tokens", tags)
if (!all(required %in% names(votes))) stop("Faltan columnas requeridas.")
if (!all(votes$winner %in% c("model_a", "model_b", "tie", "both_bad")))
  stop("Hay valores inesperados o faltantes en winner.")
for (col in c("evaluation_order", "answer_a_tokens", "answer_b_tokens")) {
  if (!is.numeric(votes[[col]]) || anyNA(votes[[col]]) ||
      any(!is.finite(votes[[col]])) || any(votes[[col]] < 0))
    stop(paste("Revisar columna numerica:", col))
}
for (tag in tags) {
  v <- toupper(as.character(votes[[tag]]))
  if (anyNA(v) || !all(v %in% c("TRUE", "FALSE")))
    stop(paste("Revisar etiqueta:", tag))
  votes[[tag]] <- v == "TRUE"
}

# Todas las filas permiten reproducir Test 3 de docs/05.
# Primer voto es una sensibilidad separada; no decide el filtro de las regresiones.
cohorts <- list(all_votes = votes,
                first_vote = votes[votes$evaluation_order == 1, , drop = FALSE])

summarise_length <- function(d, cohort, task) {
  decisive <- d$winner %in% c("model_a", "model_b")
  different <- d$answer_a_tokens != d$answer_b_tokens
  eligible <- decisive & different
  n <- sum(eligible)
  won <- sum((d$winner[eligible] == "model_a") ==
               (d$answer_a_tokens[eligible] > d$answer_b_tokens[eligible]))
  ci <- if (n > 0) binom.test(won, n)$conf.int else c(NA_real_, NA_real_)
  data.frame(cohort = cohort, task = task, total_votes = nrow(d),
             non_decisive = sum(!decisive),
             decisive_equal_length = sum(decisive & !different),
             eligible_votes = n, longer_wins = won,
             share_longer_wins = if (n > 0) won / n else NA_real_,
             ci95_low = ci[1], ci95_high = ci[2])
}

rows <- list()
for (cohort in names(cohorts)) {
  d <- cohorts[[cohort]]
  rows[[length(rows) + 1]] <- summarise_length(d, cohort, "All tasks")
  for (tag in tags) {
    rows[[length(rows) + 1]] <- summarise_length(
      d[d[[tag]], , drop = FALSE], cohort, tag)
  }
}
summary_table <- do.call(rbind, rows)
row.names(summary_table) <- NULL

# Un directorio nuevo por ejecucion; no sobrescribe resultados previos.
dir.create("R/resultados", recursive = TRUE, showWarnings = FALSE)
out <- tempfile(pattern = paste0("eli_largo_", format(Sys.Date(), "%Y-%m-%d"), "_"),
                tmpdir = "R/resultados")
if (!dir.create(out)) stop("No se pudo crear carpeta de resultados.")
write.csv(summary_table, file.path(out, "largo_resumen.csv"), row.names = FALSE)
writeLines(c(
  "Analisis descriptivo: asociacion entre largo y voto, no efecto causal.",
  "Se excluyen empates/both_bad y largos iguales SOLO de este calculo.",
  "No se decide aqui como tratar esos votos en las regresiones del grupo.",
  "Las etiquetas se solapan: un voto puede aparecer en varias tareas.",
  "IC exactos binomiales nominales; no ajustan por dependencia entre sesiones.",
  "all_votes reproduce el universo de Test 3; first_vote es sensibilidad.",
  "No hay filtro de modelos en este analisis descriptivo.",
  "Los tokens no se usan como predictores.",
  paste("Fuente:", input),
  paste("MD5:", unname(tools::md5sum(input))),
  paste("Ejecucion UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE))
), file.path(out, "notas.txt"))
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))

labels <- c("All tasks" = "All tasks", "is_code" = "Code",
            "math" = "Math", "creative_writing" = "Creative writing",
            "instruction_following" = "Instruction following")
plot_length <- function(cohort) {
  d <- summary_table[summary_table$cohort == cohort, , drop = FALSE]
  d <- d[d$eligible_votes > 0, , drop = FALSE]
  if (!nrow(d)) return(invisible(NULL))
  png(file.path(out, paste0("longer_wins_", cohort, ".png")),
      width = 1600, height = 1000, res = 150)
  on.exit(dev.off())
  par(mar = c(5, 11, 5, 2))
  y <- rev(seq_len(nrow(d)))
  plot(100 * d$share_longer_wins, y, xlim = c(0, 100),
       ylim = c(0.5, nrow(d) + 0.5), yaxt = "n", pch = 19,
       col = "#2563EB", xlab = "Votes won by the longer answer (%)",
       ylab = "", main = paste("Answer length and human preference -", cohort))
  axis(2, at = y, labels = unname(labels[d$task]), las = 1)
  segments(100 * d$ci95_low, y, 100 * d$ci95_high, y, col = "#2563EB")
  abline(v = 50, lty = 2, col = "gray50")
  text(100 * d$share_longer_wins, y,
       labels = sprintf("%.1f%% (n=%s)", 100 * d$share_longer_wins,
                        format(d$eligible_votes, big.mark = ",", trim = TRUE)),
       pos = 3, cex = 0.8)
  mtext("Decisive votes, unequal lengths. Association, not causation.",
        side = 3, line = 0.5, cex = 0.8)
}
for (cohort in names(cohorts)) plot_length(cohort)
print(summary_table)
cat("\nResultados guardados en:", out, "\n")

