# 14. Fase 2b: AUC con pROC y 5-fold CV aleatorio (desde el 9/11)

Esto es lo que toca **ahora**. Las fases 1 y 2 están hechas; no se repiten.

## Lo que pidió el profesor

**Clase del 4/11**
1. AUC calculado con el paquete **pROC**.
2. Primero el AUC con **todos los datos**.
3. **5-fold cross-validation**, con el AUC de cada fold.
4. Prefiere la regresión logística de siempre: tiene dudas sobre `quasibinomial`.

**Clase del 9/11 (cambio):** el AUC y la 5-fold CV van **primero**, y la partición es **aleatoria**, no "train = abril a junio, test = julio". Julio ya no es el examen principal.

## Decisiones

1. **Modelo principal: `glm(..., family = binomial)`**, solo con votos que tienen ganador (y = 1 si ganó, 0 si perdió). `quasibinomial` (empates = 0.5) y el ordinal (`MASS::polr`) quedan como chequeo en el apéndice. Eli (C1) mide si dan lo mismo, con coeficientes y con AUC en los mismos folds.
2. **2 escenarios, en este orden:**
   1. **Todos los datos:** se ajusta y se mide con todo.
   2. **5-fold CV aleatorio:** 5 grupos al azar, ajustar con 4 y medir en el que sobra, 5 veces. Se reporta el AUC de cada fold y el promedio.
3. **Los folds se hacen por sesión** (`evaluation_session_id`): todas las filas de una sesión caen en el mismo fold. Cada voto genera 2 filas (1 por modelo) y las 2 tienen que quedar juntas, si no el test ve el voto que ya vio el train. Semilla fija `set.seed(2026)`.
4. **Los folds los crea Mark 1 sola vez** y los guarda en `R/resultados/auc/folds_5.csv` (`id`, `fold`). **Todos los demás usan ese archivo** (Nessim para Bradley-Terry, Eli para sensibilidad). Nadie hace sus propios folds.
5. **2 tipos de AUC, los 2 con `pROC`:**
   - **Por modelo:** el AUC de cada una de las 48 regresiones con sus propias filas (ganó 1/0).
   - **Por voto:** `plogis(score_A - score_B)` contra si A ganó. `score` = predictor lineal (logit) de la regresión de ese modelo para esa pregunta.
   - La **línea base** (ranking general: % de victorias, calculado solo con los folds de entrenamiento) solo existe para el AUC **por voto**. Por modelo la base es constante y no tiene AUC.
6. En un fold, si un modelo tiene 1 sola clase en el test (solo gana o solo pierde), `pROC` no calcula el AUC: se deja `NA` y se cuenta cuántos fueron.
7. **Se reemplaza la decisión 4 de `docs/12`** (julio como evaluación principal). Con folds aleatorios entran los 48 modelos, incluidos los 4 que solo están en julio. La evaluación de julio de `R/03` (65.1% contra 64.5%) **queda como resultado histórico**: no se borra ni se repite.

## Orden: quién espera a quién

**Paso 1 (ya, en paralelo):**

| Tarea | Quién |
|---|---|
| **B. AUC con pROC + 5-fold CV aleatorio + `folds_5.csv` + curva ROC** (lo más importante, es lo que pidió el profesor) | Mark |
| A. Regresiones, reporte y demo a `binomial` | Nessim |
| C1. Sensibilidad: coeficientes de binomial vs quasibinomial vs ordinal | Eli |

**Paso 2 (cuando la tarea de la que dependen esté en `main`):**

| Tarea | Quién | Espera a |
|---|---|---|
| C1b. Agregar AUC por fold de quasibinomial y ordinal a la tabla de C1 | Eli | B |
| C2. Gráfico ROC para la presentación | Eli | B |
| A2. Agregar a la demo `R/10` la sección de AUC | Nessim | A y B |
| D1. Top 3 por precio con los coeficientes binomial | Marco | A |
| E. Bradley-Terry con covariables (#14), con los mismos folds y AUC por pROC | Nessim | A y B |

**Paso 3:** D2. Esqueleto de la app Shiny (Marco), cuando esté D1.

Si tu tarea espera a otra y esa todavía no está en `main`, **no empieces**: dile a tu persona a quién estás esperando.

## Presentación en clase (9/11)

Se presenta el **proyecto en general**: qué es, datos, resultados hasta ahora y las decisiones con su porqué. Cada uno explica la parte que hizo (issue #22). El AUC y la 5-fold todavía no están: se dice que vienen.
