# Tarea de Mark: evaluación y línea base

**Para cuándo:** lunes 16/11. **Rama:** `mark/evaluacion`. Usa `votos_filtrados.csv` y `votos_largo.csv` de Nessim, y la función `ajustar_modelos()` de Jaime.

## Qué hay que hacer

Un script `R/03_evaluacion.R` que:

1. **Parta los datos:** train = votos antes del 1/7/2025, test = votos de julio. Fuera del test quedan los votos con algún modelo que no aparece en train (por ejemplo grok-4, kimi-k2, mistral-small-2506 y grok-3-mini-high, que solo aparecen en julio).
2. **Arme la línea base (ranking general):** el % de victorias de cada modelo en train, en todos los tipos de pregunta juntos. Para cada voto de test, predice que gana el modelo con mayor % general.
3. **Evalúe nuestro método:** con `ajustar_modelos(train)`, para cada voto de test calcula la probabilidad de ganar de model_a y de model_b con las características de esa pregunta, y predice que gana el de mayor probabilidad.
4. **Compare:** % de aciertos de la línea base contra el de nuestro método, solo en votos con ganador. Guarda la tabla en `R/resultados/evaluacion.csv` y agrega los números a `docs/05-resultados.md`.

Referencia: con las 10 cajas (ya descartadas), la línea base dio 64.5% y las cajas 64.7%.

## Segunda parte (después de lo anterior)

La regresión combinada (Bradley-Terry con covariables, ver `docs/04-metodo.md`) como comparación, con `glm` sin intercepto o con el paquete `BradleyTerry2`. Se evalúa igual, sobre julio.

## No hagas

- No uses julio para entrenar nada.
- No partas una sesión (`evaluation_session_id`) entre train y test.
