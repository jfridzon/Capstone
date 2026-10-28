# 04. El método: cómo hacemos la predicción

## La idea en simple

Piénsalo como una liga de fútbol. Cada voto es un partido entre 2 modelos. `model_a` y `model_b` son como local y visitante: el lado lo asigna LMArena al azar y no significa nada. Lo que importa es quién ganó. Queremos saber qué modelo es más fuerte en cada tipo de "cancha", es decir, según las características de la pregunta.

## Nivel 1: contar (porcentaje de victorias)

Cada voto se parte en 2 líneas, 1 por modelo, con `won = 1` si ganó y `0` si perdió. Para cada modelo y tipo de pregunta, el porcentaje de victorias es votos ganados ÷ votos en los que estuvo. Cualquiera lo entiende y se puede revisar a mano.

**Su límite:** no toma en cuenta contra quién jugó cada modelo. Un modelo al que le tocaron rivales débiles sale inflado. Además, las 2 líneas de un voto están ligadas (si una es 1, la otra es 0), así que no sirven como observaciones independientes en una regresión.

## Nivel 2: regresión logística de comparaciones de a pares (Bradley-Terry)

Es el modelo estándar para comparaciones de a pares y el que usa LMArena para su leaderboard.

- **Unidad:** 1 voto decisivo = 1 fila.
- **Respuesta:** `y = 1` si ganó model_a, `0` si ganó model_b.
- **Predictores:** 1 columna por modelo, con `+1` si es model_a, `−1` si es model_b y `0` si no está en el voto.
- **Coeficientes:** 1 por modelo, su **fuerza**. 1 modelo se fija en 0 como referencia.
- **Sin intercepto.** Si se agrega uno, mide si el lado izquierdo gana más por alguna razón. Por la asignación aleatoria debería salir cerca de 0, y eso sirve de prueba ante el profesor.

```
P(gana model_a) = 1 / (1 + e^-(fuerza_a − fuerza_b))
```

**Por qué el orden A/B no importa:** si se invierten los lados, se invierten todos los signos y también `y`, y la verosimilitud queda igual. El voto "GPT a la izquierda, Claude a la derecha, ganó Claude" y el voto "Claude a la izquierda, GPT a la derecha, ganó Claude" le dicen exactamente lo mismo a la regresión.

## Nivel 3: que la fuerza dependa de las características de la pregunta

### Versión que ya NO usamos: 10 "cajas"

El 21/10 le mandamos al profesor una página (`entregas/2026-10-21 metodo-ranking.html`) donde cada voto caía en 1 de 10 tipos de tarea: código, math, escritura creativa, instrucciones y otro, cada uno fácil o difícil, con 1 regresión por tipo.

**Problema:** las preguntas reales son una combinación de varias características (por ejemplo código + math + difícil), y con las cajas solo cuenta la primera. Se pierde información.

### Versión actual: Bradley-Terry con covariables

La fuerza de cada modelo en cada pregunta es su fuerza base más un ajuste por cada característica que esté en TRUE:

```
fuerza del modelo m en la pregunta q = β_m + γ_m,code·code(q) + γ_m,math·math(q) + ... (las 11 características)
```

En la regresión:
- **Respuesta:** igual, `y = 1` si ganó model_a.
- **Predictores, grupo 1:** `x_m` = +1 / −1 / 0 por cada modelo (como en el nivel 2).
- **Predictores, grupo 2:** `z_m,k = x_m × etiqueta_k` por cada modelo m y característica k. Vale +1 o −1 solo si el modelo está en el voto **y** la pregunta tiene esa característica.
- **Las características nunca entran solas.** Una columna `is_code` sola mediría "¿gana más el lado izquierdo en código?", que no significa nada.
- **Coeficientes:** con 48 modelos, 47 fuerzas base + 47 × 11 ajustes = **564 coeficientes** (el modelo de referencia vale 0 en todo). Con unos 78,000 votos decisivos alcanza. Una penalización ridge evita números extremos en los modelos con pocos votos.
- **Supuesto:** los efectos se suman (código + math = efecto de código + efecto de math). Si una combinación específica se comporta distinto, se agrega esa interacción puntual (por ejemplo código × math) y se revisa si mejora la predicción de julio.

