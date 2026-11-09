# Precio, costo y top 3 por presupuesto (Marco, tarea 4)
# Correr desde la raíz del repo: source("R/06_costo_por_respuesta.R")
#
# Este script hace 3 cosas, en orden:
#
#   Parte 1. Tabla de precios v4 = la v2 + la columna `razona` (decisión 3 de docs/12)
#            y sin `disponible_gratis_en_app` (decisión de Jaime en el issue #15: no hay
#            fuente confiable de julio 2025).
#            Resultado: data/derivados/precios_modelos_2026-11-02_v4.csv
#            (en data/ no se sobrescribe nada, por eso es un archivo nuevo. La v3 del
#            PR #25 es igual pero todavía con esa columna vacía; se deja como estaba)
#
#   Parte 2. PRUEBA de costo por respuesta de cada modelo (la de la fase 1, sin cambios).
#            Resultado: R/resultados/costo_por_modelo.csv
#
#   Parte 3. (Se movió a R/12_top3_por_precio.R en la fase 2b, con binomial.)
#
# Necesita: data/derivados/precios_modelos_2026-10-28_v2.csv (R/05_precios_modelos.R),
#           data/lmarena_votes.csv, la base larga de Nessim y las funciones de R/02 (Jaime).
#
# Limitaciones (decirlas siempre que se use):
#   - Los tokens de razonamiento NO están en los datos. Los modelos que razonan
#     (columna `razona`) salen más baratos de lo que son en la Parte 2.
#   - Los tokens los contó LMArena con 1 solo método, no con el de cada compañía.
#   - Las respuestas más largas ganan más (61.8%, docs/05). Costo y victorias van juntos.
#   - El presupuesto de la Parte 3 es el precio de lista por millón de tokens de SALIDA,
#     no el costo real de una respuesta (un modelo que razona gasta más tokens).

# Los textos tienen acentos. Sin UTF-8, R los guarda dañados ("versi<c3><b3>n"), como
# pasó en la v2. RStudio en Windows y Mac (R 4.2 o más nuevo) ya usa UTF-8.
if (!l10n_info()$`UTF-8`) stop("Este script necesita UTF-8. En Linux: Sys.setlocale('LC_CTYPE', 'C.UTF-8')")

dir.create("R/resultados", showWarnings = FALSE)

# =============================================================================
# Parte 1. Columna `razona` -> tabla de precios v4
# =============================================================================
# razona = "si" si el modelo piensa (escribe un razonamiento) antes de responder,
#          "no" si responde directo, y vacío si no hay una fuente clara.
# La fuente va en `notas`. No se adivina: los 2 modelos experimentales quedan vacíos.

f_openai  <- "https://platform.openai.com/docs/guides/reasoning"
f_anthro  <- "https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking"
f_gemini  <- "https://developers.googleblog.com/en/start-building-with-gemini-25-flash"
f_deepsk  <- "https://api-docs.deepseek.com/guides/reasoning_model"
f_mistral <- "https://mistral.ai/news/magistral"
f_qwen3   <- "https://qwenlm.github.io/blog/qwen3/"
f_qwq     <- "https://qwenlm.github.io/blog/qwq-32b/"
f_grok3   <- "https://www.notebookcheck.net/xAI-launches-Grok-3-AI-with-chart-topping-performance-along-with-beta-reasoning-models.965366.0.html"
f_grokmin <- "https://www.promptfoo.dev/docs/providers/xai/"
f_grok4   <- "https://docs.x.ai/docs/guides/reasoning"

