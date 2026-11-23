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

- **Operación:** marca una o varias de las once características y, si quieres,
  fija un presupuesto por millón de tokens de salida. El ranking calcula la
  probabilidad estimada para un perfil exacto: las características marcadas
  están activas y las demás inactivas. Reutiliza las 48 regresiones binomiales
  de R/02 y sus datos. El conteo indica cuántos votos del estudio coinciden
  exactamente; si es cero, la interfaz identifica el resultado como extrapolación.
  Los precios provienen de la tabla histórica v4 del equipo. Con presupuesto,
  solo entran modelos con precio conocido dentro del límite.
  El CSV en `R/resultados/dashboard_ranking_por_variable.csv` guarda el primer puesto
  sin presupuesto por perfil. El HTML calcula el ranking con los coeficientes.

Prototipo para la etapa de dashboards del 2 y 7 de diciembre indicada en
`docs/07-pendientes-y-roles.md`. El dashboard reutiliza las evaluaciones
publicadas. La app Shiny del grupo sigue su propio flujo.

Preparado con asistencia de ChatGPT (OpenAI).
