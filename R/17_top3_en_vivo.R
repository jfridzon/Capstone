# Top 3 en vivo para la demo del lunes 16/11 (Marco, issue #47)
#
# Lo que pidió el profesor (punto 8 de docs/14): "algo útil". Del modelo al resultado
# concreto: le dices a la herramienta cómo es tu pregunta (y tu presupuesto) y te da
# los 3 modelos con más probabilidad de ganar.
#
# Cómo funciona:
#   - Usa top3() de R/02, sin reajustar nada a mano. top3() promedia la probabilidad de
#     ganar de cada modelo sobre las preguntas REALES de LMArena que tienen esas
#     características, y deja solo modelos con 100 o más votos en julio.
#   - Las probabilidades salen de las 48 regresiones glm(..., family = binomial)
#     (ganó = 1, perdió = 0), ajustadas con todos los votos con ganador (77,843).
#   - Presupuesto = precio de lista por millón de tokens de SALIDA, julio 2025
#     (data/derivados/precios_modelos_2026-11-02_v4.csv).
#
# Uso: desde la raíz del repo, source("R/17_top3_en_vivo.R"), o sección por sección
# con Cmd+Enter. Si ya existe un objeto `ajustes` con las 48 regresiones binomial
# (por ejemplo, porque R/14 ya las ajustó), las reusa y no vuelve a ajustar.
# Solo R base.


# ---- 1. Cargar las funciones de R/02 y las 48 regresiones ------------------------

cat("\n=== Step 8: Top 3 live - which 3 models are most likely to win your question ===\n",
    "- You give the type of question (its tags) and, if you want, a budget.\n",
    "- For each model, the chance to win comes from its glm(..., family = binomial).\n",
    "- Budget = list price per million OUTPUT tokens (July 2025).\n\n", sep = "")

options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")

archivo_precios <- "data/derivados/precios_modelos_2026-11-02_v4.csv"
precios_demo    <- read.csv(archivo_precios, stringsAsFactors = FALSE, encoding = "UTF-8")

ya_ajustados <- exists("ajustes", inherits = FALSE) && is.list(ajustes) &&
  length(ajustes) == 48 && !is.null(attr(ajustes, "preguntas")) &&
  all(vapply(ajustes, function(f) identical(f$family$family, "binomial"), TRUE))

if (!ya_ajustados) {
  cat("Fitting the 48 binomial regressions (a few seconds)...\n")
  ajustes <- ajustar_modelos(preparar_respuesta(cargar_base()))   # valores por defecto de R/02
}
cat("Ready:", length(ajustes), "binomial regressions, fitted on",
    format(nrow(attr(ajustes, "preguntas")), big.mark = ","), "votes with a winner.\n")

# Nombres en inglés simple para las 11 etiquetas (solo para imprimir; no cambia nada).
nombres_etiquetas <- c(is_code = "Code", math = "Math", creative_writing = "Creative writing",
                       instruction_following = "Instruction following",
                       complexity = "Complexity", creativity = "Creativity",
                       domain_knowledge = "Domain knowledge", problem_solving = "Problem solving",
                       real_world = "Real world", specificity = "Specificity",
                       technical_accuracy = "Technical accuracy")


# ---- 2. La función: top3_en_vivo() ----------------------------------------------
# caracteristicas: vector con las etiquetas de la pregunta, por ejemplo c("is_code", "math").
#                  Las 11 posibles están en `predictores`.
# presupuesto:     NULL = sin límite. Un número = máximo precio de salida por millón de
#                  tokens (incluye el límite: "hasta $2" deja entrar a un modelo de $2).
# Devuelve la tabla (invisible) e imprime una versión limpia en la consola.

