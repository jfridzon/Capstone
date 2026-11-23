# Run from the repository root. OpenAI Codex assisted with this verification.
stopifnot(file.exists("app/app.R"))
ref <- read.csv("R/resultados/top3_por_precio.csv", stringsAsFactors = FALSE)
tasks <- list(todas = character(), codigo = "is_code", math = "math",
              escritura_creativa = "creative_writing")
rates <- c(sin_limite = Inf, hasta_10 = 10, hasta_2 = 2, hasta_0.50 = 0.5)
check_result <- function(result, expected, limit) {
  stopifnot(identical(result$modelo, expected$modelo),
            identical(result$rank, expected$puesto),
            all(round(result$prob_ganar, 3) == expected$prob_ganar),
            all(result$votos_julio >= 100),
            all(is.finite(result$precio_salida_usd_por_millon)),
            all(result$precio_salida_usd_por_millon <= limit))
}

if ("--model-only" %in% commandArgs(TRUE)) {
  options(correr_02 = FALSE)
  source("R/02_regresiones_por_modelo.R")
  fits <- ajustar_modelos(preparar_respuesta(cargar_base()))
  stopifnot(length(fits) == 48L)
  for (task in names(tasks)) for (budget in names(rates)) {
    limit <- rates[[budget]]
    result <- top3(tasks[[task]], fits, precio_max = if (is.finite(limit)) limit else .Machine$double.xmax,
                   archivo_precios = "data/derivados/precios_modelos_2026-11-02_v4.csv")
    expected <- subset(ref, tarea == task & presupuesto == budget)
    check_result(result, expected, limit)
  }
} else {
  source("app/app.R", local = TRUE)
  shiny::testServer(server, {
    for (task in names(tasks)) for (budget in names(rates)) {
      limit <- rates[[budget]]
      label <- names(presupuestos)[match(limit, presupuestos)]
      session$setInputs(caracteristicas = tasks[[task]], presupuesto = label)
      expected <- subset(ref, tarea == task & presupuesto == budget)
      check_result(top_modelos(), expected, limit)
      stopifnot(n_preguntas() == expected$preguntas_reales[1],
                identical(resultado()[["Price date"]], precios$fecha_del_precio[match(expected$modelo, precios$modelo)]),
                length(output$grafico) > 0, nzchar(output$top))
    }
    session$setInputs(caracteristicas = c("math", "is_code"), presupuesto = "Up to $2")
    stopifnot(n_preguntas() == sum(preguntas_reales$math & preguntas_reales$is_code),
              all(top_modelos()$precio_salida_usd_por_millon <= 2))
  })
}
cat("PASS: 4 task profiles x 4 budgets, all 48 published ranks and scores.\n")
