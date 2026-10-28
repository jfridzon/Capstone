# 10. Entrega de Nessim: base para las regresiones

Preparada el 28/10/2026 con asistencia de ChatGPT/Codex.
Corresponde a la tarea 1 del plan vigente en `docs/07-pendientes-y-roles.md`.
Es una propuesta para revision del grupo; no cambia sus decisiones abiertas.

## Archivos

- Generador: `R/01_preparar_datos.R`.
- Dependencia: `R/auditar_limpieza.R`.
- Base generada: `data/derivados/base_regresiones_2026-10-28_v2.csv.gz`.
- Reportes: `R/resultados/base_regresiones_2026-10-28_v2/`.
- Pruebas: `R/probar_preparacion.R` y `R/probar_auditoria.R`.

El CSV se comprime para respetar el limite de archivos del grupo. `readr` lo lee
directamente sin descomprimirlo a mano.

## Ejecutar desde la raiz

```r
library(readr)
library(dplyr)
source("R/01_preparar_datos.R")
preparar_datos(nombre = "base_regresiones_revision_nueva")

base <- read_csv(
  "data/derivados/base_regresiones_2026-10-28_v2.csv.gz",
  show_col_types = FALSE
)
```

No reutilizar un nombre existente: se detiene antes de sobrescribir archivos.

## Columnas para la entrega

| Columna | Significado |
|---|---|
| `id`, `evaluation_session_id` | Identificadores para mantener juntos los votos y sesiones al evaluar |
| `model`, `rival`, `lado` | Modelo de esa fila, su oponente y lado original |
| `winner`, `es_decisivo` | Resultado original y si hay un ganador |
| `won` | Victoria 1 o derrota 0 en votos decisivos; NA para empates y both_bad |
| `won_medio_punto_escenario` | Alternativa con medio punto para empates y both_bad; no esta aprobada |
| Las 11 caracteristicas | TRUE/FALSE, sin agrupar en cajas ni crear una etiqueta de dificultad |
| `timestamp`, `month` | Fecha UTC y mes numerico; disponibles para Mark |
| `requiere_revision` | Caso de mismo modelo o sesion con primeros votos repetidos |

Las columnas de resultado y las banderas de revision no son predictores.
No se incluyen tokens, precio ni formato de respuesta. El rival queda como
identidad: no se estima su fuerza, porque ese control sigue abierto.

La seleccion reproduce el primer voto y el universo de modelos con suficientes
participaciones descritos en `docs/03`. No reagrupa versiones. No aprende
elegibilidad de modelado ni fuerza del rival usando test; Mark debe resolver
la evaluacion y la cobertura de los modelos que aparecen solo en julio.

## Propuesta para empates y both_bad (pendiente de aprobacion)

Propongo usar solo victorias y derrotas para el ajuste binario principal,
conservando todos los resultados en la base para comparar alternativas.
Un empate no identifica un ganador y both_bad indica rechazo de ambas
respuestas, que no necesariamente equivale a igual calidad.

La alternativa del grupo, medio punto para ambos tipos, queda disponible en
una columna separada para un analisis de sensibilidad. Si se usa, se debe
explicar que es una respuesta fraccional y acordar el ajuste estadistico;
no son victorias binarias observadas. No se ha elegido una politica final.

Antes de entrenar, Jaime y el grupo deben elegir explicitamente la respuesta
y revisar las filas senaladas. No usar `glm` con omision automatica de NA
como sustituto de esa decision.

## Pendiente para aceptar la entrega

- Revisar los casos senalados sin eliminarlos automaticamente.
- Acordar politica para empates y both_bad.
- Acordar el control del rival y coordinar con Mark la evaluacion por sesiones.
- Subir los archivos en una rama y recibir revision antes de integrar a main.

Los conteos comprobados se documentan en `docs/05-resultados.md`.
