# Evidencia de Eli: demo del 16/11/2026

Comando: `Rscript --vanilla R/validar_demo_eli_16_nov.R`.

Ejecución final satisfactoria: https://github.com/jfridzon/Capstone/actions/runs/43965093890
Código probado: `c5557fdbfe4767d48d0daf53c774e4983cd94dcc`.
R 4.4.1, Ubuntu 24.04.5 LTS, solo paquetes base.

`salida_consola.txt` copia la salida del paso de R de GitHub Actions,
eliminando solamente las marcas de tiempo del runner. No es una ejecución
local. Incluye la tabla principal, los controles y sessionInfo().

Se comprobaron 48 gráficos de once coeficientes, sus intervalos nominales,
el heatmap 48 x 11 y la tabla 4 x 8 contra sus fuentes. La diferencia máxima
de coeficientes e intervalos es 0. Se conservaron listado y hashes de los
185 archivos previos bajo data/, entregas/ y R/resultados/, excluyendo
esta carpeta de salida.

Artefacto generado por R (PDF, CSV, consola y verificacion.txt):
https://github.com/jfridzon/Capstone/actions/runs/43965093890/artifacts/14276510292
Retención: hasta el 30/11/2026; regenerable con el comando anterior.
SHA256 del ZIP publicado por Actions:
`aea27633a941924e00bac8a5185522e737632581541cf1ee56e49be0c338c11f`.

`primer_intento_stderr.txt` conserva el error inicial del comprobador.
Fuente: https://github.com/jfridzon/Capstone/actions/runs/43964487906
La comparación de NULL con character(0) se corrigió comprobando la cantidad
de argumentos; las interfaces de R/16 no cambiaron. La ejecución final
terminó sin errores ni warnings de R.

No se reajustaron modelos, recalcularon AUC ni crearon folds. No se probó
la interfaz gráfica de RStudio ni la demo completa de Nessim. Ver guía en
docs/16-graficos-eli-demo.md. No se afirma una nueva revisión visual de PDF.

Preparado con asistencia de ChatGPT/Codex (OpenAI).
