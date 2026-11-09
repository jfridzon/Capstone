# 05. Resultados hasta ahora

Todos estos números salen de los 135,634 votos completos. Cuando un número usa un filtro, se dice cuál.

## Test 1: los modelos top contra todos los demás (`R/lmarena_tests.R`)

"Top" son los 4 modelos que nombramos en Phase 0 (Claude Opus 4, o3, Gemini 2.5 Pro y Grok 4) más la versión thinking de Opus 4 y las 2 preview de Gemini 2.5 Pro. Se usaron solo los votos donde exactamente 1 de los 2 modelos es top: 35,694 votos.

| Resultado | % |
|---|---|
| Ganó el modelo top | 46.2% |
| **Ganó el otro modelo** | **28.0%** (IC 95%: 27.6% a 28.5%) |
| Empate | 16.0% |
| Both bad | 9.8% |

Ojo: "otro" no siempre es más barato. Algunos, como Claude Sonnet 4, también son pagos. Para hablar de "barato" hace falta la tabla de precios.

## Test 2: % de victorias por tipo de tarea (`R/resultados/test2_rank_by_task.csv`)

Cada voto se parte en 2 filas, y `won` = 1 si ese modelo ganó (empate y both_bad cuentan como 0). Solo entran modelos con 200 o más votos en la tarea.

- **Gemini 2.5 Pro es 1º en todas las tareas** menos en seguir instrucciones, donde 1º es su versión preview de marzo.
- Debajo, el orden cambia. En **math**, MiniMax M1 es 2º (19º en general) y Gemini 2.5 Flash es 3º (10º en general), por encima de o3 (6º) y Claude Opus 4 (18º). En **escritura creativa**, Grok 3 preview es 2º (8º en general).
- Corrección respecto al correo de Phase 0: con los datos completos, Gemma 3 **no** es 3º en escritura creativa. Es 17º.
- Muchos modelos del medio están separados por 2 o 3 puntos con pocos cientos de votos cada uno. Es una primera mirada, no un resultado probado.

## Test 3: ¿gana la respuesta más larga?

De 98,097 votos con ganador y respuestas de distinto largo, **la más larga ganó el 61.8%** (IC 95%: 61.5% a 62.1%). El largo no puede ser predictor (se conoce después), pero hay que tomarlo en cuenta al explicar los resultados.

## Chequeo de asignación y cobertura (reproducido en R, 4/11/2026)

Generador: `R/09_chequeos_datos.R`. Resultados: `R/resultados/eli_chequeos_2026-11-04/`.
Usa todos los votos para reproducir el chequeo histórico. Para cada modelo, cuenta una participación por lado y calcula qué proporción tiene cada característica. Solo los modelos con 1,000 o más participaciones en la cohorte entran a los extremos (48 modelos en todos los votos). El total se calcula sobre los votos completos, sin filtrar modelos. Las etiquetas se solapan.

| Tipo de pregunta | Total | Mínimo por modelo | Máximo por modelo |
|---|---:|---:|---:|
| Código | 29.0% | 26.4% (claude-3-7-sonnet-20250219-thinking-32k) | 35.2% (o3-2025-04-16) |
| Math | 8.0% | 5.2% (magistral-medium-2506) | 11.2% (gemini-2.5-pro-preview-03-25) |
| Escritura creativa | 8.5% | 7.8% (claude-sonnet-4-20250514-thinking-32k) | 10.9% (grok-4-0709) |
| Seguir instrucciones | 18.2% | 16.2% (claude-3-7-sonnet-20250219-thinking-32k) | 21.9% (gemini-2.5-pro-preview-03-25) |
| Difícil (6+ de 7 criterios, solo histórico) | 37.5% | 33.0% (deepseek-r1-0528) | 43.1% (magistral-medium-2506) |

Los porcentajes históricos coinciden al redondear. El CSV incluye las 11 características, el indicador histórico `hard`, los extremos, sus modelos y el detalle por modelo. `hard` solo reproduce la tabla anterior y no se agrega como predictor.

| Cohorte | Votos | Combinaciones posibles | Observadas | Mínimo que cubre el 90% |
|---|---:|---:|---:|---:|
| Todos | 135,634 | 2,048 | 843 | 120 |
| Primer voto | 108,315 | 2,048 | 794 | 115 |
| Junio | 53,447 | 2,048 | 696 | 120 |

Se reproducen las **843** combinaciones y las **120** que cubren el 90% del chequeo original. Se guardan las 2,048 combinaciones, incluso las de cero votos, y sus frecuencias para cada cohorte. El script verifica sumas, ausencia de faltantes y el umbral mínimo del 90%.

**Límite:** estos porcentajes son descriptivos y no prueban asignación aleatoria ni un sesgo causal. La afirmación anterior de que la variación era «1.2 a 2.7 veces el puro azar» no tenía definición o código reproducible y se retira de esta sección, sin sustituirla por una prueba inventada. La cobertura histórica de las 10 cajas pertenece al método descartado y no se vuelve a calcular aquí. No se cambian reglas de limpieza ni decisiones del grupo.

## Prueba de julio con la versión de 10 cajas (21/10)

Train de abril a junio y test en julio, con los votos decisivos de modelos que estaban en train: 20,416 votos.

| Modelo | Aciertos en julio |
|---|---|
| Ranking general (1 orden para todo) | 64.5% |
| Ranking por tipo de tarea (10 cajas) | 64.7% |

Prácticamente igual. Pendiente: repetirla con Bradley-Terry con covariables (`docs/04`).

## Partición train/test y línea base: el ranking general (`R/03_evaluacion.R`)

Este script pasa a R la línea base del ranking general (el 64.5% de arriba) y deja la partición guardada, para que las 48 regresiones y la regresión combinada se evalúen exactamente con los mismos votos.

**Partición** (`R/resultados/split_train_test.csv`, 1 fila por voto con `id`, `split` y `decisive`). Filtros de `docs/03`: solo el 1er voto y los 48 modelos con 1,000 votos o más. Train = 17/4 al 30/6, test = julio. Ninguna sesión queda partida entre train y test (el script lo verifica).

| | Train | Test |
|---|---|---|
| Votos decisivos | 52,214 | 25,649 |
| Empate o both_bad | 19,240 | 9,527 |

**Ranking general** (`R/resultados/ranking_general_train.csv`). Bradley-Terry sin características (1 voto decisivo = 1 fila, respuesta = ganó model_a, 1 columna por modelo con +1 / −1 / 0, sin intercepto), ajustado solo con train (52,208 votos decisivos) y 44 modelos. Hay 8 votos con el mismo modelo a ambos lados (6 decisivos, todos en train, todos de gemini-2.5-flash-preview-04-17); no dicen nada sobre la fuerza del modelo y se excluyen del ajuste y del test. Los otros 4 modelos ( grok-3-mini-high, grok-4-0709, kimi-k2-0711-preview y mistral-small-2506) solo aparecen en julio. Referencia (fuerza 0): claude-opus-4-20250514, el modelo con más votos en train. Top 5:

| Rank | Modelo | Fuerza | Votos en train |
|---|---|---|---|
| 1 | gemini-2.5-pro | 1.098 | 3,522 |
| 2 | gemini-2.5-pro-preview-03-25 | 0.756 | 796 |
| 3 | gemini-2.5-pro-preview-05-06 | 0.669 | 1,939 |
| 4 | deepseek-r1-0528 | 0.636 | 2,912 |
| 5 | o3-2025-04-16 | 0.610 | 3,058 |

**Línea base en julio** (`R/resultados/test_baseline_ranking_general.csv`). En cada voto decisivo de julio se predice que gana el modelo de mayor fuerza. De 25,649 votos decisivos, 5,233 se quedan fuera porque incluyen un modelo que no está en train. Se evalúan 20,416 votos y se acierta en 13,164: **64.5%** (IC 95%: 63.8% a 65.1%). Coincide con el 64.5% sobre 20,416 votos de la prueba anterior.

Empates y both_bad quedan **excluidos** del ajuste de estas dos líneas base, que es lo usado hasta ahora (parámetro `tie_handling`). La decisión 1 del 2/11 (`docs/12`) fue usar medio punto en las 48 regresiones; para eso hay también una versión con medio punto del % de victorias, en la subsección siguiente.

**Segunda línea base: % de victorias general** (`R/resultados/winrate_general_train.csv` y `R/resultados/evaluacion.csv`). Es la que pide la ficha de Mark (`docs/tareas/mark.md`): para cada modelo, votos ganados ÷ votos jugados en train, con todos los tipos de pregunta juntos, sobre los mismos 52,208 votos del ajuste anterior. En cada voto de julio se predice que gana el modelo con mayor %. No toma en cuenta contra quién jugó cada modelo (`docs/04`, nivel 1). Top 3 en train: gemini-2.5-pro (74.8%), gemini-2.5-pro-preview-03-25 (67.2%) y gemini-2.5-pro-preview-05-06 (65.3%).

Las dos líneas base se evalúan sobre los mismos 20,416 votos de julio:

| Línea base | Aciertos | % | IC 95% |
|---|---|---|---|
| Bradley-Terry (sin características) | 13,164 | 64.5% | 63.8% a 65.1% |
| % de victorias | 13,162 | 64.5% | 63.8% a 65.1% |

Dan prácticamente lo mismo: solo se separan en 210 de los 20,416 votos. Para comparar las 48 regresiones basta usar cualquiera de las dos como línea base. `evaluacion.csv` tiene una fila por método (con aciertos y log-loss); la regresión combinada se agrega ahí cuando exista.

