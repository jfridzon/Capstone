# 01. Contexto del proyecto

Última actualización: 26 de octubre de 2026.

## El problema

Cada vez más empresas pagan por IA, y la mayoría elige 1 solo modelo y lo usa para todo. Pero cada modelo es mejor en cosas distintas, y los precios son muy diferentes. Hoy una empresa elige por marca o por un ranking general que trata todas las tareas igual.

Para saber qué modelo es mejor para cada tarea se necesitan registros de personas reales comparando respuestas de distintos modelos en tareas reales. Esos datos existen y son públicos (LMArena).

## El cliente

Una empresa que usa IA para el trabajo de sus empleados (programar, escribir, analizar, responder clientes) y quiere saber qué modelo usar para cada tipo de trabajo.

## Qué predecimos

**Si un modelo gana o pierde una comparación contra otro modelo**, según las características de la pregunta. De ahí sale un **puntaje de fuerza** de cada modelo para cada combinación de características, y ordenando esos puntajes sale el **ranking de modelos para cada tipo de tarea**.

El detalle (variable de respuesta, predictores y modelos) está en `docs/04-metodo.md`.

## Qué cuenta como éxito (lo que le dijimos al profesor en Phase 0)

1. Nuestro modelo predice al ganador en votos que nunca vio **mejor que el ranking general**, que usa el mismo orden de modelos para todas las tareas (como el leaderboard principal de LMArena).
2. Una herramienta sencilla donde eliges el tipo de tarea y te muestra los 3 mejores modelos para esa tarea.

## Las 3 capas que pidió el profesor

- **Sabemos que podemos:** predecir el ganador según el tipo de tarea con los datos tal como vienen.
- **Queremos, si se puede:** agregar el precio de cada modelo (de las páginas públicas de precios) para mostrar también el mejor modelo por el dinero.
- **Meta:** una herramienta que una empresa pueda usar de verdad y volver a correr cuando salgan modelos nuevos.

## Límites que ya conocemos

- Los votantes son público general, no empleados de una empresa.
- Los datos van del 17 de abril al 24 de julio de 2025, así que los modelos más nuevos no están. El proyecto es un **método** que una empresa puede volver a correr con votos nuevos, no un ranking final.
- La gente tiende a votar por la respuesta más larga (61.8% de las veces). Ver `docs/05-resultados.md`.
- **Hallazgo importante:** en una primera prueba, un ranking por tipo de tarea acertó casi igual que el ranking general (64.7% contra 64.5%), porque Gemini 2.5 Pro sale 1º o 2º en casi todo. El método nuevo con todas las características (`docs/04`) todavía no se ha probado. Si tampoco mejora, la idea del precio ("el mejor modelo por el dinero") es la salida más útil para el cliente.

## Estado actual (26/10/2026)

- **Tema aprobado:** LMArena, selección de modelo por tarea. Phase 0, Phase 1 e Individual Work entregados (10/10 cada uno).
- **Data dictionary y updated data dictionary entregados** (14/10 y 19/10). Están en `entregas/`.
- **Datos limpios:** `data/lmarena_votes.csv` tiene los 135,634 votos, 1 fila por voto, sin el texto de los chats. Se genera con `R/lmarena_tests.R`.
- **Pruebas iniciales hechas:** los modelos "baratos" contra los top, el ranking por tarea, si gana la respuesta más larga y si la asignación de modelos es aleatoria. Todo en `docs/05`.
- **Lo que está en discusión ahora:** el profesor quiere ver exactamente cómo se hace la predicción. Quiere 1 regresión logística, o varias (por ejemplo 1 por modelo), que permita rankear los modelos según las características de la pregunta. Las opciones están en `docs/04-metodo.md` y la decisión sigue abierta en `docs/07`.

## Términos que usamos

| Término | Significado |
|---|---|
| Voto | 1 fila del dataset: 1 persona comparó 2 respuestas y votó |
| model_a / model_b | El modelo que salió a la izquierda / a la derecha. Es aleatorio y no significa nada |
| winner | model_a, model_b, tie (empate) o both_bad (las 2 malas) |
| Voto decisivo | Voto con un ganador (no empate ni both_bad) |
| Etiquetas o características | Las 11 variables TRUE/FALSE que describen la pregunta (is_code, math, etc.) |
| Pregunta difícil (hard) | 6 o más de las 7 etiquetas de criterios en TRUE, la misma regla de LMArena |
| Ranking general | 1 solo orden de modelos para todas las tareas. Es lo que tenemos que superar |
| Bradley-Terry | El modelo estándar para comparaciones de a pares. Es una regresión logística, y es el que usa LMArena |
