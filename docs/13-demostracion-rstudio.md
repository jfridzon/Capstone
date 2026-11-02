# Demostracion del grupo en RStudio

El profesor puede ver el codigo correr, los modelos reales en memoria y los
graficos en RStudio. No requiere presentar un HTML.

## Abrir

1. Abre `Capstone.Rproj` con RStudio. Asi las rutas parten de la raiz correcta.
2. Abre `R/00_demo_profesor.R` en el editor.
3. Ejecuta las secciones en orden. En Mac, selecciona el bloque y pulsa
   **Cmd + Enter**; en Windows, **Ctrl + Enter**. No ejecutes lineas sueltas
   que dependan de bloques anteriores.
4. Para una corrida completa de prueba puedes usar **Source**. Durante la
   explicacion, usa las secciones para detenerte y mostrar cada resultado.

El guion usa R base y las funciones del repo. No requiere instalar Shiny.
No vuelve a limpiar datos ni reemplaza archivos de datos o resultados.

## Que mostrar en cada seccion

| Seccion | En RStudio | Que demuestra | Parte del grupo |
|---|---|---|---|
| 1. Datos | Data Viewer y Console | Votos existentes, modelos y 11 caracteristicas | Limpieza y base de Nessim |
| 2. Las 48 | Console y Environment | Las 48 se ajustan ahora con `ajustar_modelos()`, no se cargan modelos ya entrenados | Codigo original de Jaime y actualizacion de Nessim |
| 3. Coeficientes | Plots -> Zoom | Todos los modelos y efectos en un heatmap | Regresiones y visualizacion |
| 4. Train/test | Console y Data Viewer | Ajustar de nuevo solo con train y predecir julio; ridge con lambda elegido por Mark | Evaluacion de Mark |
| 5. Lineas base | Console y Data Viewer | Bradley-Terry general se ajusta en vivo, y porcentaje de victorias | Lineas base de Mark |
| 6. Comparacion y precio | Plots y Data Viewer | Aciertos, log-loss, top 3 y restriccion de presupuesto | Mark, Nessim y Marco |
| 7. Contexto | Plots y Data Viewer | Largo de respuesta y ranking publicado de LMArena | Eli |

El script abre tablas completas en Data Viewer cuando corre en RStudio.
Los graficos quedan en el historial de **Plots**: usa las flechas y **Zoom**.

## Como mostrar que son regresiones de verdad

- Abre tambien `R/02_regresiones_por_modelo.R`. Dentro de `ajustar_modelos()`
  esta el `glm()` que se llama para cada modelo; con medio punto usa
  `quasibinomial`.
- En Environment, `ajustes_completos` es una lista con los 48 modelos.
  `resumenes_48` tiene los 48 resumenes completos y `coeficientes_48` sus
  coeficientes, errores estandar y p-valores nominales.
- En Console puedes elegir cualquier modelo:

```r
summary(ajustes_completos[["gemini-2.5-pro"]])
summary(ajustes_completos[["claude-opus-4-20250514"]])
```

Para mostrar una prediccion real, abre `predicciones_julio`: tiene los dos
modelos, ganador observado, probabilidades y ganador predicho.

## Explicacion corta para el profesor, en ingles

1. "One row is a real comparison. These features describe the question."
2. "We fit one regression per AI model. A win scores 1, a loss 0, and a tie or both bad 0.5."
3. "This first fit uses all months to describe models. It is not a test result."
4. "For the test, we fit again using April to June only, then predict July."
5. "We compare against a general ranking on the same votes. Mark chose the ridge penalty inside train."
6. "The improvement is small. Budget changes which models we recommend."
7. "Longer answers often win, but answer length is not a predictor."

## Limites que deben decir

- Cada voto contribuye a dos regresiones independientes; los ajustes no son
  independientes entre si. Los p-valores de `summary()` son nominales.
- El test temporal no evalua modelos que solo aparecen en julio. El ajuste
  descriptivo de los 48 si los incluye.
- La tarifa de salida por millon de tokens no es el costo real por respuesta.
- El ranking externo de Eli es contexto descriptivo, no validacion independiente.
- La regresion combinada con covariables (#14), Shiny y dashboards son pasos
  posteriores. No se muestran como completados.

El guion comprueba que su evaluacion en vivo reproduce las filas guardadas de
Mark. No cambia `R/03`, las fuentes de Marco/Eli ni los datos. La tabla de
precios usa la version mas reciente que exista en esta copia del repo.

Guion y documentacion preparados con asistencia de ChatGPT/Codex.


## Que significan los puntajes del ranking

La columna historica `prob_ganar` es el puntaje esperado de preferencia de
cada modelo: victoria 1, derrota 0, empate o both_bad 0.5. En el visor de la
demostracion aparece como `puntaje_preferencia` para evitar confusiones.
No es la probabilidad de que ese modelo sea el ganador entre los 48.
No deben sumarse ni normalizarse los puntajes para que den 100%.

Para evaluar un par concreto, la demostracion usa la transformacion de
diferencia de logits que usa Mark. Es una regla de comparacion del metodo,
no una igualdad que convierta por si sola los scores separados en
probabilidades verdaderas o garantice su calibracion. La evaluacion de julio
mide empiricamente como predice esa regla.
