# 03. Los datos

## Fuente

**LMArena, *arena-human-preference-140k*** en Hugging Face: https://huggingface.co/datasets/lmarena-ai/arena-human-preference-140k

- 135,634 votos, del 17 de abril al 24 de julio de 2025.
- 53 modelos.
- El original son 7 archivos parquet, unos 1.6 GB, y casi todo es el texto completo de las conversaciones.
- Licencia: los prompts de los usuarios son CC-BY-4.0. Las respuestas de los modelos siguen los términos de cada proveedor. **Nuestro CSV no incluye texto**, solo los metadatos de cada voto.

## Cómo se recolectaron (lo que importa para que el análisis sea válido)

Revisado en el paper de Chatbot Arena (Chiang et al., 2024), el blog de LMArena sobre este dataset y su política de leaderboard:

1. **La pregunta la escribe la persona.** No hay preguntas predefinidas.
2. **LMArena elige los 2 modelos al azar** y los muestra **sin nombre**. Los nombres se revelan solo después de votar. La persona escribe su pregunta sin saber qué modelos le van a responder, así que **la pregunta no depende del modelo**. Esto funciona como un experimento aleatorizado y es lo que permite comparar modelos de forma justa.
3. El muestreo es "típicamente uniforme, con ajustes", y los modelos entran y salen en fechas distintas. Por eso no todos tienen la misma cantidad de votos ni están en todos los meses.
4. **Las etiquetas de la pregunta no las pone una persona.** Las pone otro modelo de IA leyendo la conversación (primero llama-3-70b y después deepseek-v3).
5. Después de votar, la conversación puede seguir con **2 modelos nuevos**, que ven las respuestas anteriores. Por eso solo usamos el 1er voto de cada conversación (`evaluation_order == 1`).

**Lo que preguntó el profesor (19/10):** si para no tener sesgo cada modelo tenía que haberse probado en todas las combinaciones de etiquetas. La respuesta: no hace falta, por la asignación aleatoria (punto 2). Lo verificamos: el 29% de todas las preguntas son de código, y cada modelo recibió entre 26% y 35%. Hay algo de desbalance (en código, unas 2.7 veces más de lo que daría el puro azar), y por eso las etiquetas entran al modelo como predictores. Las 11 etiquetas dan 2,048 combinaciones posibles, y en los datos aparecen 843 (120 de ellas cubren el 90% de los votos).

## Archivo: `data/lmarena_votes.csv`

1 fila por voto, 135,634 filas. Generado por `R/lmarena_tests.R` desde los 7 parquet originales.

| Columna | Tipo | Qué es | Uso |
|---|---|---|---|
| `id` | texto | Código único del voto | Ninguno |
| `model_a`, `model_b` | categoría (53 modelos) | Los 2 modelos comparados (izquierda / derecha, al azar) | Predictores |
| `winner` | categoría | `model_a` 48,563 · `model_b` 49,785 · `tie` 21,532 · `both_bad` 15,754 | **Respuesta** |
| `evaluation_session_id` | texto | Sesión de votación | Para no partir una sesión entre train y test |
| `evaluation_order` | número | Posición del voto dentro de la sesión (1 = el primero) | Filtro: solo usamos 1 |
| `timestamp` | fecha y hora | 2025-04-17 a 2025-07-24 | Partir train (abr a jun) y test (jul). Mes como control |
| `language` | categoría (126) | en 71,175 · pl 13,813 · und 11,835 (no detectado) · ru 9,263 · zh 6,501 · ... | Posible predictor: inglés sí/no |
| `is_code` | TRUE/FALSE | La pregunta tiene que ver con código (TRUE 39,363) | Predictor |
| `math` | TRUE/FALSE | Pregunta de matemáticas (TRUE 10,892) | Predictor |
| `creative_writing` | TRUE/FALSE | Escritura creativa (TRUE 11,587) | Predictor |
| `instruction_following` | TRUE/FALSE | Tiene instrucciones específicas que seguir (TRUE 24,666). En el original se llama `if` | Predictor |
| `complexity` | TRUE/FALSE | Pregunta compleja (TRUE 66,438) | Predictor |
| `creativity` | TRUE/FALSE | Necesita pensamiento creativo (TRUE 71,495) | Predictor |
| `domain_knowledge` | TRUE/FALSE | Necesita conocimiento experto (TRUE 109,936) | Predictor |
| `problem_solving` | TRUE/FALSE | Necesita pasos de razonamiento (TRUE 92,247) | Predictor |
| `real_world` | TRUE/FALSE | Tarea práctica de la vida real (TRUE 77,642) | Predictor |
| `specificity` | TRUE/FALSE | Pide algo específico y bien definido (TRUE 80,315) | Predictor |
| `technical_accuracy` | TRUE/FALSE | La respuesta tiene que ser técnicamente correcta (TRUE 82,881) | Predictor |
| `if_score` | 0 a 5 | Puntaje que acompaña a instruction_following (2 faltantes) | Desconocido, no se usa |
| `sum_user_tokens` | número | Largo de la pregunta en tokens: 1 a 54,835, mediana 37 | Predictor posible |
| `turns` | número | Mensajes antes del voto (1 a 64, casi siempre 1) | No se usa |
| `answer_a_tokens`, `answer_b_tokens` | número | Largo de cada respuesta | **Nunca predictor** (se conoce después). Solo para explicar resultados |
| `headers_*`, `lists_*`, `bold_*` | número | Formato de cada respuesta | **Nunca predictor**, por la misma razón |

**Valores faltantes:** 0 en todas las variables que usamos. El único hueco es `language = und` (11,835 votos).

## Reglas de limpieza (las que mandamos al profesor)

1. **Solo el 1er voto de cada conversación** (`evaluation_order == 1`): 108,315 votos.
2. **Solo los 48 modelos con 1,000 votos o más.** Se quedan fuera: qwen3-coder-480b (2 votos), gemini-2.0-flash-thinking (366), gpt-4o-2024-11-20 (573), gpt-4o-mini (590) y qwen3-235b-a22b-instruct-2507 (622). Quedan **106,630 votos**.
3. **Para el ranking, solo los votos decisivos.** Empate y both_bad (27%) no dicen cuál modelo es mejor. Quedan **77,863 votos**. Si se cuenta un empate como medio punto es una decisión abierta (`docs/07`).

## Variables que creamos

| Variable | De dónde sale | Estado |
|---|---|---|
| `won` | De `winner` | Listo en la lógica |
| `company` | Del nombre del modelo (13 compañías: Anthropic, Google, OpenAI, Alibaba, Meta, Mistral, xAI, DeepSeek, Amazon, Cohere, MiniMax, Moonshot AI, Tencent) | Fácil de crear |
| `thinking` | Del nombre del modelo | **Cuidado:** solo 5 modelos dicen "thinking" en el nombre, pero o3, deepseek-r1 y otros también razonan. Hay que decidir cómo etiquetarlos |
| `english` | De `language` | Fácil de crear |
| `month` | De `timestamp` | Fácil de crear |
| `price` | Tabla externa de las páginas de precios | **Pendiente** (Marco) |

## Lista de los 53 modelos

Está en la segunda hoja de `entregas/2026-10-19 Updated Data Dictionary - LMArena.xlsx`, con la compañía de cada uno.
