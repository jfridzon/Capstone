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
# Usa las mismas preguntas decisivas y regresiones del proyecto.
project <- new.env()
previous <- options(correr_02 = FALSE)
tryCatch(sys.source("R/02_regresiones_por_modelo.R", envir = project),
         finally = options(previous))
questions <- project$preparar_respuesta(project$cargar_base())
fits <- project$ajustar_modelos(questions, rival = FALSE)
features <- c(is_code = "Coding", math = "Math", creative_writing = "Creative writing",
              instruction_following = "Following instructions", complexity = "Complex tasks",
              creativity = "Creativity", domain_knowledge = "Domain knowledge",
              problem_solving = "Problem solving", real_world = "Real-world tasks",
              specificity = "Specific requests", technical_accuracy = "Technical accuracy")
stopifnot(setequal(names(features), project$predictores),
          length(fits) == 48L, all(vapply(fits, function(f)
            f$converged && f$family$family == "binomial", logical(1))))
# Cada combinación se evalúa como un perfil: etiquetas marcadas TRUE.
profiles <- expand.grid(rep(list(c(FALSE, TRUE)), length(features)))
names(profiles) <- names(features)
weights <- 2^(seq_along(features) - 1L)
unique_questions <- questions[!duplicated(questions$id), names(features)]
observed <- tabulate(as.integer(as.matrix(unique_questions) %*% weights) + 1L,
                     nbins = nrow(profiles))
models <- sort(names(fits))
scores <- vapply(models, function(model) {
  as.numeric(predict(fits[[model]], newdata = profiles, type = "response"))
}, numeric(nrow(profiles)))
stopifnot(all(is.finite(scores)), sum(observed) == length(unique(questions$id)))
prices <- read.csv("data/derivados/precios_modelos_2026-11-02_v4.csv",
                   stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(prices$modelo), all(grepl("^[[:alnum:].:_/-]+$", models)))
price <- prices$precio_salida_usd_por_millon[match(models, prices$modelo)]
feature_checks <- paste0("<label><input type='checkbox' name='operation-feature' value='",
                         weights, "'> ", escape(features), "</label>")
# Exporta los coeficientes para evaluar perfiles sin servidor.
terms <- c("(Intercept)", paste0(names(features), "TRUE"))
betas <- vapply(models, function(m) unname(coef(fits[[m]])[terms]), numeric(length(terms)))
stopifnot(all(is.finite(betas)),
          max(abs(scores - plogis(cbind(1, as.matrix(profiles)) %*% betas))) < 1e-12)
profile_data <- paste(observed, collapse = ",")
model_data <- paste0('["', models, '",', ifelse(is.finite(price), price, "null"), ',',
                     apply(betas, 2, function(x) paste(sprintf("%.16g", x), collapse = ",")),
                     ']', collapse = ",")
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
  "@@ROWS@@" = rows,
  "@@FEATURES@@" = feature_checks,
  "@@PROFILES@@" = profile_data,
  "@@MODELS_DATA@@" = model_data
)
for (key in names(values)) template <- replace_token(template, key, values[[key]])
stopifnot(!grepl("@@", template, fixed = TRUE))
writeLines(enc2utf8(template), "dashboard/index.html", useBytes = TRUE)
best <- max.col(scores, ties.method = "first")
export <- data.frame(profile = seq_len(nrow(profiles)) - 1L, matching_votes = observed,
                     modelo = models[best],
                     prob_ganar = scores[cbind(seq_len(nrow(profiles)), best)])
write.csv(export, "R/resultados/dashboard_ranking_por_variable.csv", row.names = FALSE)
print(vote[c("fold", vote_columns)], row.names = FALSE)
print(model[c("Method", "Mean_CV")], row.names = FALSE)
