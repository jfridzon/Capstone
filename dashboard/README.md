# Dashboard de Eli

Abre `dashboard/index.html` en un navegador. El archivo funciona sin servidor
y contiene los datos necesarios. Desde la raíz del repositorio, se regenera
con `Rscript --vanilla R/dashboard_capstone_eli.R` (R base).

- **Evaluación:** alterna entre la media y cada fold. El AUC por voto se toma
  de `regresion_grande_cv_2026-11-18/comparacion_por_voto.csv`. El AUC por
  modelo de IA se toma de `fuerza_rival/escalera_auc.csv`. Son preguntas
  diferentes, así que aparecen en paneles separados.
- **Selección:** los filtros de tarea y presupuesto consultan combinaciones
  publicadas en `top3_por_precio.csv`. Son estimaciones sobre las preguntas
  del estudio con precios históricos por millón de tokens de salida.

Prototipo para la etapa de dashboards del 2 y 7 de diciembre indicada en
`docs/07-pendientes-y-roles.md`. El dashboard reutiliza las evaluaciones
publicadas. La app Shiny del grupo sigue su propio flujo.

Preparado con asistencia de ChatGPT (OpenAI).
