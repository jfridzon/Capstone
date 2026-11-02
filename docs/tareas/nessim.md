# Tarea de Nessim

## Fase 2 (desde el 2/11): lo que toca ahora

**Fase 2, para el lunes 16/11. Rama:** `nessim/bradley-terry`. Lee antes `docs/04-metodo.md` (nivel 3) y `docs/12-decisiones-2-11.md`.

### Qué hay que hacer: la regresión combinada (Bradley-Terry con covariables)

Es la comparación que pidió el profesor después de las 48. Un script nuevo, `R/07_bradley_terry_covariables.R`:

1. **1 fila por voto** (no la base larga). Respuesta `y` = 1 si ganó model_a, 0 si ganó model_b, 0.5 si empate o both_bad (decisión 1; con `quasibinomial`).
2. **Predictores:** `x_m` = +1 / −1 / 0 por modelo, y `z_m,k = x_m × característica_k` por modelo y característica. Sin intercepto. Las características nunca entran solas. 1 modelo de referencia (`claude-opus-4-20250514`, como Mark).
3. Con **ridge** sobre los `z` (con `glmnet`, `alpha = 0`, o a mano), con λ elegido en train. Son unos 564 coeficientes.
4. Ajustar **solo con train** (`R/resultados/split_train_test.csv`) y evaluar en los mismos votos decisivos de julio que Mark: aciertos y log-loss. Usa la función de evaluación de Mark si ya está; si no, la misma lógica de `R/08_chequeo_decisiones.R`.
5. Guardar la fila en `R/resultados/evaluacion.csv` y los números en `docs/05`. Comparar el top 3 por tarea con el de las 48: ¿salen los mismos modelos?

### Para documentar

Esta regresión sí controla al rival de forma exacta (decisión 5), y no usa cada voto 2 veces. Son las 2 ventajas sobre las 48, y hay que decirlas en el reporte.

### No hagas

- No toques `R/02` ni `R/03`.

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (hecha el 28/10, se deja como referencia)

**Para cuándo:** lunes 2/11. **Rama:** `nessim/preparar-datos`. Las tareas de Jaime y Mark dependen de esta.

### Qué hay que hacer

Un script `R/01_preparar_datos.R` que lea `data/lmarena_votes.csv` y genere 2 archivos en `data/derivados/`:

1. **`votos_filtrados.csv`:** 1 fila por voto, con los mismos campos del original, después de aplicar estos 2 filtros:
   - Solo `evaluation_order == 1`.
   - Solo votos donde los 2 modelos están entre los 48 con 1,000 votos o más (contando todas sus apariciones, como model_a y como model_b). Los 5 que salen están en `docs/03-datos.md`.
2. **`votos_largo.csv`:** cada voto filtrado partido en 2 filas, 1 por modelo, con estas columnas:
   `id, evaluation_session_id, timestamp, mes, modelo, rival, lado (a/b), resultado (gano / perdio / empate / ambos_malos), won (1 si gano, 0 si perdio, NA si empate o ambos_malos), is_code, math, creative_writing, instruction_following, complexity, creativity, domain_knowledge, problem_solving, real_world, specificity, technical_accuracy, sum_user_tokens, language`

### Cómo sabes que está bien

En el pull request, reporta los conteos que da el script. Deberían cuadrar con `docs/05-resultados.md`:
- `votos_filtrados.csv`: 106,630 filas.
- `votos_largo.csv`: 213,260 filas (el doble).
- Votos con ganador: 77,863. Si no cuadra, explica por qué antes de seguir.

### Decisión que te toca proponer (no tomarla)

Qué hacer con los empates y los both_bad: excluirlos (como hasta ahora) o contarlos como medio punto. Por eso `won` queda en NA para esos casos y `resultado` guarda el detalle, así se puede hacer cualquiera de las 2. Pon tu propuesta y el porqué en el pull request.

### No hagas

- No edites `data/lmarena_votes.csv`.
- No agregues predictores que se conocen después de la respuesta (largo de la respuesta, formato).
