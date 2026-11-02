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

## Chequeo de asignación aleatoria (para la pregunta del profesor del 19/10)

Para cada modelo, qué % de sus votos tuvo cada tipo de pregunta. Modelos con 1,000 o más votos.

| Tipo de pregunta | Total | Mínimo por modelo | Máximo por modelo |
|---|---|---|---|
| Código | 29.0% | 26.4% (claude-3-7-sonnet-thinking) | 35.2% (o3) |
| Math | 8.0% | 5.2% (magistral-medium) | 11.2% (gemini-2.5-pro-preview-03-25) |
| Escritura creativa | 8.5% | 7.8% | 10.9% (grok-4) |
| Seguir instrucciones | 18.2% | 16.2% | 21.9% |
| Difícil (6+ de 7 criterios) | 37.5% | 33.0% (deepseek-r1) | 43.1% (magistral-medium) |

La variación entre modelos es entre 1.2 y 2.7 veces lo que daría el puro azar, según el tipo de pregunta, y se mantiene mirando solo junio. Es un desbalance real pero moderado, y por eso las características entran como predictores.

Cobertura: de 2,048 combinaciones posibles de las 11 etiquetas, aparecen 843, y 120 cubren el 90% de los votos. Agrupando en 10 tipos de tarea, los 48 modelos con 1,000 o más votos tienen votos en los 10. El caso más flojo es hunyuan-turbos, con 16 votos en un tipo.

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


## Las 48 regresiones, 1 por modelo (`R/02_regresiones_por_modelo.R`)

Para cada uno de los 48 modelos, una regresión logística con todos los votos donde aparece. **Respuesta:** `won` (1 si ganó, 0 si perdió). **Predictores:** las 11 características TRUE/FALSE de la pregunta. Base: la de Nessim (`docs/10`), solo votos decisivos (decisión abierta #1, el script tiene `politica_empates` para cambiarlo) y sin los 28 votos que Nessim marcó para revisar (10 de un modelo contra sí mismo). Quedan **77,843 votos** (155,686 filas). Las 48 convergen.

- Coeficientes: `R/resultados/coeficientes_por_modelo.csv` (48 modelos × 12 términos = 576 filas, con error estándar y p-valor).
- Rankings: `R/resultados/rankings_ejemplo.csv`, top 10 por escenario.

**Cuidado con los escenarios "solo esta característica".** Casi ninguna pregunta real tiene 1 sola característica. Una pregunta de código casi siempre también es `problem_solving`, `technical_accuracy`, etc. Votos que calzan exactamente: solo código 449, solo math 21, solo escritura creativa 513, código + math 10. Por eso cada escenario tiene 2 versiones:

- `solo_estas`: una pregunta con solo esas características en TRUE (lo que pedía la ficha).
- `preguntas_reales`: el promedio de la probabilidad de ganar sobre todas las preguntas reales que tienen esas características (el resto puede ser cualquier cosa). Es la que tiene sentido presentar.

Top 3 con `preguntas_reales` (ajuste con todos los votos, abril a julio):

| Escenario | Preguntas | 1º | 2º | 3º |
|---|---|---|---|---|
| Código | 21,048 | gemini-2.5-pro (72.2%) | gemini-2.5-pro-preview-03-25 (65.6%) | grok-4-0709 (65.1%) |
| Math | 5,945 | gemini-2.5-pro (76.9%) | grok-4-0709 (73.5%) | gemini-2.5-pro-preview-03-25 (71.9%) |
| Escritura creativa | 6,514 | gemini-2.5-pro (75.7%) | gemini-2.5-pro-preview-03-25 (74.6%) | grok-3-preview-02-24 (66.3%) |
| Código + math | 1,491 | gemini-2.5-pro (74.8%) | grok-4-0709 (70.5%) | gemini-2.5-pro-preview-03-25 (69.2%) |
| Todas | 77,843 | gemini-2.5-pro (74.2%) | grok-4-0709 (68.8%) | gemini-2.5-pro-preview-03-25 (67.3%) |

grok-4-0709 (931 votos) y gemini-2.5-pro-preview-03-25 (796) tienen pocos votos, así que su posición es inestable. Las 3 versiones de Gemini 2.5 Pro aparecen por separado porque agruparlas es la decisión abierta #2.

La evaluación contra julio y contra la línea base la hace Mark en `R/03_evaluacion.R` con `ajustar_modelos()` y `probabilidad()`. Para cargar solo las funciones: `options(correr_02 = FALSE); source("R/02_regresiones_por_modelo.R")`.


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
