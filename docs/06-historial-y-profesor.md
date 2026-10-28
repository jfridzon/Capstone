# 06. Historial del proyecto y comunicación con el profesor

## Cronología

| Fecha (2026) | Qué pasó |
|---|---|
| Septiembre | Primera dirección: IA y empleo (exposición de ocupaciones a la IA, planificación de personal). El profesor dijo que los datos propuestos (O*NET, BLS) no permitían predecir nada preciso, que hacía falta un dataset de casos individuales con resultados registrados, y que en ningún momento se había definido una variable de respuesta. **Se descartó.** |
| 23/9 | Clase: el profesor explica Phase 1 (qué se predice, si está en los datos, qué predictores, si se conocen antes de la decisión). Pide que cada proyecto se separe en 3 capas: lo que sabemos que podemos hacer, lo que queremos hacer si se puede y lo que es solo una meta |
| Inicio de octubre | Nuevo tema: elegir el mejor modelo de IA con los votos de LMArena. Al profesor le interesa. Pregunta cómo un modelo más barato o débil le podría ganar a uno top, y sugiere enfocarlo en **qué modelo es mejor para cada tarea** en vez de pago contra gratis |
| 7/10 | Mandamos Phase 0 y Phase 1 sobre LMArena (texto completo en `entregas/2026-10-07 phase-0-1-email.md`) |
| 12/10 | Individual Work: cada uno entrega Phase 0/1 + su contribución. División del trabajo en `docs/07` |
| 14/10 | Phase 2 Part 1: **data dictionary** (`entregas/2026-10-14 ...xlsx`) |
| 19/10 | **Updated data dictionary** (`entregas/2026-10-19 ...xlsx`) |
| 19/10 | El profesor plantea un posible sesgo: para no tener sesgo, ¿cada modelo tenía que probarse en todas las combinaciones de etiquetas? Pide revisar qué método usaron los investigadores. Respondimos que la asignación aleatoria de modelos lo hace justo, con el chequeo de 26% a 35% en código (ver `docs/03` y `docs/05`). Respondió "Ok" |
| 21/10 | El profesor no ve cómo sale la predicción si model_a y model_b pueden ser cualquier modelo en cualquier orden. Le mandamos una página paso a paso (`entregas/2026-10-21 metodo-ranking.html`) |
| 21/10 | Pide los datos y la información de las pruebas |
| 22/10 | Le mandamos `lmarena_votes.zip` (los 135,634 votos) y el resumen de los tests 1 y 2 (`entregas/2026-10-22 LMArena Data and Tests.docx`) |
| 26/10 | Discusión del método: las cajas pierden información cuando una pregunta tiene varias características. El profesor quiere 1 regresión logística, o varias, para rankear modelos según las características. Opciones en `docs/04` |

## Qué pide y qué valora el profesor (patrones)

- **Primero la variable de respuesta y los predictores.** Es lo primero que mira. Siempre hay que decir exactamente qué se predice y con qué.
- **Predictores conocidos antes de la decisión.** Si algo solo se conoce después, no sirve para predecir.
- **Que el grupo entienda lo que entrega.** Ha preguntado si el grupo entiende el contenido cuando se nota mucho contenido de IA. Todo lo que se le mande tiene que poder explicarse en persona.
- **Simple y rápido de leer.** Respuestas cortas, que se entiendan a la primera, asumiendo que no conoce el tema. Si es largo o complejo, no lo lee.
- **Datos que existen de verdad.** Le importa que el proyecto se construya sobre datos reales y suficientes, no sobre supuestos.
- **Proyectos útiles**, que resuelvan un problema real. Puso de ejemplo a un grupo anterior que predecía retrasos de vuelos.

## Correos que mandamos (texto nuestro)

Todos van al profesor con el grupo en copia, en el hilo "IDS 3000 - Phase 2 Part 1 - Data Dictionary".

**14/10, data dictionary:**
> Attached is our data dictionary for the LMArena dataset. [...] In short, winner is our response, the 2 model names and the labels that describe the question are our predictors, and anything about the answers themselves (length, bullet points, bold) is marked not relevant since it's only known after the answer is written. We also added a short list at the bottom of the variables we will create ourselves.

**19/10, updated data dictionary:**
> The first sheet is the same one we sent you last week, and the second sheet has only the response, predictor and transform variables, with the range or levels of each one and the number of missing values, counted on all 135,634 votes.

**19/10, respuesta sobre el sesgo:**
> When someone writes a question on LMArena, the 2 models that answer it are picked at random and their names are hidden. The person writes the question without knowing which models will answer it, so every model gets close to the same mix of questions, the same way a randomized experiment works. [...] 29% of all questions involve code, and every model got between 26% and 35%. [...] On top of that, we will: keep the question labels as predictors; group questions into 10 task types; use only the 1st vote of each conversation (108,315 votes); use 48 of the 53 models.

Nota: después de ese correo cambiamos de las 10 cajas a usar las características directamente (`docs/04`). Hay que explicárselo al profesor cuando se le presente el modelo.

**21/10:** link a la página del método paso a paso.

**22/10:**
> Attached is the data with all 135,634 votes. The tests were simple. We had Claude count every vote where one of the top models went against another model and counted who won, and the "other model" won 28% of the time. Then we ranked the models by how often they win inside each type of task, like math or creative writing, and the order changes from task to task.
