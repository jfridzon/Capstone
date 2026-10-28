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

Estos números (chequeo aleatorio, cobertura, prueba de julio y top 3) se calcularon con un análisis aparte que todavía **no está en `R/`**. Pendiente: pasarlo a un script de R para que sea reproducible (`docs/07`).

## Tabla de precios (`R/05_precios_modelos.R` → `data/derivados/precios_modelos.csv`)

Precio de lista de cada uno de los 48 modelos, en dólares por 1 millón de tokens (entrada y salida), de la API del dueño del modelo, tarifa estándar. Los precios salen del archivo público de precios de LiteLLM en su versión del **24/7/2025** (el último día de nuestros datos), así que son los de la misma época de los votos. El script baja esa versión fija, así que cualquiera obtiene los mismos números.

- **35 de 48 modelos tienen precio oficial.** Claude Opus 4, Sonnet 4 y Haiku 3.5 se compararon con la página oficial de Anthropic y coinciden.
- **13 no tienen precio oficial:** 9 open-source (gemma, llama y qwen/qwq, que cada proveedor cobra distinto), 2 versiones experimentales que solo estuvieron en LMArena, minimax-m1 y hunyuan-turbos (no encontramos una fuente verificable). Quedan vacíos con la razón en la columna `nota`. Qué hacer con ellos lo decide el grupo.
- **Rango:** de 0.10 / 0.30 (Mistral Small) a 15 / 75 (Claude Opus 4) por millón de tokens de entrada / salida.
- **Ojo con o3:** OpenAI le bajó el precio el 10/6/2025, de 10 / 40 a 2 / 8. La tabla usa el de julio.
- **Ojo con los modelos que razonan** (thinking, o3, deepseek-r1, etc.): el precio por token es igual, pero gastan más tokens de salida. El costo real por pregunta no sale solo de esta tabla.
- **qwen-max** es el único con precio de oct 2026, porque no estaba en la versión de 2025.

## PRUEBA: costo por respuesta (`R/06_costo_por_respuesta.R` → `R/resultados/costo_por_modelo.csv`)

**Es una prueba, no un resultado para el profesor todavía.** El profesor dejó tokens y precio fuera por ahora (26/10). Sirve para cuando el grupo agregue el costo.

- Costo de cada respuesta = tokens de la pregunta × precio de entrada + tokens de la respuesta × precio de salida (tabla de precios de arriba).
- Votos: 1er voto, 48 modelos, solo conversaciones de 1 turno: **91,111 votos**. 35 de 48 modelos tienen costo (los otros no tienen precio).
- **Costo por 1,000 respuestas:** de 0.23 dólares (Mistral Small 3.1) a 41.78 (Claude Opus 4). Gemini 2.5 Pro, el que más gana (74.4% de los votos con ganador, conteo simple), cuesta 15.75.
- Ejemplos para "el mejor por el dinero": gemini-2.5-flash gana 63.9% y cuesta 4.04. deepseek-r1-0528 gana 65.5% y cuesta 2.72.

**Limitaciones:**
- **Los tokens de razonamiento no están en los datos.** Los modelos que razonan salen más baratos de lo real. Se nota en Claude con thinking: su respuesta visible mediana es de 177 a 336 tokens, igual que sin thinking.
- Los tokens los contó LMArena con 1 solo método, no con el de cada compañía.
- Las respuestas largas ganan más (61.8%), así que costo y victorias no son independientes.
- El % de victorias es el conteo simple (nivel 1 de `docs/04`), no ajusta por el rival.
