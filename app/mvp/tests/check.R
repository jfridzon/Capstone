# Build an independent reference for standard and combined feature selections.
# Launch Chrome against the same HTML file a user opens. No web server is required.
source("R/generar_mvp.R")
ref <- read.csv("R/resultados/top3_por_precio.csv")
tasks <- list(todas = character(), codigo = "is_code", math = "math",
              escritura_creativa = "creative_writing", combined = c("math", "is_code"),
              all_features = predictores)
limits <- c(hasta_0.50 = 0.5, hasta_2 = 2, hasta_10 = 10, sin_limite = Inf)
cases <- list()
for (task in names(tasks)) for (budget in names(limits)) {
  features <- tasks[[task]]
  n <- sum(if (length(features)) Reduce(`&`, q[features]) else rep(TRUE, nrow(q)))
  limit <- limits[[budget]]
  result <- if (n) top3(features, fits, precio_max = min(limit, .Machine$double.xmax),
              archivo_precios = "data/derivados/precios_modelos_2026-11-02_v4.csv") else data.frame()
  published <- subset(ref, tarea == task & presupuesto == budget)
  if (nrow(published)) stopifnot(identical(result$modelo, published$modelo),
    n == published$preguntas_reales[1], all(round(result$prob_ganar, 3) == published$prob_ganar))
  cases[[length(cases)+1L]] <- list(features = I(features), limit = as.character(limit),
    count = n, ids = I(as.character(result$modelo)), scores = I(as.numeric(result$prob_ganar)))
}
fixture <- jsonlite::toJSON(cases, auto_unbox = TRUE, digits = 15)
writeLines(fixture, file.path(tempdir(), "cases.json"))
html <- paste(readLines("app/mvp/ArenaGuide.html"), collapse = "\n")
test <- paste(readLines("app/mvp/tests/browser.js"), collapse = "\n")
html <- sub("</html>", paste0("<script>const cases=", fixture, ";\n", test, "</script></html>"), html, fixed=TRUE)
probe <- tempfile(fileext = ".html")
writeLines(html, probe)
chrome <- Sys.getenv("CHROME_BIN", Sys.which("google-chrome"))
stopifnot(nzchar(chrome))
dom <- system2(chrome, c("--headless", "--no-sandbox", "--disable-gpu",
  paste0("--user-data-dir=", tempfile()), "--dump-dom", paste0("file://", probe)),
  stdout = TRUE, stderr = tempfile())
stopifnot(any(grepl('data-test="passed"', dom, fixed = TRUE)))
cat("PASS: 24 combinations, price limits, exact IDs, probabilities, counts, six dashboard views.\n")
