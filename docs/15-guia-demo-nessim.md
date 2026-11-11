# Demo simple de Nessim: código y resultados en RStudio

Archivo: R/14_demo_rstudio.R. Actualizado el 11/11/2026 por petición de Nessim.
Preparado con asistencia de ChatGPT/Codex (OpenAI).
Esta guía se lee aparte; el script solo tiene títulos cortos, código y resultados.

## Preparación

Abre Capstone.Rproj dentro de capstone-repo. Comprueba la raíz del proyecto:

```r
getwd()
file.exists("R/14_demo_rstudio.R")
```

file.exists() debe dar TRUE. Si se usa un equipo sin pROC:
`install.packages("pROC")` una sola vez.

Ensayo completo:

```r
source("R/14_demo_rstudio.R")
```

Para presentar, abre el archivo y selecciona cada bloque completo, desde
su título hasta el siguiente, y presiona Cmd+Enter. Corre 1 a 6 en orden.
No ejecutes todo de golpe durante la explicación: las tablas y gráficos avanzan.

## 1. Data

Muestra los filtros y la tabla: 77,843 votos y 48 modelos.

Di: “We use votes with a clear winner. The response is won: one for a win
and zero for a loss. The predictors are eleven features of the question,
all available before the answer.”

Cada voto tiene dos filas, una por modelo; cada regresión usa la fila de
su modelo. Empates, both_bad y casos señalados quedan fuera del ajuste principal.

## 2. The 48 logistic regressions

Señala la fórmula completa en glm(), family = binomial y el loop por modelo.
Ejecuta TODO el bloque. length(fits) imprime 48 y summary() muestra o3.

Di: “This loop fits one standard logistic regression for each model,
using the same eleven predictors. Here is the full summary for o3.”

Para mostrar los coeficientes de las 48 regresiones juntos:

```r
View(as.data.frame(coefficients_48))
```

Si pide otro summary:

```r
summary(fits[["gemini-2.5-pro"]])
```

Intercept = log-odds de ganar con todas las etiquetas en FALSE.
Cada coeficiente cambia esos log-odds, manteniendo las otras etiquetas fijas.
No interpretes coeficientes como cambios directos en probabilidad.

## 3. AUC for each of the 48 regressions

Señala predict(type = "link"), pROC::roc() y pROC::auc().
Ejecuta el bloque; aparece una fila de AUC por modelo.

Di: “For each regression, we calculate the AUC from that model’s wins and
losses, using pROC. These are in-sample AUCs.”

```r
View(auc_models_all)
```

Este AUC por modelo es distinto del AUC por voto de la siguiente sección.
La tabla final también tendrá el promedio CV de cada modelo.

## 4. AUC per vote: all data vs general ranking

Muestra las dos fórmulas de score_votes:
- p_48 = plogis(score_A - score_B).
- p_general usa los logits de las tasas generales de victoria.

Muestra las llamadas pROC::roc() y pROC::auc() debajo, y ejecuta el bloque.
La tabla da 0.7005 para las regresiones y 0.6854 para el ranking general.
El gráfico compara las dos curvas ROC.

Di: “We compare the two models in each vote using the difference in their
regression scores. Our baseline uses their overall win rates. We compute
both AUCs with pROC. These results use all the data for fitting and evaluation.”

AUC no es accuracy: mide separación de victorias y derrotas, no porcentaje
de votos acertados. Esta evaluación es descriptiva dentro de muestra.

## 5. Random folds by session

Muestra read.csv(folds_5.csv), set.seed(2026), sample() y la comparación
contra el archivo oficial. Ejecuta el bloque.

Di: “The folds are random at the session level. This reproduces the
original random assignment to verify Mark’s shared file. We use the
saved assignments, so everyone evaluates on the same folds.”

El código no guarda particiones nuevas. Todas las filas de la misma sesión
quedan juntas. La tabla muestra 15,569; 15,560; 15,475; 15,679; 15,560 votos
decisivos en los cinco folds.

## 6. Five-fold cross-validation

Señala estas líneas en el loop:
- train: fold != f.
- test: fold == f.
- fit_48(train).
- score_votes(fits_fold, train, test).
- pROC::roc() y pROC::auc().

Ejecuta el bloque completo.

Di: “For each fold, we refit the 48 regressions on the other four folds
and evaluate on the held-out fold. The baseline win rates also use only
training data. No session appears in both sets.”

Muestra auc_folds: el AUC de cada fold y su media.

| Fold | AUC regresiones | AUC ranking general |
|---|---:|---:|
| 1 | 0.6902 | 0.6844 |
| 2 | 0.6921 | 0.6873 |
| 3 | 0.6954 | 0.6908 |
| 4 | 0.6779 | 0.6735 |
| 5 | 0.6912 | 0.6857 |
| Media | 0.6894 | 0.6843 |

Di: “The regressions have a slightly higher AUC in all five folds.
The average is 0.6894 versus 0.6843. The improvement is small.”

El último gráfico muestra las cinco curvas ROC de las regresiones.
La tabla AUC_48_models contiene una fila por modelo, AUC_all y AUC_CV:

```r
View(AUC_48_models)
```

Para inspeccionar los 240 AUC individuales de modelo/fold, solo si lo pide:

```r
View(auc_models_folds)
```

La media CV es la media de los cinco AUCs; no es el AUC de juntar sus predicciones.
NA_model_fold_AUC debe dar 0 para estos datos.

## Respuestas cortas

- Why not split rows randomly? “Rows from the same vote or session could
  leak into both training and testing.”
- Why a lower AUC in CV? “The held-out votes were not used to fit the models.”
- Is 0.6894 the accuracy? “No. AUC measures ranking or separation across thresholds.”
- Why are the individual-model AUCs near 0.54 but the per-vote AUC near 0.69?
  “Within a model, question features explain relatively little. Per-vote
  scoring also compares the overall strengths of the two models.”
- Are coefficient effects causal? “No. They are associations, and p-values
  are nominal because the voting data have dependence.”

Para esta presentación sigue solo estos seis bloques. Los otros análisis
permanecen en el repo y se pueden abrir si el profesor los pide.
