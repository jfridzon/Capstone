# 12. Decisiones del 2/11/2026

Jaime cerró las 6 decisiones abiertas de `docs/07` para que la fase de análisis (4/11 a 16/11) pueda arrancar. Cada una se probó antes con datos: `R/08_chequeo_decisiones.R` (resultados en `R/resultados/decisiones_2026-11-02/`). **Si alguien no está de acuerdo, lo dice en el PR o en su issue antes del miércoles 4/11.**

Cómo se probó: las 48 regresiones de `R/02`, ajustadas solo con train (abril a junio), sobre los mismos 20,416 votos decisivos de julio que usa Mark. Se miden 2 cosas:
- **Aciertos:** % de votos donde el modelo que predecimos ganador ganó.
- **Log-loss:** qué tan buenas son las probabilidades (más bajo es mejor). Sirve porque una probabilidad de 51% y una de 90% cuentan igual en aciertos, pero no son igual de útiles.

## Resumen

| # | Decisión | Qué se hace |
|---|---|---|
| 1 | Empates y both_bad | **Medio punto** (0.5) para los dos en el ajuste. La evaluación sigue sobre votos decisivos |
| 2 | Versiones de Gemini 2.5 Pro | **No se agrupan** en las regresiones. La herramienta solo recomienda modelos con 100 o más votos en julio |
| 3 | Variable `thinking` | **No se crea como predictor.** Marco agrega una columna `razona` (sí/no) a la tabla de precios |
| 4 | Modelos que solo están en julio | Evaluación principal: **julio** (44 modelos). Chequeo extra: **partición aleatoria por sesión**, 5 semillas, con los 48 |
| 5 | Controlar por el rival | **No** en las 48. La regresión combinada (Bradley-Terry) ya lo controla de forma exacta |
| 6 | Si no le ganamos al ranking general | Le ganamos poco en aciertos, y en probabilidades le ganamos al % de victorias (contra Bradley-Terry no es claro, ver abajo). Se reporta tal cual y **el valor de la presentación va al top 3 por tarea + precio** |
| Nuevo | Ridge | Se agrega como variante: encoge los 11 efectos hacia 0 en los modelos con pocos votos. El λ se elige **solo con train** (validación cruzada), nunca mirando julio |

## 1. Empates y both_bad: medio punto

Hoy se botan 28,767 votos (27% de los 106,630). Con medio punto se usan todos.

| Política (julio, sin ridge) | Aciertos 48 | Aciertos base | Log-loss 48 | Log-loss base |
|---|---|---|---|---|
| Excluir | 65.15% | 64.47% | 0.6298 | 0.6340 |
| **Medio punto** | **65.16%** | 64.51% | 0.6321 | 0.6378 |
| Empate 0.5, both_bad 0 | 65.13% | 64.61% | 0.6308 | 0.6363 |

- Los aciertos casi no cambian, así que se decide por principio: un empate dice que las 2 respuestas valían lo mismo, y botarlo pierde esa información. LMArena también cuenta los empates como medio punto en su leaderboard.
- both_bad también va a 0.5: dice que ninguna fue mejor que la otra, igual que un empate. La versión "both_bad = 0" no mejora nada.
- En R: `glm(..., family = quasibinomial)`, porque la respuesta ya no es solo 0 o 1. La columna es `won_medio_punto_escenario` de la base de Nessim.
- **Excluir** queda en el reporte como chequeo de sensibilidad (1 fila más en la tabla).
- Las 2 versiones (excluir o medio punto) se evalúan sobre los mismos votos decisivos de julio, porque en un empate no hay ganador que acertar.

## 2. Gemini 2.5 Pro: no se agrupa

| Versión (julio, medio punto) | Modelos | Aciertos 48 | Log-loss |
|---|---|---|---|
| Separadas | 44 | 65.16% | 0.6321 |
| Agrupadas | 42 | 65.13% | 0.6327 |

Da lo mismo, y son versiones distintas del modelo. Pero las 2 preview ya no existían en julio (0 y 1 votos ese mes, ver `votos_por_mes.csv`), así que no tiene sentido recomendarlas. **Regla para la herramienta y el top 3 de la presentación:** solo modelos con 100 o más votos en julio. Las preview siguen en el reporte técnico.

