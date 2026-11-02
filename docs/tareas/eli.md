# Tarea de Eli

## Fase 2 (desde el 2/11): lo que toca ahora

**Fase 2, para el lunes 16/11. Rama:** `eli/chequeos-y-graficos`. Lee antes `docs/12-decisiones-2-11.md`.

### Qué hay que hacer

1. **Pasar a R los chequeos viejos** de `docs/05` que todavía no están en `R/` (los pidió el profesor el 19/10 y hoy no se pueden reproducir): en `R/09_chequeos_datos.R`,
   - el chequeo de asignación aleatoria (qué % de los votos de cada modelo es de cada tipo de pregunta, mínimo y máximo por modelo),
   - la cobertura (de 2,048 combinaciones posibles de las 11 características, cuántas aparecen y cuántas cubren el 90% de los votos).
   Si un número no cuadra con `docs/05`, se corrige el doc con el número de R y se dice en el PR.
2. **Gráficos de resultados** en `R/04_contexto_y_graficos.R` (carpeta nueva con la fecha):
   - Aciertos y log-loss: línea base contra las 48 contra la combinada (con lo que haya en `R/resultados/evaluacion.csv`).
   - El heatmap modelo × característica, de nuevo con los coeficientes de medio punto de Jaime, solo con los modelos que tengan 100 o más votos en julio.
   - Los gráficos tienen que entenderse sin explicación: van a la presentación para gente de negocios.

### No hagas

- No inventes números.
- No toques los scripts de los demás.

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (hecha el 28/10, se deja como referencia)

**Para cuándo:** lunes 16/11. **Rama:** `eli/contexto-graficos`. Las partes 1 y 2 no dependen de nadie. La 3 usa los resultados de Jaime cuando estén.

### Qué hay que hacer

Un script `R/04_contexto_y_graficos.R` con 3 partes. Los resultados van en `R/resultados/` y los gráficos en `R/resultados/graficos/`.

1. **Comparar con el leaderboard oficial de LMArena:** busca el ranking que LMArena publicó para julio de 2025 (por ejemplo su dataset `lmarena-ai/leaderboard-dataset` en Hugging Face) y compáralo con nuestro ranking general (el % de victorias de cada modelo). Reporta la correlación de rangos y los modelos que más cambian de posición.
2. **Efecto del largo de la respuesta:** ya sabemos que la respuesta más larga gana el 61.8% de las veces (test 3 en `docs/05-resultados.md`). Repítelo por tipo de pregunta (código, math, escritura creativa, instrucciones) y por modelo.
3. **Gráficos para la presentación:** % de victorias por modelo (top 15), y cuando estén los coeficientes de Jaime, un mapa de calor de modelo × característica.

### Para recordar

El largo de la respuesta **no es un predictor** (se conoce después de responder). Esto es para explicar los resultados, no para predecir.

### No hagas

- **No inventes rankings ni números.** Si no encuentras una fuente oficial del leaderboard, dilo en el pull request.
- No toques los scripts de los demás.
