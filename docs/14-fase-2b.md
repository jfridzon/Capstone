# 14. Fase 2b: AUC con pROC y modelo binomial (desde el 9/11)

Esto es lo que toca **ahora**. Las fases 1 y 2 están hechas; no se repiten.

## Lo que pidió el profesor (clase del 4/11)

1. AUC calculado con el paquete **pROC**.
2. Primero el AUC con **todos los datos**.
3. Después **train/test** (abril a junio / julio) y ver si da parecido.
4. **5-fold cross-validation**, con el AUC de cada fold.
5. Prefiere la regresión logística de siempre: tiene dudas sobre `quasibinomial`.

## Decisiones

1. **Modelo principal: `glm(..., family = binomial)`**, solo con votos que tienen ganador (y = 1 si ganó, 0 si perdió). `quasibinomial` (empates = 0.5) y el ordinal (`MASS::polr`) quedan como chequeo en el apéndice. Ya se probó que dan lo mismo: AUC en julio 0.702 en los 2 casos.
2. **2 tipos de AUC, los 2 con pROC:**
   - **Por modelo:** el AUC de cada una de las 48 regresiones, con sus propias filas (ganó 1/0).
   - **Por voto:** P(gana A) = logística(score de A − score de B), contra si A ganó de verdad.
3. **3 escenarios, en este orden:** todos los datos → train/test (julio) → 5-fold CV por sesión (AUC de cada fold + promedio). En los 3, al lado de la línea base (ranking general).

## Orden: quién espera a quién

| Tarea | Quién | Puede empezar |
|---|---|---|
| A. Regresiones, reporte y demo a `binomial` | Nessim | **Ya** |
| B. AUC con pROC (3 escenarios) + curva ROC | Mark | **Ya** (en paralelo con A) |
| C1. Tabla de sensibilidad (binomial vs quasibinomial vs ordinal) | Eli | **Ya** |
| C2. Gráfico ROC para la presentación | Eli | Cuando esté **B** en `main` |
| D1. Top 3 por precio con los coeficientes binomial | Marco | Cuando esté **A** en `main` |
| D2. Esqueleto de la app Shiny | Marco | Cuando esté **D1** en `main` |
| E. Bradley-Terry con covariables (#14), con AUC por pROC | Nessim | Después de **A** |

Si tu tarea espera a otra y esa todavía no está en `main`, **no empieces**: dile a tu persona a quién estás esperando.

## Hoy en clase

El profesor quiere que cada uno presente cómo va el proyecto: qué es, qué hizo cada uno y qué sigue. Cada persona explica su propia parte (issue #22). Lo ideal es mostrar hoy las regresiones en `binomial` con su `summary()`, la tabla de AUC y la curva ROC.
