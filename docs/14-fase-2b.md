# 14. Fase 2b: AUC con pROC y 5-fold CV aleatorio (desde el 9/11)

Actualizado el 11/11/2026. Las fases 1 y 2 están hechas; no se repiten.

## Lo que pidió el profesor

**Clase del 4/11**
1. AUC calculado con el paquete **pROC**.
2. Primero el AUC con **todos los datos**.
3. **5-fold cross-validation**, con el AUC de cada fold.
4. Prefiere la regresión logística de siempre: tiene dudas sobre `quasibinomial`.

**Clase del 9/11 (cambio):** el AUC y la 5-fold CV van **primero**, y la partición es **aleatoria**, no "train = abril a junio, test = julio". Julio ya no es el examen principal.

**Siempre (de clases y correos anteriores):** primero la variable de respuesta y los predictores, explícitos. Quiere **ver el trabajo** (el código corriendo), lo simple primero (las 48 regresiones) y lo sofisticado como comparación (Bradley-Terry), y que cada uno pueda explicar en persona lo que entrega.

## Decisiones

1. **Modelo principal: `glm(..., family = binomial)`**, solo con votos que tienen ganador (y = 1 si ganó, 0 si perdió). `quasibinomial` (empates = 0.5) y el ordinal (`MASS::polr`) quedan como chequeo en el apéndice (Eli, PR #43: dan lo mismo).
2. **2 escenarios, en este orden:**
   1. **Todos los datos:** se ajusta y se mide con todo.
   2. **5-fold CV aleatorio:** 5 grupos al azar, ajustar con 4 y medir en el que sobra, 5 veces. Se reporta el AUC de cada fold y el promedio.
3. **Los folds se hacen por sesión** (`evaluation_session_id`): todas las filas de una sesión caen en el mismo fold. Cada voto genera 2 filas (1 por modelo) y las 2 tienen que quedar juntas, si no el test ve el voto que ya vio el train. Semilla fija `set.seed(2026)`.
4. **Los folds los creó Mark 1 sola vez** y están en `R/resultados/auc/folds_5.csv` (`id`, `fold`). **Todos usan ese archivo**: nadie hace sus propios folds.
5. **2 tipos de AUC, los 2 con `pROC`:**
   - **Por modelo:** el AUC de cada una de las 48 regresiones con sus propias filas (ganó 1/0).
   - **Por voto:** `plogis(score_A - score_B)` contra si A ganó. `score` = predictor lineal (logit) de la regresión de ese modelo para esa pregunta.
   - La **línea base** (ranking general: % de victorias, calculado solo con los folds de entrenamiento) solo existe para el AUC **por voto**.
6. En un fold, si un modelo tiene 1 sola clase en el test, `pROC` no calcula el AUC: se deja `NA` y se cuenta cuántos fueron (hasta ahora, 0 casos).
7. **Se reemplaza la decisión 4 de `docs/12`** (julio como evaluación principal). La evaluación de julio de `R/03` (65.1% contra 64.5%) **queda como resultado histórico**: no se borra ni se repite.

## Estado de la fase 2b (11/11)

Todo está en `main`.

| Tarea | Quién | PR |
|---|---|---|
| A. Regresiones, reporte y demo en `binomial` | Nessim | #35 |
| B. AUC con pROC, 5-fold por sesión, `folds_5.csv` y curva ROC | Mark | #39 |
| C1, C1b, C2. Sensibilidad (binomial, quasibinomial, ordinal) y figura ROC | Eli | #43 |
| D1. Top 3 por precio con `binomial` | Marco | #38 |
| D2. Esqueleto de la app Shiny | Marco | #40 |
| E. Bradley-Terry con covariables | Nessim | #41 |

Resultados principales (AUC por voto, 77,843 votos con ganador): con todos los datos, 0.7005 las 48 regresiones contra 0.6854 el ranking general. En 5-fold, promedio 0.6894 contra 0.6843, y las regresiones ganan en los 5 folds. Bradley-Terry: 0.6909. Detalle en `docs/05-resultados.md`.

## Demo para el profesor (lunes 16/11)

Se muestra en **RStudio**, con el código a la vista, y **Nessim presenta**. Cada pieza va en un archivo propio y Nessim las llama con `source()` desde `R/14_demo_rstudio.R`. Cada persona tiene su issue con el detalle. Fecha límite de las piezas: domingo 15/11 en la noche.

| # | Lo que pidió el profesor | Qué se muestra en RStudio | Archivo | Quién | Issue |
|---|---|---|---|---|---|
| 1 | Respuesta y predictores explícitos | `y = won` (1/0) y las 11 características; el largo de la respuesta no entra | `R/14_demo_rstudio.R` | Nessim | #44 |
| 2 | Ver el trabajo | 1 modelo con `glm(..., binomial)`: `summary()` con Intercept y coeficientes, y odds ratios | `R/14_demo_rstudio.R` | Nessim | #44 |
| 3 | AUC con pROC, todos los datos | `roc()` y `auc()` a la vista: curva ROC y AUC 0.7005 contra 0.6854 | `R/15_roc_por_fold.R` | Mark | #45 |
| 4 | 5-fold aleatorio, AUC de cada fold | Folds por sesión, tabla de AUC por fold y promedio, 5 curvas ROC | `R/15_roc_por_fold.R` | Mark | #45 |
| 5 | Gráficos de coeficientes | Coeficientes con intervalo de 1 modelo, heatmap de los 48 | `R/16_graficos_coeficientes.R` | Eli | #46 |
| 6 | Dudas con `quasibinomial` | Tabla de sensibilidad: binomial, quasibinomial y ordinal | `R/16_graficos_coeficientes.R` | Eli | #46 |
| 7 | Simple primero, sofisticado después | 1 línea con Bradley-Terry (0.6909) | `R/14_demo_rstudio.R` | Nessim | #44 |
| 8 | Algo útil | `top3()` en vivo para 3 preguntas, con y sin presupuesto | `R/17_top3_en_vivo.R` | Marco | #47 |

Cómo se lee el **Intercept**: es el log-odds de que ese modelo gane cuando las 11 etiquetas de la pregunta son FALSE. Cada coeficiente es cuánto cambia ese log-odds cuando la etiqueta es TRUE, y `exp(coef)` es el odds ratio.

**Preguntas probables del profesor, con la respuesta**
- *¿Por qué el AUC por modelo es solo cerca de 0.54?* Dentro de un modelo, las 11 etiquetas cambian poco su probabilidad de ganar. El 0.69 por voto sale de comparar a los 2 modelos del voto.
- *¿Por qué la mejora sobre el ranking general es solo +0.005?* Porque unos pocos modelos top (Gemini 2.5 Pro) son fuertes en casi todo. El valor extra está en el top 3 por tarea y presupuesto.
- *¿Los p-valores valen?* Son orientativos: cada voto se usa 2 veces (una por modelo). El profesor ya lo sabe.

**Fuera de la demo del lunes:** la app Shiny (18/11 a 30/11), los dashboards (2/12 y 7/12), el reporte y la presentación final (9/12 a 23/12). Calendario completo en `docs/07`.

## Si algo falla el lunes

Respaldo: `R/10_demo_clase_48.R` (los `summary()` y la tabla de AUC por fold) y `R/resultados/auc/curva_roc_cv5.png`.
