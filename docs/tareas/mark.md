# Tarea de Mark

## Fase 2b (desde el 9/11): LO QUE TOCA AHORA

Lee primero `docs/14-fase-2b.md` (decisiones y orden).

**Tarea B (puede empezar ya, en paralelo con Nessim):** `R/11_auc_proc.R`. Con `glm(..., family = binomial)`, votos decisivos y la misma fórmula de 11 predictores (no necesitas esperar a Nessim):
1. **AUC por modelo:** el AUC de cada regresión con sus propias filas (48 filas).
2. **AUC por voto:** P(gana A) = `plogis(score_A - score_B)` contra si A ganó.
3. Los 2 en **3 escenarios**: todos los datos (abril a julio), train/test (abril a junio / julio) y 5-fold CV por sesión (AUC de cada fold + promedio). Con la línea base (ranking general) en los 3.
4. Todo con `pROC::roc()` y `pROC::auc()`.
5. Salida en `R/resultados/auc/` (`por_modelo.csv`, `por_voto.csv`, `folds.csv`) y 1 curva ROC de julio (48 regresiones vs línea base). Actualizar `docs/05`.

**Hoy en clase:** explica tu parte (issue #22).

## Fase 2 (HECHA). No la repitas

**Fase 2. Rama:** `mark/evaluacion-48`. Lee antes `docs/12-decisiones-2-11.md`. **Esta es la tarea que más falta: hoy nadie ha evaluado las 48 regresiones en R.**

### Parte A, para el lunes 9/11: evaluar las 48 en julio

En `R/03_evaluacion.R`:

1. Cargar las funciones de Jaime sin correr su script: `options(correr_02 = FALSE); source("R/02_regresiones_por_modelo.R")`.
2. `ajustar_modelos()` **solo con train**, con `politica_empates = "medio_punto"` y también con `"excluir"` (sensibilidad).
3. Para cada voto decisivo de julio: probabilidad de model_a y de model_b con las características de esa pregunta (`probabilidad()`). Predice que gana el de mayor probabilidad.
4. Medir sobre los mismos 20,416 votos que la línea base:
   - **Aciertos** (% y IC 95%).
   - **Log-loss** de P(gana model_a) = `plogis(qlogis(p_a) - qlogis(p_b))`. Para la línea base, lo mismo con el % de victorias. Más bajo es mejor.
5. Agregar las filas a `R/resultados/evaluacion.csv` (columnas nuevas: `logloss`) y los números a `docs/05`.

Referencia para saber si está bien (`R/08_chequeo_decisiones.R`): medio punto 65.16% y log-loss 0.6321, línea base 64.51% y 0.6378. Excluir: 65.15% y 0.6298. Si tu número no cuadra con esos, explica por qué en el PR.

### Parte B, para el lunes 16/11

1. **Ridge:** elegir λ con validación cruzada **dentro de train** (por ejemplo 5 grupos por sesión, valores 0, 10, 30, 100, 300, el que dé menor log-loss). Con ese λ, evaluar una sola vez en julio.
2. **Partición aleatoria por sesión** (decisión 4): 80/20 con 5 semillas, con los 48 modelos. Aciertos y log-loss, sin ridge y con el λ elegido.
3. Dejar una función `evaluar(ajustes_o_predicciones, test)` que Nessim pueda usar para la regresión combinada, así todo se mide igual.

### No hagas

- No uses julio para elegir nada.
- No partas una sesión entre train y test.

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (YA HECHA el 28/10). No la repitas: es solo historia

**Para cuándo:** lunes 16/11. **Rama:** `mark/evaluacion`. Usa la base larga de Nessim (`data/derivados/base_regresiones_2026-10-28_v2.csv.gz`, ver `docs/10`) y la función `ajustar_modelos()` de Jaime.

### Qué hay que hacer

Un script `R/03_evaluacion.R` que:

1. **Parta los datos:** train = votos antes del 1/7/2025, test = votos de julio. Fuera del test quedan los votos con algún modelo que no aparece en train (por ejemplo grok-4, kimi-k2, mistral-small-2506 y grok-3-mini-high, que solo aparecen en julio).
2. **Arme la línea base (ranking general):** el % de victorias de cada modelo en train, en todos los tipos de pregunta juntos. Para cada voto de test, predice que gana el modelo con mayor % general.
3. **Evalúe nuestro método:** con `ajustar_modelos(train)`, para cada voto de test calcula la probabilidad de ganar de model_a y de model_b con las características de esa pregunta, y predice que gana el de mayor probabilidad.
4. **Compare:** % de aciertos de la línea base contra el de nuestro método, solo en votos con ganador. Guarda la tabla en `R/resultados/evaluacion.csv` y agrega los números a `docs/05-resultados.md`.

Referencia: con las 10 cajas (ya descartadas), la línea base dio 64.5% y las cajas 64.7%.

### Segunda parte (después de lo anterior)

La regresión combinada (Bradley-Terry con covariables, ver `docs/04-metodo.md`) como comparación, con `glm` sin intercepto o con el paquete `BradleyTerry2`. Se evalúa igual, sobre julio.

### No hagas

- No uses julio para entrenar nada.
- No partas una sesión (`evaluation_session_id`) entre train y test.
