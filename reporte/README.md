# Como abrir y mostrar el reporte

## Para mostrar al profesor

Abre `01_regresiones_48.html` con Chrome, Safari o Firefox. No hace falta
RStudio ni ejecutar codigo para verlo. El HTML contiene el grafico y las tablas.
En "The regressions: full R output", abre los tres desplegables para ver
los `summary()` completos.

El ajuste binomial descriptivo usa los votos decisivos de abril a julio.
La seccion de evaluacion lee los
resultados de train/test de Mark; no los calcula con el ajuste descriptivo.

## Para revisar el codigo en RStudio

1. Abre el repositorio como proyecto o fija su raiz como carpeta de trabajo.
2. Abre `reporte/01_regresiones_48.Rmd` y usa Knit -> Knit to HTML.
3. Para ver el calculo de los modelos, abre `R/02_regresiones_por_modelo.R`.

Paquetes del reporte: `rmarkdown`, `knitr`, `htmltools` y `ggplot2`. RStudio
normalmente incluye Pandoc. Desde una terminal, Pandoc debe estar disponible
para `rmarkdown` (en PATH o mediante `RSTUDIO_PANDOC`).

Para regenerar tambien los CSV y controles, desde la raiz:

```r
source("R/generar_reporte_48.R")
```

No ejecuta la fase 1 ni `R/03`. Las pruebas del codigo estan en
`R/probar_regresiones_48.R`. El reporte es para revision del grupo; crearlo no
significa que se haya enviado al profesor.

R documenta las familias binomial (principal) y quasibinomial (opcional) aqui:
https://stat.ethz.ch/R-manual/R-devel/library/stats/html/family.html

Preparado con asistencia de ChatGPT/Codex para Nessim (issues #17 y #31).
