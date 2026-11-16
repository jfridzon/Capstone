# 17. Tareas de hoy: demo al profesor (lunes 16/11)

Esta es la lista de **quién hace qué hoy**, en qué orden y de quién depende cada uno. Si eres la IA de alguien del grupo: lee `AGENTS.md`, `docs/14-fase-2b.md`, este documento y la ficha de tu persona en `docs/tareas/`, y haz **solo la tarea de tu persona**.

Hoy se muestra todo en **RStudio**, con el código a la vista, y **Nessim presenta**. Si algo de aquí choca con `AGENTS.md`, manda `AGENTS.md`.

## Qué pidió el profesor (clases del 9/11 y 11/11)

1. Primero la **variable de respuesta y los predictores**, explícitos.
2. **Ver el código corriendo**, con coeficientes e Intercept (`summary()` del `glm`) y gráficos.
3. **AUC con `pROC`**: primero con todos los datos, después **5-fold cross-validation aleatoria** (por sesión, con `R/resultados/auc/folds_5.csv`).
4. **Una tabla de 48 filas × 7 columnas**: una fila por modelo; columnas = AUC de los folds 1 a 5, promedio de los 5 y AUC con todos los datos.
5. **Después** de esa tabla (no hoy): selección de variables (stepwise) por riesgo de overfitting, y probar un solo modelo con las mismas variables para todos.
6. Lo simple primero (las 48 regresiones) y lo sofisticado después (Bradley-Terry, 1 línea).
7. Cada uno tiene que **poder explicar en persona** lo que entrega. Le importa el proceso: qué se hizo y por qué.

## Orden de la demo (lo que ve el profesor)

Cada paso imprime un título que dice qué se está mostrando.

| # | Qué se muestra | Quién |
|---|---|---|
| 1 | Respuesta (`won` 1/0) y los 11 predictores | Nessim |
| 2 | 1 regresión: `glm(..., binomial)` con `summary()`, Intercept y odds ratios | Nessim |
| 3 | Las 48 regresiones (el loop de `glm`) | Nessim |
| 4 | **Tabla 48 × 7 de AUC** (folds 1 a 5, promedio, todos los datos) | Nessim (verifica Mark) |
| 5 | AUC con `pROC` con todos los datos y en 5-fold, con la curva ROC | Mark |
| 6 | Gráfico de coeficientes de 1 modelo y heatmap de los 48; tabla de sensibilidad | Eli |
| 7 | Bradley-Terry, 1 línea | Nessim |
| 8 | `top3_en_vivo()` con 3 preguntas, con y sin presupuesto | Marco |

## Tareas de hoy

### Jaime (`jfridzon`)

- **Primero:** revisar y aprobar el PR #57 (demo de Nessim). Es lo que bloquea a todos. Nessim no puede aprobarlo; lo puede aprobar Jaime o Mark.
- Revisar y aprobar los PR que lleguen de los demás (nadie aprueba el suyo).
- Preparar sus 2 o 3 slides de update individual sobre su parte.
- **Depende de:** nadie. **Lo esperan:** Nessim (PR #57).

### Nessim (`NDB13`), presenta

1. Cuando el PR #57 esté aprobado, mergearlo.
2. En `R/14_demo_rstudio.R`, añadir un bloque que **pivotee `R/resultados/auc/por_modelo.csv`** (columnas `scenario`, `fold`, `model`, `n_rows`, `n_wins`, `auc`, `status`) a la tabla **48 × 7** y la abra con `View()`. Los números salen del CSV, no se escriben a mano.
3. Que cada sección imprima un título que diga qué muestra (ver tabla de arriba).
4. **Ensayo final** del script completo, de principio a fin, en una sesión limpia de RStudio.
- **Depende de:** Jaime o Mark (aprobar #57). El punto 2 no depende de nadie (el CSV ya está en `main`). El ensayo final (punto 4) espera la confirmación de Mark, Eli y Marco.
- **Lo esperan:** nadie, pero la demo depende de él.

### Mark (`markbzq`)

1. Confirmar que `roc_todos_los_datos()`, `explicar_folds()` y `roc_cinco_folds()` de `R/15_roc_por_fold.R` corren en una sesión limpia, y avisar a Nessim.
2. Cuando Nessim suba la tabla 48 × 7, **verificarla de forma independiente** contra `folds_5.csv` y `por_modelo.csv` con `pROC`. Si no coincide, avisar a Nessim antes de la clase.
3. Si queda tiempo hoy: empezar `R/18_stepwise.R` (`step()` por AIC dentro de cada fold de entrenamiento, AUC en el fold de prueba con los mismos folds, y cuántas variables se quedan por modelo). **Esto no bloquea la demo y es para esta semana.**
- **Depende de:** Nessim (solo el punto 2). **Lo esperan:** Nessim (punto 1).

### Eli (`eliwulfsohn03`)

1. Confirmar que `grafico_coeficientes(modelo)`, `heatmap_48()` y `tabla_sensibilidad()` de `R/16_graficos_coeficientes.R` corren en una sesión limpia, y avisar a Nessim.
2. Que cada gráfico tenga **título y ejes que digan claro qué muestra** (coeficiente de qué, de qué modelo, qué significa el color).
3. Que la tabla de sensibilidad (binomial, quasibinomial, ordinal) se lea sola, por si el profesor pregunta por `quasibinomial`.
- **Depende de:** nadie. **Lo esperan:** Nessim.

### Marco (`marcofnounou-bit`)

1. Confirmar que `top3_en_vivo(caracteristicas, presupuesto = NULL)` de `R/17_top3_en_vivo.R` corre en una sesión limpia con 3 preguntas, con y sin presupuesto, y avisar a Nessim.
2. Que la salida diga claro qué se muestra (qué pregunta, qué presupuesto, qué 3 modelos).
3. La app Shiny y los dashboards **no son para hoy**.
- **Depende de:** nadie. **Lo esperan:** Nessim.

## Regla de oro para hoy: no se cambian las interfaces

Nessim carga las piezas de los demás con `source()`. **Nadie renombra ni cambia los argumentos de estas funciones** sin avisarle a Nessim y esperar su confirmación:

`explicar_folds`, `roc_todos_los_datos`, `roc_cinco_folds` (Mark) · `grafico_coeficientes`, `heatmap_48`, `tabla_sensibilidad` (Eli) · `top3_en_vivo` (Marco)

Tampoco se tocan los archivos de otra persona ni `folds_5.csv`.

## Si algo falla durante la demo

Respaldo: `R/10_demo_clase_48.R` y `R/resultados/auc/curva_roc_cv5.png`.

## Cómo explicarlo (para todos)

- **Intercept:** log-odds de que ese modelo gane cuando las 11 etiquetas son FALSE. Cada coeficiente es cuánto cambia ese log-odds cuando la etiqueta es TRUE, y `exp(coef)` es el odds ratio.
- **AUC por modelo vs por voto:** el AUC por modelo (cerca de 0.54) usa solo las filas de ese modelo. El AUC por voto (0.69) compara a los 2 modelos del voto. Ver `docs/05`.
- Los números salen del código y de los CSV, nunca de memoria.
