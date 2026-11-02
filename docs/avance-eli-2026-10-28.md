# Avance de Eli — contexto y gráficos

## Ejecutar

Desde la raíz del repositorio, con R base:

```r
source("R/04_contexto_y_graficos.R")
```

Se necesita `data/lmarena_votes.csv` y la fuente oficial archivada en
`R/resultados/fuentes_eli_2026-10-28/leaderboard_oficial.csv`.
Cada ejecución genera carpetas nuevas; conserva resultados anteriores.

## Hecho

- Comparación histórica con IDs exactos, correlación y cambios de posición.
- Largo por tarea y por modelo, todos los votos y primer voto.
- Gráficos top 15, largo, comparación de rangos y mapa de calor con coeficientes de Jaime, en `R/resultados/graficos/`.
- Actualización de `docs/05-resultados.md`, fuentes y limitaciones.
- Ejecución completa con R 4.3.3; conciliación de conteos y revisión visual.

## Pendiente

- Revisión del grupo y publicación por pull request.
- Citar la asistencia de IA en el formato que se use para la entrega final.

No modifica datos originales, entregas, scripts de otros ni decisiones abiertas.
Preparado con asistencia de ChatGPT (OpenAI), 28/10/2026.
