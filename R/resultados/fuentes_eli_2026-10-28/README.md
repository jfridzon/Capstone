# Fuente oficial histórica para la tarea de Eli

`leaderboard_oficial.csv` es una extracción de filas oficiales, sin calcular
ni reconstruir ratings: text_style_control, full, overall, último día de julio
publicado hasta 2025-07-24. El archivo resultante es del 2025-07-17.

La URL, revisión inspeccionada y SHA256 del parquet descargado están en
`fuente.json`. La extracción usa exclusivamente filtros de fecha y categoría;
no fusiona nombres ni versiones. El script R verifica el esquema y las fechas,
calcula todos los resultados, y guarda el MD5 de esta copia y del CSV de votos.
La copia incluida permite repetir el análisis sin depender de una API cambiante.

Dataset oficial: https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset
Licencia: CC BY 4.0. Autor: Arena/LMArena. Consultado el 28/10/2026.
Style control era la opción predeterminada de texto desde el 16/5/2025,
según la ficha del dataset. Se implementó reponderación el 23/7/2025;
nuestro snapshot del 17/7 es anterior a ese cambio.

No se debe presentar como validación externa independiente, ni como ranking
del 24/7 o actual. Los votos y modelos cubiertos difieren del CSV del curso.

## Coeficientes de Jaime

Copia sin cambios de `R/resultados/coeficientes_por_modelo.csv`, commit
`a2a42961d5679acbe94e6753f32e4766e94f98af` de main. Se archiva para reproducir el mapa de calor.
Son ajustes sobre todos los votos seleccionados, no una evaluación en test.
