# Eli, C1: sensibilidad de coeficientes (9/11/2026)

Generador: `R/12_sensibilidad.R`. Requiere MASS. Ejecutar desde la raíz del repo.

Ajuste descriptivo con todos los meses (abril–julio), los 48 modelos y las mismas 11 características de R/02.
Se usa la base de Nessim y se excluyen sus casos de revisión, igual que R/02. Sin rival ni ridge.
Binomial usa solo victorias/derrotas; quasibinomial usa también empate y both_bad como 0.5.
Ordinal usa peor < empate < mejor; both_bad se agrupa con empate, sin cambiar los datos.

| Comparación (11 efectos por modelo) | Modelos | Pearson mín. | Mediana | Máx. | Spearman mediana | Signos iguales |
|---|---:|---:|---:|---:|---:|---:|
| binomial_vs_quasibinomial | 48 | 0.9188 | 0.9974 | 0.9997 | 0.9909 | 508/528 |
| binomial_vs_ordinal | 48 | 0.8443 | 0.9938 | 0.9992 | 0.9818 | 500/528 |
| quasibinomial_vs_ordinal | 48 | 0.9870 | 0.9992 | 0.9999 | 0.9955 | 520/528 |

Cada correlación compara los 11 efectos DENTRO de un modelo; el resumen abarca los 48 modelos.
El ordinal usa logit P(Y <= k) = umbral_k - X beta: un beta positivo apunta hacia mejor.
No se comparan interceptos con umbrales; se exportan aparte. No son parámetros equivalentes.
Las escalas y respuestas son distintas: correlación alta no significa coeficientes idénticos ni equivalencia predictiva.
No se calcula AUC, no se evalúa julio fuera de muestra y no se cambia el método principal binomial.
Las filas de un mismo voto se usan para dos modelos. Las correlaciones son descriptivas, sin p-valores.
C2 (gráfico ROC) sigue pendiente de que la tarea B de Mark (#32) esté fusionada en main.

Código y documentación preparados con asistencia de ChatGPT/Codex (OpenAI).
