# 11. Entrega de Marco: tabla de precios y prueba de costo

Preparada el 28/10/2026 y ampliada el 2/11/2026 (fase 2: columna `razona` y top 3 por presupuesto), con asistencia de Claude (Anthropic). Corresponde a la tarea 4 de `docs/07` y a la ficha `docs/tareas/marco.md`.
Este documento es para que cualquiera del grupo pueda **explicar en persona** qué se hizo, de dónde salen los números y qué límites tienen.

## En 30 segundos

1. Hicimos una tabla con el **precio de cada uno de los 48 modelos**: cuántos dólares cobra la compañía por 1 millón de tokens que entran (la pregunta) y por 1 millón que salen (la respuesta).
2. Usamos los precios de **julio 2025**, la misma época de los votos, y no los de hoy.
3. **35 de 48 tienen precio oficial.** Los otros 13 quedan vacíos y la tabla explica por qué.
4. Como **prueba**, multiplicamos esos precios por los tokens de cada respuesta de los datos y sacamos **cuánto cuesta cada modelo por cada 1,000 respuestas**.
5. Nada de esto entra en las regresiones. El profesor dejó el precio para después (26/10).
6. **Fase 2 (2/11):** agregamos si cada modelo **razona** antes de responder (sí/no, con fuente) y armamos el **top 3 por tarea dentro de cada presupuesto** con las 48 regresiones de Jaime. Es la tabla central de la presentación (decisión 6 de `docs/12`).

## Archivos

