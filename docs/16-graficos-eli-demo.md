# Pieza de Eli para la demo del 16/11 (issue #46)

Archivo: `R/16_graficos_coeficientes.R`. Solo R base. Las dependencias ya
están en main: los coeficientes binomiales de R/02 y la sensibilidad del PR #43.
No recalcula AUC, no crea folds ni ejecuta scripts de otros integrantes.

## Integración de Nessim

Desde la raíz del repo, dentro de su demo, puede correr por secciones:

```r
source("R/16_graficos_coeficientes.R")
grafico_coeficientes("o3-2025-04-16")
grafico_coeficientes("minimax-m1")  # opcional: otro ejemplo
heatmap_48()
tabla_sensibilidad()
# View(tabla_sensibilidad())
```

`source()` solo define las funciones. Los gráficos aparecen en el dispositivo
actual (panel Plots en RStudio); no abre ni cierra dispositivos. Cada gráfico
restaura los parámetros gráficos previos. Para los 48 nombres, usar Plots > Zoom.
Si ya se cargó la demo antigua R/00, cargar R/16 después: ambas definen
`heatmap_48`, pero la interfaz del issue #46 es `heatmap_48()` sin argumentos.

## Qué significa cada salida

- `grafico_coeficientes(modelo)`: 11 puntos, ordenados por coeficiente, con
  barras `beta +/- qnorm(0.975) * error_estandar`. Son IC Wald nominales del
  GLM binomial publicado. Línea en cero; rojo negativo y azul positivo.
  Manteniendo las otras características fijas, un coeficiente positivo indica
  mayores odds de victoria; no son puntos porcentuales ni efectos causales.
  Si la barra cruza cero, el intervalo incluye ambas direcciones. Los IC son
  orientativos: no corrigen la dependencia entre votos/modelos. El Intercept
  sigue en `summary()` de Nessim; no se mezcla con estos 11 efectos.
  La función devuelve su tabla invisiblemente: `d <- grafico_coeficientes(id)`.
- `heatmap_48()`: 48 IDs completos en orden alfabético por 11 características,
  sin interceptos. Una única escala simétrica en log-odds; no es un ranking.
  Devuelve invisiblemente la matriz con todos los valores, sin recortarlos.
- `tabla_sensibilidad()`: data.frame de cuatro métodos, primero todos los
  datos (dentro de muestra), después cinco folds y media. Copia los AUC
  almacenados por Eli con redondeo a cuatro decimales; no vuelve a entrenar.
  La media es la de los cinco AUC, no el AUC de las predicciones agrupadas.

## Reproducir los ejemplos guardados

```sh
Rscript R/16_graficos_coeficientes.R
```

Solo escribe `R/resultados/eli_demo_2026-11-11/`: dos PDF vectoriales y tres
CSV (coeficientes/IC de o3, matriz completa y tabla de sensibilidad).
Se verificaron los 48 gráficos y el heatmap en un dispositivo de 7x7 pulgadas,
los IC contra los 48 ajustes originales de R/02 y la tabla contra su CSV fuente.
Los ejemplos PDF se revisaron visualmente. No cambia archivos existentes.

## Para explicarlo en clase

“I made the coefficient charts and the sensitivity table for our live demo.
The bars show the uncertainty around each question-feature effect.
The heatmap shows all 48 models, and the three regression methods have almost identical AUCs.”

Código, gráficos y documentación preparados con asistencia de ChatGPT/Codex (OpenAI).
