# 09. Auditoria reproducible de limpieza

Responsable: Nessim. Preparado con asistencia de ChatGPT/Codex.

## Ejecutar

Desde la raiz del repositorio, con R y los paquetes readr y dplyr instalados:

```r
install.packages(c("readr", "dplyr")) # solo si faltan
source("R/auditar_limpieza.R")
auditar_limpieza()
```

Alternativa desde terminal:

```sh
Rscript R/auditar_limpieza.R
Rscript R/probar_auditoria.R
```

Cada ejecucion crea una carpeta nueva en `R/resultados/`. Si ya existe,
se detiene para no sobrescribir reportes anteriores. Para reproducir con
otro destino:

```r
auditar_limpieza(
  entrada = "data/lmarena_votes.csv",
  salida = "R/resultados/auditoria_revision_nueva"
)
```

## Que hace

- Lee el CSV como texto para detectar valores mal formados antes de convertirlos.
- Audita esquema, faltantes, vacios, espacios, duplicados, tipos y fechas.
- Distingue el idioma no detectado (`und`) de un faltante real.
- Informa comparaciones de un modelo consigo mismo y primeros votos repetidos
  dentro de una sesion. No decide eliminarlos.
- Calcula elegibilidad por participaciones, usando por separado el archivo
  completo y el subconjunto de primeros votos. No cuenta solo victorias.
- Reproduce la secuencia documentada de filtros y muestra cuantos votos quedan.
- Comprueba `won` por cada lado y `y` por comparacion decisiva en memoria.
  No asigna derrota a empates ni a `both_bad`; deja su respuesta binaria sin definir.
- Compara el hash MD5 de entrada antes y despues.

## Que NO decide

Los escenarios son diagnosticos. La salida de votos decisivos reproduce el
tratamiento historico, no aprueba excluir empates en el modelo final.
No se imputa, deduplica, agrupa versiones, etiqueta `thinking`, elige el modelo
ni parte train/test. No se exporta un CSV limpio definitivo.

El universo de conteo del umbral debe coordinarse con Mark para modelar usando
solo train. Los escenarios calculados sobre todo el CSV no deben usarse como
un filtro aprendido del test.

Los controles que impiden interpretar los filtros (por ejemplo ganador invalido,
orden invalido, ID repetido o modelo faltante) bloquean los escenarios y dejan
los reportes de auditoria disponibles. Desde terminal devuelve estado de salida
no exitoso en ese caso. Otros hallazgos se informan sin corregirlos.

## Resultados y revision

La ejecucion sobre los datos del repositorio esta en
`R/resultados/auditoria_2026-10-28_final/`; el resumen esta en
`docs/05-resultados.md`. Revisar `controles.csv` y `perfil_columnas.csv` antes
de considerar los datos aptos para entrenar.

Las pruebas usan datos artificiales en una carpeta temporal y verifican
conteos, respuestas binarias, casos sin votos elegibles, entradas invalidas,
hallazgos que requieren revision y rechazo de salidas existentes. No generan
metricas del proyecto.
