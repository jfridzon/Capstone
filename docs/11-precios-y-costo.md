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
| `R/06_costo_por_respuesta.R` | Script de la v3 (`razona`), la prueba de costo y el top 3 por presupuesto |
| `R/resultados/costo_por_modelo.csv` | Resultado de la prueba: costo por 1,000 respuestas de cada modelo |
| `R/resultados/top3_por_precio.csv` | Top 3 por tarea dentro de cada presupuesto |

Para correrlos, desde la raíz del repo, en orden:

```r
source("R/05_precios_modelos.R")     # necesita internet y el paquete jsonlite
source("R/06_costo_por_respuesta.R") # solo R base, usa las funciones de R/02 (unos 20 segundos)
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

## Parte 4 (fase 2): top 3 por tarea dentro de cada presupuesto

**La pregunta del cliente:** "si no quiero pagar el mejor, ¿cuál es el mejor para mi tarea dentro de mi presupuesto?"

### Cómo se arma

1. Las **48 regresiones de Jaime** (`R/02`), con empates y both_bad a **medio punto** (decisión 1), ajustadas con **todos los votos de abril a julio** (decisión 4: la herramienta final usa todos). Sin ridge: el λ lo elige Mark con train y todavía no está.
2. Para cada tarea, la **probabilidad de ganar promedio sobre las preguntas reales** que tienen esa característica (`ranking_real` de `R/02`). Por ejemplo, para código se promedian las 29,149 preguntas con `is_code = TRUE`. "Todas" promedia las 106,602.
3. Solo modelos con **100 o más votos en julio** (decisión 2) y **con precio oficial** (los 13 sin precio quedan fuera).
4. Presupuesto = **precio de lista por millón de tokens de salida**: sin límite, hasta $10, hasta $2 y hasta $0.50. "Hasta" incluye el límite: gemini-2.5-pro ($10) entra en "hasta $10".

### Resultado

Cada celda: modelo (probabilidad de ganar contra un rival al azar, precio de salida por millón).

| Tarea (preguntas) | Presupuesto | 1º | 2º | 3º |
|---|---|---|---|---|
| Todas (106,602) | Sin límite | gemini-2.5-pro (68.4%, $10) | grok-4-0709 (64.1%, $15) | o3-2025-04-16 (61.9%, $8) |
|  | Hasta $10 | gemini-2.5-pro (68.4%, $10) | o3-2025-04-16 (61.9%, $8) | deepseek-r1-0528 (60.5%, $2.19) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (55.7%, $0.6) | gemini-2.5-flash-lite-preview-06-17-thinking (53.5%, $0.4) | deepseek-v3-0324 (53.2%, $1.1) |
|  | Hasta $0.50 | gemini-2.5-flash-lite-preview-06-17-thinking (53.5%, $0.4) | grok-3-mini-beta (50.7%, $0.5) | grok-3-mini-high (50.5%, $0.5) |
| Código (29,149) | Sin límite | gemini-2.5-pro (66.5%, $10) | grok-4-0709 (61.5%, $15) | o3-2025-04-16 (61.4%, $8) |
|  | Hasta $10 | gemini-2.5-pro (66.5%, $10) | o3-2025-04-16 (61.4%, $8) | deepseek-r1-0528 (59.7%, $2.19) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (53.4%, $0.6) | deepseek-v3-0324 (51.8%, $1.1) | grok-3-mini-high (51.5%, $0.5) |
|  | Hasta $0.50 | grok-3-mini-high (51.5%, $0.5) | grok-3-mini-beta (50.9%, $0.5) | gemini-2.5-flash-lite-preview-06-17-thinking (50.3%, $0.4) |
| Math (8,687) | Sin límite | gemini-2.5-pro (69.4%, $10) | grok-4-0709 (67.3%, $15) | gemini-2.5-flash (61.8%, $2.5) |
|  | Hasta $10 | gemini-2.5-pro (69.4%, $10) | gemini-2.5-flash (61.8%, $2.5) | o3-2025-04-16 (58.9%, $8) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (57.4%, $0.6) | gemini-2.5-flash-lite-preview-06-17-thinking (53.9%, $0.4) | grok-3-mini-high (51.1%, $0.5) |
|  | Hasta $0.50 | gemini-2.5-flash-lite-preview-06-17-thinking (53.9%, $0.4) | grok-3-mini-high (51.1%, $0.5) | grok-3-mini-beta (49.1%, $0.5) |
| Escritura creativa (8,902) | Sin límite | gemini-2.5-pro (69.8%, $10) | grok-3-preview-02-24 (62.3%, $15) | grok-4-0709 (61.5%, $15) |
|  | Hasta $10 | gemini-2.5-pro (69.8%, $10) | deepseek-r1-0528 (59.8%, $2.19) | gemini-2.5-flash (58.7%, $2.5) |
|  | Hasta $2 | gemini-2.5-flash-preview-04-17 (57.3%, $0.6) | gemini-2.5-flash-lite-preview-06-17-thinking (55.9%, $0.4) | deepseek-v3-0324 (55.5%, $1.1) |
|  | Hasta $0.50 | gemini-2.5-flash-lite-preview-06-17-thinking (55.9%, $0.4) | gemini-2.0-flash-001 (51.3%, $0.4) | grok-3-mini-high (48.6%, $0.5) |

### Cómo leerlo

- **gemini-2.5-pro es 1º en todo** cuando el presupuesto lo permite (lo mismo que dice `docs/12`). Las características pesan **debajo del 1º y en los presupuestos bajos**.
- **Por $2 o menos**, gemini-2.5-flash-preview-04-17 es 1º en las 4 tareas. **Ojo:** $0.60 es su precio **sin** razonamiento. Con razonamiento costaba $3.50 (Parte 1, "Cosas a saber"), y el modelo razona por defecto. Con $3.50 no entraría en "hasta $2" (ver "Decisiones").
- **deepseek-r1** ($2.19) queda a 1.4 puntos de o3 ($8) en todas las preguntas (60.5% contra 61.9%) y a 1.7 en código (59.7% contra 61.4%), por casi 4 veces menos. Es el ejemplo más claro de "casi lo mismo por mucho menos".
- **minimax-m1** es 3º en math en este mismo ranking (antes de filtrar por precio), pero no tiene precio oficial, así que no aparece aquí. Se dice en el reporte.
- Casi todos los modelos del top 3 **razonan**. Su costo real por respuesta es más alto de lo que dice el precio por token.

### Límites (decirlos siempre)

1. Es el **precio por token**, no el costo por respuesta. Un modelo que razona gasta más tokens.
2. Las probabilidades no tienen ridge todavía, y los modelos con pocos votos (grok-4: 1,249) tienen más ruido.
3. Es la versión de "preguntas reales". La de "solo esta característica" (`ranking`, también en `R/02`) puede dar otro orden.

## Decisiones para el grupo (no las tomó Marco ni la IA)

1. ~~**Modelos sin precio**~~: decidido el 2/11 (issue #15). Se quedan en la tabla marcados `tiene_precio_oficial = no` y quedan fuera del top 3. No se usan precios de otros proveedores.
2. ~~**`disponible_gratis_en_app`**~~: decidido el 2/11 (issue #15). Se elimina de la tabla (v4): no hay fuente confiable de julio 2025.
3. ~~**Cómo usar el costo**~~: decidido el 2/11 (decisión 6 de `docs/12`): top 3 por tarea dentro de cada presupuesto (Parte 4).
4. **Precio de gemini-2.5-flash-preview-04-17 en el top 3** (nuevo, 2/11): usar $0.60 (sin razonamiento, lo que hay hoy) o $3.50 (con razonamiento, que es como responde por defecto). Con $3.50 sale de "hasta $2" y entra el siguiente.
5. **Versión del ranking para la presentación** (nuevo, 2/11): "preguntas reales" (la que se usa aquí) o "solo esta característica".
