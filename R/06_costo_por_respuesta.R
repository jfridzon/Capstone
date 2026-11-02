# PRUEBA: costo por respuesta de cada modelo (Marco)
#
# Esto es una prueba para cuando el grupo agregue el precio al análisis.
# El profesor dijo el 26/10 que tokens y precio quedan fuera de las regresiones por ahora.
# Nada de esto entra a las regresiones.
#
# Qué hace:
#   Por cada voto y cada modelo calcula cuánto costó su respuesta:
#     costo = tokens de la pregunta  x precio de entrada / 1,000,000
#           + tokens de la respuesta x precio de salida  / 1,000,000
#   y lo resume por modelo.
#
# Filtros (los mismos de docs/03, más 1):
#   - 1er voto de cada conversación (evaluation_order == 1)
#   - los 48 modelos con 1,000 votos o más
#   - solo conversaciones de 1 pregunta y 1 respuesta (turns == 1). Con más turnos,
#     los tokens se suman entre mensajes y el costo real de entrada es más alto.
#   - sin los votos con el mismo modelo a los 2 lados (igual que Mark en R/03_evaluacion.R)
#
# Limitaciones (decirlas siempre que se use):
#   - Los tokens de razonamiento NO están en los datos. Los modelos que razonan
#     (o3, thinking, deepseek-r1, etc.) salen más baratos de lo que son.
#   - Los tokens los contó LMArena con 1 solo método, no con el de cada compañía.
#   - Las respuestas más largas ganan más (61.8%, docs/05). Costo y victorias van juntos.
#
# Necesita: data/derivados/precios_modelos_2026-10-28_v2.csv (lo genera R/05_precios_modelos.R)
# Resultado: R/resultados/costo_por_modelo.csv

votes  <- read.csv("data/lmarena_votes.csv", stringsAsFactors = FALSE)
prices <- read.csv("data/derivados/precios_modelos_2026-10-28_v2.csv", stringsAsFactors = FALSE)
prices <- data.frame(model             = prices$modelo,
                     company           = prices$compania,
                     input_usd_per_1m  = prices$precio_entrada_usd_por_millon,
                     output_usd_per_1m = prices$precio_salida_usd_por_millon)

# ---- 1. Filtros ---------------------------------------------------------------

first <- votes[votes$evaluation_order == 1, ]
n_votes <- table(c(first$model_a, first$model_b))
models_48 <- names(n_votes)[n_votes >= 1000]
first <- first[first$model_a %in% models_48 & first$model_b %in% models_48, ]
single <- first[first$turns == 1 & first$model_a != first$model_b, ]

# ---- 2. Base larga: 1 fila por modelo por voto --------------------------------

long <- data.frame(
  model         = c(single$model_a, single$model_b),
  input_tokens  = c(single$sum_user_tokens, single$sum_user_tokens),
  output_tokens = c(single$answer_a_tokens, single$answer_b_tokens),
  won           = c(single$winner == "model_a", single$winner == "model_b"),
  decisive      = rep(single$winner %in% c("model_a", "model_b"), 2)
)

long <- merge(long, prices[, c("model", "company", "input_usd_per_1m", "output_usd_per_1m")],
              by = "model", all.x = TRUE)
long$cost_usd <- (long$input_tokens  * long$input_usd_per_1m +
                  long$output_tokens * long$output_usd_per_1m) / 1e6

# ---- 3. Resumen por modelo ----------------------------------------------------

summ <- do.call(rbind, lapply(split(long, long$model), function(d) data.frame(
  model                    = d$model[1],
  company                  = d$company[1],
  responses                = nrow(d),
  median_input_tokens      = median(d$input_tokens),
  median_output_tokens     = median(d$output_tokens),
  mean_output_tokens       = round(mean(d$output_tokens)),
  input_usd_per_1m         = d$input_usd_per_1m[1],
  output_usd_per_1m        = d$output_usd_per_1m[1],
  cost_per_1000_responses  = round(mean(d$cost_usd) * 1000, 3),   # en dólares
  win_rate_decisive        = round(sum(d$won) / sum(d$decisive), 3)  # % simple (nivel 1, docs/04)
)))
summ <- summ[order(summ$cost_per_1000_responses, na.last = TRUE), ]

dir.create("R/resultados", showWarnings = FALSE)
write.csv(summ, "R/resultados/costo_por_modelo.csv", row.names = FALSE, na = "")

cat("Votos usados (1er voto, 48 modelos, 1 turno, modelos distintos):", nrow(single), "\n")
cat("Modelos con costo:", sum(!is.na(summ$cost_per_1000_responses)), "de", nrow(summ), "\n")
print(summ[, c("model", "median_output_tokens", "cost_per_1000_responses", "win_rate_decisive")],
      row.names = FALSE)
