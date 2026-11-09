# App Shiny: el mejor modelo de IA para tu pregunta y tu presupuesto
# (Marco, tarea D2 de la fase 2b, docs/14)
#
# Esto es el ESQUELETO: funciona de punta a punta, pero el diseño y las opciones
# extra quedan para la fase de la app (18/11 a 30/11, docs/07).
#
# Qué hace:
#   1. Al abrir, ajusta las 48 regresiones de R/02 con sus valores por defecto
#      (binomial, votos con ganador de abril a julio, sin los 28 de revisión, sin ridge).
#      Tarda unos segundos, 1 sola vez.
#   2. Tú marcas las características de tu pregunta y eliges un presupuesto.
#   3. Llama a top3() de R/02 y muestra los 3 modelos con mayor probabilidad de ganar,
#      con su precio (tabla de precios v4) y si razonan.
#
# Son los mismos números que R/resultados/top3_por_precio.csv (R/12): no calcula nada nuevo.
#
# Cómo abrirla, desde la raíz del repo (en RStudio o en la consola):
#   shiny::runApp("app")
# Paquetes: shiny (lo demás es R base).

library(shiny)

# Shiny corre este archivo desde la carpeta app/. Los scripts del repo usan rutas
# desde la raíz, así que nos movemos a la raíz.
# Mientras la app corre, Shiny vuelve a la carpeta app/, así que los archivos que se
# leen después usan la ruta completa (raiz).
if (!file.exists("R/02_regresiones_por_modelo.R")) setwd("..")
stopifnot(file.exists("R/02_regresiones_por_modelo.R"))
raiz <- normalizePath(".")

options(correr_02 = FALSE)
source("R/02_regresiones_por_modelo.R")

archivo_precios <- file.path(raiz, "data/derivados/precios_modelos_2026-11-02_v4.csv")
archivo_meses   <- file.path(raiz, "R/resultados/decisiones_2026-11-02/votos_por_mes.csv")

# ---- Datos (se calculan 1 vez al abrir la app) ----------------------------------

message("Ajustando las 48 regresiones...")
base    <- cargar_base()
datos   <- preparar_respuesta(base)          # binomial: votos con ganador
ajustes <- ajustar_modelos(datos)
preguntas_reales <- attr(ajustes, "preguntas")
precios <- read.csv(archivo_precios, stringsAsFactors = FALSE, encoding = "UTF-8")
message("Listo: ", length(ajustes), " regresiones.")

# Nombres que ve el usuario para las 11 características
etiquetas <- c(
  is_code               = "Code",
  math                  = "Math",
  creative_writing      = "Creative writing",
  instruction_following = "Follow specific instructions",
  complexity            = "Complex question",
  creativity            = "Needs creativity",
  domain_knowledge      = "Needs expert knowledge",
  problem_solving       = "Problem solving",
  real_world            = "Real-world task",
  specificity           = "Very specific question",
  technical_accuracy    = "Needs technical accuracy"
)
stopifnot(setequal(names(etiquetas), predictores))

presupuestos <- c("No limit"      = Inf,
                  "Up to $10"     = 10,
                  "Up to $2"      = 2,
                  "Up to $0.50"   = 0.5)

# ---- Interfaz ----------------------------------------------------------------------

ui <- fluidPage(
  titlePanel("Which AI model should I use?"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("caracteristicas", "What is your question like?",
                         choices = setNames(names(etiquetas), etiquetas),
                         selected = "is_code"),
      radioButtons("presupuesto", "Budget (price per 1M output tokens)",
                   choices = names(presupuestos), selected = "No limit"),
      helpText("Leave everything unchecked to see the best models for all questions.")
    ),
    mainPanel(
      h3("Top 3 models"),
      tableOutput("top"),
      textOutput("resumen"),
      tags$hr(),
      helpText(
        "Win probability: chance that the model wins a vote against a random rival,",
        "averaged over real LMArena questions with the characteristics you picked",
        "(votes with a winner, April to July 2025).",
        "Prices: official list prices, July 2025. Models without an official price",
        "or with fewer than 100 votes in July are not shown.",
        "Models that reason use more output tokens, so their real cost per answer is higher."
      )
    )
  )
)

# ---- Lógica ------------------------------------------------------------------------

server <- function(input, output, session) {

  # Cuántas preguntas reales tienen TODAS las características marcadas
  n_preguntas <- reactive({
    car <- input$caracteristicas
    if (length(car) == 0) return(nrow(preguntas_reales))
    sum(apply(preguntas_reales[car], 1, all))
  })

  resultado <- reactive({
    car <- if (is.null(input$caracteristicas)) character(0) else input$caracteristicas
    validate(need(n_preguntas() > 0,
                  "No real questions have all these characteristics. Uncheck one."))
    lim <- presupuestos[[input$presupuesto]]
    # "No limit" usa un tope enorme en vez de NULL para que, igual que en R/12,
    # solo entren modelos con precio oficial (top3() deja fuera los precios vacíos).
    top <- top3(car, ajustes,
                precio_max = if (is.finite(lim)) lim else 1e9,
                archivo_meses = archivo_meses,
                archivo_precios = archivo_precios)
    validate(need(nrow(top) > 0, "No model fits this budget."))
    i <- match(top$modelo, precios$modelo)
    data.frame(
      Rank                        = seq_len(nrow(top)),
      Model                       = top$modelo,
      Company                     = precios$compania[i],
      `Win probability`           = sprintf("%.1f%%", 100 * top$prob_ganar),
      `Output price ($ per 1M)`   = sprintf("$%g", precios$precio_salida_usd_por_millon[i]),
      `Input price ($ per 1M)`    = sprintf("$%g", precios$precio_entrada_usd_por_millon[i]),
      Reasons                     = ifelse(precios$razona[i] == "si", "yes", "no"),
      check.names = FALSE
    )
  })

  output$top <- renderTable(resultado(), align = "l")

  output$resumen <- renderText({
    sprintf("Based on %s real questions with these characteristics.",
            format(n_preguntas(), big.mark = ","))
  })
}

shinyApp(ui, server)