### Las 48 regresiones contra las líneas base (julio)

Es la Parte A de la ficha de Mark (`docs/tareas/mark.md`, fase 2). `R/03_evaluacion.R` carga las funciones de `R/02_regresiones_por_modelo.R` (Jaime), ajusta las regresiones **solo con train** y, en cada voto de julio, calcula la probabilidad de ganar de `model_a` y de `model_b` con las 11 características de esa pregunta. Se predice que gana el de mayor probabilidad. Se ajustan **dos veces**, según la decisión 1 del 2/11 (`docs/12`): con **medio punto** (empate y both_bad valen 0.5; es la versión principal) y **excluyendo** empates y both_bad (chequeo de sensibilidad). Los modelos entrenados son 44 (los 4 que solo aparecen en julio no tienen regresión) y los votos evaluados son los mismos 20,416 de las líneas base: en julio solo hay votos con ganador, porque en un empate no hay ganador que acertar. Las 44 regresiones convergen. Votos de train que usa cada versión: 71,426 con medio punto (la regresión más chica usa 698) y 52,194 excluyendo (la más chica, 523). `R/02` deja fuera 28 votos que Nessim marcó para revisión (10 de un modelo contra sí mismo y 18 de sesiones con varios "primeros votos"; todos están en train, así que julio no cambia).

**Qué se mide.** *Aciertos*: % de votos donde el modelo predicho como ganador ganó. *Log-loss*: qué tan buenas son las probabilidades (más bajo es mejor); una probabilidad de 51% y una de 90% cuentan igual en aciertos, pero no en log-loss. La probabilidad de que gane `model_a` es `plogis(qlogis(p_a) - qlogis(p_b))`; para el % de victorias es lo mismo con el % de cada modelo, y para Bradley-Terry es `plogis(fuerza_a - fuerza_b)`.

| Método | Se ajusta con | Aciertos | % | IC 95% | Log-loss |
|---|---|---|---|---|---|
| Línea base: Bradley-Terry | excluir | 13,164 | 64.5% | 63.8% a 65.1% | 0.6340 |
| Línea base: % de victorias | excluir | 13,162 | 64.5% | 63.8% a 65.1% | 0.6340 |
| Línea base: % de victorias | medio punto | 13,171 | 64.5% | 63.9% a 65.2% | 0.6378 |
| **48 regresiones (principal)** | **medio punto** | **13,298** | **65.1%** | 64.5% a 65.8% | **0.6321** |
| 48 regresiones (sensibilidad) | excluir | 13,303 | 65.2% | 64.5% a 65.8% | 0.6298 |
| 48 + fuerza del rival (chequeo) | medio punto | 13,315 | 65.2% | 64.6% a 65.9% | 0.6368 |
| 48 + fuerza del rival (chequeo) | excluir | 13,302 | 65.2% | 64.5% a 65.8% | 0.6684 |

Bradley-Terry y el % de victorias tienen casi el mismo log-loss (0.634003 y 0.634032) porque sus probabilidades son casi iguales (correlación 0.9995; predicen distinto ganador en 210 votos).

**Comparación voto por voto** (`R/resultados/evaluacion_pareada.csv`). Los intervalos de arriba se traslapan porque se evalúan los mismos votos, así que se cuentan los votos donde **solo uno** de los dos métodos acierta. En log-loss se promedia, voto por voto, la pérdida del método base menos la del nuevo (positivo = el nuevo es mejor).

| Comparación | Solo acierta el nuevo / el base | Diferencia en aciertos | p | Mejora en log-loss (IC 95%) |
|---|---|---|---|---|
| 48 (medio punto) contra % de victorias (medio punto) | 1,215 / 1,088 | +0.62 puntos (+0.16 a +1.08) | 0.0086 | +0.0058 (+0.0042 a +0.0074) |
| 48 (medio punto) contra Bradley-Terry | 1,230 / 1,096 | +0.66 puntos (+0.19 a +1.12) | 0.0058 | +0.0019 (−0.00002 a +0.0039) |
| 48 (excluir) contra % de victorias | 1,226 / 1,085 | +0.69 puntos (+0.23 a +1.15) | 0.0036 | +0.0042 (+0.0021 a +0.0063) |
| 48 (excluir) contra Bradley-Terry | 1,233 / 1,094 | +0.68 puntos (+0.22 a +1.14) | 0.0042 | +0.0042 (+0.0020 a +0.0063) |
| 48 medio punto contra 48 excluir | 120 / 125 | −0.02 puntos (−0.17 a +0.13) | 0.80 | −0.0022 (−0.0036 a −0.0009) |

Como el % de victorias es lo mismo que una regresión sin características, la diferencia contra él es lo que aportan las 11 características.

**Cómo leerlo:**
- La mejora en aciertos es **pequeña**: unos 130 votos más de 20,416 (menos de 1 punto). Va en la dirección que esperaba el método, pero la precisión sigue cerca de 65%: gemini-2.5-pro sale 1º o 2º en casi todos los tipos de pregunta (`docs/01`), así que el orden de los modelos cambia poco de una tarea a otra.
- **Log-loss:** las 48 mejoran contra el % de victorias en las dos versiones. Contra Bradley-Terry la mejora con medio punto es de solo 0.0019 y su intervalo llega a 0, así que ahí no se puede afirmar que sea distinta de cero. `docs/12` dice "siempre en log-loss": es cierto contra el % de victorias; contra Bradley-Terry con medio punto no es claro.
- **Medio punto contra excluir:** los aciertos son iguales (120 contra 125 votos de diferencia). En log-loss, excluir sale un poco mejor (0.6298 contra 0.6321) sobre votos decisivos, que es lo esperable porque se ajusta al mismo tipo de voto que se evalúa. Medio punto se usa por la decisión 1 de `docs/12` (un empate trae información), no porque gane en esta métrica.
- Los p-valores y los intervalos son nominales: no corrigen que los mismos modelos se repiten en muchos votos ni que cada voto se usa 2 veces al ajustar (el profesor lo sabe, `docs/04`).
- Es 1 sola partición (entrenar con abril a junio, evaluar en julio) y julio no incluye grok-4, kimi-k2, mistral-small-2506 ni grok-3-mini-high (decisión 4 de `docs/12`). Los 5,233 votos de julio que los incluyen quedan fuera de todas las comparaciones.
- **Fuerza del rival (decisión 5 de `docs/12`: no se controla en las 48):** agregarla como 12º predictor no mejora los aciertos (579 contra 562 votos con medio punto; 582 contra 583 excluyendo) y empeora el log-loss (0.6368 contra 0.6321; 0.6684 contra 0.6298). Queda como chequeo.
- **Por tipo de pregunta** (`R/resultados/evaluacion_por_tarea.csv`, % de aciertos, descriptivo; las etiquetas se solapan y son 4 grupos, así que uno puede salir mejor por azar):

| Grupo (votos de julio) | Bradley-Terry | % de victorias (medio punto) | 48 medio punto | 48 excluir |
|---|---|---|---|---|
| Todos (20,416) | 64.5% | 64.5% | 65.1% | 65.2% |
| Código (5,502) | 63.2% | 63.1% | 64.0% | 64.1% |
| Math (1,409) | 65.9% | 65.6% | 66.4% | 66.7% |
| Escritura creativa (1,621) | 61.2% | 61.2% | 62.6% | 63.0% |
| Seguir instrucciones (3,215) | 62.9% | 62.5% | 64.9% | 64.9% |

Las regresiones con medio punto quedan arriba del % de victorias en los 4 grupos: +0.9 puntos en código, +0.8 en math, +1.4 en escritura creativa y +2.4 en seguir instrucciones. Con 1,409 y 1,621 votos en math y escritura creativa, esas diferencias por grupo no son concluyentes por sí solas.

**Contra la referencia de `R/08`** (`docs/tareas/mark.md`): el log-loss coincide en los 4 números (0.6321 y 0.6378 con medio punto; 0.6298 y 0.6340 excluyendo) y los aciertos de la línea base también (64.51% y 64.47%). Las regresiones dan 65.14% con medio punto y 65.16% excluyendo, contra 65.16% y 65.15% de `R/08`. La diferencia (6 votos con medio punto, 1 excluyendo) viene de que `R/02` saca del ajuste los 28 votos marcados para revisión y `R/08` no: sin sacarlos, una implementación independiente en Python da 13,304 y 13,302 aciertos, que son las cifras de `R/08`.

Para la decisión 6 de `docs/12` (cómo contar el resultado): las 48 le ganan al ranking general por poco en aciertos y de forma clara en log-loss contra el % de victorias.

Con las 10 cajas (ya descartadas) la diferencia era 64.7% contra 64.5%. Ese número viene de un análisis que todavía no está en `R/`, así que no lo reproduje y no lo comparo directamente con estos.

### Ridge, partición aleatoria y la función `evaluar()` (Parte B)

**Ridge** (`R/03_evaluacion.R`, sección 7). Es la misma regresión de cada modelo con una penalización que encoge sus 11 efectos hacia 0 (no el intercepto), lo que ayuda a los modelos con pocos votos. `R/02` no tiene ridge, así que el ajuste está escrito en `R/03` (mínimos cuadrados reponderados, como `R/08`). Con λ = 0 da los mismos coeficientes que `glm()` (diferencia máxima 1.1e-8; el script lo verifica). La fuerza de la penalización, λ, se elige **solo con train**: validación cruzada de 5 grupos de sesiones (una sesión nunca queda partida), con medio punto en el ajuste, y se queda el λ de menor log-loss sobre los votos decisivos que quedan fuera de cada grupo. Julio no se usa para elegir; se mide una sola vez con el λ elegido.

