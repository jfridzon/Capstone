# Tabla de precios de los 48 modelos (tarea 4, Marco)
#
# Qué hace:
#   1. Saca de data/lmarena_votes.csv los 48 modelos que usamos
#      (1er voto de cada conversación y 1,000 votos o más, igual que docs/03).
#   2. Para cada modelo busca su precio de lista en el archivo público de precios
#      de LiteLLM (github.com/BerriAI/litellm, model_prices_and_context_window.json),
#      en una versión fija (commit) para que cualquiera obtenga los mismos números.
#      Se usa la versión del 24/7/2025, el último día de nuestros datos.
#   3. Guarda data/derivados/precios_modelos_2026-10-28_v2.csv con las columnas
#      que pide la ficha docs/tareas/marco.md (más 4 columnas de apoyo al final).
#
# Versiones:
#   - v1 (PR #4): data/derivados/precios_modelos.csv, columnas en inglés. Se deja
#     como está porque no se sobrescribe nada en data/ (AGENTS.md, regla 2).
#   - v2 (este script): mismos precios, columnas de la ficha. Es la que se usa.
#
# Precio = dólares por 1 millón de tokens, de la API del dueño del modelo
# (Anthropic, OpenAI, Google, etc.), tarifa estándar, sin descuentos por caché o batch.
# Los modelos sin precio oficial quedan vacíos con la razón en "notas".
# Los precios coinciden con las páginas oficiales de cada compañía (fuente_url);
# se toman de LiteLLM porque esas páginas ya no muestran los precios de julio 2025.
# Qué hacer con ellos es una decisión abierta del grupo (ver el pull request).
#
# Paquetes: jsonlite. Necesita internet para bajar el archivo de LiteLLM.

library(jsonlite)

# ---- 1. Los 48 modelos ------------------------------------------------------

votes <- read.csv("data/lmarena_votes.csv", stringsAsFactors = FALSE)
first <- votes[votes$evaluation_order == 1, ]
n_votes <- table(c(first$model_a, first$model_b))
models_48 <- sort(names(n_votes)[n_votes >= 1000])
stopifnot(length(models_48) == 48)

# ---- 2. Versiones del archivo de precios de LiteLLM -------------------------

commit_jul2025 <- "8aa4beff5fd5d19bdb2bff7c3dfd8ba1ceea0d56"   # 24/7/2025
commit_oct2026 <- "cf7c35a1174eb9864cf35c1513c2d6d50b5df26a"   # 28/10/2026 (solo qwen-max, que no estaba en 2025)

load_prices <- function(commit) {
  url <- paste0("https://raw.githubusercontent.com/BerriAI/litellm/", commit,
                "/model_prices_and_context_window.json")
  fromJSON(url, simplifyVector = FALSE)
}
prices <- list(jul2025 = load_prices(commit_jul2025), oct2026 = load_prices(commit_oct2026))
commits <- c(jul2025 = commit_jul2025, oct2026 = commit_oct2026)
dates   <- c(jul2025 = "2025-07-24", oct2026 = "2026-10-28")

# ---- 3. Qué entrada de LiteLLM corresponde a cada modelo --------------------
# litellm_key = NA cuando el dueño del modelo no tiene un precio oficial.

pag_anthropic <- "https://platform.claude.com/docs/en/about-claude/pricing"
pag_openai    <- "https://openai.com/api/pricing/"
pag_google    <- "https://ai.google.dev/gemini-api/docs/pricing"
pag_xai       <- "https://docs.x.ai/docs/models"
pag_mistral   <- "https://mistral.ai/pricing"
pag_cohere    <- "https://cohere.com/pricing"
pag_deepseek  <- "https://api-docs.deepseek.com/quick_start/pricing"
pag_amazon    <- "https://aws.amazon.com/bedrock/pricing/"
pag_moonshot  <- "https://platform.moonshot.ai/docs/pricing/chat"
pag_alibaba   <- "https://www.alibabacloud.com/help/en/model-studio/models"

