# Demo de Nessim: lunes 16 de noviembre

Tarea: issue #44. Script principal: `R/14_demo_rstudio.R`.
Guía preparada con asistencia de ChatGPT/Codex (OpenAI).

## Cómo abrir y ensayar

1. Abre `Capstone.Rproj` con la versión actual del repo.
2. Si falta pROC, instala una vez: `install.packages("pROC")`.
3. Abre `R/14_demo_rstudio.R`. Corre Setup y después cada sección con
   Cmd+Enter. La consola muestra las tablas y el panel Plots los gráficos.
   Usa las flechas del panel para volver a un gráfico; usa Zoom para el heatmap.
4. Para comprobar todo de una vez: `source("R/14_demo_rstudio.R")`.
5. Al final, las cuatro filas de `demo_14$integration` deben decir TRUE.
   Que el script termine con una pieza ausente no significa que la demo
   completa esté lista: el aviso identifica quién falta.

No hacen falta la app Shiny ni otro ajuste de Bradley-Terry para esta demo.
La comparación Bradley-Terry se lee de su resultado guardado.

## Qué mostrar y cómo explicarlo

| Sección | Qué haces | Idea para decir en inglés simple |
|---|---|---|
| 1 | Muestra `won` y las once características | We predict whether an AI model wins a human vote. We only use features of the question. |
| 2 | Muestra el `glm()` de o3, el `summary()` completo y los odds ratios | We fit one logistic regression for each AI model. This is one example. |
| 3 | Llama `demo_14$mark$roc_todos_los_datos()` | First, we fit and measure on all the data. This describes the sample. |
| 4 | Explica sesiones y muestra los cinco folds | Now each session is tested without being used to fit. The general ranking also learns only from the training folds. |
| 5 | Muestra el gráfico de o3 y el heatmap de Eli | Each dot is a feature coefficient. The bars show nominal confidence intervals. |
| 6 | Muestra la tabla de sensibilidad | The three methods have very similar AUCs. Binomial remains our main method. |
| 7 | Lee la comparación guardada de Bradley-Terry | Bradley-Terry compares both opponents directly. Its average AUC is slightly higher. |
| 8 | Muestra los tres ejemplos de Marco | The tool recommends three models for a task. A budget changes which models qualify. |

El script carga cada pieza en su propio entorno, incluidas las llamadas
internas a `source()`. No necesitas ejecutar R/11 entero ni copiar el código
de Mark. Sus funciones recalculan el AUC a la vista y usan `folds_5.csv`.

## Lo que tienes que poder explicar

- **Intercept:** log-odds de ganar cuando las once etiquetas son FALSE.
  Es una referencia del modelo, no la tasa general de victorias.
- **Coeficiente:** cambio en log-odds al pasar una etiqueta de FALSE a TRUE,
  manteniendo las demás iguales. Un signo positivo indica una asociación
  con mayores odds; no demuestra causalidad.
- **`exp(coef)`:** odds ratio. Por ejemplo, en o3 el de `mathTRUE` es 0.8625:
  las odds ajustadas se multiplican por ese valor. No significa una caída
  de 13.75 puntos porcentuales en probabilidad. Su p-valor es orientativo;
  no presentes ese coeficiente como evidencia concluyente.
- **AUC:** separa ganadores y perdedores. No es el porcentaje de aciertos.
  Distingue el AUC por modelo del AUC por voto que compara ambos modelos.
- **Todos los datos:** se ajusta y se mide con lo mismo; no mide desempeño
  en sesiones nuevas. La validación cruzada sí reserva sesiones.
- **Folds:** se lee el archivo de Mark. Todas las filas de una sesión se
  mantienen juntas para evitar que el ajuste vea parte de lo que se prueba.
- **Resultado:** la mejora de AUC sobre el ranking general es pequeña.
  Los números se leen del código y de los CSV, no se escriben a mano.
- **Límites:** los votos se usan dos veces entre las 48 regresiones;
  los p-valores e intervalos son nominales. Son preferencias humanas de
  2025; las probabilidades del top 3 no suman 100% entre modelos.
- **Precio:** es USD por millón de tokens de salida en la tabla histórica,
  no el costo total de una respuesta ni una cotización actual. Sin límite
  pueden aparecer modelos sin precio oficial; con presupuesto se excluyen.

## Antes de clase

Revisa que estén las piezas R/15, R/16 y R/17 de main y ensaya el script
completo. En la sección 3 abre también R/15 para mostrar `pROC::roc()` y
`pROC::auc()`; en la 4 señala el entrenamiento con cuatro folds y la prueba
con el restante. Si hace falta volver a una tabla:

```r
demo_14$odds_ratios
demo_14$auc_folds
demo_14$sensitivity
```

Respaldo acordado en docs/14: `R/10_demo_clase_48.R` y
`R/resultados/auc/curva_roc_cv5.png`. La demo anterior contiene una sección
histórica de julio: no la presentes como evaluación principal.
