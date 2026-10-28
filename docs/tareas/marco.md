# Tarea de Marco: tabla de precios

**Para cuándo:** lunes 9/11. **Rama:** `marco/precios`. No depende de nadie y nadie depende de ella todavía: es para la pregunta de costo que el profesor va a plantear después.

## Qué hay que hacer

Un archivo `data/derivados/precios_modelos.csv` con 1 fila por cada uno de los 48 modelos (la lista con su compañía está en la segunda hoja de `entregas/2026-10-19 Updated Data Dictionary - LMArena.xlsx`; los 5 que no entran están en `docs/03-datos.md`), con estas columnas:

`modelo, compania, precio_entrada_usd_por_millon, precio_salida_usd_por_millon, disponible_gratis_en_app (si/no), fuente_url, fecha_consulta, notas`

- `modelo` tiene que estar escrito **exactamente** como en los datos (por ejemplo `claude-opus-4-20250514`), porque se va a unir por ese nombre.
- Los precios salen solo de las páginas oficiales de cada compañía (o de su API), con el link en `fuente_url`.
- Se puede armar en Excel y exportar a CSV.

## Cómo sabes que está bien

48 filas, sin nombres repetidos, y cada precio con su fuente.

## No hagas

- **No inventes ni estimes precios.** Si un modelo ya no existe o no tiene precio público, deja el precio vacío y explica en `notas`.
- No toques ningún otro archivo del repo.
