# Tarea de Eli: contexto y gráficos

**Para cuándo:** lunes 16/11. **Rama:** `eli/contexto-graficos`. Las partes 1 y 2 no dependen de nadie. La 3 usa los resultados de Jaime cuando estén.

## Qué hay que hacer

Un script `R/04_contexto_y_graficos.R` con 3 partes. Los resultados van en `R/resultados/` y los gráficos en `R/resultados/graficos/`.

1. **Comparar con el leaderboard oficial de LMArena:** busca el ranking que LMArena publicó para julio de 2025 (por ejemplo su dataset `lmarena-ai/leaderboard-dataset` en Hugging Face) y compáralo con nuestro ranking general (el % de victorias de cada modelo). Reporta la correlación de rangos y los modelos que más cambian de posición.
2. **Efecto del largo de la respuesta:** ya sabemos que la respuesta más larga gana el 61.8% de las veces (test 3 en `docs/05-resultados.md`). Repítelo por tipo de pregunta (código, math, escritura creativa, instrucciones) y por modelo.
3. **Gráficos para la presentación:** % de victorias por modelo (top 15), y cuando estén los coeficientes de Jaime, un mapa de calor de modelo × característica.

## Para recordar

El largo de la respuesta **no es un predictor** (se conoce después de responder). Esto es para explicar los resultados, no para predecir.

## No hagas

- **No inventes rankings ni números.** Si no encuentras una fuente oficial del leaderboard, dilo en el pull request.
- No toques los scripts de los demás.
