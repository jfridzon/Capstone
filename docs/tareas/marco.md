# Tarea de Marco

## Fase 2 (desde el 2/11): lo que toca ahora

**Fase 2, para el lunes 16/11. Rama:** `marco/precios-v3`. Lee antes `docs/12-decisiones-2-11.md` (decisiones 3 y 6).

### Qué hay que hacer

1. **PR #9:** está abierto esperando aprobación (Mark o Nessim). Si te piden cambios, hazlos ahí.
2. **Columna `razona` (sí/no):** si el modelo razona antes de responder (thinking, o3, o4-mini, deepseek-r1, qwq, magistral, grok-3-mini, Gemini 2.5, etc.), con la fuente en `notas`. Como en `data/` no se sobrescribe nada, va en un archivo nuevo: `data/derivados/precios_modelos_2026-11-XX_v3.csv` (con la fecha del día).
3. **Top 3 por tarea dentro de cada presupuesto:** con los coeficientes de Jaime (`R/resultados/coeficientes_por_modelo.csv`, o la función `top3(..., precio_max)` cuando esté) y tu tabla, una tabla `R/resultados/top3_por_precio.csv`: para código, math, escritura creativa y todas, el top 3 sin límite, debajo de $10, debajo de $2 y debajo de $0.50 por millón de tokens de salida. Esta tabla es el centro de la presentación (decisión 6).
4. Los 13 modelos sin precio quedan fuera de este top 3, y se dice en el reporte.

### No hagas

- No inventes ni estimes precios.
- No toques los scripts de los demás.

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (hecha el 28/10, se deja como referencia)

**Para cuándo:** lunes 9/11. **Rama:** `marco/precios`. No depende de nadie y nadie depende de ella todavía: es para la pregunta de costo que el profesor va a plantear después.

### Qué hay que hacer

Un archivo `data/derivados/precios_modelos.csv` con 1 fila por cada uno de los 48 modelos (la lista con su compañía está en la segunda hoja de `entregas/2026-10-19 Updated Data Dictionary - LMArena.xlsx`; los 5 que no entran están en `docs/03-datos.md`), con estas columnas:

`modelo, compania, precio_entrada_usd_por_millon, precio_salida_usd_por_millon, disponible_gratis_en_app (si/no), fuente_url, fecha_consulta, notas`

- `modelo` tiene que estar escrito **exactamente** como en los datos (por ejemplo `claude-opus-4-20250514`), porque se va a unir por ese nombre.
- Los precios salen solo de las páginas oficiales de cada compañía (o de su API), con el link en `fuente_url`.
- Se puede armar en Excel y exportar a CSV.

### Cómo sabes que está bien

48 filas, sin nombres repetidos, y cada precio con su fuente.

### No hagas

- **No inventes ni estimes precios.** Si un modelo ya no existe o no tiene precio público, deja el precio vacío y explica en `notas`.
- No toques ningún otro archivo del repo.
