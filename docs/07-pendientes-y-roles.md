# 07. Roles, pendientes y decisiones

## AHORA: fase 2b (desde el 9/11)

Ver **`docs/14-fase-2b.md`**: decisiones (modelo `binomial`, AUC con pROC en 3 escenarios), orden de las tareas y quién espera a quién. Sin fechas límite: se avanza en el orden de la tabla.

## Fase 2: análisis (HECHA, salvo Bradley-Terry #14)

La fase 1 está hecha (ver abajo). Las decisiones abiertas se cerraron el 2/11: ver `docs/12-decisiones-2-11.md`. Cada persona tiene su ficha en `docs/tareas/` y un issue en GitHub con lo mismo.

| # | Quién | Tarea fase 2 | Entrega | Para cuándo |
|---|---|---|---|---|
| 1 | **Nessim** (`NDB13`), antes Jaime | **Las 48 regresiones para mostrarle al profesor:** `R/02` a medio punto + ridge + `top3()`, y un R Markdown que muestre el trabajo | `R/02_regresiones_por_modelo.R`, `reporte/01_regresiones_48.Rmd` | lun 9/11 |
| 2 | Mark (`markbzq`) | ~~Evaluar las 48 en julio~~ **hecho** (PR #18 y #20). Falta: ridge con λ elegido en train, partición aleatoria por sesión y función `evaluar()` | `R/03_evaluacion.R`, `R/resultados/evaluacion.csv` | lun 16/11 |
| 3 | Nessim (`NDB13`) | **Regresión combinada (Bradley-Terry con covariables)**, evaluada sobre los mismos votos de julio. Va después de la tarea 1 | `R/07_bradley_terry_covariables.R` | lun 16/11 |
| 4 | Marco (`marcofnounou-bit`) | ~~Cerrar el PR #9~~ (fusionado). ~~Columna `razona` y top 3 por tarea dentro de cada rango de precio~~ **hecho** (PR #25). Tabla sin `disponible_gratis_en_app` (v4) | `data/derivados/precios_modelos_2026-11-02_v4.csv`, `R/06_costo_por_respuesta.R`, `R/resultados/top3_por_precio.csv` | lun 16/11 |
| 5 | Eli (`eliwulfsohn03`) | Pasar a R los chequeos viejos de `docs/05` (asignación aleatoria y cobertura) y los gráficos de resultados (aciertos, log-loss, heatmap nuevo) | `R/09_chequeos_datos.R`, `R/04_contexto_y_graficos.R` | lun 16/11 |
| Todos | | **Primer update individual:** 2 o 3 slides sobre la tarea propia (qué hice, qué salió, qué sigue y cómo ayuda al grupo) | Slides propias | lun 9/11 |

Cambio del 2/11 (noche): la tarea 1 pasó de Jaime a Nessim. Orden: Nessim hace primero la 1 (lun 9/11) y después la 3 (lun 16/11). Marco (4) y Eli (5) usan los coeficientes nuevos de la tarea 1 cuando estén. Jaime revisa y aprueba los PR y coordina con el profesor.

**Fase 1 ya está hecha. Ninguna IA debe rehacerla** (el 2/11 se repitió la base de Nessim por leer la sección vieja de la ficha: PR #19).

## Decisiones tomadas

- **Método (26/10):** primero las 48 regresiones, después la combinada como comparación. Ver `docs/04`.
- **Características:** entran las 11 directo como predictores. Ya no se usan las 10 cajas ni la regla de "difícil".
- **Tokens y precio:** fuera de las regresiones. El precio entra después, en el top 3 por presupuesto.
- **2/11, ver `docs/12`:**
  1. Empates y both_bad: medio punto en el ajuste. Evaluación sobre votos decisivos. Excluir queda como chequeo.
  2. Gemini 2.5 Pro: no se agrupa. La herramienta solo recomienda modelos con 100 o más votos en julio.
  3. `thinking`: no es predictor. Columna `razona` en la tabla de precios.
  4. Modelos solo de julio: evaluación principal en julio y partición aleatoria por sesión (5 semillas) como chequeo.
  5. Rival: no se controla en las 48. Lo controla la regresión combinada.
  6. Resultado: se reporta tal cual (ganamos poco en aciertos; en log-loss le ganamos al % de victorias, contra Bradley-Terry no es claro). El valor de la presentación va al top 3 por tarea + precio.
  - Nuevo: ridge como variante, con λ elegido solo con train.

## Decisiones abiertas

Ninguna por ahora. Cerradas el 2/11 (noche):
- **Modelos sin precio oficial (13 de 48):** quedan fuera del top 3 por precio. En la tabla siguen, marcados "sin precio oficial". No se usan precios de otros proveedores.
- **`disponible_gratis_en_app`:** se elimina de la tabla v3 (no hay fuente confiable de julio 2025).
- **Pregunta de costo:** mientras el profesor no diga otra cosa, se responde con el top 3 por tarea dentro de cada presupuesto (Marco).

## Fase 3 (desde el 18/11): quién hace qué

Se detalla en las fichas cuando termine la fase 2. Por ahora:
- **App** (18/11 a 30/11): una app Shiny donde eliges las características de tu pregunta y tu presupuesto, y te da el top 3. Mark (con `top3()` de Nessim) y Marco (precios).
- **Dashboards** (2/12 y 7/12): Eli.
- **Reporte en R Markdown** (40% de la nota): Nessim arma la base con su `reporte/01_regresiones_48.Rmd`; cada uno escribe la sección de su parte.
- **Presentación** (30%): todos; cada uno presenta su parte.

## Fase 1 (hecha el 28/10)

| Quién | Qué | PR |
|---|---|---|
| Nessim | Base larga para las regresiones (`R/01`, `docs/10`) | #3 |
| Jaime | Las 48 regresiones y rankings (`R/02`) | #8 |
| Mark | Partición train/test y 2 líneas base, 64.5% (`R/03`) | #2, #6, #10 |
| Marco | Tabla de precios v1 y v2 (`R/05`) y prueba de costo (`R/06`) | #4, #9 |
| Eli | Comparación con el leaderboard oficial, largo de respuesta y gráficos (`R/04`) | #11 |

## Pendientes generales

- [ ] Primer update individual (todos, lun 9/11): issue #22.
- [x] PR #9 de Marco fusionado.
- [x] PR #20 de Mark fusionado.
- [ ] Mark: archivar su repo viejo `markbzq/proyecto-capstone-DataAnalytics`.
- [ ] Calendario: analytics 4/11 a 16/11, app 18/11 a 30/11, dashboards 2/12 y 7/12, reporte y presentación 9/12 a 23/12.

## Avance de Marco (tarea 4)

### Fase 1 (PR #9)

La tabla de precios v2 está en `data/derivados/precios_modelos_2026-10-28_v2.csv` (formato de la ficha), generada por `R/05_precios_modelos.R`. Además hay una **prueba** de costo por respuesta en `R/06_costo_por_respuesta.R`. Todo está explicado en `docs/11-precios-y-costo.md`.

Sigue abierto (el grupo decide):

- ~~**`disponible_gratis_en_app`**~~: decidido el 2/11 (issue #15), se elimina. Hecho en la v4.
- ~~**Modelos sin precio (13 de 48)**~~: decidido el 2/11 (issue #15). Siguen en la tabla con `tiene_precio_oficial = no` y quedan fuera del top 3.

### Fase 2 (2/11, rama `marco/precios-v3`)

- **`razona`** (PR #25): la v2 + la columna `razona` (22 si, 24 no, 2 vacíos), con la fuente en `notas`. También arregla los acentos que la v2 tenía dañados (`versi<c3><b3>n`). La tabla que se usa es `data/derivados/precios_modelos_2026-11-02_v4.csv`: la misma, sin `disponible_gratis_en_app`.
- **Top 3 por presupuesto:** `R/resultados/top3_por_precio.csv`, desde `R/12_top3_por_precio.R` (fase 2b, 9/11): regresiones `binomial` y `top3()` de `R/02`. El orden no cambió contra la versión con medio punto del 2/11. Detalle en `docs/11`, Parte 4.

## Complemento de la entrega de Nessim: fase 1 (PR #19)

El generador de `R/01_preparar_datos.R` produce `votos_filtrados.csv` y
`votos_largo.csv` con las columnas de la ficha de fase 1. Incluye auditoria,
pruebas y validacion de las exportaciones. Ver `docs/10-base-regresiones-nessim.md`
y los conteos en `docs/05-resultados.md`. Pendiente de aprobacion del PR.

La base exportada conserva `won = NA` para empates y both_bad y guarda su
detalle en `resultado`. Esto no cambia las decisiones del grupo del 2/11
(`docs/12`): el ajuste posterior usa medio punto. La tarea actual de Nessim
sigue siendo la regresion combinada de fase 2, descrita arriba y en su ficha.

Conflictos de documentacion combinados con asistencia de ChatGPT/Codex,
conservando los resultados de Mark y el plan vigente del grupo.


## Entrega propuesta de Nessim: tarea 1 de fase 2 (issue #17)

Rama `nessim/regresiones-48`: medio punto por defecto en `R/02`, ridge
opcional sin elegir lambda y `top3()` con los filtros de julio y precio.
Se regeneran coeficientes/rankings y se agrega el R Markdown para
el reporte. Para demostrar el proyecto completo en vivo se agrega
`Capstone.Rproj` y `R/00_demo_profesor.R` (guia en `docs/13`). Ver la seccion actualizada de las 48 en `docs/05`.

La implementacion esta preparada para revision; no implica aprobacion ni
reescribe decisiones del grupo. La eleccion de lambda y la evaluacion
siguen con Mark; el issue #14 (Bradley-Terry) queda para despues.
Preparado con asistencia de ChatGPT/Codex.
