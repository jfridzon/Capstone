# Build the portable app from the same fitted models, question mix and prices as Shiny.
# Run from the repository root. Implementation assisted by OpenAI Codex.
options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")
fits <- ajustar_modelos(preparar_respuesta(cargar_base()))
q <- attr(fits, "preguntas")
mask <- drop(as.matrix(q[predictores]) %*% 2^(seq_along(predictores) - 1))
counts <- table(mask)
prices <- read.csv("data/derivados/precios_modelos_2026-11-02_v4.csv")
july <- read.csv("R/resultados/decisiones_2026-11-02/votos_por_mes.csv")
models <- lapply(names(fits), function(id) {
  price <- prices[match(id, prices$modelo), ]
  b <- unname(coef(fits[[id]]))
  stopifnot(all(is.finite(b)), length(b) == length(predictores) + 1)
  list(id = id, company = price$compania, input = price$precio_entrada_usd_por_millon,
       output = price$precio_salida_usd_por_millon, date = price$fecha_del_precio,
       source = price$fuente_url, official = identical(price$tiene_precio_oficial, "si"),
       july = july$mes_7[match(id, july$modelo)], beta = b)
})
auc <- read.csv("R/resultados/auc/por_voto.csv")
comparison <- read.csv("R/resultados/regresion_grande_cv_2026-11-18/comparacion_por_voto.csv")
ladder <- read.csv("R/resultados/fuerza_rival/escalera_auc.csv")
payload <- list(comparison = subset(comparison, scenario == "cv5"), ladder = ladder, features = predictores, profiles = data.frame(mask = as.integer(names(counts)),
                count = as.integer(counts)), models = models, auc = subset(auc, scenario == "cv5" & fold != "sd"))
template <- readLines("app/mvp/template.html", warn = FALSE)
at <- which(template == "<!-- MODEL DATA -->")
stopifnot(length(at) == 1, length(fits) == 48, sum(counts) == 77843)
template[at] <- paste0('<script type="application/json" id="dataset">',
  gsub("<", "\\\\u003c", jsonlite::toJSON(payload, auto_unbox = TRUE, digits = 15, na = "null"), fixed = TRUE),
  "</script>")
writeLines(template, "app/mvp/ArenaGuide.html", useBytes = TRUE)
