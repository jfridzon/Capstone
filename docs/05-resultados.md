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

Empates y both_bad quedan **excluidos** del ajuste, que es lo usado hasta ahora. Es la decisión abierta #1 de `docs/07`: el script tiene el parámetro `tie_handling` para cambiarlo a medio punto cuando el grupo decida.

**Segunda línea base: % de victorias general** (`R/resultados/winrate_general_train.csv` y `R/resultados/evaluacion.csv`). Es la que pide la ficha de Mark (`docs/tareas/mark.md`): para cada modelo, votos ganados ÷ votos jugados en train, con todos los tipos de pregunta juntos, sobre los mismos 52,208 votos del ajuste anterior. En cada voto de julio se predice que gana el modelo con mayor %. No toma en cuenta contra quién jugó cada modelo (`docs/04`, nivel 1). Top 3 en train: gemini-2.5-pro (74.8%), gemini-2.5-pro-preview-03-25 (67.2%) y gemini-2.5-pro-preview-05-06 (65.3%).

Las dos líneas base se evalúan sobre los mismos 20,416 votos de julio:

| Línea base | Aciertos | % | IC 95% |
|---|---|---|---|
| Bradley-Terry (sin características) | 13,164 | 64.5% | 63.8% a 65.1% |
| % de victorias | 13,162 | 64.5% | 63.8% a 65.1% |

Dan prácticamente lo mismo: solo se separan en 210 de los 20,416 votos. Para comparar las 48 regresiones basta usar cualquiera de las dos como línea base. `evaluacion.csv` tiene una fila por método; la regresión combinada se agrega ahí cuando exista.

### Las 48 regresiones contra las líneas base (julio)

Es la evaluación de "nuestro método" que pide la ficha de Mark. `R/03_evaluacion.R` carga las funciones de `R/02_regresiones_por_modelo.R` (Jaime), ajusta las regresiones **solo con train** y, en cada voto de julio, calcula la probabilidad de ganar de `model_a` y de `model_b` con las 11 características de esa pregunta. Se predice que gana el de mayor probabilidad. Los modelos entrenados son 44 (los 4 que solo aparecen en julio no tienen regresión) y los votos evaluados son los mismos 20,416 de las líneas base. Las 44 regresiones convergen y la más chica usa 523 votos. Usan 52,194 votos de train, 14 menos que las líneas base: son votos de sesiones con varios "primeros votos" que Nessim marcó para revisión y que `R/02` deja fuera (todos están en train, así que julio no cambia).

| Método | Aciertos | % | IC 95% |
|---|---|---|---|
| Línea base: Bradley-Terry | 13,164 | 64.5% | 63.8% a 65.1% |
| Línea base: % de victorias | 13,162 | 64.5% | 63.8% a 65.1% |
| **48 regresiones (11 características)** | **13,303** | **65.2%** | 64.5% a 65.8% |
| 48 regresiones + fuerza del rival (chequeo) | 13,302 | 65.2% | 64.5% a 65.8% |

Los intervalos se traslapan porque se evalúan los mismos votos, así que se comparan voto por voto (`R/resultados/evaluacion_pareada.csv`). Contra el % de victorias hay 1,226 votos que solo acierta la regresión y 1,085 que solo acierta el % de victorias: **+0.69 puntos** (IC 95%: +0.23 a +1.15; p = 0.0036). Contra Bradley-Terry: +0.68 puntos (IC 95%: +0.22 a +1.14; p = 0.0042). Como el % de victorias es lo mismo que una regresión sin características, esa diferencia es lo que aportan las 11 características.

