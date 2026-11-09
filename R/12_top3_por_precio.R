# Top 3 por tarea dentro de cada presupuesto, con las regresiones binomial (Marco, D1, issue #34)
#
# Fase 2b (docs/14): el modelo principal es glm(..., family = binomial) con votos que
# tienen ganador (ganó = 1, perdió = 0). Este script rehace R/resultados/top3_por_precio.csv
# con esos coeficientes. Antes (2/11) se hacía con medio punto (quasibinomial) dentro de
# R/06; esa versión queda guardada en R/resultados/top3_por_precio_2026-11-02_medio_punto.csv.
#
# Cómo se arma:
#   - Las 48 regresiones de R/02 con sus valores por defecto: binomial, sin empates ni
#     both_bad, sin los 28 votos marcados para revisión, sin ridge, sin rival.
#     Se ajustan con TODOS los votos de abril a julio (decisión 4 de docs/12: la
#     herramienta final usa todos).
#   - El top 3 sale de top3() de R/02: probabilidad de ganar promedio sobre las
#     preguntas reales que tienen esa característica, solo modelos con 100 o más
#     votos en julio, y con precio de salida <= presupuesto.
#   - Presupuesto = precio de lista por millón de tokens de SALIDA (julio 2025):
#     sin límite, hasta $10, hasta $2 y hasta $0.50. "Hasta" incluye el límite.
#   - Los 13 modelos sin precio oficial no entran en ningún presupuesto. En "sin límite"
#     también se dejan fuera, igual que en la versión del 2/11, para que las 4 columnas
#     se puedan comparar (sin límite = el mejor con precio conocido).
#
# No usa los folds de R/resultados/auc/folds_5.csv: esto no es una evaluación, es la
# tabla final de la herramienta.
#
# Ojo: el presupuesto es el precio por token, no el costo de una respuesta. Los modelos
# que razonan (columna `razona`) gastan más tokens de salida (ver docs/11).
#
# Desde la raíz del repo: source("R/12_top3_por_precio.R")   (solo R base)

options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")

archivo_precios <- "data/derivados/precios_modelos_2026-11-02_v4.csv"
archivo_meses   <- "R/resultados/decisiones_2026-11-02/votos_por_mes.csv"
archivo_salida  <- "R/resultados/top3_por_precio.csv"
archivo_antes   <- "R/resultados/top3_por_precio_2026-11-02_medio_punto.csv"

# ---- 1. Las 48 regresiones binomial --------------------------------------------

base  <- cargar_base()
datos <- preparar_respuesta(base)              # por defecto: "excluir" -> binomial
ajustes <- ajustar_modelos(datos)
stopifnot(length(ajustes) == 48,
          all(vapply(ajustes, function(f) f$family$family, "") == "binomial"),
          all(vapply(ajustes, `[[`, TRUE, "converged")))
cat("Regresiones binomial:", length(ajustes), "| votos:", length(unique(datos$id)),
    "| filas:", nrow(datos), "\n")

# ---- 2. Top 3 por tarea y presupuesto ------------------------------------------

tareas <- list(todas              = character(0),
               codigo             = "is_code",
               math               = "math",
               escritura_creativa = "creative_writing")
presupuestos <- c(sin_limite = Inf, hasta_10 = 10, hasta_2 = 2, hasta_0.50 = 0.5)

precios <- read.csv(archivo_precios, stringsAsFactors = FALSE, encoding = "UTF-8")
preguntas <- attr(ajustes, "preguntas")

top <- do.call(rbind, lapply(names(tareas), function(t) {
  car <- tareas[[t]]
  n_preg <- if (length(car) == 0) nrow(preguntas) else sum(apply(preguntas[car], 1, all))
  # Ranking completo (con precio) para saber el puesto sin límite
  completo <- ranking_real(car, ajustes, preguntas)
  meses <- read.csv(archivo_meses, stringsAsFactors = FALSE)
  completo$votos_julio <- meses$mes_7[match(completo$modelo, meses$modelo)]
  completo$precio <- precios$precio_salida_usd_por_millon[match(completo$modelo, precios$modelo)]
  completo <- completo[completo$votos_julio >= 100 & !is.na(completo$precio), ]
  completo <- completo[order(-completo$prob_ganar, completo$modelo), ]

  do.call(rbind, lapply(names(presupuestos), function(p) {
    lim <- if (is.finite(presupuestos[[p]])) presupuestos[[p]] else 1e9
    d <- top3(car, ajustes, precio_max = lim, archivo_meses = archivo_meses,
              archivo_precios = archivo_precios)
    i <- match(d$modelo, precios$modelo)
    data.frame(tarea                         = t,
               preguntas_reales              = n_preg,
               presupuesto                   = p,
               puesto                        = d$rank,
               modelo                        = d$modelo,
               compania                      = precios$compania[i],
               prob_ganar                    = round(d$prob_ganar, 3),
               precio_salida_usd_por_millon  = precios$precio_salida_usd_por_millon[i],
               precio_entrada_usd_por_millon = precios$precio_entrada_usd_por_millon[i],
               razona                        = precios$razona[i],
               votos_julio                   = d$votos_julio,
               votos_total                   = d$votos,
               puesto_sin_limite             = match(d$modelo, completo$modelo))
  }))
}))

stopifnot(nrow(top) == length(tareas) * length(presupuestos) * 3,
          all(!is.na(top$precio_salida_usd_por_millon)), all(top$votos_julio >= 100))
write.csv(top, archivo_salida, row.names = FALSE, na = "", fileEncoding = "UTF-8")
cat("Guardado:", archivo_salida, "(", nrow(top), "filas )\n")

# ---- 3. Qué cambió contra la versión del 2/11 (medio punto) ----------------------

antes <- read.csv(archivo_antes, stringsAsFactors = FALSE, encoding = "UTF-8")
clave <- function(d) paste(d$tarea, d$presupuesto, d$puesto)
top$modelo_medio_punto <- antes$modelo[match(clave(top), clave(antes))]
cambios <- top[top$modelo != top$modelo_medio_punto,
               c("tarea", "presupuesto", "puesto", "modelo_medio_punto", "modelo")]
cat("\nPuestos que cambian contra medio punto:", nrow(cambios), "de", nrow(top), "\n")
if (nrow(cambios)) print(cambios, row.names = FALSE)

for (t in names(tareas)) {
  cat("\n", t, " (", top$preguntas_reales[top$tarea == t][1], " preguntas)\n", sep = "")
  print(top[top$tarea == t, c("presupuesto", "puesto", "modelo", "prob_ganar",
                              "precio_salida_usd_por_millon", "razona")], row.names = FALSE)
}