## 3. `thinking`: no es predictor

Cada una de las 48 regresiones es de 1 solo modelo, así que una variable "este modelo razona" sería constante dentro de cada regresión y no puede estimar nada. Donde sí importa es en el costo: los modelos que razonan gastan más tokens de salida. Por eso va como columna `razona` en la tabla de precios (Marco), con fuente.

## 4. Modelos solo de julio: partición aleatoria como chequeo

La evaluación principal sigue siendo la de julio (predecir el futuro con el pasado es la prueba honesta). Los 4 modelos de julio (grok-4, kimi-k2, mistral-small-2506, grok-3-mini-high) se incluyen con una partición aleatoria 80/20 por sesión:

| Semilla | Aciertos 48 (sin ridge) | Con ridge λ=30 | Base | Log-loss 48 (λ=30) | Log-loss base |
|---|---|---|---|---|---|
| 1 | 64.23% | 64.53% | 64.40% | 0.6373 | 0.6421 |
| 2 | 63.62% | 63.81% | 63.69% | 0.6408 | 0.6445 |
| 3 | 63.46% | 63.64% | 63.16% | 0.6421 | 0.6472 |
| 4 | 64.11% | 64.26% | 64.31% | 0.6372 | 0.6430 |
| 5 | 63.58% | 63.97% | 64.28% | 0.6400 | 0.6432 |

En aciertos es un empate técnico. En log-loss las 48 le ganan al % de victorias en las 5 (contra Bradley-Terry no se midió acá). **Esto es un hallazgo, no un problema:** el modelo que es mejor en general gana casi siempre, sin importar el tipo de pregunta. Las características sí cambian el orden debajo del 1º, y por eso importan cuando el mejor modelo es muy caro (decisión 6).

La herramienta final se ajusta con todos los votos (abril a julio), así que incluye a los 4 modelos de julio, marcados con su número de votos.

## 5. Rival: sin controlar en las 48

| Julio | Aciertos 48 | Log-loss 48 |
|---|---|---|
| Sin rival, excluir | 65.15% | 0.6298 |
| Con rival, excluir | 65.14% | 0.6683 |
| Sin rival, medio punto | 65.16% | 0.6321 |
| Con rival, medio punto | 65.23% | 0.6367 |

No mejora los aciertos y empeora las probabilidades. Además, el rival se asigna al azar, así que en promedio no sesga nada. El control exacto del rival lo hace la regresión combinada (Nessim).

## 6. Cómo se cuenta el resultado

- **Para el profesor:** las 48 regresiones predicen julio mejor que el ranking general (65.1% contra 64.5% de aciertos con medio punto, p < 0.01). La mejora es chica porque Gemini 2.5 Pro es 1º en casi todo.
- **Corrección del 2/11 (de la evaluación de Mark, PR #20):** en log-loss, las 48 le ganan claramente al % de victorias (mejora de 0.0058, IC 0.0042 a 0.0074), pero contra Bradley-Terry sin características la mejora es 0.0019 y su IC llega a 0. Antes este doc decía "siempre en log-loss": eso solo vale contra el % de victorias. Para el profesor se dice así, sin exagerar.
- **Para el negocio (presentación):** "si no quieres pagar el mejor, este es el mejor para tu tarea dentro de tu presupuesto". Ahí las características pesan, porque debajo del 1º el orden cambia mucho por tarea (por ejemplo MiniMax M1 en math). Esto une las 48 con la tabla de precios de Marco.

## Ridge

| λ (julio, medio punto) | Aciertos 48 | Log-loss |
|---|---|---|
| 0 | 65.16% | 0.6321 |
| 10 | 65.34% | 0.6319 |
| 30 | 65.35% | 0.6321 |
| 100 | 65.27% | 0.6331 |
| 300 | 65.04% | 0.6347 |

Ayuda un poco, sobre todo en la partición aleatoria (donde hay modelos con pocos votos). **Ojo:** esta tabla mira julio, así que **no** sirve para elegir λ. Mark elige λ con validación cruzada dentro de train y después evalúa una sola vez en julio.