| λ | Aciertos (validación cruzada en train) | Log-loss (validación cruzada en train) |
|---|---|---|
| 0 | 63.45% | 0.6411 |
| 10 | 63.66% | 0.6406 |
| **30** | 63.78% | **0.6404** |
| 100 | 63.90% | 0.6410 |
| 300 | 63.94% | 0.6422 |

Se elige **λ = 30** (`R/resultados/ridge_validacion_cruzada.csv`). Las diferencias entre λ son chicas (0.0006 de log-loss entre el mejor y λ = 0). En julio, con λ = 30:

| Método | Aciertos | % | IC 95% | Log-loss |
|---|---|---|---|---|
| 48 regresiones, medio punto (λ = 0) | 13,298 | 65.1% | 64.5% a 65.8% | 0.6321 |
| **48 regresiones con ridge (λ = 30)** | **13,340** | **65.3%** | 64.7% a 66.0% | 0.6321 |

Contra las 48 sin penalización, ridge acierta en 323 votos donde ellas fallan y falla en 281 donde ellas aciertan: **+0.21 puntos** (IC 95%: −0.03 a +0.44; p = 0.095). El log-loss no cambia (mejora de 0.0000; IC −0.0005 a +0.0004). Contra el % de victorias con medio punto: +0.83 puntos (IC 95%: +0.42 a +1.24; p = 0.0001) y 0.0057 menos de log-loss (IC +0.0045 a +0.0069). Contra Bradley-Terry: +0.86 puntos (IC 95%: +0.45 a +1.27) y 0.0019 menos de log-loss (IC +0.0002 a +0.0036). **Lectura:** ridge no cambia el log-loss en julio y la mejora en aciertos contra las 48 sin penalización no se distingue de cero. Los p-valores e intervalos son nominales, como arriba. Las filas están en `evaluacion.csv` y `evaluacion_pareada.csv` (`regressions_48_ridge_half_point`).

**Partición aleatoria por sesión** (`R/03_evaluacion.R`, sección 10; `R/resultados/particion_aleatoria.csv`). La decisión 4 de `docs/12` pide este chequeo porque la evaluación de julio deja fuera los 4 modelos que solo aparecen en julio. Aquí entran los 48: 80% de las sesiones a train (85,282 votos) y 20% a test, con 5 semillas. En cada partición, λ se elige con validación cruzada dentro de su propio train (salió λ = 30 en las 5). Los tres métodos se miden en los mismos votos decisivos de test (entre 15,468 y 15,652 por semilla). Las 48 regresiones usan medio punto en el ajuste.

| Semilla | Aciertos % de victorias | Aciertos 48 (λ = 0) | Aciertos 48 (ridge) | Log-loss % de victorias | Log-loss 48 (λ = 0) | Log-loss 48 (ridge) |
|---|---|---|---|---|---|---|
| 1 | 63.9% | 64.1% | 64.2% | 0.6444 | 0.6381 | 0.6383 |
| 2 | 63.8% | 63.6% | 63.7% | 0.6440 | 0.6405 | 0.6397 |
| 3 | 64.1% | 63.9% | 64.2% | 0.6426 | 0.6397 | 0.6389 |
| 4 | 64.6% | 64.5% | 64.8% | 0.6409 | 0.6377 | 0.6369 |
| 5 | 63.8% | 63.9% | 64.0% | 0.6442 | 0.6398 | 0.6393 |
| Promedio | 64.0% | 64.0% | 64.2% | 0.6432 | 0.6392 | 0.6386 |

**Lectura:** en aciertos, las 48 sin penalización quedan empatadas con el % de victorias (mejores en 2 semillas y peores en 3), y con ridge quedan arriba del % de victorias en 4 de 5 semillas y por encima de las 48 sin ridge en las 5. En log-loss las 48 ganan al % de victorias en las 5 semillas, con o sin ridge, y ridge mejora a las 48 sin ridge en 4 de 5. Son 5 particiones del mismo conjunto de votos, así que no se calcularon intervalos. No son comparables número a número con la tabla de `docs/12`: con la misma semilla esa tabla da otros números (por ejemplo, semilla 1: 64.40% para el % de victorias, contra 63.9% aquí), así que las sesiones de test no son las mismas. No investigué por qué; aquí además se sacan los 28 votos marcados para revisión, como en `R/02`.

**`evaluar()`** (`R/03b_evaluar.R`). Una sola función mide todo igual: `evaluar(p_model_a, winner, method, tie_handling)` recibe, para cada voto de test, la probabilidad de que gane `model_a` y quién ganó, y devuelve aciertos, IC 95% y log-loss. Predice `model_a` si la probabilidad es mayor que 0.5. `R/03` la usa para todas las filas de `evaluacion.csv`. Para medir la regresión combinada sobre los mismos votos de julio (Nessim):

```r
source("R/03b_evaluar.R")
test <- read.csv("R/resultados/test_julio_votos.csv")   # 20,416 votos: id, model_a, model_b, winner
# p = probabilidad de que gane model_a en cada fila de `test`, en ese mismo orden
evaluar(p, test$winner, method = "combined_bradley_terry", tie_handling = "half")
```

Con un puntaje por modelo y pregunta en escala logit, `p = plogis(puntaje_a - puntaje_b)`. Los 20,416 votos son los de las líneas base y las 48 (los de julio con ganador y con los dos modelos en train).

La regresión combinada (Bradley-Terry con covariables, `docs/04`) la hace Nessim en `R/07` y se agrega a `evaluacion.csv`.

## Top 3 por tipo de tarea (Bradley-Terry, 10 cajas, 1er voto, 48 modelos, votos decisivos)

| Tipo | 1º | 2º | 3º |
|---|---|---|---|
| Code (easy) | gemini-2.5-pro | grok-4-0709 | deepseek-r1-0528 |
| Code (hard) | gemini-2.5-pro | gemini-2.5-pro-preview-03-25 | o3 |
| Math (easy) | grok-4-0709 | gemini-2.5-pro | minimax-m1 |
| Math (hard) | grok-4-0709 | gemini-2.5-pro-preview-03-25 | gemini-2.5-pro-preview-05-06 |
| Creative writing (easy) | gemini-2.5-pro-preview-03-25 | gemini-2.5-pro | grok-3-preview-02-24 |
| Creative writing (hard) | gemini-2.5-pro | gemini-2.5-pro-preview-03-25 | claude-sonnet-4-thinking-32k |
| Following instructions (easy) | gemini-2.5-pro-preview-03-25 | gemini-2.5-pro-preview-05-06 | gemini-2.5-pro |
| Following instructions (hard) | gemini-2.5-pro-preview-03-25 | grok-3-preview-02-24 | gemini-2.5-pro |
| Everything else (easy) | gemini-2.5-pro | grok-4-0709 | gemini-2.5-pro-preview-05-06 |
| Everything else (hard) | gemini-2.5-pro-preview-03-25 | gemini-2.5-pro | o3 |
| **General** | gemini-2.5-pro | gemini-2.5-pro-preview-03-25 | grok-4-0709 |

Cuidado: las versiones preview y grok-4 tienen pocos votos (a veces 30 a 100 en un tipo), así que su posición es inestable. Agrupar las versiones de un mismo modelo (por ejemplo todas las Gemini 2.5 Pro) es una decisión abierta.

Estos números (chequeo aleatorio, cobertura, prueba de julio y top 3) se calcularon con un análisis aparte que todavía **no está en `R/`**, salvo el 64.5% del ranking general en julio, que ya se reproduce en `R/03_evaluacion.R` (ver arriba). Pendiente: pasar el resto a un script de R para que sea reproducible (`docs/07`).


## Auditoría reproducible de limpieza (28/10/2026)

Ejecutada con `R/auditar_limpieza.R` sobre el CSV del repositorio, sin modificarlo.
Reportes: `R/resultados/auditoria_2026-10-28_final/`.

| Etapa de diagnóstico | Votos |
|---|---:|
| CSV original | 135,634 |
| `evaluation_order == 1` | 108,315 |
| Ambos modelos elegibles con al menos 1,000 participaciones | 106,630 |
| Solo votos decisivos (escenario histórico, no decisión final) | 77,863 |

Calcular el umbral sobre el archivo completo o sobre los primeros votos produce
los mismos conteos de retención en este CSV. Esto no determina qué universo
debe usarse en train/test: se debe coordinar con Mark sin usar test para
aprender la elegibilidad.

Hallazgos observados, no corregidos automáticamente:

- No se detectaron IDs repetidos ni filas completamente idénticas.
- Se detectaron 10 votos con el mismo modelo a ambos lados, sobre el CSV original.
- Entre las filas con `evaluation_order == 1`, hay 11 filas adicionales cuyo
  identificador de sesión ya aparece en otra de esas filas. Esto no significa
  necesariamente que sean votos duplicados: requiere revisión.
- `if_score` tiene 2 valores faltantes; no hay NA ni campos vacíos en las demás
  columnas. `language = und` aparece en 11,835 votos y se informa por separado.
