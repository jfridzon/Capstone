# 18. Tareas del miércoles 18/11: responder lo que pidió el profesor el lunes

Si eres la IA de alguien del grupo: lee `AGENTS.md`, este documento y la ficha de tu persona en `docs/tareas/`, y haz **solo la tarea de tu persona**. Nessim presenta en RStudio. Lo del 16/11 ya está en `main`; no se repite (ver `docs/17`).

## Qué dijo el profesor el lunes 16/11

Sacado del transcript de clase (el audio termina a media frase, puede faltar el final).

1. Los AUC por modelo están cerca de 0.5 (promedio ~0.59 según él, "this is not good"). Un AUC de 0.5 es tirar una moneda.
2. **Siempre mira cuánto mejora contra una línea base** ("how much of a differential there is"). Quería comparar con lo anterior.
3. **Mismas 11 variables en los 48** (para poder comparar). El stepwise por modelo queda fuera.
4. En los **48**: solo 0/1 (`binomial`). En la **regresión grande**: probar 0/1 y 0.5 (`quasibinomial`) con 5-fold; si dan parecido, usar `binomial`. Quiere que el modelo sea el correcto: es un 0/1, no una regresión lineal.
5. De la **regresión grande** (Bradley-Terry) sacar la comparación modelo A contra modelo B, y ver si por voto le gana a las 48.
6. Habló de matriz de confusión y umbral (accuracy, recall).
7. Avisó que el AUC de las 48 y el de la regresión grande **puede no ser comparable**.
8. Distinguió "modelo de regresión" de "modelo de IA". Hay que decir siempre cuál es cuál.

## Decisión abierta #5 (docs/07): controlar por la fuerza del rival

**Propuesta de este PR:** añadir como predictor la **fuerza del rival** (su % de victorias, calculado solo con los folds de entrenamiento de cada corrida, nunca con el fold de prueba). El rival se conoce antes de que los modelos respondan, así que cumple la regla de predictores. **Aprobar este PR es aprobar esta decisión.**

Chequeo rápido hecho en Python (solo para saber qué esperar, **no son resultados oficiales**): AUC por modelo en 5-fold, promedio de los 48.

| Qué usa cada regresión | AUC aproximado |
|---|---|
| Solo las 11 etiquetas (lo que ya mostramos) | 0.54 |
| Solo la fuerza del rival | 0.63 |
| Las 11 etiquetas + fuerza del rival | 0.63 |

Lectura honesta: el salto viene del **rival**, no de las etiquetas. Las etiquetas aportan poco encima del rival (alrededor de +0.005), igual que por voto (+0.005 sobre el ranking general). Eso es lo que se le dice al profesor.

## Cómo se presenta (regla de este PR)

- **Siempre se muestran las 4 filas juntas:** moneda (0.5), solo etiquetas, solo rival, etiquetas + rival. Nunca el AUC con rival sin las otras filas.
- Se dice con claridad **de dónde viene** el aumento (el rival) y **cuánto aportan las etiquetas** (poco).
- Todo número sale de código en `R/` con `glm`, `pROC` y `R/resultados/auc/folds_5.csv`. Ningún número se escribe a mano. Si el resultado oficial difiere de la tabla de arriba, **manda el oficial**.

## Tareas de hoy

### Eli (`eliwulfsohn03`): la pieza clave. Nessim espera por ella

Archivo: `R/19_fuerza_rival.R` (resultados en `R/resultados/fuerza_rival/`).
1. Para los 48 modelos, `glm(won ~ 11 etiquetas + fuerza_rival, family = binomial)`, con la fuerza del rival recalculada en cada corrida solo con los folds de entrenamiento.
2. AUC con `pROC` en 5-fold (`folds_5.csv`) y con todos los datos, para las **3 variantes** (solo etiquetas, solo rival, etiquetas + rival). Una función `escalera_auc()` que devuelva la tabla de las 4 filas (con la moneda 0.5) y otra que devuelva la tabla 48 × 7 de la variante con rival.
3. Comparar con los números de arriba y decir si coinciden.
- **Depende de:** nadie. **Lo espera:** Nessim.

### Mark (`markbzq`)

Archivo: `R/20_regresion_grande_cv.R`.
1. La regresión grande (Bradley-Terry de `R/07`) con 5-fold usando `folds_5.csv`, en las dos versiones: 0/1 (`binomial`, sin empates) y 0.5 (`quasibinomial`). Ver si dan parecido.
2. AUC **por voto** (A contra B) de la regresión grande, y comparación con las 48 y con el ranking general. Escribir en el PR si los AUC son comparables entre sí y por qué.
3. El stepwise (`R/18`) **no se usa hoy**.
- **Depende de:** nadie (`R/07` ya está en `main`). **Lo espera:** Nessim.

### Marco (`marcofnounou-bit`)

Archivo: `R/21_matriz_confusion.R`.
1. Matriz de confusión por voto, con umbral 0.5: accuracy, precision y recall de las 48 regresiones contra el ranking general, con los mismos folds de `folds_5.csv`.
2. Dejar una función `matriz_confusion()` que Nessim pueda llamar. Si Eli ya hizo merge, añadir la variante con rival; si no, entregar la de las 48 sin rival y avisar.
3. `top3_en_vivo()` se queda como está.
- **Depende de:** nadie para empezar; Eli solo para la variante con rival. **Lo espera:** Nessim.

### Nessim (`NDB13`), presenta

1. Actualizar `R/14_demo_rstudio.R`: la escalera de AUC (de Eli), la regresión grande en sus 2 versiones (de Mark) y la matriz de confusión (de Marco), cada sección con título que diga qué se muestra.
2. Abrir con: variable de respuesta, 11 predictores, y qué significa AUC 0.5 (moneda). Decir siempre "regression model" o "AI model".
3. Ensayo final en una sesión limpia.
- **Depende de:** Eli (escalera), Mark y Marco. Mientras esperan, prepara el guion y las secciones que ya existen. **No cambia** nombres de funciones de los demás.

### Jaime (`jfridzon`)

1. Revisar y aprobar los PR de Eli, Mark, Marco y Nessim (nadie aprueba el suyo; este PR lo aprueba Mark o Nessim).
2. Preparar el slide de **Dark Data** que pidió el profesor el 9/11: qué datos no tenemos que cambiarían la predicción (por ejemplo, el texto real de la pregunta, quién vota, el contexto del voto), para explicar por qué el AUC no es más alto.
3. Preparar su update individual.

## Orden

1. Eli, Mark y Marco empiezan **ya y en paralelo**.
2. Cuando Eli haga merge, Nessim integra la escalera. Después Mark y Marco.
3. Ensayo final de Nessim en sesión limpia.

## Qué se le dice al profesor (inglés simple, 4 líneas)

- Our regression models using only the question labels are near a coin flip (AUC about 0.54).
- Who the opponent is matters much more: adding the opponent's strength lifts the AUC to about 0.63.
- The question labels add only a little on top of the opponent, the same small gain we see per vote against the general ranking.
- We compared against baselines at every step, and we tested 0/1 versus 0.5 for ties.

## Regla de oro

Nadie renombra ni cambia argumentos de funciones que otros cargan con `source()`. Tampoco se tocan `folds_5.csv`, `data/` ni `entregas/`.