top3_en_vivo <- function(caracteristicas, presupuesto = NULL) {
  preguntas <- attr(ajustes, "preguntas")
  n <- if (length(caracteristicas) == 0) nrow(preguntas) else
    sum(apply(preguntas[caracteristicas], 1, all))

  t <- top3(caracteristicas, ajustes, precio_max = presupuesto,
            archivo_precios = archivo_precios)
  i <- match(t$modelo, precios_demo$modelo)
  tabla <- data.frame(
    Puesto           = t$rank,
    Modelo           = t$modelo,
    Compania         = precios_demo$compania[i],
    `Prob. de ganar` = sprintf("%.1f%%", 100 * t$prob_ganar),
    `Precio salida`  = ifelse(is.na(precios_demo$precio_salida_usd_por_millon[i]),
                              "sin precio oficial",
                              sprintf("$%.2f", precios_demo$precio_salida_usd_por_millon[i])),
    Razona           = precios_demo$razona[i],
    check.names = FALSE
  )

  etiquetas_txt <- ifelse(caracteristicas %in% names(nombres_etiquetas),
                          nombres_etiquetas[caracteristicas], caracteristicas)
  pregunta_txt <- if (length(caracteristicas) == 0) "any question" else
    paste0(paste(etiquetas_txt, collapse = " + "),
           "   (tags: ", paste(caracteristicas, collapse = ", "), " = TRUE)")
  presupuesto_txt <- if (is.null(presupuesto)) "no limit" else
    sprintf("up to $%.2f per million output tokens", presupuesto)
  cat("\nQuestion: ", pregunta_txt, "\n",
      "Budget:   ", presupuesto_txt, "\n",
      "Average over ", format(n, big.mark = ","),
      " real LMArena questions with these tags\n", sep = "")
  if (nrow(tabla) == 0) {
    cat("No model fits this budget.\n")
    return(invisible(tabla))
  }
  cat("Top 3 models (highest chance to win the vote):\n\n")
  imprimir <- tabla
  names(imprimir) <- c("Rank", "Model", "Company", "Chance to win",
                       "Output price", "Reasoning")
  imprimir$`Output price` <- sub("sin precio oficial", "no official price",
                                 imprimir$`Output price`, fixed = TRUE)
  imprimir$Reasoning <- ifelse(imprimir$Reasoning == "si", "yes",
                               ifelse(imprimir$Reasoning == "no", "no", imprimir$Reasoning))
  op <- options(width = max(getOption("width"), 120))   # que la tabla no se corte
  on.exit(options(op))
  print(imprimir, row.names = FALSE, right = FALSE)
  invisible(tabla)
}


# ---- 3. Ejemplo 1: una pregunta de código, sin límite de presupuesto -------------
# "Necesito ayuda con código y el precio no importa": ¿qué modelo uso?

cat("\n--- Example 1 of 3: a code question, price does not matter ---\n")
ej1 <- top3_en_vivo("is_code")


# ---- 4. Ejemplo 2: código + math, sin límite de presupuesto ----------------------
# Una pregunta que es de código Y de matemáticas a la vez (por ejemplo, un algoritmo).

cat("\n--- Example 2 of 3: a code + math question, price does not matter ---\n")
ej2 <-top3_en_vivo(c("is_code", "math"))


# ---- 5. Ejemplo 3: código + math, con presupuesto de $2 --------------------------
# La misma pregunta, pero la empresa no quiere pagar más de $2 por millón de tokens
# de salida. Así se ve lo que pierdes (o no) al pagar menos.

cat("\n--- Example 3 of 3: the same code + math question, budget up to $2 ---\n")
ej3 <-top3_en_vivo(c("is_code", "math"), presupuesto = 2)


# ---- 6. Cómo cambia el top 3 cuando entra el precio -------------------------------
# Ejemplo 2 (sin límite) al lado del ejemplo 3 (hasta $2).

cat("\n--- What changes when price enters: code + math, no limit vs up to $2 ---\n\n")
op <- options(width = max(getOption("width"), 140))
precio_en <- function(x) sub("sin precio oficial", "no official price", x, fixed = TRUE)
print(data.frame(Rank                  = ej2$Puesto,
                 `No limit`            = paste0(ej2$Modelo, " (", ej2$`Prob. de ganar`, ", ",
                                                precio_en(ej2$`Precio salida`), ")"),
                 `Up to $2`            = paste0(ej3$Modelo, " (", ej3$`Prob. de ganar`, ", ",
                                                precio_en(ej3$`Precio salida`), ")"),
                 check.names = FALSE),
      row.names = FALSE, right = FALSE)
options(op)

p_top  <- as.numeric(sub("%", "", ej2$`Prob. de ganar`[1]))
p_2    <- as.numeric(sub("%", "", ej3$`Prob. de ganar`[1]))
precio_top <- precios_demo$precio_salida_usd_por_millon[match(ej2$Modelo[1], precios_demo$modelo)]
precio_2   <- precios_demo$precio_salida_usd_por_millon[match(ej3$Modelo[1], precios_demo$modelo)]
cat(sprintf(paste0("\nNo limit, #1 wins %.1f%% and costs $%.2f. Up to $2, #1 wins %.1f%% and costs $%.2f:\n",
                   "%.1f points less, for a price %.0f times lower.\n"),
            p_top, precio_top, p_2, precio_2, p_top - p_2, precio_top / precio_2))
