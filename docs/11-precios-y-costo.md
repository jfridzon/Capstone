# 11. Entrega de Marco: tabla de precios y prueba de costo

Preparada el 28/10/2026 con asistencia de Claude (Anthropic). Corresponde a la tarea 4 de `docs/07` y a la ficha `docs/tareas/marco.md`.
Este documento es para que cualquiera del grupo pueda **explicar en persona** qué se hizo, de dónde salen los números y qué límites tienen.

## En 30 segundos

1. Hicimos una tabla con el **precio de cada uno de los 48 modelos**: cuántos dólares cobra la compañía por 1 millón de tokens que entran (la pregunta) y por 1 millón que salen (la respuesta).
2. Usamos los precios de **julio 2025**, la misma época de los votos, y no los de hoy.
3. **35 de 48 tienen precio oficial.** Los otros 13 quedan vacíos y la tabla explica por qué.
4. Como **prueba**, multiplicamos esos precios por los tokens de cada respuesta de los datos y sacamos **cuánto cuesta cada modelo por cada 1,000 respuestas**.
5. Nada de esto entra en las regresiones. El profesor dejó el precio para después (26/10).

## Archivos

| Archivo | Qué es |
|---|---|
| `R/05_precios_modelos.R` | Script que arma la tabla de precios |
| `data/derivados/precios_modelos_2026-10-28_v2.csv` | **La tabla que se usa** (formato de la ficha) |
| `data/derivados/precios_modelos.csv` | Versión 1 (PR #4), mismos precios con columnas en inglés. Se deja porque en `data/` no se sobrescribe nada |
| `R/06_costo_por_respuesta.R` | Script de la prueba de costo |
| `R/resultados/costo_por_modelo.csv` | Resultado de la prueba: costo por 1,000 respuestas de cada modelo |

Para correrlos, desde la raíz del repo, en orden:

```r
source("R/05_precios_modelos.R")     # necesita internet y el paquete jsonlite
source("R/06_costo_por_respuesta.R") # solo R base
```

`R/05` se detiene si la tabla v2 ya existe, para no sobrescribirla. Si hay que rehacerla, se cambia el nombre del archivo (por ejemplo `_v3`).

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
| `disponible_gratis_en_app` | **Vacía por ahora** (ver "Lo que falta") |
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

**No inventamos ni estimamos ningún precio.** Lo que se puede hacer con estos 13 lo decide el grupo (ver "Decisiones").

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

## Decisiones para el grupo (no las tomó Marco ni la IA)

1. **Modelos sin precio:** (a) dejarlos fuera del análisis de costo, o (b) ponerles el precio de un proveedor fijo, por ejemplo AWS Bedrock en julio 2025 (llama-3.3: 0.72 / 0.72, maverick: 0.24 / 0.97, scout: 0.17 / 0.66, sacado del mismo archivo de LiteLLM). Con (b), 3 modelos más tendrían precio. Si se elige, hay que agregarlo al script y marcarlo como "precio de proveedor", no oficial.
2. **`disponible_gratis_en_app`:** ¿qué quiere decir exactamente (la app de chat de la compañía, gratis con límites)? No encontramos una fuente fiable de cómo estaba cada app en julio 2025, así que quedó vacía para no inventar.
3. **Cómo usar el costo** cuando el profesor lo pida: % de victorias por dólar, el mejor modelo debajo de cierto precio, o costo de la pregunta típica de cada tipo de tarea.