**Ejemplo con números inventados.** En una pregunta de código + math: Gemini tiene 0.3 + 0.2 + 0.4 = 0.9 y Claude tiene 0.3 + 0.5 + 0.0 = 0.8. Gemini le gana a Claude con probabilidad 1 / (1 + e^−0.1) ≈ 52.5%, aunque Claude sea mejor en código solo.

**Nombre técnico (para el reporte):** "A Bradley-Terry model (a logistic regression on paired comparisons) with question characteristics as contest-specific covariates interacting with each model's strength". Paquete de R: `BradleyTerry2`, o directo con `glm(..., family = binomial)` sin intercepto. LMArena usa la misma estructura en su "style control" (covariables de largo y formato).

## Las opciones que se discutieron el 26/10 (decisión abierta)

El profesor quiere **una regresión logística, o varias, que permita rankear los modelos según las características de la pregunta.**

| | A. 1 regresión por modelo (48) | B. 1 regresión combinada (Bradley-Terry con covariables) | C. 1 regresión por cada par de modelos |
|---|---|---|---|
| Respuesta | `won` de ese modelo (1/0) | `y` = ganó model_a | ganó el modelo 1 del par |
| Predictores | las 11 características + `opponent_strength` (fuerza general del rival) | `x_m` y `z_m,k` (arriba) | las 11 características |
| Fácil de explicar | Sí | Más difícil | Sí |
| Ajusta por el rival | Aproximado | Exacto | No hace falta |
| Probabilidad cara a cara | Indirecta | Directa | Directa, pero solo para ese par |
| Problema | Rival controlado de forma aproximada | Más difícil de presentar | 1,128 pares posibles con unos 70 votos por par en promedio (estimado). La mayoría no alcanza, no comparte información entre pares y no da un ranking |

**Recomendación que está sobre la mesa:** A como modelo principal (el más fácil de presentar y defender), B como chequeo de que los rankings salen iguales y C solo para los 5 a 10 pares con más votos, para confirmar que las predicciones cara a cara cuadran. **No está decidido.** Ver `docs/07`.

Código de la opción A, para 1 modelo:

```r
glm(won ~ is_code + math + creative_writing + instruction_following + complexity + creativity +
          domain_knowledge + problem_solving + real_world + specificity +
          technical_accuracy + opponent_strength,
    family = binomial, data = votos_de_este_modelo)
```

**Cómo sale el ranking** (A o B): se elige un conjunto de características (por ejemplo código + difícil), se calcula para cada modelo su probabilidad de ganar, o su fuerza, en ese tipo de pregunta, y se ordena de mayor a menor.

## Cómo probamos que funciona

1. **Train:** votos del 17/4 al 30/6/2025. **Test:** votos de julio, que el modelo nunca vio.
2. En cada voto de julio se predice que gana el modelo con más fuerza para esas características, y se mide el % de aciertos.
3. Se compara contra el **ranking general**, 1 solo orden para todo (lo que hace el leaderboard principal de LMArena).
4. Los votos de julio con modelos que no estaban en train (por ejemplo grok-4, kimi-k2 y mistral-small-2506, que solo aparecen en julio) quedan fuera del test.
5. Una sesión de votación no se parte entre train y test.

**Resultado de la versión de 10 cajas:** 64.7% contra 64.5% del ranking general, prácticamente igual. Hay que correr esta prueba con la versión de covariables. Si tampoco mejora, también es un hallazgo ("1 modelo es el mejor en casi todo"), y el ángulo de **precio** (el mejor por el dinero) pasa a ser el valor principal para el cliente.

## Reglas que no se rompen

- Solo predictores que se conocen **antes** de que el modelo responda. El largo y el formato de la respuesta nunca son predictores.
- La gente vota por la respuesta más larga el 61.8% de las veces. Hay que mencionarlo al explicar resultados, porque un modelo puede ganar en parte por escribir más.
