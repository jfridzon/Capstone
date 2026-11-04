# Eli: fase 2, avance del 4/11/2026

Issue #16. Rama propuesta: `eli/chequeos-y-graficos`. No modifica `data/`, `entregas/` ni scripts de otros.

## Entregables

- `R/09_chequeos_datos.R`: asignación por modelo y cobertura, para todos los votos, primer voto y junio. Cada cohorte calcula su umbral de 1,000 participaciones. Exporta las 11 características y `hard` solo para reproducir el chequeo histórico.
- `R/04_contexto_y_graficos.R`: fase 2 por defecto, conserva fase 1 como función optativa. Métricas desde la evaluación oficial y heatmap de medio punto con los modelos de 100+ votos en julio.
- `reporte/eli_update_2026-11-09.pptx`: 3 slides en inglés, con fuentes y notas para presentar.

## Ejecutar desde la raíz en RStudio

```r
source("R/09_chequeos_datos.R")
source("R/04_contexto_y_graficos.R")
```

R base, sin instalar paquetes. Crea carpetas con la fecha de ejecución. Repetir el mismo día reemplaza solo los archivos de resultados de Eli de ese día. No modifica datos, entregas o resultados de otros. Las opciones `correr_09 = FALSE` y `correr_04 = FALSE` permiten cargar funciones sin ejecutar. La fase 1 se conserva para consultar, pero no forma parte de esta ejecución.

## Resultados y comprobaciones

- Los porcentajes históricos de asignación y las 843/120 combinaciones coinciden con lo documentado. Primer voto: 794 combinaciones y 115 para el 90%.
- Conteos y acumulación verificados por el script. Archivos de entrada identificados por MD5 y versión de R guardada junto a los resultados.
- La evaluación usa la tabla de Mark, con 20,416 votos comunes. El heatmap tiene 46 modelos e incluye una tabla con los modelos que cumplen/no cumplen el umbral.
- Se elimina la afirmación histórica «1.2 a 2.7 veces el azar» de docs/05: no había definición reproducible. Se conserva la descripción observada sin presentarla como prueba formal.
- Dependencia externa pendiente: la evaluación de la regresión combinada de Nessim. La gráfica dice que falta; el script acepta su futura fila `combined_bradley_terry` si usa los mismos votos.

## Para explicar tus slides

1. **Qué hice:** pasé los chequeos viejos a R y preparé gráficos. 11 variables binarias permiten 2^11 = 2,048 combinaciones. Solo se observan 843 y 120 concentran el 90% de todos los votos. Esto describe la cobertura, no prueba que los modelos recibieran preguntas idénticas.
2. **Qué salió:** las regresiones por tarea aciertan 65.1% frente al 64.5% de la línea base. Mark calculó las métricas; tu aporte es verificarlas contra su CSV y comunicarlas. Log-loss mide calidad de las probabilidades y más bajo es mejor. Contra Bradley-Terry la mejora con medio punto no es concluyente.
3. **Qué sigue y por qué ayuda:** agregar la combinada cuando esté evaluada y usar los gráficos para explicar recomendaciones por tarea y presupuesto. El heatmap muestra asociaciones de cada característica con el puntaje de preferencia, sin prometer causalidad.

El largo de las respuestas sigue siendo contexto descriptivo y nunca predictor. No se rehace la fase 1 ni se alteran decisiones del grupo. No se entrega nada al profesor automáticamente.

Preparado con asistencia de ChatGPT (OpenAI).
