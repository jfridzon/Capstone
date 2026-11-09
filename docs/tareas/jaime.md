# Tarea de Jaime

## Fase 2b (desde el 9/11): LO QUE TOCA AHORA

Lee primero `docs/14-fase-2b.md` (decisiones y orden).

Revisar y aprobar los PR, coordinar con el profesor y presentar el proyecto en clase.

**Hoy en clase (9/11):** se presenta el proyecto en general (qué es, datos, resultados, decisiones). Explica la parte que hiciste (issue #22). El AUC y la 5-fold todavía no están: se dice que vienen.

## Fase 2 (HECHA). No la repitas

**La tarea de las 48 regresiones pasó a Nessim** (ver `docs/tareas/nessim.md`, tarea 1). Jaime:

- Revisa y aprueba los PR de los demás (Jaime, Mark o Nessim aprueban; nadie se aprueba a sí mismo).
- Coordina con el profesor: qué se le muestra y cuándo (con el R Markdown de Nessim).
- Prepara su update individual sobre su parte de la fase 1 (las 48 regresiones originales) y las decisiones del 2/11 (`docs/12`).

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (YA HECHA el 28/10). No la repitas: es solo historia

**Para cuándo:** lunes 9/11. **Rama:** `jaime/regresiones`. Usa la base larga de Nessim, `data/derivados/base_regresiones_2026-10-28_v2.csv.gz` (ver `docs/10`), y la partición de Mark, `R/resultados/split_train_test.csv`.

### Qué hay que hacer

Un script `R/02_regresiones_por_modelo.R` con:

1. **Una función `ajustar_modelos(datos)`** que, para cada uno de los 48 modelos, ajuste:
   `glm(won ~ is_code + math + creative_writing + instruction_following + complexity + creativity + domain_knowledge + problem_solving + real_world + specificity + technical_accuracy, family = binomial)`
   con las filas de ese modelo (solo `won` 0 o 1 mientras no se decidan los empates). Tiene que recibir los datos como argumento, porque Mark la va a llamar solo con los votos de entrenamiento.
2. **Una función `ranking(caracteristicas)`** que, dada una combinación (por ejemplo código + math), calcule para cada modelo la probabilidad predicha de ganar y devuelva los modelos ordenados de mayor a menor.
3. **Resultados en `R/resultados/`:**
   - `coeficientes_por_modelo.csv`: `modelo, termino, estimado, error_estandar, p_valor`
   - `rankings_ejemplo.csv`: el top 10 para código, math, escritura creativa, código + math y una pregunta sin ninguna característica.

### Lo que el profesor quiere ver

La respuesta y los predictores explícitos, y el trabajo, no solo el resultado. Deja comentado en el script qué es cada paso.

### Para documentar

- Los votos se usan 2 veces (una por cada modelo), así que las regresiones no son independientes. El profesor lo sabe y dijo que por ahora no nos preocupemos. Igual hay que mencionarlo en el reporte.
- Decisión abierta #5 (`docs/07`): si se controla por la fuerza del rival. Primero sin rival. Si sobra tiempo, una versión con `fuerza_rival` (el % de victorias general del rival) como chequeo.
