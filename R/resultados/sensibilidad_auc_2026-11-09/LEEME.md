# Eli: sensibilidad AUC y gráfico ROC (C1b/C2)

Generador: R/13_sensibilidad_auc_roc.R. Entrada completa C1+C1b+C2: Rscript R/12_sensibilidad.R.
Requiere MASS y pROC. Usa folds_5.csv de Mark tal cual, sin semilla propia ni folds nuevos.
No ejecuta ni modifica R/11 ni sus salidas. Se excluyen las mismas banderas de revisión que R/02.

Binomial se ajusta solo con votos decisivos. Quasibinomial y ordinal incluyen empate/both_bad del entrenamiento.
Las tres variantes se evalúan solo con las mismas filas decisivas: 1 victoria, 0 derrota.
Por modelo, binomial/quasibinomial usan el predictor lineal del glm.
Ordinal: puntaje = logit(P(mejor) + 0.5 P(empate)), derivado de las probabilidades de polr.
Es una extensión explícita del puntaje de medio punto al ordinal, no su predictor lineal ni P(victoria decisiva).
La transformación es monótona en el predictor latente: conserva su AUC dentro de cada modelo.
Por voto se usa plogis(puntaje_A - puntaje_B); el resultado ordinal depende de esta conversión documentada.
La línea base solo existe por voto, con tasas de victoria calculadas en el entrenamiento decisivo.

| Método | Todos (ajuste) | Fold 1 | Fold 2 | Fold 3 | Fold 4 | Fold 5 | Media CV |
|---|---:|---:|---:|---:|---:|---:|---:|
| binomial | 0.7005 | 0.6902 | 0.6921 | 0.6954 | 0.6779 | 0.6912 | 0.6894 |
| quasibinomial | 0.7004 | 0.6900 | 0.6923 | 0.6955 | 0.6780 | 0.6917 | 0.6895 |
| ordinal | 0.7002 | 0.6898 | 0.6924 | 0.6954 | 0.6779 | 0.6917 | 0.6895 |
| general_ranking | 0.6854 | 0.6844 | 0.6873 | 0.6908 | 0.6735 | 0.6857 | 0.6843 |

Todos = ajuste y evaluación en los mismos datos. CV = cada sesión evaluada sin participar en el ajuste.
Se exportan 48 modelos por variante y escenario/fold. AUC=NA si el test tiene una sola clase; se cuentan los casos.
Media CV es el promedio simple de los cinco AUC; el AUC de una curva agrupada puede diferir ligeramente.
Se verifica binomial/base contra Mark con tolerancia de redondeo y cada AUC contra la fórmula de rangos.
C2 redibuja las curvas oficiales curva_roc_cv5.csv; verifica sus puntos contra las predicciones binomiales OOF.
El PDF vectorial es para la presentación; no muestra julio como evaluación principal.
No se afirma equivalencia predictiva por correlación alta ni por diferencias pequeñas de AUC.
No se cambia el método principal, que sigue siendo binomial. Sin inferencia causal ni p-valores nuevos.

Código, gráfico y documentación preparados con asistencia de ChatGPT/Codex (OpenAI).