razona <- read.csv(text = '
modelo|razona|nota
qwen-max-2025-01-25|no|Qwen2.5-Max: modelo de instrucciones, sin modo de razonamiento (https://qwenlm.github.io/blog/qwen2.5-max/)
qwen3-235b-a22b|si|Qwen3 piensa por defecto (enable_thinking=True); LMArena tiene aparte la versión no-thinking
qwen3-235b-a22b-no-thinking|no|Misma Qwen3 con el modo de razonamiento apagado
qwen3-30b-a3b|si|Qwen3 piensa por defecto (enable_thinking=True)
qwq-32b|si|Modelo de razonamiento de Alibaba
amazon-nova-experimental-chat-05-14||Experimental, solo existió en LMArena: no hay fuente
amazon.nova-pro-v1:0|no|Nova Pro v1 no tiene modo de razonamiento (Amazon lo agregó después, en Nova 2) (https://aws.amazon.com/ai/generative-ai/nova/)
claude-3-5-haiku-20241022|no|No tiene extended thinking (empieza en Claude 3.7 Sonnet)
claude-3-5-sonnet-20241022|no|No tiene extended thinking (empieza en Claude 3.7 Sonnet)
claude-3-7-sonnet-20250219|no|Extended thinking apagado (LMArena tiene aparte la versión -thinking)
claude-3-7-sonnet-20250219-thinking-32k|si|Extended thinking encendido, presupuesto de 32k tokens
claude-opus-4-20250514|no|Extended thinking apagado (LMArena tiene aparte la versión -thinking)
claude-opus-4-20250514-thinking-16k|si|Extended thinking encendido, presupuesto de 16k tokens
claude-sonnet-4-20250514|no|Extended thinking apagado (LMArena tiene aparte la versión -thinking)
claude-sonnet-4-20250514-thinking-32k|si|Extended thinking encendido, presupuesto de 32k tokens
command-a-03-2025|no|Command A no razona; Cohere sacó después un modelo aparte, Command A Reasoning (https://cohere.com/blog/command-a-reasoning)
deepseek-r1-0528|si|deepseek-reasoner (R1) es el modelo de razonamiento de DeepSeek
deepseek-v3-0324|no|deepseek-chat (V3) responde sin razonamiento
gemini-2.0-flash-001|no|Los modelos que piensan de Google empiezan en Gemini 2.5
gemini-2.5-flash|si|Google: "Our Gemini 2.5 models are thinking models"
gemini-2.5-flash-lite-preview-06-17-thinking|si|Versión con razonamiento encendido (el nombre lo dice)
gemini-2.5-flash-preview-04-17|si|Google: "Our Gemini 2.5 models are thinking models"; piensa por defecto
gemini-2.5-pro|si|Google: "Our Gemini 2.5 models are thinking models"
gemini-2.5-pro-preview-03-25|si|Google: "Our Gemini 2.5 models are thinking models"
gemini-2.5-pro-preview-05-06|si|Google: "Our Gemini 2.5 models are thinking models"
gemma-3-27b-it|no|Gemma 3 no tiene modo de razonamiento (https://ai.google.dev/gemma/docs/core)
gemma-3n-e4b-it|no|Gemma 3n no tiene modo de razonamiento (https://ai.google.dev/gemma/docs/gemma-3n)
llama-3.3-70b-instruct|no|Modelo de instrucciones sin razonamiento (https://www.llama.com/docs/model-cards-and-prompt-formats/llama3_3/)
llama-4-maverick-03-26-experimental||Experimental, solo existió en LMArena: no hay fuente
llama-4-maverick-17b-128e-instruct|no|Llama 4 no es modelo de razonamiento (https://ai.meta.com/blog/llama-4-multimodal-intelligence/)
llama-4-scout-17b-16e-instruct|no|Llama 4 no es modelo de razonamiento (https://ai.meta.com/blog/llama-4-multimodal-intelligence/)
minimax-m1|si|MiniMax: "the world\'s first open-weight, large-scale hybrid-attention reasoning model" (https://github.com/MiniMax-AI/MiniMax-M1)
magistral-medium-2506|si|Magistral es el primer modelo de razonamiento de Mistral
mistral-medium-2505|no|Antes de Magistral, el primer modelo de razonamiento de Mistral
mistral-small-2506|no|Antes de Magistral, el primer modelo de razonamiento de Mistral
mistral-small-3.1-24b-instruct-2503|no|Antes de Magistral, el primer modelo de razonamiento de Mistral
kimi-k2-0711-preview|no|Moonshot: "state-of-the-art performance among open-source non-thinking models" (https://arxiv.org/abs/2507.20534)
chatgpt-4o-latest-20250326|no|GPT-4o no es modelo de razonamiento (los de OpenAI son la serie o)
gpt-4.1-2025-04-14|no|GPT-4.1 no es modelo de razonamiento (los de OpenAI son la serie o)
gpt-4.1-mini-2025-04-14|no|GPT-4.1 no es modelo de razonamiento (los de OpenAI son la serie o)
o3-2025-04-16|si|Modelo de razonamiento de OpenAI (serie o)
o3-mini|si|Modelo de razonamiento de OpenAI (serie o)
o4-mini-2025-04-16|si|Modelo de razonamiento de OpenAI (serie o)
hunyuan-turbos-20250416|si|Adaptativo: piensa solo en las preguntas difíciles ("adaptive long-short chain-of-thought") (https://arxiv.org/abs/2505.15431)
grok-3-mini-beta|si|En la API, grok-3-mini razona (tiene reasoning_effort). En la app de Grok la versión que piensa se llamaba aparte "Think"
grok-3-mini-high|si|grok-3-mini con esfuerzo de razonamiento alto
grok-3-preview-02-24|no|Grok 3 beta normal no razona; la versión que razona era "Grok 3 (Think)"
grok-4-0709|si|xAI: "Grok 4 is a reasoning model with no non-reasoning mode"
', sep = "|", stringsAsFactors = FALSE, colClasses = "character", strip.white = TRUE)

# Fuente por compañía cuando la nota no trae su propio link
fuente_razona <- function(modelo, nota) {
  if (grepl("https://", nota, fixed = TRUE)) return("")
  if (grepl("^(o3|o4|gpt|chatgpt)", modelo)) return(f_openai)
  if (grepl("^claude", modelo))   return(f_anthro)
  if (grepl("^gemini", modelo))   return(f_gemini)
  if (grepl("^deepseek", modelo)) return(f_deepsk)
  if (grepl("^(magistral|mistral)", modelo)) return(f_mistral)
  if (grepl("^qwen3", modelo))    return(f_qwen3)
  if (grepl("^qwq", modelo))      return(f_qwq)
  if (modelo == "grok-4-0709")    return(f_grok4)
  if (grepl("^grok-3-mini", modelo)) return(f_grokmin)
  if (grepl("^grok-3", modelo))   return(f_grok3)
  ""
}

v2 <- read.csv("data/derivados/precios_modelos_2026-10-28_v2.csv", stringsAsFactors = FALSE,
               colClasses = c(disponible_gratis_en_app = "character"))
stopifnot(nrow(v2) == 48, !anyDuplicated(v2$modelo), setequal(v2$modelo, razona$modelo))

# La v2 se escribió sin UTF-8 y quedaron acentos como "versi<c3><b3>n". En la v3 se
# devuelven a su letra (la v2 no se toca: en data/ no se sobrescribe nada).
arreglar_acentos <- function(x) {
  for (cod in unique(unlist(regmatches(x, gregexpr("(<[0-9a-f]{2}>)+", x))))) {
    bytes <- as.raw(strtoi(regmatches(cod, gregexpr("[0-9a-f]{2}", cod))[[1]], 16L))
    x <- gsub(cod, rawToChar(bytes), x, fixed = TRUE)
  }
  Encoding(x) <- "UTF-8"
  x
}
v2[] <- lapply(v2, function(col) if (is.character(col)) arreglar_acentos(col) else col)

v3 <- merge(v2, razona, by = "modelo", sort = FALSE)
v3 <- v3[match(v2$modelo, v3$modelo), ]                       # mismo orden que la v2
fuente <- mapply(fuente_razona, v3$modelo, v3$nota)
texto  <- ifelse(v3$razona == "", paste0("razona: vacío. ", v3$nota),
                 paste0("razona: ", v3$razona, ". ", v3$nota,
                        ifelse(fuente == "", "", paste0(" (", fuente, ")"))))
v3$notas <- ifelse(v3$notas == "", texto, paste0(v3$notas, " | ", texto))
v3$nota <- NULL

# `razona` toma el lugar de `disponible_gratis_en_app`, que se elimina (issue #15).
# Los 13 sin precio se quedan en la tabla con tiene_precio_oficial = "no" (issue #15).
cols <- names(v2)
cols[cols == "disponible_gratis_en_app"] <- "razona"
v3 <- v3[, cols]
stopifnot(!"disponible_gratis_en_app" %in% names(v3),
          all((v3$tiene_precio_oficial == "no") == is.na(v3$precio_salida_usd_por_millon)))
stopifnot(nrow(v3) == 48, all(v3$razona %in% c("si", "no", "")))

# Los textos de este script están en UTF-8: se marcan así para que los acentos salgan
# bien en cualquier compu (Windows, Mac o Linux).
v3[] <- lapply(v3, function(col) { if (is.character(col)) Encoding(col) <- "UTF-8"; col })

archivo_v3 <- "data/derivados/precios_modelos_2026-11-02_v4.csv"
write.csv(v3, archivo_v3, row.names = FALSE, na = "", fileEncoding = "UTF-8")
cat("Parte 1:", archivo_v3, "| razona: si =", sum(v3$razona == "si"),
    "| no =", sum(v3$razona == "no"), "| vacío =", sum(v3$razona == ""), "\n")

# =============================================================================
# Parte 2. PRUEBA: costo por respuesta (sin cambios desde la fase 1)
# =============================================================================
# Por cada voto y cada modelo:
#   costo = tokens de la pregunta  x precio de entrada / 1,000,000
#         + tokens de la respuesta x precio de salida  / 1,000,000
# Filtros: 1er voto, los 48 modelos, conversaciones de 1 turno, sin votos con el
# mismo modelo a los 2 lados (igual que Mark en R/03_evaluacion.R).

votes  <- read.csv("data/lmarena_votes.csv", stringsAsFactors = FALSE)
prices <- data.frame(model             = v3$modelo,
                     company           = v3$compania,
                     input_usd_per_1m  = v3$precio_entrada_usd_por_millon,
                     output_usd_per_1m = v3$precio_salida_usd_por_millon)

first <- votes[votes$evaluation_order == 1, ]
n_votes <- table(c(first$model_a, first$model_b))
models_48 <- names(n_votes)[n_votes >= 1000]
first <- first[first$model_a %in% models_48 & first$model_b %in% models_48, ]
single <- first[first$turns == 1 & first$model_a != first$model_b, ]

long <- data.frame(
  model         = c(single$model_a, single$model_b),
  input_tokens  = c(single$sum_user_tokens, single$sum_user_tokens),
  output_tokens = c(single$answer_a_tokens, single$answer_b_tokens),
  won           = c(single$winner == "model_a", single$winner == "model_b"),
  decisive      = rep(single$winner %in% c("model_a", "model_b"), 2)
)
long <- merge(long, prices, by = "model", all.x = TRUE)
long$cost_usd <- (long$input_tokens  * long$input_usd_per_1m +
                  long$output_tokens * long$output_usd_per_1m) / 1e6

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
write.csv(summ, "R/resultados/costo_por_modelo.csv", row.names = FALSE, na = "")
cat("Parte 2: votos usados (1er voto, 48 modelos, 1 turno, modelos distintos):", nrow(single),
    "| modelos con costo:", sum(!is.na(summ$cost_per_1000_responses)), "de", nrow(summ), "\n")

# =============================================================================
# Parte 3. Top 3 por tarea dentro de cada presupuesto -> se movió a R/12_top3_por_precio.R
# =============================================================================
# Desde la fase 2b (9/11, docs/14) el top 3 se hace con las regresiones binomial en
# R/12_top3_por_precio.R. La versión del 2/11 (medio punto) quedó guardada en
# R/resultados/top3_por_precio_2026-11-02_medio_punto.csv.
