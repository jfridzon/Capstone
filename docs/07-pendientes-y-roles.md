# 07. Roles, pendientes y decisiones

## Fase 2: análisis (desde el 2/11)

La fase 1 está hecha (ver abajo). Las decisiones abiertas se cerraron el 2/11: ver `docs/12-decisiones-2-11.md`. Cada persona tiene su ficha en `docs/tareas/` y un issue en GitHub con lo mismo.

| # | Quién | Tarea fase 2 | Entrega | Para cuándo |
|---|---|---|---|---|
| 1 | Jaime (`jfridzon`) | Actualizar las 48 regresiones a las decisiones del 2/11 (medio punto, opción ridge) y armar la herramienta `top3()` | `R/02_regresiones_por_modelo.R` | lun 9/11 |
| 2 | Mark (`markbzq`) | **Evaluar las 48 en julio** (aciertos y log-loss) contra la línea base. Después: ridge con λ elegido en train y partición aleatoria por sesión | `R/03_evaluacion.R`, `R/resultados/evaluacion.csv` | lun 9/11 (evaluación) y lun 16/11 (el resto) |
| 3 | Nessim (`NDB13`) | **Regresión combinada (Bradley-Terry con covariables)**, evaluada sobre los mismos votos de julio | `R/07_bradley_terry_covariables.R` | lun 16/11 |
| 4 | Marco (`marcofnounou-bit`) | Cerrar el PR #9, agregar la columna `razona`, y armar el **top 3 por tarea dentro de cada rango de precio** | `data/derivados/precios_modelos_2026-11-XX_v3.csv`, `R/06_costo_por_respuesta.R` | lun 16/11 |
| 5 | Eli (`eliwulfsohn03`) | Pasar a R los chequeos viejos de `docs/05` (asignación aleatoria y cobertura) y los gráficos de resultados (aciertos, log-loss, heatmap nuevo) | `R/09_chequeos_datos.R`, `R/04_contexto_y_graficos.R` | lun 16/11 |
| Todos | | **Primer update individual:** 2 o 3 slides sobre la tarea propia (qué hice, qué salió, qué sigue y cómo ayuda al grupo) | Slides propias | lun 9/11 |

Orden: Jaime (1) y Mark (2) van en paralelo: Mark ya puede llamar `ajustar_modelos()` con `politica_empates = "medio_punto"` sin esperar a Jaime. Nessim (3) usa la partición de Mark. Marco (4) y Eli (5) usan los coeficientes nuevos de Jaime cuando estén.

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
  6. Resultado: se reporta tal cual (ganamos poco en aciertos y siempre en log-loss). El valor de la presentación va al top 3 por tarea + precio.
  - Nuevo: ridge como variante, con λ elegido solo con train.

## Decisiones abiertas

- Qué hacer con los 13 modelos sin precio oficial (propuesta de Marco en el PR #9).
- Cómo plantear la pregunta de costo: el profesor dijo que lo iba a pensar. Mientras tanto, va el top 3 por presupuesto.

## Fase 1 (hecha el 28/10)

| Quién | Qué | PR |
|---|---|---|
| Nessim | Base larga para las regresiones (`R/01`, `docs/10`) | #3 |
| Jaime | Las 48 regresiones y rankings (`R/02`) | #8 |
| Mark | Partición train/test y 2 líneas base, 64.5% (`R/03`) | #2, #6, #10 |
| Marco | Tabla de precios v1 (`R/05`); v2 y prueba de costo pendientes | #4, #9 (abierto) |
| Eli | Comparación con el leaderboard oficial, largo de respuesta y gráficos (`R/04`) | #11 |

## Pendientes generales

- [ ] Primer update individual (todos, lun 9/11).
- [ ] Aprobar el PR #9 de Marco (Mark o Nessim).
- [ ] Mark: archivar su repo viejo `markbzq/proyecto-capstone-DataAnalytics`.
- [ ] Calendario: analytics 4/11 a 16/11, app 18/11 a 30/11, dashboards 2/12 y 7/12, reporte y presentación 9/12 a 23/12.