| Archivo | Qué es |
|---|---|
| `R/05_precios_modelos.R` | Script que arma la tabla de precios |
| `data/derivados/precios_modelos_2026-11-02_v4.csv` | **La tabla que se usa**: la v2 + la columna `razona`, sin `disponible_gratis_en_app` (issue #15) |
| `data/derivados/precios_modelos_2026-11-02_v3.csv` | Versión 3 (PR #25): igual a la v4 pero todavía con `disponible_gratis_en_app` vacía. Se deja porque en `data/` no se sobrescribe nada |
| `data/derivados/precios_modelos_2026-10-28_v2.csv` | Versión 2 (PR #9), formato de la ficha. Mismos precios que la v3 |
| `data/derivados/precios_modelos.csv` | Versión 1 (PR #4), mismos precios con columnas en inglés. Se deja porque en `data/` no se sobrescribe nada |
| `R/06_costo_por_respuesta.R` | Script de la v4 (`razona`) y la prueba de costo |
| `R/12_top3_por_precio.R` | Script del top 3 por presupuesto (fase 2b, binomial) |
| `app/app.R` | Esqueleto de la app Shiny (fase 2b, D2): características + presupuesto → top 3 |
| `R/17_top3_en_vivo.R` | Top 3 en vivo en la consola, para la demo del 16/11 |
| `R/resultados/costo_por_modelo.csv` | Resultado de la prueba: costo por 1,000 respuestas de cada modelo |
| `R/resultados/top3_por_precio.csv` | Top 3 por tarea dentro de cada presupuesto (binomial, 9/11) |
| `R/resultados/top3_por_precio_2026-11-02_medio_punto.csv` | Versión anterior, con medio punto (2/11) |

Para correrlos, desde la raíz del repo, en orden:

```r
source("R/05_precios_modelos.R")     # necesita internet y el paquete jsonlite
source("R/06_costo_por_respuesta.R") # solo R base, usa las funciones de R/02 (unos 20 segundos)
source("R/12_top3_por_precio.R")      # solo R base, top 3 por presupuesto con binomial (unos 30 segundos)
```

`R/05` se detiene si la tabla v2 ya existe, para no sobrescribirla. `R/06` arma la v4 a partir de la v2.

## Parte 1: la tabla de precios

### Qué es un token

Un token es un pedazo de texto, más o menos 3/4 de una palabra en inglés. Las compañías cobran por token: un precio por los que les mandas (entrada) y otro, más caro, por los que escribe el modelo (salida).

### Columnas

| Columna | Qué tiene |
|---|---|
| `modelo` | Nombre exacto como aparece en los datos, para poder unir las tablas |
| `compania` | Dueño del modelo |
| `precio_entrada_usd_por_millon` | Dólares por 1 millón de tokens de entrada |
| `precio_salida_usd_por_millon` | Dólares por 1 millón de tokens de salida |
| `disponible_gratis_en_app` | Solo en v2 y v3, vacía. **Se eliminó en la v4** (issue #15: no hay fuente confiable de julio 2025). En su lugar va `razona` |
| `fuente_url` | Página oficial de precios de la compañía |
| `fecha_consulta` | Cuándo armamos la tabla (28/10/2026) |
| `notas` | Aclaraciones, o por qué un modelo no tiene precio |
| `tiene_precio_oficial` | si / no |
| `fecha_del_precio` | De cuándo es el precio (casi todos 24/7/2025) |
| `fuente_datos` | De qué archivo exacto sale el número (ver abajo) |
| `votos_1er_voto` | Cuántos votos tiene el modelo, para saber cuánto pesa |

### De dónde salen los precios (la pregunta que más van a hacer)

- Las páginas oficiales de precios **muestran los precios de hoy**, no los de julio 2025. Algunos cambiaron: por ejemplo, OpenAI bajó o3 de 10 / 40 a 2 / 8 el 10/6/2025.
- Por eso usamos **LiteLLM**, una librería open-source muy usada que guarda en un archivo público el precio oficial de cada modelo, con historial de cambios en GitHub. Tomamos la versión del **24/7/2025**, el último día de nuestros datos.
- El script baja siempre esa misma versión (commit `8aa4bef`), así que **cualquiera que lo corra obtiene los mismos números**.
- Comprobación: Claude Opus 4, Sonnet 4 y Haiku 3.5 se compararon con la página oficial actual de Anthropic, que todavía los muestra, y coinciden.
- Única excepción: **qwen-max** no estaba en la versión de 2025, así que tiene el precio de oct 2026.

Cómo decirlo en inglés: *"We used each company's official list price from July 2025, the same period as the votes. Since the official pages now show today's prices, we took the July 2025 values from LiteLLM, a public open-source price file with full version history."*

### Los 13 modelos sin precio y por qué

| Grupo | Modelos | Por qué no tienen precio |
|---|---|---|
| Open-source de Meta | llama-3.3-70b, llama-4-maverick, llama-4-scout | Meta no los vende. Muchos proveedores sí (AWS, Google, Groq...), cada uno con su precio |
| Open-source de Google | gemma-3-27b, gemma-3n | Google da gemma-3-27b gratis con límites. gemma-3n no tiene precio en ningún lado |
| Open-source de Alibaba | qwen3-235b (2 versiones), qwen3-30b, qwq-32b | Alibaba los vende, pero no encontramos el precio de 2025 en una fuente que se pueda verificar |
| Experimentales | llama-4-maverick-03-26-experimental, amazon-nova-experimental | Solo existieron en LMArena |
| Otros | minimax-m1, hunyuan-turbos | Solo hay precios en páginas de terceros sin fecha, o en yuanes sin fuente clara |

**No inventamos ni estimamos ningún precio.** Decidido el 2/11 (issue #15): los 13 se quedan en la tabla con `tiene_precio_oficial = no`, quedan fuera del top 3 por precio, y no se usan precios de otros proveedores.

### Cosas a saber de algunos precios

- **Modelos "thinking"** (Claude thinking, o3, deepseek-r1...): cobran lo mismo por token que la versión normal, pero escriben muchos tokens de razonamiento que no se ven. Esos tokens se cobran como salida.
- **gemini-2.5-flash-preview-04-17:** 0.60 es la salida sin razonamiento. Con razonamiento costaba 3.50.
- **grok-3-preview-02-24** usa el precio de grok-3. Es casi seguro el mismo modelo, pero es un supuesto.
- **gemini-2.5-pro:** el precio es para preguntas de hasta 200,000 tokens, que son casi todas las de los datos.
- Son precios **de lista**, sin descuentos (caché, batch, horario nocturno de DeepSeek).

## Parte 2: prueba de costo por respuesta

### La cuenta

Por cada voto y cada uno de los 2 modelos:

```
costo de la respuesta = tokens de la pregunta  × precio de entrada / 1,000,000
                      + tokens de la respuesta × precio de salida  / 1,000,000
```

Los tokens salen de los datos (`sum_user_tokens`, `answer_a_tokens`, `answer_b_tokens`). Después se promedia por modelo y se multiplica por 1,000 para que el número se lea fácil.

**Votos usados:** 1er voto de cada conversación, los 48 modelos, solo conversaciones de 1 pregunta y 1 respuesta, y sin los votos con el mismo modelo a los 2 lados (igual que Mark). Total: **91,104 votos**.

### Resultado (ejemplos)

| Modelo | % de victorias (conteo simple) | Costo por 1,000 respuestas |
|---|---|---|
| gemini-2.5-pro (el que más gana) | 74.4% | $15.75 |
| o3 | 66.2% | $7.95 |
| deepseek-r1-0528 | 65.5% | $2.72 |
| gemini-2.5-flash | 63.9% | $4.04 |
| claude-opus-4 (el más caro) | 47.5% | $41.78 |
| mistral-small-3.1 (el más barato) | 30.9% | $0.23 |

Todos los modelos están en `R/resultados/costo_por_modelo.csv`.

**La idea para el cliente:** hay modelos que ganan casi tanto como el mejor y cuestan varias veces menos. Por ejemplo, deepseek-r1 y gemini-2.5-flash cuestan entre 4 y 6 veces menos que gemini-2.5-pro.

### Límites (decirlos siempre)

1. **El razonamiento no está en los datos.** Los modelos que piensan salen **más baratos de lo real**. Se nota en Claude con thinking, que muestra respuestas igual de cortas (mediana de 177 a 336 tokens) que sin thinking.
2. **Los tokens los contó LMArena con 1 solo método**, no con el de cada compañía. Sirve para comparar, no para una factura exacta.
3. **Las respuestas largas ganan más** (61.8%, `docs/05`). Un modelo puede ganar más y también costar más porque escribe más.
4. **El % de victorias es el conteo simple** (nivel 1 de `docs/04`): no ajusta por el rival ni por el tipo de pregunta. Cuando estén las regresiones, se cruza el costo con el ranking de Jaime y Mark.

## Parte 3 (fase 2): columna `razona`

`razona` = **si** si el modelo escribe un razonamiento antes de responder (thinking, serie o de OpenAI, deepseek-r1, Gemini 2.5...), **no** si responde directo, y **vacío** si no hay una fuente clara. La fuente de cada uno está en `notas`.

- **22 si, 24 no, 2 vacíos.** Entre los 35 con precio: 17 si y 18 no.
- Vacíos: `amazon-nova-experimental-chat-05-14` y `llama-4-maverick-03-26-experimental`. Solo existieron en LMArena y no hay documentación.
- Para qué sirve (decisión 3 de `docs/12`): no es predictor (sería constante dentro de cada una de las 48 regresiones), pero avisa que ese modelo gasta tokens de razonamiento que se cobran como salida y que **no están en los datos**. En la Parte 2 esos modelos salen más baratos de lo real.
- Casos a revisar con cuidado:
  - **hunyuan-turbos:** es adaptativo, piensa solo en las preguntas difíciles. Quedó como "si".
  - **grok-3-mini-beta:** en la API razona. En la app de Grok, la versión que pensaba se llamaba aparte "Think". Quedó como "si".
  - **grok-3-preview-02-24:** es Grok 3 normal, sin "Think". Quedó como "no".
  - Los "no" de Llama, Gemma, Command A y Nova Pro se apoyan en que la compañía no los presenta como modelos de razonamiento (Cohere y Amazon sacaron versiones que razonan después, como modelos aparte).

## Parte 4: top 3 por tarea dentro de cada presupuesto (actualizada en la fase 2b, 9/11)

**La pregunta del cliente:** "si no quiero pagar el mejor, ¿cuál es el mejor para mi tarea dentro de mi presupuesto?"

**Script:** `R/12_top3_por_precio.R` → `R/resultados/top3_por_precio.csv` (tarea D1, issue #34). La versión del 2/11, con medio punto, quedó guardada en `R/resultados/top3_por_precio_2026-11-02_medio_punto.csv`.

### Cómo se arma

1. Las **48 regresiones de `R/02`** con el modelo principal de la fase 2b: **`glm(..., family = binomial)`**, solo votos con ganador (ganó = 1, perdió = 0), sin los 28 votos marcados para revisión, sin ridge. Se ajustan con **todos los votos de abril a julio** (decisión 4: la herramienta final usa todos): 77,843 votos.
2. Para cada tarea, la **probabilidad de ganar promedio sobre las preguntas reales** que tienen esa característica. Lo hace `top3()` de `R/02`. Por ejemplo, para código se promedian las 21,048 preguntas con `is_code = TRUE`.
3. Solo modelos con **100 o más votos en julio** (decisión 2) y **con precio oficial** (los 13 sin precio quedan fuera).
4. Presupuesto = **precio de lista por millón de tokens de salida**: sin límite, hasta $10, hasta $2 y hasta $0.50. "Hasta" incluye el límite: gemini-2.5-pro ($10) entra en "hasta $10".

### Resultado

Cada celda: modelo (probabilidad de ganar contra un rival al azar, precio de salida por millón).

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

### Qué cambió contra la versión del 2/11 (medio punto)

- **El orden es el mismo en los 48 puestos** (4 tareas × 4 presupuestos × 3). El script lo compara solo.
- **Las probabilidades suben** (gemini-2.5-pro en todas: de 68.4% a 74.2%). No es que los modelos mejoraron: antes un empate contaba como medio punto y ahora los empates no entran, así que la probabilidad es "de ganar cuando hay un ganador".
- El número de preguntas baja (todas: de 106,602 a 77,843) por la misma razón.

### Cómo leerlo

- **gemini-2.5-pro es 1º en todo** cuando el presupuesto lo permite. Las características pesan **debajo del 1º y en los presupuestos bajos**.
- **Por $2 o menos**, gemini-2.5-flash-preview-04-17 es 1º en las 4 tareas. **Ojo:** $0.60 es su precio **sin** razonamiento. Con razonamiento costaba $3.50 (Parte 1, "Cosas a saber"), y el modelo razona por defecto. Con $3.50 no entraría en "hasta $2" (ver "Decisiones").
- **deepseek-r1** ($2.19) queda a 1.4 puntos de o3 ($8) en todas las preguntas (64.4% contra 65.8%) y a 1.3 en código (63.7% contra 65.0%), por casi 4 veces menos. Es el ejemplo más claro de "casi lo mismo por mucho menos".
- En math, **qwen3-235b-a22b** es 5º antes de filtrar por precio, pero no tiene precio oficial, así que no aparece. gemini-2.5-pro-preview-03-25 es 3º, pero no tiene votos en julio. Se dice en el reporte.
- Casi todos los modelos del top 3 **razonan**. Su costo real por respuesta es más alto de lo que dice el precio por token.

### Límites (decirlos siempre)

1. Es el **precio por token**, no el costo por respuesta. Un modelo que razona gasta más tokens.
2. Las probabilidades no tienen ridge, y los modelos con pocos votos (grok-4: 931 votos con ganador) tienen más ruido.
3. Es la versión de "preguntas reales". La de "solo esta característica" (`ranking`, también en `R/02`) puede dar otro orden.

## Parte 5 (fase 2b, D2): esqueleto de la app Shiny

**Archivo:** `app/app.R`. **Cómo abrirla**, desde la raíz del repo en RStudio: `shiny::runApp("app")` (necesita el paquete `shiny`).

**Qué hace:**
1. Al abrir, ajusta las 48 regresiones de `R/02` igual que `R/12` (binomial, votos con ganador de abril a julio). Tarda unos segundos, 1 sola vez.
2. Marcas las características de tu pregunta (las 11) y eliges un presupuesto (sin límite, $10, $2 o $0.50 por millón de tokens de salida).
3. Llama a `top3()` de `R/02` y muestra los 3 modelos con mayor probabilidad de ganar, con su compañía, precio de salida y de entrada, y si razona. Abajo dice sobre cuántas preguntas reales se promedió.

**No calcula nada nuevo:** con 1 sola característica (o ninguna) da exactamente lo mismo que `R/resultados/top3_por_precio.csv`. Se comprobó en las 16 combinaciones (4 tareas × 4 presupuestos). Con varias características, promedia las preguntas reales que tienen **todas** las marcadas. Si no hay ninguna, la app lo dice.

**Es un esqueleto:** el texto de la app está en inglés (es para mostrar al profesor). El diseño, gráficos y opciones extra quedan para la fase de la app (18/11 a 30/11). Captura: `app/captura_esqueleto.png`.

## Parte 6 (demo 16/11): top 3 en vivo en la consola

**Archivo:** `R/17_top3_en_vivo.R` (issue #47). Nessim lo llama con `source()` desde `R/14`. Si ya hay un objeto `ajustes` con las 48 regresiones binomial, las reusa.

- `top3_en_vivo(c("is_code", "math"))` → top 3 sin límite.
- `top3_en_vivo(c("is_code", "math"), presupuesto = 2)` → top 3 con precio de salida de hasta $2 por millón.
- Corre 3 ejemplos (código; código + math; código + math hasta $2) y al final pone el ejemplo 2 al lado del 3.
- **Diferencia con `R/12`:** aquí "sin límite" es `precio_max = NULL`, así que entran también los modelos sin precio oficial (salen como "sin precio oficial"). En `R/12` se dejaban fuera para comparar columnas.

## Decisiones para el grupo (no las tomó Marco ni la IA)

1. ~~**Modelos sin precio**~~: decidido el 2/11 (issue #15). Se quedan en la tabla marcados `tiene_precio_oficial = no` y quedan fuera del top 3. No se usan precios de otros proveedores.
2. ~~**`disponible_gratis_en_app`**~~: decidido el 2/11 (issue #15). Se elimina de la tabla (v4): no hay fuente confiable de julio 2025.
3. ~~**Cómo usar el costo**~~: decidido el 2/11 (decisión 6 de `docs/12`): top 3 por tarea dentro de cada presupuesto (Parte 4).
4. **Precio de gemini-2.5-flash-preview-04-17 en el top 3** (nuevo, 2/11): usar $0.60 (sin razonamiento, lo que hay hoy) o $3.50 (con razonamiento, que es como responde por defecto). Con $3.50 sale de "hasta $2" y entra el siguiente.
5. **Versión del ranking para la presentación** (nuevo, 2/11): "preguntas reales" (la que se usa aquí) o "solo esta característica".
