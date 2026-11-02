# Tarea de Jaime

## Fase 2 (desde el 2/11): lo que toca ahora

**Fase 2, para el lunes 9/11. Rama:** `jaime/regresiones-v2`. Lee antes `docs/12-decisiones-2-11.md`.

### Qué hay que hacer

Actualizar `R/02_regresiones_por_modelo.R` a las decisiones del 2/11:

1. **Medio punto por defecto:** `politica_empates <- "medio_punto"` (usa `won_medio_punto_escenario`, `glm` con `quasibinomial`). `"excluir"` sigue disponible como chequeo.
2. **Opción ridge:** un argumento `lambda` en `ajustar_modelos()` (0 = el `glm` de siempre). Penaliza solo los 11 efectos, nunca el intercepto. Se puede copiar la función `ajustar()` de `R/08_chequeo_decisiones.R`. El λ lo elige Mark con train, no Jaime.
3. **Herramienta `top3(caracteristicas, ajustes, precio_max = NULL)`:** devuelve los 3 modelos con mayor probabilidad de ganar en preguntas reales con esas características (usa `ranking_real()`), **solo entre modelos con 100 o más votos en julio** (`R/resultados/decisiones_2026-11-02/votos_por_mes.csv`). `precio_max` queda listo para cuando Marco tenga la tabla v3 (filtra por precio de salida).
4. **Volver a generar** `coeficientes_por_modelo.csv` y `rankings_ejemplo.csv` con medio punto y todos los votos (abril a julio). Actualizar la sección de las 48 en `docs/05`.

### No hagas

- No elijas λ mirando julio.
- No borres `con_rival`: queda en `FALSE` (decisión 5), pero sirve para el reporte.

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (hecha el 28/10, se deja como referencia)

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
