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

options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")

archivo_precios <- "data/derivados/precios_modelos_2026-11-02_v4.csv"
precios_demo    <- read.csv(archivo_precios, stringsAsFactors = FALSE, encoding = "UTF-8")

ya_ajustados <- exists("ajustes", inherits = FALSE) && is.list(ajustes) &&
  length(ajustes) == 48 && !is.null(attr(ajustes, "preguntas")) &&
  all(vapply(ajustes, function(f) identical(f$family$family, "binomial"), TRUE))

if (!ya_ajustados) {
  cat("Ajustando las 48 regresiones binomial (unos segundos)...\n")
  ajustes <- ajustar_modelos(preparar_respuesta(cargar_base()))   # valores por defecto de R/02
}
cat("Listas:", length(ajustes), "regresiones binomial con",
    format(nrow(attr(ajustes, "preguntas")), big.mark = ","), "votos con ganador.\n")


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

  pregunta_txt <- if (length(caracteristicas) == 0) "cualquier pregunta" else
    paste(caracteristicas, collapse = " + ")
  presupuesto_txt <- if (is.null(presupuesto)) "sin límite" else
    sprintf("hasta $%.2f por millón de tokens de salida", presupuesto)
  cat("\nPregunta:    ", pregunta_txt, "\n",
      "Presupuesto: ", presupuesto_txt, "\n",
      "Se promedia sobre ", format(n, big.mark = ","), " preguntas reales\n\n", sep = "")
  if (nrow(tabla) == 0) {
    cat("Ningún modelo entra en este presupuesto.\n")
    return(invisible(tabla))
  }
  op <- options(width = max(getOption("width"), 120))   # que la tabla no se corte
  on.exit(options(op))
  print(tabla, row.names = FALSE, right = FALSE)
  invisible(tabla)
}


# ---- 3. Ejemplo 1: una pregunta de código, sin límite de presupuesto -------------
# "Necesito ayuda con código y el precio no importa": ¿qué modelo uso?

ej1 <- top3_en_vivo("is_code")


# ---- 4. Ejemplo 2: código + math, sin límite de presupuesto ----------------------
# Una pregunta que es de código Y de matemáticas a la vez (por ejemplo, un algoritmo).

ej2 <- top3_en_vivo(c("is_code", "math"))


# ---- 5. Ejemplo 3: código + math, con presupuesto de $2 --------------------------
# La misma pregunta, pero la empresa no quiere pagar más de $2 por millón de tokens
# de salida. Así se ve lo que pierdes (o no) al pagar menos.

ej3 <- top3_en_vivo(c("is_code", "math"), presupuesto = 2)


# ---- 6. Cómo cambia el top 3 cuando entra el precio -------------------------------
# Ejemplo 2 (sin límite) al lado del ejemplo 3 (hasta $2).

cat("\nCódigo + math: sin límite contra hasta $2\n\n")
op <- options(width = max(getOption("width"), 140))
print(data.frame(Puesto                = ej2$Puesto,
                 `Sin limite`          = paste0(ej2$Modelo, " (", ej2$`Prob. de ganar`, ", ",
                                                ej2$`Precio salida`, ")"),
                 `Hasta $2`            = paste0(ej3$Modelo, " (", ej3$`Prob. de ganar`, ", ",
                                                ej3$`Precio salida`, ")"),
                 check.names = FALSE),
      row.names = FALSE, right = FALSE)
options(op)

p_top  <- as.numeric(sub("%", "", ej2$`Prob. de ganar`[1]))
p_2    <- as.numeric(sub("%", "", ej3$`Prob. de ganar`[1]))
precio_top <- precios_demo$precio_salida_usd_por_millon[match(ej2$Modelo[1], precios_demo$modelo)]
precio_2   <- precios_demo$precio_salida_usd_por_millon[match(ej3$Modelo[1], precios_demo$modelo)]
cat(sprintf(paste0("\nEl 1º sin límite gana %.1f%% y cuesta $%.2f. El 1º hasta $2 gana %.1f%% y cuesta $%.2f:\n",
                   "%.1f puntos menos por %.0f veces menos de precio.\n"),
            p_top, precio_top, p_2, precio_2, p_top - p_2, precio_top / precio_2))
