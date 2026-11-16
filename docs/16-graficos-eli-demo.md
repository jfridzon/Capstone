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


## Confirmación de Eli para el 16/11/2026

Se ejecutó `Rscript --vanilla R/validar_demo_eli_16_nov.R` con R 4.4.1
en un runner nuevo de Ubuntu 24.04. El comprobador carga R/16 sin escribir
archivos ni abrir dispositivos, verifica las firmas originales y ejecuta
los 48 gráficos (11 coeficientes por modelo), el heatmap 48 × 11 y la tabla
4 × 8. Compara los coeficientes e intervalos con sus CSV, comprueba la
restauración de márgenes y repite los gráficos en un dispositivo de 7 × 7
pulgadas. Los archivos previos de data/, entregas/ y R/resultados/ conservan
su listado y sus hashes; se excluye solamente la carpeta propia de evidencia.

La tabla imprime ahora una explicación en inglés. Binomial usa votos con
ganador; quasibinomial asigna medio punto a los empates; ordinal los incluye
como categoría intermedia. La línea base es un ranking que ignora el tipo
de pregunta. Los AUC por voto y las decisiones del grupo no cambian:
0.6894, 0.6895 y 0.6895 de media CV en las tres regresiones, frente a 0.6843
del ranking general. Son resultados guardados, no estimaciones nuevas.

Ejecución: https://github.com/jfridzon/Capstone/actions/runs/43965093890
(commit de código `c5557fdbfe4767d48d0daf53c774e4983cd94dcc`).
Evidencia textual en `R/resultados/eli_validacion_demo_2026-11-16/`.
Los PDF y el CSV generados por R están en el artefacto `eli-demo-validacion`
de esa ejecución (retención de 14 días); pueden regenerarse con el comando.

El primer intento falló en una aserción del comprobador, porque los argumentos
de una función sin argumentos son NULL, no character(0). Se corrigió el
comprobador, conservando el error exacto en `primer_intento_stderr.txt`.
La ejecución final no tiene errores ni warnings de R. Las advertencias de
Node de las acciones auxiliares no son errores del código R.

**Alcance:** valida la pieza de Eli leyendo los resultados publicados.
No reajusta las regresiones, no recalcula AUC, no cambia folds y no prueba
la interfaz gráfica de RStudio ni la demo completa de Nessim. Los títulos,
ejes y leyendas existentes se revisaron en el código; los gráficos no
cambiaron en esta entrega. No se afirma una nueva revisión visual de PDF.

**Qué sigue:** que un responsable revise y fusione este PR. Nessim debe
cargar R/16 después de cualquier demo antigua que también defina heatmap_48,
ejecutar el bloque de integración anterior y hacer su ensayo completo en
RStudio con Plots > Zoom. Eli no depende de otra tarea; Nessim espera esta
confirmación. El workflow nuevo requiere revisión humana por estar bajo
.github/, según la política del repo.

Preparado con asistencia de ChatGPT/Codex (OpenAI).
