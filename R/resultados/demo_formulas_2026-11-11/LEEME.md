# Verificación de la demo simple de Nessim

Script: R/14_demo_rstudio.R. Ejecutado completo el 11/11/2026.
R 4.5.1 y pROC 1.19.1; aproximadamente nueve segundos en esta ejecución.
Hubo un aviso de que el paquete fue compilado con R 4.5.2; no hubo errores.

- AUC por voto con todos los datos, cinco folds y media: coincide con
  R/resultados/auc/por_voto.csv al redondeo publicado.
- Los 48 AUC dentro de muestra, 240 AUC modelo/fold y 48 medias CV:
  coinciden con R/resultados/auc/por_modelo.csv al redondeo publicado.
- Los 48 GLM convergen en cada ajuste. No hay AUC modelo/fold ausentes.
- La receta de asignación aleatoria coincide con folds_5.csv.
- Ninguna sesión aparece en ambos grupos en cada vuelta de la CV.
- Los hashes de data/, entregas/ y R/resultados/auc/ no cambiaron.

Los CSV conservan precisión de cálculo; la consola redondea para mostrar.
salida_consola.txt incluye la ejecución y el resultado de las comprobaciones.
No se cambió el método ni se ejecutaron los scripts de los compañeros.
La versión anterior de la demo se conserva en Git y en sus salidas históricas.

Para reproducir desde la raíz del proyecto:

```r
source("R/14_demo_rstudio.R")
```

Preparado con asistencia de ChatGPT/Codex (OpenAI).
