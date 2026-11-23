# Genera el dashboard de Eli con resultados publicados. Ejecutar desde la raíz.
# Preparado con asistencia de ChatGPT (OpenAI).
read_result <- function(path) read.csv(file.path("R/resultados", path),
                                      stringsAsFactors = FALSE)
vote <- read_result("regresion_grande_cv_2026-11-18/comparacion_por_voto.csv")
model <- read_result("fuerza_rival/escalera_auc.csv")
top <- read_result("top3_por_precio.csv")
vote <- vote[match(c("mean", as.character(1:5)), vote$fold), ]
stopifnot(!anyNA(vote), nrow(model) == 4, !anyNA(model),
          all(vote$scenario == "cv5"), sum(vote$n_votes[-1]) == vote$n_votes[1])
escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
fmt <- function(x) sprintf("%.4f", x)
chart <- function(labels, values) {
  stopifnot(length(labels) == length(values), all(values >= 0 & values <= 1))
  paste0("<div class='metric'><span>", escape(labels),
         "</span><strong>", fmt(values), "</strong><span class='track' aria-hidden='true'><span style='width:",
         100 * values, "%'></span></span></div>", collapse = "\n")
}
vote_columns <- c("auc_ranking_general", "auc_48_regresiones", "auc_big_01", "auc_big_05")
vote_labels <- c("General win-rate ranking", "48 logistic regressions",
                 "Bradley–Terry · decisive votes", "Bradley–Terry · ties as half points")
views <- c("5-fold average", paste("Fold", 1:5))
evidence <- vapply(seq_along(views), function(i) {
  v <- unlist(vote[i, vote_columns], use.names = FALSE)
  m <- model[[c("Mean_CV", paste0("Fold_", 1:5))[i]]]
  paste0("<div class='evidence' data-view='", i, "'", if (i > 1) " hidden", ">",
    "<div class='cards'><section><h3>Per vote</h3><p>Can the score rank votes where model A won above votes where model B won?</p>",
    chart(vote_labels, v), "</section>",
    "<section><h3>Per AI model</h3><p>Can each model’s score separate its own wins from losses? These are averages across all AI models.</p>",
    chart(model$Method, m), "</section></div>")
}, character(1))
tasks <- c(todas = "All questions", codigo = "Coding", math = "Math",
           escritura_creativa = "Creative writing")
budgets <- c(sin_limite = "No cap", hasta_0.50 = "$0.50", hasta_2 = "$2", hasta_10 = "$10")
options_html <- function(labels) paste0("<option>", escape(labels), "</option>", collapse = "")
rows <- do.call(c, lapply(seq_along(tasks), function(i) vapply(seq_along(budgets), function(j) {
  r <- top[top$tarea == names(tasks)[i] & top$presupuesto == names(budgets)[j], ]
  r <- r[order(r$puesto), ]
  stopifnot(identical(as.integer(r$puesto), 1:3), !anyNA(r[c("modelo", "prob_ganar", "precio_salida_usd_por_millon")]))
  paste0("<tbody data-task='", i, "' data-budget='", j, "'", if (i != 1 || j != 1) " hidden", ">",
    paste0("<tr><td>", r$puesto, "</td><th scope='row'>", escape(r$modelo),
           "</th><td>", sprintf("%.1f%%", r$prob_ganar * 100), "</td><td>",
           sprintf("$%.2f", r$precio_salida_usd_por_millon), "</td></tr>", collapse = ""),
    "</tbody>")
}, character(1))))
template <- paste(readLines("dashboard/template.html", warn = FALSE), collapse = "\n")
replace_token <- function(html, key, value) {
  parts <- strsplit(html, key, fixed = TRUE)[[1]]
  stopifnot(length(parts) == 2L)
  paste0(parts[1], paste(value, collapse = "\n"), parts[2])
}
values <- list(
  "@@VOTES@@" = format(vote$n_votes[1], big.mark = ","),
  "@@MODELS@@" = nrow(read_result("fuerza_rival/auc_rival_48x7.csv")),
  "@@GAIN@@" = fmt(model$Mean_CV[4] - model$Mean_CV[3]),
  "@@FOLDS@@" = options_html(views),
  "@@EVIDENCE@@" = evidence,
  "@@TASKS@@" = options_html(tasks),
  "@@BUDGETS@@" = options_html(budgets),
  "@@ROWS@@" = rows
)
for (key in names(values)) template <- replace_token(template, key, values[[key]])
stopifnot(!grepl("@@", template, fixed = TRUE))
writeLines(enc2utf8(template), "dashboard/index.html", useBytes = TRUE)
print(vote[c("fold", vote_columns)], row.names = FALSE)
print(model[c("Method", "Mean_CV")], row.names = FALSE)
