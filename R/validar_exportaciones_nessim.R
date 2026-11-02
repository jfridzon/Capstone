# Validacion de los CSV escritos, independiente de objetos en memoria.
# Ejecutar desde la raiz tras preparar_datos(). Asistencia: ChatGPT/Codex.
library(readr)
library(dplyr)
x <- read_csv("data/lmarena_votes.csv", col_types = cols(.default = col_character()),
              show_col_types = FALSE)
f <- read_csv("data/derivados/votos_filtrados.csv",
              col_types = cols(.default = col_character()), show_col_types = FALSE)
l <- read_csv("data/derivados/votos_largo.csv",
              col_types = cols(.default = col_character()), show_col_types = FALSE)
originales <- x[match(f$id, x$id), ]
mapa <- match(l$id, f$id)
stopifnot(!anyNA(mapa), identical(names(f), names(x)),
          identical(as.data.frame(f), as.data.frame(originales)))
base <- f[mapa, ]
stopifnot(all(l$modelo == ifelse(l$lado == "a", base$model_a, base$model_b)),
          all(l$rival == ifelse(l$lado == "a", base$model_b, base$model_a)),
          all(l$evaluation_session_id == base$evaluation_session_id),
          all(as.integer(l$mes) == as.integer(substr(base$timestamp, 6, 7))))
for (campo in c("is_code", "math", "creative_writing", "instruction_following",
  "complexity", "creativity", "domain_knowledge", "problem_solving",
  "real_world", "specificity", "technical_accuracy", "sum_user_tokens", "language")) {
  stopifnot(identical(l[[campo]], base[[campo]]))
}
pares <- l |> count(id)
stopifnot(all(pares$n == 2L), nrow(l) == 2L * nrow(f),
  all(is.na(l$won[l$resultado %in% c("empate", "ambos_malos")])),
  all(l$won[l$resultado == "gano"] == "1"),
  all(l$won[l$resultado == "perdio"] == "0"))
resumen <- tibble(control = c("campos_originales_conservados",
  "valores_originales_conservados", "modelo_rival_lado_consistentes",
  "caracteristicas_tokens_idioma_conservados", "dos_filas_por_voto",
  "won_segun_resultado", "filas_filtradas", "filas_largas"),
  resultado = c(rep("TRUE", 6), as.character(nrow(f)), as.character(nrow(l))))
write_csv(resumen, "R/resultados/preparacion_ficha_2026-11-02/validacion_exportaciones.csv")
print(resumen)