**Cómo leerlo:**
- La mejora es **pequeña**: unos 140 votos más acertados de 20,416 (1 de cada 145). Va en la dirección que esperaba el método, pero la precisión sigue cerca de 65%: gemini-2.5-pro sale 1º o 2º en casi todos los tipos de pregunta (`docs/01`), así que el orden de los modelos cambia poco de una tarea a otra.
- Los p-valores y los intervalos son nominales: no corrigen que los mismos modelos se repiten en muchos votos ni que cada voto se usa 2 veces al ajustar (el profesor lo sabe, `docs/04`).
- Es 1 sola partición (entrenar con abril a junio, evaluar en julio) y julio no incluye grok-4, kimi-k2, mistral-small-2506 ni grok-3-mini-high (decisión abierta #4 de `docs/07`). Los 5,233 votos de julio que los incluyen quedan fuera de todas las comparaciones.
- **Fuerza del rival (decisión abierta #5, sigue abierta):** agregar el % de victorias general del rival como 12º predictor, calculado solo con train, no cambia nada: 13,302 contra 13,303 aciertos, y se reparten 582 contra 583 votos de diferencia. Es información para el grupo, no una decisión.
- **Por tipo de pregunta** (`R/resultados/evaluacion_por_tarea.csv`, descriptivo; las etiquetas se solapan y son 4 grupos, así que uno puede salir mejor por azar):

| Grupo (votos de julio) | Bradley-Terry | % de victorias | 48 regresiones |
|---|---|---|---|
| Todos (20,416) | 64.5% | 64.5% | 65.2% |
| Código (5,502) | 63.2% | 63.0% | 64.1% |
| Math (1,409) | 65.9% | 65.6% | 66.7% |
| Escritura creativa (1,621) | 61.2% | 61.1% | 63.0% |
| Seguir instrucciones (3,215) | 62.9% | 62.6% | 64.9% |

Las regresiones quedan arriba en los 4 grupos, con más diferencia en escritura creativa (+1.9 puntos contra el % de victorias) y seguir instrucciones (+2.3) que en código y math (+1.1 en ambos). Con 1,409 a 1,621 votos en math y escritura creativa, esas diferencias por grupo no son concluyentes por sí solas.

Para la decisión abierta #6 de `docs/07` (qué hacer si no le ganamos al ranking general): en esta prueba sí le ganamos, por poco.

Con las 10 cajas (ya descartadas) la diferencia era 64.7% contra 64.5%. Ese número viene de un análisis que todavía no está en `R/`, así que no lo reproduje y no lo comparo directamente con estos.

Pendiente: la regresión combinada (Bradley-Terry con covariables, `docs/04`) como comparación, evaluada igual sobre julio.

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

## Tabla de precios (`R/05_precios_modelos.R` → `data/derivados/precios_modelos.csv`)

Precio de lista de cada uno de los 48 modelos, en dólares por 1 millón de tokens (entrada y salida), de la API del dueño del modelo, tarifa estándar. Los precios salen del archivo público de precios de LiteLLM en su versión del **24/7/2025** (el último día de nuestros datos), así que son los de la misma época de los votos. El script baja esa versión fija, así que cualquiera obtiene los mismos números.

- **35 de 48 modelos tienen precio oficial.** Claude Opus 4, Sonnet 4 y Haiku 3.5 se compararon con la página oficial de Anthropic y coinciden.
- **13 no tienen precio oficial:** 9 open-source (gemma, llama y qwen/qwq, que cada proveedor cobra distinto), 2 versiones experimentales que solo estuvieron en LMArena, minimax-m1 y hunyuan-turbos (no encontramos una fuente verificable). Quedan vacíos con la razón en la columna `nota`. Qué hacer con ellos lo decide el grupo.
- **Rango:** de 0.10 / 0.30 (Mistral Small) a 15 / 75 (Claude Opus 4) por millón de tokens de entrada / salida.
- **Ojo con o3:** OpenAI le bajó el precio el 10/6/2025, de 10 / 40 a 2 / 8. La tabla usa el de julio.
- **Ojo con los modelos que razonan** (thinking, o3, deepseek-r1, etc.): el precio por token es igual, pero gastan más tokens de salida. El costo real por pregunta no sale solo de esta tabla.
- **qwen-max** es el único con precio de oct 2026, porque no estaba en la versión de 2025.

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