map <- read.csv(text = '
model|company|litellm_key|version|official_page|nota
amazon-nova-experimental-chat-05-14|Amazon|NA|jul2025|NA|Versión experimental que solo estuvo en LMArena. No tiene precio público
amazon.nova-pro-v1:0|Amazon|amazon.nova-pro-v1:0|jul2025|pag_amazon|Precio de Amazon Bedrock (región US)
chatgpt-4o-latest-20250326|OpenAI|chatgpt-4o-latest|jul2025|pag_openai|
claude-3-5-haiku-20241022|Anthropic|claude-3-5-haiku-20241022|jul2025|pag_anthropic|
claude-3-5-sonnet-20241022|Anthropic|claude-3-5-sonnet-20241022|jul2025|pag_anthropic|
claude-3-7-sonnet-20250219|Anthropic|claude-3-7-sonnet-20250219|jul2025|pag_anthropic|
claude-3-7-sonnet-20250219-thinking-32k|Anthropic|claude-3-7-sonnet-20250219|jul2025|pag_anthropic|Mismo precio que la versión normal. El razonamiento se cobra como tokens de salida
claude-opus-4-20250514|Anthropic|claude-opus-4-20250514|jul2025|pag_anthropic|
claude-opus-4-20250514-thinking-16k|Anthropic|claude-opus-4-20250514|jul2025|pag_anthropic|Mismo precio que la versión normal. El razonamiento se cobra como tokens de salida
claude-sonnet-4-20250514|Anthropic|claude-sonnet-4-20250514|jul2025|pag_anthropic|
claude-sonnet-4-20250514-thinking-32k|Anthropic|claude-sonnet-4-20250514|jul2025|pag_anthropic|Mismo precio que la versión normal. El razonamiento se cobra como tokens de salida
command-a-03-2025|Cohere|command-a-03-2025|jul2025|pag_cohere|
deepseek-r1-0528|DeepSeek|deepseek/deepseek-reasoner|jul2025|pag_deepseek|Precio estándar. DeepSeek tenía descuento en horario nocturno de China
deepseek-v3-0324|DeepSeek|deepseek/deepseek-chat|jul2025|pag_deepseek|Precio estándar. DeepSeek tenía descuento en horario nocturno de China
gemini-2.0-flash-001|Google|gemini/gemini-2.0-flash-001|jul2025|pag_google|
gemini-2.5-flash|Google|gemini/gemini-2.5-flash|jul2025|pag_google|El precio de salida incluye el razonamiento
gemini-2.5-flash-lite-preview-06-17-thinking|Google|gemini/gemini-2.5-flash-lite-preview-06-17|jul2025|pag_google|El razonamiento se cobra igual que la salida
gemini-2.5-flash-preview-04-17|Google|gemini/gemini-2.5-flash-preview-04-17|jul2025|pag_google|Salida sin razonamiento. Con razonamiento la salida costaba 3.50
gemini-2.5-pro|Google|gemini/gemini-2.5-pro|jul2025|pag_google|Hasta 200k tokens. Arriba de 200k: 2.50 entrada y 15 salida
gemini-2.5-pro-preview-03-25|Google|gemini/gemini-2.5-pro-preview-03-25|jul2025|pag_google|Hasta 200k tokens
gemini-2.5-pro-preview-05-06|Google|gemini/gemini-2.5-pro-preview-05-06|jul2025|pag_google|Hasta 200k tokens
gemma-3-27b-it|Google|NA|jul2025|NA|Modelo open-source. Google lo da gratis en su API con límites, y otros proveedores lo cobran distinto
gemma-3n-e4b-it|Google|NA|jul2025|NA|Modelo open-source. Sin precio oficial de pago
gpt-4.1-2025-04-14|OpenAI|gpt-4.1-2025-04-14|jul2025|pag_openai|
gpt-4.1-mini-2025-04-14|OpenAI|gpt-4.1-mini-2025-04-14|jul2025|pag_openai|
grok-3-mini-beta|xAI|xai/grok-3-mini-beta|jul2025|pag_xai|
grok-3-mini-high|xAI|xai/grok-3-mini|jul2025|pag_xai|Es grok-3-mini con razonamiento alto. Mismo precio por token
grok-3-preview-02-24|xAI|xai/grok-3-beta|jul2025|pag_xai|Versión preview de LMArena. Se usa el precio de grok-3 en la API
grok-4-0709|xAI|xai/grok-4-0709|jul2025|pag_xai|
hunyuan-turbos-20250416|Tencent|NA|jul2025|NA|Tencent Cloud cobra en yuanes y no encontramos un precio oficial verificable para esta versión
kimi-k2-0711-preview|Moonshot AI|moonshot/kimi-k2-0711-preview|jul2025|pag_moonshot|
llama-3.3-70b-instruct|Meta|NA|jul2025|NA|Modelo open-source. Meta no vendía acceso con precio público y cada proveedor cobra distinto
llama-4-maverick-03-26-experimental|Meta|NA|jul2025|NA|Versión experimental que solo estuvo en LMArena. No tiene precio público
llama-4-maverick-17b-128e-instruct|Meta|NA|jul2025|NA|Modelo open-source. Meta no vendía acceso con precio público y cada proveedor cobra distinto
llama-4-scout-17b-16e-instruct|Meta|NA|jul2025|NA|Modelo open-source. Meta no vendía acceso con precio público y cada proveedor cobra distinto
magistral-medium-2506|Mistral|mistral/magistral-medium-2506|jul2025|pag_mistral|
minimax-m1|MiniMax|NA|jul2025|NA|MiniMax vende su API, pero no encontramos el precio oficial de julio 2025 en una fuente verificable
mistral-medium-2505|Mistral|mistral/mistral-medium-2505|jul2025|pag_mistral|
mistral-small-2506|Mistral|mistral/mistral-small-latest|jul2025|pag_mistral|Mistral Small 3.2. En julio 2025 mistral-small-latest apuntaba a esta versión
mistral-small-3.1-24b-instruct-2503|Mistral|mistral/mistral-small-latest|jul2025|pag_mistral|Mistral Small 3.1. Mismo precio de lista que Small 3.2
o3-2025-04-16|OpenAI|o3-2025-04-16|jul2025|pag_openai|OpenAI bajó el precio el 10/6/2025. Antes costaba 10 entrada y 40 salida
o3-mini|OpenAI|o3-mini|jul2025|pag_openai|
o4-mini-2025-04-16|OpenAI|o4-mini-2025-04-16|jul2025|pag_openai|
qwen-max-2025-01-25|Alibaba|dashscope/qwen-max|oct2026|pag_alibaba|Precio de Alibaba Cloud internacional. No estaba en el archivo de 2025, se usa la versión de oct 2026
qwen3-235b-a22b|Alibaba|NA|jul2025|NA|Modelo open-source. Alibaba lo vende, pero no encontramos su precio de 2025 en una fuente verificable
qwen3-235b-a22b-no-thinking|Alibaba|NA|jul2025|NA|Modelo open-source. Alibaba lo vende, pero no encontramos su precio de 2025 en una fuente verificable
qwen3-30b-a3b|Alibaba|NA|jul2025|NA|Modelo open-source. Alibaba lo vende, pero no encontramos su precio de 2025 en una fuente verificable
qwq-32b|Alibaba|NA|jul2025|NA|Modelo open-source. Alibaba lo vende, pero no encontramos su precio de 2025 en una fuente verificable
', sep = "|", stringsAsFactors = FALSE, na.strings = "NA")

pages <- c(pag_anthropic = pag_anthropic, pag_openai = pag_openai, pag_google = pag_google,
           pag_xai = pag_xai, pag_mistral = pag_mistral, pag_cohere = pag_cohere,
           pag_deepseek = pag_deepseek, pag_amazon = pag_amazon, pag_moonshot = pag_moonshot,
           pag_alibaba = pag_alibaba)

# Cada uno de los 48 modelos tiene que estar 1 vez en la tabla
stopifnot(setequal(map$model, models_48), !anyDuplicated(map$model))

# ---- 4. Armar la tabla ------------------------------------------------------

get_price <- function(key, version, field) {
  if (is.na(key)) return(NA_real_)
  entry <- prices[[version]][[key]]
  if (is.null(entry)) stop("No se encontró en LiteLLM: ", key)
  round(entry[[field]] * 1e6, 4)   # de dólares por token a dólares por 1M tokens
}

has_price <- !is.na(map$litellm_key)

out <- data.frame(
  # --- columnas de la ficha docs/tareas/marco.md ---
  modelo                        = map$model,
  compania                      = map$company,
  precio_entrada_usd_por_millon = mapply(get_price, map$litellm_key, map$version, "input_cost_per_token"),
  precio_salida_usd_por_millon  = mapply(get_price, map$litellm_key, map$version, "output_cost_per_token"),
  disponible_gratis_en_app      = NA,   # sin verificar: falta fuente de julio 2025 (ver docs/11)
  fuente_url                    = ifelse(is.na(map$official_page), NA, pages[map$official_page]),
  fecha_consulta                = "2026-10-28",
  notas                         = ifelse(map$nota == "", NA, map$nota),
  # --- columnas de apoyo ---
  tiene_precio_oficial          = ifelse(has_price, "si", "no"),
  fecha_del_precio              = ifelse(has_price, dates[map$version], NA),
  fuente_datos                  = ifelse(has_price,
                                    paste0("LiteLLM model_prices_and_context_window.json, commit ",
                                           substr(commits[map$version], 1, 7), ", clave ", map$litellm_key),
                                    NA),
  votos_1er_voto                = as.integer(n_votes[map$model]),
  row.names = NULL
)
out <- out[order(out$compania, out$modelo), ]

# Chequeos de la ficha: 48 filas, sin nombres repetidos, cada precio con su fuente
stopifnot(nrow(out) == 48, !anyDuplicated(out$modelo),
          all(!is.na(out$fuente_url[!is.na(out$precio_entrada_usd_por_millon)])))

archivo <- "data/derivados/precios_modelos_2026-10-28_v2.csv"
if (file.exists(archivo)) stop("Ya existe ", archivo, ". Usa un nombre nuevo, no se sobrescribe.")
write.csv(out, archivo, row.names = FALSE, na = "")

cat("Modelos:", nrow(out), "| con precio oficial:", sum(has_price),
    "| sin precio:", sum(!has_price), "\n")