- El hash MD5 del CSV antes y después coincide; ver `integridad.csv`.

Estos hallazgos no invalidan por sí solos el dataset ni autorizan eliminar filas.
Los escenarios conservan los casos señalados y no exportan una base limpia
definitiva. `won` se comprueba solo para votos decisivos; la política de empates
y `both_bad` sigue abierta en `docs/07`.

Código y documentación preparados con asistencia de ChatGPT/Codex.


## Base larga de Nessim para las regresiones (28/10/2026)

Generador: `R/01_preparar_datos.R`. Resultado:
`data/derivados/base_regresiones_2026-10-28_v2.csv.gz`.
Reportes: `R/resultados/base_regresiones_2026-10-28_v2/`.

- 106,630 votos tras filtrar primer voto y ambos modelos elegibles.
- 213,260 filas en formato largo, para 48 modelos.
- Se conservan 77,863 votos decisivos y los empates/both_bad sin decidir su politica.
- 28 votos seleccionados tienen alguna bandera de revision: mismo modelo o
  sesion con varios primeros votos. Se conservan; no son necesariamente duplicados.
- `won` vale 1/0 en votos decisivos y NA en los demas. La columna de medio
  punto es un escenario separado, no una decision aprobada.
- Se verificaron dos filas por voto, inversion de lados, suma de victorias
  igual a uno por voto decisivo y hash del original sin cambios.

La propuesta y el contrato de columnas estan en `docs/10-base-regresiones-nessim.md`.
No se entrenaron regresiones ni se hizo la particion train/test.

## Tabla de precios (`R/05_precios_modelos.R` → `data/derivados/precios_modelos_2026-10-28_v2.csv`)

Explicación completa en `docs/11-precios-y-costo.md`.

Precio de lista de cada uno de los 48 modelos, en dólares por 1 millón de tokens (entrada y salida), de la API del dueño del modelo, tarifa estándar, de **julio 2025** (la misma época de los votos). Se toman del archivo público de precios de LiteLLM en su versión del 24/7/2025 (commit fijo), porque las páginas oficiales ya muestran los precios de hoy.

