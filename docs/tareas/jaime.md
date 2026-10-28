# Tarea de Jaime: las 48 regresiones

**Para cuándo:** lunes 9/11. **Rama:** `jaime/regresiones`. Usa la base larga de Nessim, `data/derivados/base_regresiones_2026-10-28_v2.csv.gz` (ver `docs/10`), y la partición de Mark, `R/resultados/split_train_test.csv`.

## Qué hay que hacer

Un script `R/02_regresiones_por_modelo.R` con:

1. **Una función `ajustar_modelos(datos)`** que, para cada uno de los 48 modelos, ajuste:
   `glm(won ~ is_code + math + creative_writing + instruction_following + complexity + creativity + domain_knowledge + problem_solving + real_world + specificity + technical_accuracy, family = binomial)`
   con las filas de ese modelo (solo `won` 0 o 1 mientras no se decidan los empates). Tiene que recibir los datos como argumento, porque Mark la va a llamar solo con los votos de entrenamiento.
2. **Una función `ranking(caracteristicas)`** que, dada una combinación (por ejemplo código + math), calcule para cada modelo la probabilidad predicha de ganar y devuelva los modelos ordenados de mayor a menor.
3. **Resultados en `R/resultados/`:**
   - `coeficientes_por_modelo.csv`: `modelo, termino, estimado, error_estandar, p_valor`
   - `rankings_ejemplo.csv`: el top 10 para código, math, escritura creativa, código + math y una pregunta sin ninguna característica.

## Lo que el profesor quiere ver

La respuesta y los predictores explícitos, y el trabajo, no solo el resultado. Deja comentado en el script qué es cada paso.

## Para documentar

- Los votos se usan 2 veces (una por cada modelo), así que las regresiones no son independientes. El profesor lo sabe y dijo que por ahora no nos preocupemos. Igual hay que mencionarlo en el reporte.
- Decisión abierta #5 (`docs/07`): si se controla por la fuerza del rival. Primero sin rival. Si sobra tiempo, una versión con `fuerza_rival` (el % de victorias general del rival) como chequeo.
