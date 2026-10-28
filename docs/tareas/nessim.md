# Tarea de Nessim: la base para las regresiones

**Para cuándo:** lunes 2/11. **Rama:** `nessim/preparar-datos`. Las tareas de Jaime y Mark dependen de esta.

## Qué hay que hacer

Un script `R/01_preparar_datos.R` que lea `data/lmarena_votes.csv` y genere 2 archivos en `data/derivados/`:

1. **`votos_filtrados.csv`:** 1 fila por voto, con los mismos campos del original, después de aplicar estos 2 filtros:
   - Solo `evaluation_order == 1`.
   - Solo votos donde los 2 modelos están entre los 48 con 1,000 votos o más (contando todas sus apariciones, como model_a y como model_b). Los 5 que salen están en `docs/03-datos.md`.
2. **`votos_largo.csv`:** cada voto filtrado partido en 2 filas, 1 por modelo, con estas columnas:
   `id, evaluation_session_id, timestamp, mes, modelo, rival, lado (a/b), resultado (gano / perdio / empate / ambos_malos), won (1 si gano, 0 si perdio, NA si empate o ambos_malos), is_code, math, creative_writing, instruction_following, complexity, creativity, domain_knowledge, problem_solving, real_world, specificity, technical_accuracy, sum_user_tokens, language`

## Cómo sabes que está bien

En el pull request, reporta los conteos que da el script. Deberían cuadrar con `docs/05-resultados.md`:
- `votos_filtrados.csv`: 106,630 filas.
- `votos_largo.csv`: 213,260 filas (el doble).
- Votos con ganador: 77,863. Si no cuadra, explica por qué antes de seguir.

## Decisión que te toca proponer (no tomarla)

Qué hacer con los empates y los both_bad: excluirlos (como hasta ahora) o contarlos como medio punto. Por eso `won` queda en NA para esos casos y `resultado` guarda el detalle, así se puede hacer cualquiera de las 2. Pon tu propuesta y el porqué en el pull request.

## No hagas

- No edites `data/lmarena_votes.csv`.
- No agregues predictores que se conocen después de la respuesta (largo de la respuesta, formato).
