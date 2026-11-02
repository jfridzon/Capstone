# Tarea de Nessim

## Fase 2 (desde el 2/11): lo que toca ahora

Tienes 2 tareas, en este orden. **La 1 es nueva** (era de Jaime y pasó a ti el 2/11 en la noche). Lee antes `docs/12-decisiones-2-11.md`.

### Tarea 1, para el lunes 9/11: las 48 regresiones, listas para mostrarle al profesor

**Rama:** `nessim/regresiones-48`. El profesor dijo el 26/10 que quiere **ver el trabajo**, no solo el resultado: la variable de respuesta, los predictores y las regresiones de verdad. `R/02_regresiones_por_modelo.R` ya existe (lo hizo Jaime en la fase 1) y Mark ya lo evaluó en julio (`R/03`, PR #18 y #20). No empieces de cero.

1. **Actualizar `R/02` a las decisiones del 2/11:**
   - `politica_empates <- "medio_punto"` por defecto (usa `won_medio_punto_escenario`, `glm` con `quasibinomial`). `"excluir"` sigue disponible como chequeo.
   - Argumento `lambda` en `ajustar_modelos()` para ridge (0 = el `glm` de siempre). Penaliza solo los 11 efectos, nunca el intercepto. Puedes copiar la función `ajustar()` de `R/08_chequeo_decisiones.R`. El λ lo elige Mark con train; tú solo dejas la opción.
   - Función `top3(caracteristicas, ajustes, precio_max = NULL)`: los 3 modelos con mayor probabilidad de ganar en preguntas reales con esas características (usa `ranking_real()`), **solo entre modelos con 100 o más votos en julio** (`R/resultados/decisiones_2026-11-02/votos_por_mes.csv`). `precio_max` filtra por precio de salida con la tabla de Marco (`data/derivados/precios_modelos_2026-10-28_v2.csv`).
   - Volver a generar `coeficientes_por_modelo.csv` y `rankings_ejemplo.csv` con medio punto y todos los votos (abril a julio), y actualizar la sección de las 48 en `docs/05`.
   - No cambies los nombres de `ajustar_modelos()` ni `probabilidad()`: `R/03` de Mark los usa.
2. **Un R Markdown para el profesor: `reporte/01_regresiones_48.Rmd`** (y el `.html` que genera, los 2 en el repo). En **inglés simple**, corto, que se entienda sin explicación:
   - Qué se predice y con qué: respuesta = el modelo ganó (1), perdió (0) o empató (0.5); predictores = las 11 características TRUE/FALSE, cada una explicada en 1 línea.
   - El código del `glm()` visible, y el `summary()` completo de 2 o 3 modelos de ejemplo (por ejemplo `gemini-2.5-pro`, `claude-opus-4-20250514` y uno con pocos votos), con 2 o 3 frases que lean los coeficientes (qué significa un coeficiente positivo en `math`).
   - La tabla o el heatmap de los coeficientes de los 48 (puedes reusar el gráfico de Eli).
   - El resultado en julio, leído de `R/resultados/evaluacion.csv` (no copies números a mano): 48 regresiones contra el ranking general, en aciertos y log-loss. Contarlo como es: ganan por poco (ver `docs/12`, decisión 6 y la corrección).
   - El top 3 por tarea con `top3()`.
   - Límites en 3 líneas: cada voto se usa 2 veces, 1 sola partición en el tiempo, 4 modelos solo en julio.
3. Tienes que poder explicarlo en persona: el profesor pregunta.

### Tarea 2, para el lunes 16/11: la regresión combinada

**Rama:** `nessim/bradley-terry`. Lee antes `docs/04-metodo.md` (nivel 3). Usa la función `evaluar()` de Mark si ya está.

#### Qué hay que hacer: Bradley-Terry con covariables

Es la comparación que pidió el profesor después de las 48. Un script nuevo, `R/07_bradley_terry_covariables.R`:

1. **1 fila por voto** (no la base larga). Respuesta `y` = 1 si ganó model_a, 0 si ganó model_b, 0.5 si empate o both_bad (decisión 1; con `quasibinomial`).
2. **Predictores:** `x_m` = +1 / −1 / 0 por modelo, y `z_m,k = x_m × característica_k` por modelo y característica. Sin intercepto. Las características nunca entran solas. 1 modelo de referencia (`claude-opus-4-20250514`, como Mark).
3. Con **ridge** sobre los `z` (con `glmnet`, `alpha = 0`, o a mano), con λ elegido en train. Son unos 564 coeficientes.
4. Ajustar **solo con train** (`R/resultados/split_train_test.csv`) y evaluar en los mismos votos decisivos de julio que Mark: aciertos y log-loss. Usa la función de evaluación de Mark si ya está; si no, la misma lógica de `R/08_chequeo_decisiones.R`.
5. Guardar la fila en `R/resultados/evaluacion.csv` y los números en `docs/05`. Comparar el top 3 por tarea con el de las 48: ¿salen los mismos modelos?

#### Para documentar

Esta regresión sí controla al rival de forma exacta (decisión 5), y no usa cada voto 2 veces. Son las 2 ventajas sobre las 48, y hay que decirlas en el reporte.

#### No hagas

- No toques `R/03`.
- No rehagas la fase 1 (la base ya está; ver abajo).

## Todos: primer update individual (lunes 9/11)

2 o 3 slides sobre **tu** tarea: qué hiciste, qué salió (con un número o un gráfico), qué sigue, y cómo ayuda al objetivo del grupo. Vale el 20% de la nota y se presenta en persona, así que tienes que poder explicar cada número sin leer.

---

## Fase 1 (YA HECHA el 28/10). No la repitas: es solo historia

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
