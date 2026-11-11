# Comprobación de la demo de Nessim (11/11/2026)

Se ejecutó R/14_demo_rstudio.R completo con las piezas fusionadas R/15,
R/16 y R/17. R 4.5.1, pROC 1.19.1. Duración observada: 13 segundos en
esta máquina; no es una garantía para otras máquinas.

- `salida_consola.txt`: salida de las ocho secciones y estado completo.
- `odds_ratios_o3.csv`: coeficientes del GLM de ejemplo y exp(coef).
- `auc_por_fold.csv`: tabla devuelta por la función de Mark.
- `integracion.csv`: las cuatro piezas cargadas.

La consola confirmó coincidencia con R/resultados/auc/por_voto.csv para
todos los datos, los cinco folds y el promedio. El GLM de ejemplo convergió
y sus coeficientes fueron finitos. Las funciones de Eli leyeron y comprobaron
sus fuentes; se ejecutaron los tres ejemplos de Marco.

Se compararon hashes MD5 de los 26 archivos bajo data/, entregas/ y
R/resultados/auc/ antes y después: idénticos. La carga anidada de R/02
desde Marco quedó en su entorno, sin definir ajustar_modelos en GlobalEnv.

En una copia temporal sin R/15, R/16 ni R/17, el mismo script terminó y
marcó esas tres piezas como pendientes. No se sustituyeron por datos falsos.

Para repetir en RStudio, desde la raíz:

```r
source("R/14_demo_rstudio.R")
```

Estos archivos son evidencia de ejecución, no de un ensayo oral ni de
aprobación del grupo. No se cambió el método ni se entrenó Bradley-Terry
otra vez. Preparado con asistencia de ChatGPT/Codex (OpenAI).
