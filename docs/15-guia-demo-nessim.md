# Demo simple de Nessim: código y resultados en RStudio

Archivo: R/14_demo_rstudio.R. Actualizado el 11/11/2026 por petición de Nessim.
Preparado con asistencia de ChatGPT/Codex (OpenAI).
Esta guía se lee aparte; el script solo tiene títulos cortos, código y resultados.

## Preparación del miércoles 18/11 (borrador)

Esta sección actualiza el guion del 16/11 de abajo. La demo completa del
18/11 sigue pendiente: en el commit base del PR #63 no están las nuevas
piezas R/19 (Eli), R/20 (Mark) y R/21 (Marco). Los bloques 8–10 solo
explican qué se mostrará; no cargan funciones ni publican resultados nuevos.
La presencia futura de un archivo no certifica su integración.

Se puede ensayar ahora la apertura y los bloques existentes 1–7:

“We predict whether an AI model wins a decisive vote. Each regression
model uses the same eleven question features, known before the answer.
An AUC of 0.5 means chance-level discrimination, like a coin flip.
AUC is not accuracy. We separate per-AI-model AUC from per-vote AUC,
and in-sample results from held-out results.”

Después de que lleguen a main las entregas del equipo, en este orden:

1. Eli: inspeccionar la interfaz real de R/19. Integrar la escalera completa
   (moneda, etiquetas, rival, etiquetas + rival), primero todos los datos y
   después cinco folds. Mostrar la tabla 48 × 7 con rival. Calcular desde su
   tabla cuánto aporta el rival y cuánto añaden las etiquetas; no usar las
   aproximaciones de Python de docs/18 como resultados oficiales.
2. Mark: inspeccionar R/20 e integrar ambas versiones de Bradley–Terry.
   “This regression model compares AI model A with AI model B.” Explicar
   la diferencia entre victoria decisiva (binomial) y puntaje esperado con
   medio punto (quasibinomial). Comparar por voto sobre los mismos casos,
   con las 48 regresiones y la línea base. No afirmar que dan parecido
   hasta ver los resultados oficiales de Mark. No usar stepwise hoy.
3. Marco: inspeccionar R/21 y llamar a su matriz_confusion() con su interfaz
   publicada, sin modificarla. Mostrar accuracy, precision y recall con
   umbral 0.5; indicar qué variante incluye. Si falta la variante con rival,
   decirlo explícitamente.
4. Repetir el ensayo técnico en sesión limpia con las tres piezas integradas,
   y después ensayar personalmente en RStudio. Una corrida parcial sin
   errores no significa que la presentación completa esté lista.

No adelantar las implementaciones de R/19–21, no asumir sus argumentos y
no renombrar funciones compartidas. Se conservan los gráficos y top 3 del
16/11 en sus archivos originales. Avisar a Eli, Mark y Marco de las piezas
que se esperan, y a Jaime para revisar el borrador y la integración final.

Verificación de este adelanto, desde la raíz:
`Rscript --vanilla R/verificar_demo_18nov_nessim.R`.
Evidencia en `R/resultados/nessim_demo_2026-11-18/`.
Guion preparado con asistencia de ChatGPT/Codex (OpenAI).

## Preparación (guía del 16/11)

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
su título hasta el siguiente, y presiona Cmd+Enter. Corre 1 a 7 en orden.
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

## 4. Tabla de AUC por modelo: 48 × 7 (16/11)

El bloque lee `R/resultados/auc/por_modelo.csv` y lo pivotea con `reshape()`.
`AUC_48x7` tiene los modelos como nombres de fila y exactamente siete
columnas numéricas: Fold_1 a Fold_5, Mean_CV y All_data. En RStudio se
abre automáticamente con `View()`; en Rscript se imprime en consola.
La media se lee de la fila `cv5 / mean`: se calculó antes de redondear
los AUC guardados. No se vuelve a promediar las cinco celdas redondeadas.
El bloque 7 recalcula con pROC y comprueba las siete columnas al redondeo
del CSV. No se modifica el archivo de Mark ni sus folds.

Di: “Each row is one model. The columns show its five held-out AUCs,
their mean, and the AUC fitted and measured on all data.”

## 5. AUC per vote: all data vs general ranking

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

## 6. Random folds by session

Muestra read.csv(folds_5.csv), set.seed(2026), sample() y la comparación
contra el archivo oficial. Ejecuta el bloque.

Di: “The folds are random at the session level. This reproduces the
original random assignment to verify Mark’s shared file. We use the
saved assignments, so everyone evaluates on the same folds.”

El código no guarda particiones nuevas. Todas las filas de la misma sesión
quedan juntas. La tabla muestra 15,569; 15,560; 15,475; 15,679; 15,560 votos
decisivos en los cinco folds.

## 7. Five-fold cross-validation

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

Para esta presentación sigue solo estos siete bloques. Los otros análisis
permanecen en el repo y se pueden abrir si el profesor los pide.


## Estado del lunes 16/11

El PR #57 ya está aprobado y fusionado. La tabla y los títulos se preparan
en `nessim/tabla-auc-demo-16-nov`. La ejecución técnica limpia se reproduce
con `Rscript --vanilla R/verificar_demo_16nov_nessim.R`; sus salidas quedan
en `R/resultados/nessim_demo_2026-11-16/`.

**Ensayo final pendiente:** Nessim confirmó que aún faltan los avisos de
Mark, Eli y Marco. Esta ejecución de R/14 no sustituye esas confirmaciones
ni el ensayo personal completo en RStudio. El orden general de presentación
sigue en docs/17: después de la tabla, Mark muestra R/15, Eli R/16,
Nessim la comparación guardada Bradley-Terry y Marco R/17. Las piezas y
sus interfaces se conservan; R/14 mantiene las fórmulas visibles del PR #57.

Avisar a Mark para que verifique la tabla independientemente con pROC,
`folds_5.csv` y `por_modelo.csv`; a Jaime para revisión del PR; a Eli y Marco
para recibir sus confirmaciones antes del ensayo completo.

Cinco frases para Nessim:

1. We predict whether an AI model wins, using eleven features of the question.
2. We fit one logistic regression for each of the forty-eight models.
3. The intercept is the log-odds of winning when all eleven features are false.
4. My table shows five held-out AUCs, their mean, and the in-sample AUC for each model.
5. We keep each session in one fold so it cannot appear in both training and testing.

Actualización preparada con asistencia de ChatGPT/Codex (OpenAI).
