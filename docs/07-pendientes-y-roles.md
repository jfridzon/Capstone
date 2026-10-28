# 07. Roles, pendientes y decisiones abiertas

## Plan de trabajo (desde el 28/10)

Cada update individual (20% de la nota) tiene que mostrar qué hizo **esa persona**, así que cada uno tiene una parte suya. La cadena principal (datos, regresiones, evaluación) la llevan los 3 responsables. Las otras 2 partes son archivos nuevos que no tocan el código de los demás.

| # | Quién | Tarea | Entrega | Para cuándo |
|---|---|---|---|---|
| 1 | Nessim (`NDB13`) | **Base para las regresiones:** filtrar 1er voto y los 48 modelos, y armar la base "larga" (1 fila por modelo por voto) con `won`, rival, las 11 características y el mes. Proponer cómo tratar empates y both_bad | `R/01_preparar_datos.R` y el archivo que genere en `data/derivados/` | lun 2/11 |
| 2 | Jaime (`jfridzon`) | **Las 48 regresiones:** 1 `glm` por modelo con las 11 características, tabla de coeficientes y función que, dada una combinación de características, devuelve el ranking de modelos | `R/02_regresiones_por_modelo.R` y `R/resultados/` | lun 9/11 |
| 3 | Mark (`markbzq`) | **Evaluación y línea base:** train (abril a junio) y test (julio), ranking general como línea base y % de aciertos de las 48 regresiones contra esa base. Después, la regresión combinada (Bradley-Terry) como comparación | `R/03_evaluacion.R` | lun 16/11 |
| 4 | Marco (`marcofnounou-bit`) | **Tabla de precios** para la pregunta de costo de más adelante: precio por millón de tokens (entrada y salida) de cada uno de los 48 modelos, con fuente y fecha | `data/derivados/precios_modelos.csv` | lun 9/11 |
| 5 | Eli (`eliwulfsohn03`) | **Contexto y gráficos:** comparar nuestros rankings con el leaderboard publicado de LMArena, medir el efecto del largo de la respuesta y hacer los primeros gráficos para la presentación | `R/04_contexto_y_graficos.R` y `R/resultados/` | lun 16/11 |

**Cada persona tiene una ficha con el detalle exacto en `docs/tareas/`** (por ejemplo `docs/tareas/nessim.md`).

Orden: la tarea 1 alimenta la 2 y la 3. Mientras tanto, 2 y 3 pueden arrancar con `data/lmarena_votes.csv` directo.

## Decisiones tomadas

- **Método (26/10):** primero las 48 regresiones, después la combinada como comparación. Ver `docs/04`.
- **Características:** entran las 11 directo como predictores. Ya no se usa la regla de "difícil" ni las 10 cajas.
- **Tokens y precio:** fuera de las regresiones por ahora.

## Decisiones abiertas (el grupo decide, no la IA)

1. **Empates y both_bad:** se excluyen o cuentan como medio punto. Propuesta de Nessim en la tarea 1.
2. **Versiones de un mismo modelo:** agrupar o no las preview de Gemini 2.5 Pro con la versión final, y las thinking con la normal.
3. **Variable `thinking`:** cómo etiquetar los modelos que razonan pero no dicen "thinking" en el nombre (o3, deepseek-r1, qwq, magistral, etc.).
4. **Modelos que solo aparecen en julio** (grok-4, kimi-k2, mistral-small-2506, grok-3-mini-high): no se pueden evaluar con train de abril a junio. ¿Se agrega una partición aleatoria por sesión como chequeo?
5. **Rival en las 48 regresiones:** se controla por la fuerza general del rival o no.
6. **Qué hacer si no le ganamos al ranking general:** reportarlo como hallazgo y mover el valor al ángulo de precio.

## Pendientes generales

- [ ] Preparar el primer update formal individual (2 o 3 slides cada uno, sobre su tarea de arriba).
- [ ] Pasar a R los análisis de `docs/05` que todavía no están en `R/`.
- [ ] Calendario: limpieza 28/10 y 2/11, analytics 4/11 a 16/11, app 18/11 a 30/11, dashboards 2/12 y 7/12, reporte y presentación 9/12 a 23/12.


## Avance propuesto de Nessim (28/10, pendiente de integrar)

La tarea 1 esta preparada en `R/01_preparar_datos.R`, con base larga nueva en
`data/derivados/base_regresiones_2026-10-28_v2.csv.gz`, auditoria y pruebas.
El detalle esta en `docs/10-base-regresiones-nessim.md`.

La politica de empates/both_bad y el control del rival siguen abiertos.
La propuesta no cambia ninguna decision del grupo ni implica aprobacion.

## Avance de Marco (28/10, tarea 4)

La tabla de precios está en `data/derivados/precios_modelos_2026-10-28_v2.csv` (formato de la ficha), generada por `R/05_precios_modelos.R`. Además hay una **prueba** de costo por respuesta en `R/06_costo_por_respuesta.R`. Todo está explicado en `docs/11-precios-y-costo.md`.

Decisiones abiertas que salen de esta tarea (el grupo decide):

- **Modelos sin precio (13 de 48):** dejarlos fuera del análisis de costo, o ponerles el precio de un proveedor fijo (por ejemplo AWS Bedrock) marcado como "precio de proveedor".
- **`disponible_gratis_en_app`:** definir qué significa. Quedó vacía porque no hay una fuente fiable de julio 2025.
- **Cómo usar el costo** cuando el profesor lo pida: % de victorias por dólar, mejor modelo debajo de cierto precio, etc.
