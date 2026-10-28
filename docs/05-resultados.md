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

**Ranking general** (`R/resultados/ranking_general_train.csv`). Bradley-Terry sin características (1 voto decisivo = 1 fila, respuesta = ganó model_a, 1 columna por modelo con +1 / −1 / 0, sin intercepto), ajustado solo con train y 44 modelos (los otros 4, grok-3-mini-high, grok-4-0709, kimi-k2-0711-preview y mistral-small-2506, solo aparecen en julio). Referencia (fuerza 0): claude-opus-4-20250514, el modelo con más votos en train. Top 5:

| Rank | Modelo | Fuerza | Votos en train |
|---|---|---|---|
| 1 | gemini-2.5-pro | 1.098 | 3,522 |
| 2 | gemini-2.5-pro-preview-03-25 | 0.756 | 796 |
| 3 | gemini-2.5-pro-preview-05-06 | 0.668 | 1,939 |
| 4 | deepseek-r1-0528 | 0.636 | 2,912 |
| 5 | o3-2025-04-16 | 0.610 | 3,058 |

**Línea base en julio** (`R/resultados/test_baseline_ranking_general.csv`). En cada voto decisivo de julio se predice que gana el modelo de mayor fuerza. De 25,649 votos decisivos, 5,233 se quedan fuera porque incluyen un modelo que no está en train. Se evalúan 20,416 votos y se acierta en 13,164: **64.5%** (IC 95%: 63.8% a 65.1%). Coincide con el 64.5% sobre 20,416 votos de la prueba anterior.

Empates y both_bad quedan **excluidos** del ajuste, que es lo usado hasta ahora. Es la decisión abierta #1 de `docs/07`: el script tiene el parámetro `tie_handling` para cambiarlo a medio punto cuando el grupo decida.

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