- **35 de 48 modelos tienen precio oficial.** Claude Opus 4, Sonnet 4 y Haiku 3.5 se compararon con la página oficial de Anthropic y coinciden.
- **13 no tienen precio oficial:** 9 open-source (gemma, llama y qwen/qwq), 2 versiones experimentales que solo estuvieron en LMArena, minimax-m1 y hunyuan-turbos. Quedan vacíos con la razón en `notas`. Qué hacer con ellos lo decide el grupo.
- **Rango:** de 0.10 / 0.30 (Mistral Small) a 15 / 75 (Claude Opus 4) por millón de tokens de entrada / salida.
- **Ojo con o3:** OpenAI le bajó el precio el 10/6/2025, de 10 / 40 a 2 / 8. La tabla usa el de julio.
- **qwen-max** es el único con precio de oct 2026, porque no estaba en la versión de 2025.
- La v1 (`data/derivados/precios_modelos.csv`, PR #4) tiene los mismos precios con columnas en inglés. La v2 sigue el formato de `docs/tareas/marco.md` y es la que se usa.

## PRUEBA: costo por respuesta (`R/06_costo_por_respuesta.R` → `R/resultados/costo_por_modelo.csv`)

**Es una prueba, no un resultado para el profesor todavía.** El profesor dejó tokens y precio fuera por ahora (26/10).

- Costo de cada respuesta = tokens de la pregunta × precio de entrada + tokens de la respuesta × precio de salida.
- Votos: 1er voto, 48 modelos, conversaciones de 1 turno y sin votos con el mismo modelo a los 2 lados: **91,104 votos**. 35 de 48 modelos tienen costo.
- **Costo por 1,000 respuestas:** de 0.23 dólares (Mistral Small 3.1) a 41.78 (Claude Opus 4). Gemini 2.5 Pro, el que más gana (74.4% de los votos con ganador, conteo simple), cuesta 15.75. deepseek-r1-0528 gana 65.5% y cuesta 2.72. gemini-2.5-flash gana 63.9% y cuesta 4.04.
- **Límites:** los tokens de razonamiento no están en los datos (los modelos que razonan salen más baratos de lo real); los tokens los contó LMArena con 1 solo método; las respuestas largas ganan más (61.8%); el % de victorias no ajusta por el rival.


## Las 48 regresiones, 1 por modelo: actualizacion de Nessim (2/11/2026)

Tarea 1 de fase 2, issue #17. Se actualiza el codigo existente de Jaime en
`R/02_regresiones_por_modelo.R`; no se rehace la base ni se modifica `R/03`.

**Respuesta:** 1 victoria, 0 derrota y 0.5 empate o both_bad, por defecto
(`politica_empates = "medio_punto"`). Se usa `quasibinomial`; `"excluir"`
permanece como sensibilidad. **Predictores:** las 11 caracteristicas de la
pregunta, sin rival, tokens, precio ni variables de la respuesta. Un coeficiente
positivo aumenta el log-odds del puntaje esperado, manteniendo las demas
caracteristicas constantes; no es un efecto causal.

**Ajuste descriptivo con todos los meses (abril a julio):** 106,602 votos,
213,204 filas largas, 48 modelos y 576 coeficientes. Los 28 casos de revision
siguen excluidos como en el codigo anterior; no se toma una nueva decision de
limpieza. Se incluyen 28,759 votos no decisivos con medio punto. Las 48
regresiones convergen. Los archivos `coeficientes_por_modelo.csv` y
`rankings_ejemplo.csv` se regeneran con esta politica; la seccion anterior de
este documento conserva la evaluacion temporal de Mark.

**Ridge opcional:** `ajustar_modelos(datos, lambda = 0)` conserva el `glm`
anterior. Con lambda positivo penaliza solo los 11 efectos, nunca el intercepto
ni el control opcional de rival de los chequeos. El objetivo usa la suma de la
perdida logistica mas `lambda/2 * sum(beta_efectos^2)`, sin estandarizar.
No selecciona lambda: eso lo hace Mark usando train; su evaluacion actual
eligio lambda = 30 (`ridge_validacion_cruzada.csv`). Los ajustes ridge no
reportan p-valores ni errores estandar de un `glm` sin penalizacion.

**Top 3 para la herramienta:** `top3(caracteristicas, ajustes, precio_max = NULL)`
usa `ranking_real()` sobre las preguntas usadas en el ajuste, conservando las
combinaciones reales de caracteristicas. Solo recomienda modelos con al menos
100 votos en julio, segun `R/resultados/decisiones_2026-11-02/votos_por_mes.csv`.
`precio_max` filtra el precio de salida en USD por millon de tokens con la tabla
v2 de Marco; no es costo por respuesta. Sin presupuesto, se conservan modelos
con precio desconocido; con presupuesto, no se pueden comparar y se excluyen.
Puede devolver menos de tres si no hay candidatos suficientes. La funcion
implementa las preguntas reales que pide la ficha y usa las tarifas publicadas;
no interpreta la tarifa por token como costo real de una respuesta.

Top 3 del ajuste descriptivo, con el filtro de julio (puntajes, no precision):

| Escenario | 1o | 2o | 3o |
|---|---|---|---|
| codigo | gemini-2.5-pro (0.665) | grok-4-0709 (0.615) | o3-2025-04-16 (0.614) |
| math | gemini-2.5-pro (0.694) | grok-4-0709 (0.673) | minimax-m1 (0.635) |
| escritura_creativa | gemini-2.5-pro (0.698) | grok-3-preview-02-24 (0.623) | grok-4-0709 (0.615) |
| instrucciones | gemini-2.5-pro (0.674) | grok-4-0709 (0.624) | gemini-2.5-flash (0.604) |
| codigo_y_math | gemini-2.5-pro (0.673) | grok-4-0709 (0.657) | qwen3-235b-a22b (0.630) |
| todas | gemini-2.5-pro (0.684) | grok-4-0709 (0.641) | o3-2025-04-16 (0.619) |

Los puntajes con medio punto no son probabilidades de victoria exclusivamente
en votos decisivos. `rankings_ejemplo.csv` conserva tambien rankings tecnicos
sin el filtro de recomendaciones, incluidos los previews. No confundirlos.

**Evaluacion fuera de muestra:** se lee de `R/resultados/evaluacion.csv` de
Mark, no del ajuste descriptivo. Sobre los mismos 20,416 votos decisivos de
julio: 48 con medio punto, 13,298 aciertos (65.1%) y log-loss 0.6321;
Bradley-Terry general, 13,164 (64.5%) y 0.6340; porcentaje de victorias con
medio punto, 13,171 (64.5%) y 0.6378. La mejora en aciertos es pequena. En
log-loss es clara contra el porcentaje de victorias; contra Bradley-Terry el
intervalo de Mark llega a cero, asi que no se afirma una mejora clara.

**Reporte para el profesor:** `reporte/01_regresiones_48.Rmd` y su HTML, en
ingles simple. Contiene la respuesta, las 11 definiciones, el `glm` visible,
el `summary()` completo de tres ejemplos, heatmap de los 48, evaluacion leida
del CSV y el top 3. El codigo visible distingue el ajuste descriptivo del test.

**Reproducir:** `Rscript R/generar_reporte_48.R` (requiere Pandoc para HTML).
Reportes y controles en `R/resultados/regresiones_48_2026-11-02/`.
Pruebas: `Rscript R/probar_regresiones_48.R`. El chequeo de compatibilidad
corre el `R/03` intacto en una carpeta temporal y verifica que conserva los
resultados de Mark.

Limites: cada voto se usa dos veces en las regresiones independientes, solo
hay una particion temporal principal y cuatro modelos solo aparecen en julio.
La regresion combinada del issue #14 es una tarea posterior, fuera de este PR.

Actualizacion y reporte preparados con asistencia de ChatGPT/Codex, a partir
del codigo de Jaime y la evaluacion de Mark.

## Contexto y gráficos de Eli — ejecución del 28/10/2026

Generador: `R/04_contexto_y_graficos.R`, ejecutado con R 4.3.3 sobre el CSV
del repositorio. Resultados: `R/resultados/eli_contexto_2026-10-28_221546/`.
Gráficos: `R/resultados/graficos/eli_contexto_2026-10-28_221546/`.
Fuente externa archivada: `R/resultados/fuentes_eli_2026-10-28/`.

### Comparación histórica con LMArena

Se usa `lmarena-ai/leaderboard-dataset`, subconjunto `text_style_control`,
`full`, categoría `overall`. La publicación más reciente de julio disponible
en ese archivo hasta el cierre de votos (24/7/2025) es del **17/7/2025**.
No se presenta como un snapshot del día 24.

Nuestro ranking es el porcentaje descriptivo del Test 2: todos los votos,
mínimo de 200 participaciones, empates y both_bad cuentan como cero victorias.
No reemplaza el Bradley–Terry de train de Mark ni decide la política de empates
para las regresiones. Se usa el porcentaje sin redondear y rangos promedio
cuando hay empate exacto. Solo se unen IDs exactamente iguales, sin agrupar
versiones preview o thinking.

- Modelos coincidentes: **41**. Sin coincidencia: **11**, exportados aparte.
- Correlación de rangos de Spearman: **0.8641**.
- Los cambios de puesto se calculan dentro de los modelos comunes,
  no comparando posiciones de listas de distinto tamaño.

| Modelo | Puesto nuestro (comunes) | Oficial (comunes) | Nuestro − oficial |
|---|---:|---:|---:|
| claude-3-7-sonnet-20250219-thinking-32k | 32 | 17 | 15 |
| claude-3-7-sonnet-20250219 | 35 | 22 | 13 |
| claude-opus-4-20250514 | 19 | 7 | 12 |
| claude-opus-4-20250514-thinking-16k | 17 | 6 | 11 |
| claude-sonnet-4-20250514 | 27 | 16 | 11 |
| claude-sonnet-4-20250514-thinking-32k | 22 | 12 | 10 |

Un valor positivo significa peor posición en nuestro ranking. La correlación
no es precisión predictiva ni validación independiente: los datasets pueden
compartir votos. El ranking oficial ajusta por rival y estilo y usa otro
historial de votos. Nuestro periodo llega una semana después del snapshot.

### Largo de respuestas

Se reproduce el 61.8% del Test 3 (60,638 de 98,097 votos elegibles). En primer
voto da 62.4% (49,207 de 78,885). Solo votos con ganador y largos distintos.
Se exportan el desglose por tarea y `largo_por_modelo.csv`, con participaciones,
victorias e intervalos cuando cada modelo escribe más largo o más corto.
Los modelos están separados; se incluyen todos, sin el filtro de 48.
Las tareas se solapan. Primer voto es `evaluation_order == 1`, no una garantía
de sesión única. Se conservan los casos de revisión de Nessim.

La asociación no identifica un efecto causal. Los IC exactos binomiales son
nominales, sin ajuste por sesiones ni comparaciones múltiples. No se usa largo
como predictor ni se entrenan regresiones con variables de las respuestas.

Se generan top 15, dos gráficos del largo, dispersión de rangos y mapa de calor
modelo × característica. Este último usa una copia exacta de los coeficientes
publicados por Jaime en main; sus valores son cambios en log-odds, no
probabilidades ni efectos causales. No se reentrenan los modelos.

Fuentes oficiales:
- https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset
- https://arena.ai/blog/arena-leaderboard-dataset

Código y documentación preparados con asistencia de ChatGPT (OpenAI).

## Chequeo para cerrar las decisiones del 2/11 (`R/08_chequeo_decisiones.R`)

Las 48 regresiones ajustadas solo con train (abril a junio, 44 modelos) y evaluadas sobre los mismos 20,416 votos decisivos de julio que la línea base de Mark. Resultados en `R/resultados/decisiones_2026-11-02/`. Las decisiones que salen de acá están en `docs/12-decisiones-2-11.md`. **No es la evaluación oficial**: esa la hace Mark en `R/03`.

| Variante (julio) | Aciertos 48 | Aciertos base | Log-loss 48 | Log-loss base |
|---|---|---|---|---|
| Excluir empates | 65.15% | 64.47% | 0.6298 | 0.6340 |
| Medio punto | 65.16% | 64.51% | 0.6321 | 0.6378 |
| Medio punto + ridge λ=30 | 65.35% | 64.51% | 0.6321 | 0.6378 |

- Las 48 le ganan a la línea base en julio por unos 0.7 puntos de aciertos, y tienen mejores probabilidades (log-loss más bajo).
- Con una partición aleatoria 80/20 por sesión (5 semillas, los 48 modelos), en aciertos es un empate (de −0.70 a +0.30 puntos sin ridge, de −0.31 a +0.48 con ridge λ=30), pero el log-loss de las 48 es mejor en las 5.
- Controlar por el rival no mejora los aciertos y empeora el log-loss. Agrupar las 3 versiones de Gemini 2.5 Pro da lo mismo (65.13% contra 65.16%).
- Lectura: el modelo que es mejor en general gana casi siempre. Las características mejoran las probabilidades y cambian el orden debajo del 1º.
- La tabla de ridge mira julio, así que no sirve para elegir λ. Eso se hace con train (`docs/tareas/mark.md`).

## Exportaciones de Nessim: ficha de fase 1 (2/11/2026)

Generador: `R/01_preparar_datos.R`. Reportes:
`R/resultados/preparacion_ficha_2026-11-02/`.

| Archivo | Filas |
|---|---:|
| `data/derivados/votos_filtrados.csv` | 106,630 |
| `data/derivados/votos_largo.csv` | 213,260 |

Se mantienen 48 modelos y 77,863 votos decisivos. La base larga conserva
los empates y both_bad con `won = NA` y detalle en `resultado`, como pide
el contrato de exportacion de fase 1. Para el ajuste posterior rige la decision
del grupo de usar medio punto (`docs/12-decisiones-2-11.md`); se deriva desde
`resultado` sin cambiar estos CSV. Los 28 votos con banderas de revision se conservan
y se identifican en un reporte separado.

Validacion de los archivos escritos: el ancho conserva los campos y valores
originales de los votos seleccionados; cada voto produce dos filas en el largo,
con modelo y rival invertidos, mes, las once caracteristicas, tokens de la
pregunta e idioma. Se verifico el hash del original y no cambio.
La base comprimida de octubre tampoco se reemplazo.

No se modificaron las regresiones ni la evaluacion de otros integrantes.
Codigo y documentacion preparados con asistencia de ChatGPT/Codex.

## Marco, fase 2: `razona` y top 3 por presupuesto (2/11/2026)

Script: `R/06_costo_por_respuesta.R`. Detalle y cómo leerlo: `docs/11-precios-y-costo.md`, Partes 3 y 4.

- **`razona`** (`data/derivados/precios_modelos_2026-11-02_v4.csv`, igual a la v3 pero sin `disponible_gratis_en_app`, issue #15): 22 modelos razonan, 24 no y 2 quedan vacíos (los experimentales). Entre los 35 con precio: 17 si y 18 no. Fuente de cada uno en `notas`.
- **Top 3 por tarea y presupuesto** (versión del 2/11, reemplazada el 9/11 por la de abajo con binomial; guardada en `R/resultados/top3_por_precio_2026-11-02_medio_punto.csv`): las 48 regresiones de `R/02` con medio punto y todos los votos (106,602), probabilidad promedio sobre las preguntas reales de cada tarea, solo modelos con 100 o más votos en julio y con precio oficial. Presupuesto = precio de salida por millón: sin límite, hasta $10, $2 y $0.50.
- **gemini-2.5-pro es 1º en las 4 tareas** cuando entra en el presupuesto (68.4% en todas, $10).
- **Hasta $2:** gemini-2.5-flash-preview-04-17 es 1º en las 4 tareas (55.7% en todas). Su precio de $0.60 es sin razonamiento (con razonamiento era $3.50): decisión abierta en `docs/07`.
- **Hasta $10:** deepseek-r1-0528 ($2.19) queda a 1.4 puntos de o3 ($8) en todas las preguntas (60.5% contra 61.9%).
- minimax-m1 es 3º en math antes de filtrar por precio, pero no tiene precio oficial y no entra.

Código y documentación preparados con asistencia de Claude (Anthropic).


## Demostracion en vivo del grupo en RStudio (2/11/2026)

`R/00_demo_profesor.R` ajusta en memoria las 48 regresiones descriptivas,
los modelos de train con y sin ridge, Bradley-Terry general y el porcentaje
de victorias; evalua los mismos votos de julio con `R/03b_evaluar.R`.
La comprobacion de la demostracion reproduce los aciertos y el log-loss
guardados por Mark, incluidos los modelos con ridge. No modifica los datos
ni los CSV de resultados.

Muestra los coeficientes de todos los modelos, las predicciones individuales,
graficos de evaluacion, top 3 por presupuesto con precios de Marco y contexto
de largo de respuesta y ranking externo de Eli. No incluye como terminados
Bradley-Terry con covariables, Shiny ni dashboards.

Se abre con `Capstone.Rproj`; instrucciones en `docs/13-demostracion-rstudio.md`.
Codigo y guia preparados con asistencia de ChatGPT/Codex.

## Eli, fase 2: gráficos actualizados (4/11/2026)

`R/04_contexto_y_graficos.R` ejecuta ahora la fase 2 por defecto; la fase 1 permanece como `ejecutar_contexto_fase1()` sin repetirla. Carpeta: `R/resultados/graficos/eli_fase2_2026-11-04/`.

- Aciertos y log-loss: lee `R/resultados/evaluacion.csv` de Mark, sobre los mismos 20,416 votos decisivos de julio. Grafica las dos líneas base, las regresiones con medio punto y ridge. Los aciertos publicados son 64.5%, 64.5%, 65.1% y 65.3%; el log-loss es 0.6378, 0.6340, 0.6321 y 0.6321, respectivamente. No reentrena ni reemplaza la evaluación.
- La regresión combinada no tiene fila en esa evaluación todavía. Se muestra como pendiente y se incorporará cuando exista `combined_bradley_terry`, sin inventar resultados.
- Heatmap: usa las funciones actuales de `R/02`, medio punto, sin ridge y excluyendo los casos marcados para revisión. Se ajusta con todos los votos limpios de abril a julio. Incluye **46 modelos con 100 o más participaciones en julio**, contadas en la misma base larga del ajuste. Exporta coeficientes, matriz y auditoría de inclusión. No sobreescribe archivos de Nessim ni Mark. Colores: verde = mayor puntaje de preferencia, rojo = menor, manteniendo las otras características constantes. Coeficientes en log-odds, descriptivos, sin inferencia causal.
- Las métricas comparan las mismas observaciones; el Bradley-Terry general publicado excluye empates en el ajuste, mientras las variantes principales de regresiones y porcentaje de victorias usan medio punto. La mejora en aciertos es pequeña y no se exagera la evidencia en log-loss contra Bradley-Terry.

Update individual de 3 slides en inglés: `reporte/eli_update_2026-11-09.pptx`. Guía en español: `docs/avance-eli-fase2-2026-11-04.md`.
Código, gráficos, documentación y slides preparados con asistencia de ChatGPT (OpenAI).

## Fase 2b, tarea A de Nessim: regresiones binomiales (9/11/2026)

Según la decisión de la fase 2b, `R/02_regresiones_por_modelo.R` usa como
modelo principal `glm(..., family = binomial)` con votos decisivos
(victoria = 1, derrota = 0) y las mismas once características de la pregunta.
`preparar_respuesta(base, politica = "medio_punto")` conserva el ajuste
quasibinomial para sensibilidad. La opción ridge sigue disponible.

El ajuste descriptivo de abril a julio usa **77,843 votos decisivos**
(155,686 filas, después de excluir los casos marcados para revisión).
Convergen las **48 regresiones** y se exportan **576 coeficientes**,
incluidos los interceptos. Los coeficientes y rankings de ejemplo se
regeneran en `R/resultados/`. El top 3 y los controles están en
`R/resultados/regresiones_48_2026-11-09/`. El top 3 promedia las
probabilidades ajustadas sobre las preguntas decisivas con cada
característica y conserva el requisito de al menos 100 votos en julio.

La demo `R/10_demo_clase_48.R` ajusta de nuevo solo con abril a junio y
reproduce la fila binomial de la evaluación de Mark en los **20,416 votos**
decisivos de julio. El reporte actualizado lee esta misma evaluación.

| Método | Aciertos | Exactitud | Log-loss |
|---|---:|---:|---:|
| Bradley–Terry general | 13,164 | 64.5% | 0.6340 |
| Regresiones binomiales por modelo | 13,303 | 65.2% | 0.6298 |

Para regenerar: `Rscript R/generar_reporte_48.R`. Para probar y mostrar:
`Rscript R/probar_regresiones_48.R` y `Rscript R/10_demo_clase_48.R`.
El AUC con pROC corresponde a la tarea B de Mark (#32). Código y reporte
actualizados con asistencia de ChatGPT/Codex.

## Fase 2b, tarea B de Mark: AUC con pROC y 5-fold CV aleatorio (9/11/2026)

Script: `R/11_auc_proc.R`. Resultados: `R/resultados/auc/` (`folds_5.csv`, `por_voto.csv`, `por_modelo.csv`, `folds.csv` y la curva `curva_roc_cv5.png`, con sus puntos en `curva_roc_cv5.csv`). Todo el AUC se calcula con `pROC::roc()` y `pROC::auc()` (intervalos y prueba pareada de DeLong con `pROC::ci.auc()` y `pROC::roc.test()`). Sigue el plan de `docs/14`: primero todos los datos y después 5-fold CV con folds aleatorios por sesión. **Reemplaza la versión anterior de esta sección (PR #37, con julio como examen)**: julio ya no es la evaluación principal y `R/03` queda como resultado histórico. Los archivos `curva_roc_julio.*` de esa versión se dejan como historia y no se regeneran.

**Qué se mide.** El AUC dice qué tan bien un puntaje separa los votos que se ganan de los que se pierden: es la probabilidad de que, tomando 1 voto ganado y 1 perdido al azar, el ganado tenga el puntaje más alto. 0.5 es tirar una moneda y 1 es perfecto. Las regresiones son las 48 de `R/02` (1 por modelo, `glm(..., family = binomial)`, las mismas 11 características) con los votos decisivos: 77,843 votos (155,686 filas), sin los 28 marcados para revisión. Hay 2 tipos de AUC:

- **Por voto:** P(gana model_a) = `plogis(puntaje_A - puntaje_B)`, donde cada puntaje es el predictor lineal (logit) de la regresión de ese modelo con las características de la pregunta, contra si model_a ganó de verdad.
- **Por modelo:** el AUC de cada regresión con sus propias filas (ese modelo ganó 1 / perdió 0).

**Línea base: el ranking general** = % de victorias de cada modelo (votos ganados ÷ votos jugados, todos los tipos de pregunta juntos), calculado **solo con los folds de entrenamiento** (en el 5-fold, con los otros 4 grupos). Por voto es `plogis(logit(%_A) - logit(%_B))`, la misma línea base de `R/03`. **Solo existe por voto:** por modelo la línea base le da el mismo puntaje a todas sus filas, así que no tiene AUC.

**Los folds** (`R/resultados/auc/folds_5.csv`, columnas `id` y `fold`) se crean 1 sola vez en este script y todos los demás los usan (Nessim, Eli): nadie hace folds propios. Son 5 grupos al azar de **sesiones** (`evaluation_session_id`), con `set.seed(2026)`: las 2 filas de un voto y todos los votos de una sesión caen en el mismo fold, así el test nunca ve lo que el ajuste ya vio (el script lo comprueba en cada fold). El archivo cubre **los 106,630 votos de la base** (también empates, both_bad y los marcados), por si otra tarea los necesita: quedan 21,324 a 21,327 votos por fold. De ellos, los votos decisivos que usa el AUC quedan en 15,475 a 15,679 por fold. Si el archivo ya existe, el script lo lee y no lo sobrescribe.

**2 escenarios, en este orden.** (1) todos los datos, ajustando y midiendo en los mismos votos; (2) 5-fold CV: ajustar con 4 grupos, medir en el que sobra, 5 veces.

### AUC por voto

| Escenario | Votos | AUC 48 regresiones (IC 95%) | AUC ranking general (IC 95%) | Diferencia | p (DeLong, pareada) |
|---|---:|---|---|---:|---:|
| 1. Todos los datos | 77,843 | 0.7005 (0.6969 a 0.7042) | 0.6854 (0.6817 a 0.6891) | +0.0151 | < 0.0001 |
| 2. 5-fold, fold 1 | 15,569 | 0.6902 (0.6819 a 0.6984) | 0.6844 (0.6761 a 0.6927) | +0.0058 | 0.0018 |
| 2. Fold 2 | 15,560 | 0.6921 (0.6839 a 0.7003) | 0.6873 (0.6791 a 0.6956) | +0.0048 | 0.0091 |
| 2. Fold 3 | 15,475 | 0.6954 (0.6872 a 0.7036) | 0.6908 (0.6825 a 0.6990) | +0.0047 | 0.011 |
| 2. Fold 4 | 15,679 | 0.6779 (0.6696 a 0.6862) | 0.6735 (0.6652 a 0.6819) | +0.0044 | 0.018 |
| 2. Fold 5 | 15,560 | 0.6912 (0.6830 a 0.6994) | 0.6857 (0.6774 a 0.6940) | +0.0055 | 0.0025 |
| **2. Promedio de los 5 folds** (desv. estándar) | 77,843 | **0.6894** (0.0067) | 0.6843 (0.0065) | **+0.0050** (0.0006) | |

**Cómo leerlo:**
- **Las 48 regresiones le ganan al ranking general en los 5 folds, pero por poco:** entre +0.004 y +0.006 de AUC, +0.005 en promedio. La prueba pareada (que compara los mismos votos) da p menor a 0.02 en cada fold, pero los intervalos de las 2 líneas se traslapan. En aciertos prácticamente empatan: 49,801 votos bien con las regresiones contra 49,795 con el ranking general, de 77,843 (suma de los 5 folds).
- **Con votos que el ajuste no vio, el AUC baja 0.011** (0.7005 con todos los datos, 0.6894 en el 5-fold). Es una baja chica, y entre folds la variación también es chica (desviación 0.0067).
- Con un AUC cerca de 0.69, ambos métodos separan ganadores de perdedores bastante mejor que una moneda, pero lejos de perfecto.
- Los p-valores y los intervalos son nominales: no corrigen que los mismos modelos se repiten en muchos votos ni que cada voto se usa 2 veces al ajustar (el profesor lo sabe, `docs/04`).
- **No se deja fuera ningún voto:** con folds aleatorios las 48 regresiones existen en los 5 folds (incluidos los 4 modelos que solo aparecen en julio), así que los 77,843 votos decisivos son test de exactamente 1 fold.

### AUC por modelo (cada una de las 48 regresiones con sus propias filas)

Detalle de cada modelo y de cada fold en `R/resultados/auc/por_modelo.csv` (la fila `mean` es el promedio de sus 5 folds). Resumen (promedio simple entre modelos):

| Escenario | Modelos con AUC | AUC medio | Mínimo | Máximo | Modelos con AUC > 0.5 |
|---|---:|---:|---|---|---:|
| 1. Todos los datos | 48 | 0.5617 | 0.5276 (`qwq-32b`) | 0.6375 (`gemini-2.5-pro-preview-03-25`) | 48 de 48 |
| 2. 5-fold, promedio de los 5 folds de cada modelo | 48 | 0.5387 | 0.4917 (`kimi-k2-0711-preview`) | 0.5969 (`gemini-2.5-pro-preview-03-25`) | 46 de 48 |

- El AUC medio por fold va de 0.5339 a 0.5418 (promedio 0.5387, desviación 0.0031); en cada fold hay entre 38 y 46 modelos con AUC mayor que 0.5. Las regresiones por sí solas separan poco: las 11 características de la pregunta cambian la probabilidad de ganar de un modelo, pero no mucho.
- **Casos sin AUC (`NA`): ninguno.** En los 5 folds los 48 modelos tienen regresión y tienen victorias y derrotas en el test (el mínimo es 147 filas por modelo y fold), así que salen los 240 AUC (48 modelos × 5 folds), con 0 casos de 1 sola clase. `folds.csv` lleva este conteo por fold (`models_na_one_class`, `models_na_no_regression`, `models_na_no_rows`) y el script los cuenta si alguna vez aparecen.
- No hay comparación con la línea base en esta tabla: por modelo no existe (ver arriba).

### Curva ROC

`R/resultados/auc/curva_roc_cv5.png`: curva por voto de las 48 regresiones contra el ranking general, con las predicciones de los 5 folds juntas (cada voto predicho con regresiones ajustadas sin su fold). AUC de la curva: 0.6893 (regresiones) y 0.6843 (ranking general), casi igual que el promedio de los folds (0.6894 y 0.6843): juntar folds con regresiones distintas da una cifra apenas diferente. Las 2 curvas casi se superponen. Los puntos están en `curva_roc_cv5.csv`.

### Verificación

- Con todos los datos, el script da lo mismo que la versión anterior de esta sección: AUC 0.7005 y 0.6854, y 50,439 y 49,830 votos bien con las regresiones y el ranking general. Los AUC de los 48 modelos con todos los datos también son iguales a los de esa versión.
- Cada AUC de `pROC` se compara dentro del script con el AUC calculado con la fórmula de rangos (Mann-Whitney), y todos coinciden.
- Una segunda corrida lee `folds_5.csv` sin sobrescribirlo y todos los resultados salen idénticos.

Para regenerar (necesita el paquete `pROC`): `source("R/11_auc_proc.R")` desde la raíz del repo (~15 segundos). Script y documentación preparados con asistencia de Claude (Anthropic).

## Fase 2b, tarea D1 de Marco: top 3 por presupuesto con binomial (9/11/2026)

Script: `R/12_top3_por_precio.R` → `R/resultados/top3_por_precio.csv` (issue #34). Detalle y cómo leerlo: `docs/11-precios-y-costo.md`, Parte 4.

Las 48 regresiones de `R/02` con el modelo principal de la fase 2b (`glm(..., family = binomial)`, votos con ganador, sin los 28 de revisión, sin ridge), ajustadas con todos los votos de abril a julio (77,843). El top 3 sale de `top3()` de `R/02`: probabilidad de ganar promedio sobre las preguntas reales de cada tarea, solo modelos con 100 o más votos en julio y con precio oficial. Presupuesto = precio de lista por millón de tokens de salida (julio 2025). No es una evaluación, así que no usa los folds.

| Tarea (preguntas) | Presupuesto | 1º | 2º | 3º |
|---|---|---|---|---|
| Todas (77,843) | Sin límite | gemini-2.5-pro (74.2%, $10) | grok-4-0709 (68.8%, $15) | o3-2025-04-16 (65.8%, $8) |
|  | Hasta $10 | gemini-2.5-pro (74.2%, $10) | o3-2025-04-16 (65.8%, $8) | deepseek-r1-0528 (64.4%, $2.19) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (57.7%, $0.6) | gemini-2.5-flash-lite-preview-06-17-thinking (54.9%, $0.4) | deepseek-v3-0324 (54.6%, $1.1) |
|  | Hasta $0.50 | gemini-2.5-flash-lite-preview-06-17-thinking (54.9%, $0.4) | grok-3-mini-beta (50.9%, $0.5) | grok-3-mini-high (50.7%, $0.5) |
| Código (21,048) | Sin límite | gemini-2.5-pro (72.2%, $10) | grok-4-0709 (65.1%, $15) | o3-2025-04-16 (65.0%, $8) |
|  | Hasta $10 | gemini-2.5-pro (72.2%, $10) | o3-2025-04-16 (65.0%, $8) | deepseek-r1-0528 (63.7%, $2.19) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (54.5%, $0.6) | deepseek-v3-0324 (52.5%, $1.1) | grok-3-mini-high (51.9%, $0.5) |
|  | Hasta $0.50 | grok-3-mini-high (51.9%, $0.5) | grok-3-mini-beta (51.2%, $0.5) | gemini-2.5-flash-lite-preview-06-17-thinking (50.3%, $0.4) |
| Math (5,945) | Sin límite | gemini-2.5-pro (76.9%, $10) | grok-4-0709 (73.5%, $15) | gemini-2.5-flash (67.5%, $2.5) |
|  | Hasta $10 | gemini-2.5-pro (76.9%, $10) | gemini-2.5-flash (67.5%, $2.5) | o3-2025-04-16 (62.6%, $8) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (60.5%, $0.6) | gemini-2.5-flash-lite-preview-06-17-thinking (55.6%, $0.4) | grok-3-mini-high (51.6%, $0.5) |
|  | Hasta $0.50 | gemini-2.5-flash-lite-preview-06-17-thinking (55.6%, $0.4) | grok-3-mini-high (51.6%, $0.5) | grok-3-mini-beta (48.6%, $0.5) |
| Escritura creativa (6,514) | Sin límite | gemini-2.5-pro (75.7%, $10) | grok-3-preview-02-24 (66.3%, $15) | grok-4-0709 (63.9%, $15) |
|  | Hasta $10 | gemini-2.5-pro (75.7%, $10) | deepseek-r1-0528 (62.9%, $2.19) | gemini-2.5-flash (62.1%, $2.5) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (59.9%, $0.6) | gemini-2.5-flash-lite-preview-06-17-thinking (58.7%, $0.4) | deepseek-v3-0324 (57.5%, $1.1) |
|  | Hasta $0.50 | gemini-2.5-flash-lite-preview-06-17-thinking (58.7%, $0.4) | gemini-2.0-flash-001 (51.8%, $0.4) | grok-3-mini-high (47.7%, $0.5) |

- **El orden es el mismo que con medio punto (2/11) en los 48 puestos.** Las probabilidades suben porque ahora los empates no cuentan (por ejemplo, gemini-2.5-pro en todas: 68.4% → 74.2%).
- **gemini-2.5-pro es 1º en las 4 tareas** cuando entra en el presupuesto.
- **Hasta $10:** deepseek-r1-0528 ($2.19) queda a 1.4 puntos de o3 ($8) en todas las preguntas (64.4% contra 65.8%).
- **Hasta $2:** gemini-2.5-flash-preview-04-17 es 1º en las 4 tareas. Su $0.60 es sin razonamiento (con razonamiento, $3.50): sigue abierto en `docs/07`.

Código y documentación preparados con asistencia de Claude (Anthropic).

## Fase 2b, tarea D2 de Marco: esqueleto de la app Shiny (9/11/2026)

`app/app.R`, se abre con `shiny::runApp("app")` desde la raíz. Eliges las características de la pregunta y el presupuesto, y muestra el top 3 con `top3()` de `R/02` (binomial, mismos ajustes que `R/12`). No agrega números nuevos: en las 16 combinaciones de `R/resultados/top3_por_precio.csv` (4 tareas × 4 presupuestos) da los mismos modelos y probabilidades. Detalle en `docs/11`, Parte 5.

Código y documentación preparados con asistencia de Claude (Anthropic).

## Fase 2b, tareas A2 y E de Nessim: AUC en la demo y Bradley–Terry con covariables

La demo `R/10_demo_clase_48.R` lee la tabla por voto de Mark en
`R/resultados/auc/por_voto.csv`. Muestra el ajuste con todos los datos, el AUC
de cada fold reservado y su promedio. La prueba de julio aparece como
resultado histórico.

`R/07_bradley_terry_covariables.R` ajusta una regresión con una fila por voto.
Cada modelo tiene una fuerza base y un ajuste por cada una de las 11
características de la pregunta. La diferencia de fuerzas entre A y B
determina la predicción, así que el ajuste toma en cuenta al rival de ese
voto. Claude Opus 4 es la referencia y el modelo se ajusta sin intercepto.

Para el ajuste, una victoria de A vale 1, una de B vale 0 y un empate o
`both_bad` vale 0.5, como pide la ficha para esta regresión combinada.
`glmnet` recibe esos resultados como dos proporciones por voto. Ridge
penaliza las interacciones con las características y deja libres las fuerzas
base. Se elige λ por log-loss de votos decisivos, usando solo los folds de
entrenamiento en cada vuelta externa. Todas las particiones provienen de
`R/resultados/auc/folds_5.csv`.

El AUC de `pROC` usa los mismos votos decisivos por fold que Mark. La
comparación es entre dos procedimientos completos, pues las 48 regresiones
se ajustan solo con decisivos y Bradley–Terry incluye medios puntos. El AUC
con todos los datos es descriptivo. El promedio de los folds mide el
desempeño en sesiones reservadas. Los resultados se guardan en
`R/resultados/bradley_terry/por_voto.csv`, con aciertos y log-loss para
Bradley–Terry. La tabla histórica de julio sigue en su propio CSV.

| Evaluación | Votos | AUC Bradley–Terry | AUC 48 regresiones | AUC ranking general |
|---|---:|---:|---:|---:|
| Todos los datos (descriptivo) | 77,843 | 0.7002 | 0.7005 | 0.6854 |
| Fold 1 | 15,569 | 0.6914 | 0.6902 | 0.6844 |
| Fold 2 | 15,560 | 0.6935 | 0.6921 | 0.6873 |
| Fold 3 | 15,475 | 0.6973 | 0.6954 | 0.6908 |
| Fold 4 | 15,679 | 0.6788 | 0.6779 | 0.6735 |
| Fold 5 | 15,560 | 0.6934 | 0.6912 | 0.6857 |
| Promedio de los cinco folds | 77,843 | 0.6909 | 0.6894 | 0.6843 |

La mejora media frente a las 48 regresiones fue de 0.0015 de AUC. En los
folds reservados, Bradley–Terry acertó 49,870 de 77,843 votos (64.06%) y
obtuvo un log-loss de 0.6390.

`R/resultados/bradley_terry/top3_por_tarea.csv` compara ambos rankings sobre
las mismas preguntas decisivas y con la misma regla de elegibilidad de
`top3()`. El puntaje de Bradley–Terry promedia su predicción frente a Claude
Opus 4 para todas las preguntas de cada tarea. Es un puntaje esperado con
medio punto para empates. Gemini 2.5 Pro quedó primero en los seis
escenarios con ambos métodos. El único cambio en el top 3 fue el tercer
puesto en matemáticas: MiniMax M1 entró en lugar de Gemini 2.5 Flash.

Para reproducir, desde la raíz se ejecutan `Rscript R/07_bradley_terry_covariables.R`
(requiere Matrix, glmnet y pROC) y `Rscript R/10_demo_clase_48.R`.
Código y documentación preparados con asistencia de ChatGPT/Codex.


## Eli, fase 2b: sensibilidad de coeficientes, AUC y ROC (C1/C1b/C2, 9/11/2026)

Generador completo: `Rscript R/12_sensibilidad.R`. La sección de AUC/ROC
también puede correrse sola: `Rscript R/13_sensibilidad_auc_roc.R`. Requiere
MASS y pROC. Se conserva C1 del PR #36 (cerrado sin fusionar) y se completa
el issue #33. No se modifican R/02, R/11, sus resultados ni las decisiones del grupo.

### C1: coeficientes

Los 48 modelos usan las mismas 11 características, sin rival ni ridge.
Binomial usa 77,843 votos decisivos; quasibinomial y ordinal incluyen
28,759 no decisivos, para un total de 106,602 votos tras excluir los mismos
28 casos marcados de R/02. Empate y both_bad se agrupan como empate en ordinal.
Los 144 ajustes descriptivos convergen. Resultados en
`R/resultados/sensibilidad_2026-11-09/`: coeficientes, interceptos/umbrales,
correlaciones por modelo y controles.

| Comparación (11 efectos por modelo) | Modelos | Pearson mín. | Mediana | Máx. | Spearman mediana | Signos iguales |
|---|---:|---:|---:|---:|---:|---:|
| binomial_vs_quasibinomial | 48 | 0.9188 | 0.9974 | 0.9997 | 0.9909 | 508/528 |
| binomial_vs_ordinal | 48 | 0.8443 | 0.9938 | 0.9992 | 0.9818 | 500/528 |
| quasibinomial_vs_ordinal | 48 | 0.9870 | 0.9992 | 0.9999 | 0.9955 | 520/528 |

Las correlaciones comparan los 11 efectos dentro de cada modelo.
Los interceptos y umbrales ordinales no son equivalentes y se exportan aparte.
Correlación alta no implica igualdad de coeficientes ni equivalencia predictiva.

### C1b: AUC con los folds oficiales de Mark

Se lee `R/resultados/auc/folds_5.csv` sin modificarlo ni generar folds nuevos.
Se verifica una asignación por voto y sesión; cada fold se evalúa sin usar
sus votos ni sus sesiones en entrenamiento. Quasibinomial y ordinal usan los
empates de los cuatro folds de entrenamiento; los tres métodos se evalúan
sobre las mismas filas decisivas del fold excluido. Primero se ajusta/mide
con todos los datos y después se hace la CV. Los 864 ajustes de esta sección
convergen (48 modelos × 3 métodos × 6 escenarios de ajuste).

**AUC por voto:**

| Método | Todos (ajuste) | Fold 1 | Fold 2 | Fold 3 | Fold 4 | Fold 5 | Media CV |
|---|---:|---:|---:|---:|---:|---:|---:|
| binomial | 0.7005 | 0.6902 | 0.6921 | 0.6954 | 0.6779 | 0.6912 | 0.6894 |
| quasibinomial | 0.7004 | 0.6900 | 0.6923 | 0.6955 | 0.6780 | 0.6917 | 0.6895 |
| ordinal | 0.7002 | 0.6898 | 0.6924 | 0.6954 | 0.6779 | 0.6917 | 0.6895 |
| general_ranking | 0.6854 | 0.6844 | 0.6873 | 0.6908 | 0.6735 | 0.6857 | 0.6843 |

Por modelo, el promedio de sus cinco AUC y después de los 48 modelos es
0.5387 (binomial), 0.5390 (quasibinomial) y 0.5391 (ordinal). Se exportan
720 AUC de modelo/fold (48 × 3 × 5); **ningún caso NA por una sola clase**
en esta base. El código deja NA si no hay dos clases y cuenta los casos.
La línea base solo se compara por voto; sus tasas se calculan con entrenamiento.

**Cómo se obtiene el puntaje ordinal:** se calcula
`P(mejor) + 0.5 * P(empate)` con las probabilidades de polr y se toma su logit.
Es una extensión explícita del puntaje de medio punto, no el predictor lineal
de polr ni una probabilidad pura de victoria decisiva. Dentro de cada modelo
es monótono en el predictor latente y conserva su AUC. Por voto se aplica
`plogis(puntaje_A - puntaje_B)`, como para las otras variantes; esta comparación
ordinal depende de la conversión documentada. No se cambia binomial como principal.

Las diferencias de AUC medio entre las tres variantes son menores que 0.0002.
Es un chequeo de sensibilidad descriptivo: no demuestra equivalencia estadística
ni justifica cambiar la decisión del grupo. Todos los datos es evaluación dentro
de muestra; la media CV usa cinco AUC de votos no vistos en su ajuste.
No se repite julio ni se agregan p-valores.

Salidas de C1b/C2: `R/resultados/sensibilidad_auc_2026-11-09/`.
Incluye AUC por voto, por modelo/fold y promedios, convergencia, tabla y versiones.
Cada AUC se verifica contra la fórmula de rangos; binomial/base y los AUC
binomiales por modelo reproducen los CSV de Mark dentro del redondeo publicado.

### C2: gráfico para la presentación

`roc_presentacion.pdf` es una figura vectorial en inglés simple. Redibuja los
puntos oficiales `curva_roc_cv5.csv` y comprueba esos puntos contra las
predicciones binomiales fuera de fold. Las curvas casi se superponen:
AUC agrupado 0.6893 (características) y 0.6843 (ranking general). Se distingue
este AUC agrupado de la media de los cinco folds (0.6894 y 0.6843).
Los ejes explican qué se detecta y qué es una falsa alarma; se aclara que AUC
no es porcentaje de aciertos. PDF revisado visualmente.

Ejecución completa con R 4.3.3, MASS 7.3-60 y pROC 1.18.5. Los hashes de
data/, entregas/ y todas las salidas de Mark (incluidos los folds) no cambian.
Código, gráfico y documentación preparados con asistencia de ChatGPT/Codex (OpenAI).
