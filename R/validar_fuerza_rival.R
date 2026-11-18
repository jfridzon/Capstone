# Eli: comprobaciones de integracion y ausencia de fuga, 18/11/2026.
# Ejecutar DESPUES de R/19: Rscript --vanilla R/validar_fuerza_rival.R
# Preparado con asistencia de ChatGPT/Codex (OpenAI).
options(warn = 2)
files <- list.files(".", recursive = TRUE)
opts <- options()
device <- dev.cur()
source("R/19_fuerza_rival.R")
stopifnot(identical(files, list.files(".", recursive = TRUE)),
          identical(opts, options()), identical(device, dev.cur()),
          length(formals(escalera_auc)) == 0L,
          length(formals(tabla_auc_rival)) == 0L)
cat("PASS: source has no file, option or device effects; public functions take no arguments.\n")

input <- .eli19_datos()
d <- input$d
train <- d[d$fold != 1L, ]
test <- d[d$fold == 1L, ]
rates <- .eli19_tasas(train)
# Cambiar TODAS las respuestas reservadas no puede afectar ninguna fuerza de train.
changed <- d
# as.integer: sin esto '1 - won' vuelve decimal toda la columna y identical() falla solo por el tipo.
changed$won[changed$fold == 1L] <- as.integer(1L - changed$won[changed$fold == 1L])
stopifnot(identical(rates, .eli19_tasas(changed[changed$fold != 1L, ])))
cat("PASS: changing held-out outcomes cannot change training strengths.\n")

fails <- function(expr) inherits(tryCatch(force(expr), error = function(e) e), "error")
bad <- test[1, ]
bad$rival <- "not_a_training_model"
stopifnot(fails(.eli19_con_rival(bad, rates)),
          is.na(.eli19_auc(rep(1, 2), c(0, 1))),
          .eli19_auc(c(0, 1), c(0.5, 0.5)) == 0.5,
          fails(.eli19_auc(c(0, 1), c(NA, 0))))
cat("PASS: missing training opponents and invalid scores fail; one-class test gives NA.\n")

# Comprobacion independiente con la interfaz ya existente de R/02.
env02 <- new.env()
old <- options(correr_02 = FALSE)
sys.source("R/02_regresiones_por_modelo.R", envir = env02)
options(old)
models <- env02$ajustar_modelos(train, rival = TRUE)
pred <- read.csv(gzfile(file.path(.eli19_dir, "predicciones_cv.csv.gz")), stringsAsFactors = FALSE)
test <- .eli19_con_rival(test, rates)
ref <- pred[pred$fold == 1L, ]
stopifnot(nrow(ref) == nrow(test), !anyDuplicated(paste(ref$id, ref$model)))
for (model in names(models)) {
  x <- test[test$model == model, ]
  r <- ref[match(paste(x$id, x$model), paste(ref$id, ref$model)), ]
  stopifnot(models[[model]]$converged, !anyNA(r),
            max(abs(as.numeric(predict(models[[model]], x, type = "link")) - r$score)) < 1e-10)
}
cat("PASS: fold 1 scores match all 48 original R/02 opponent-control fits.\n")

ladder <- escalera_auc()
wide <- tabla_auc_rival()
stopifnot(nrow(ladder) == 4L, identical(dim(wide), c(48L, 7L)),
          all(ladder[1, -1] == 0.5),
          max(abs(rowMeans(wide[paste0("Fold_", 1:5)]) - wide$Mean_CV)) < 1e-12,
          max(abs(colMeans(wide)[names(ladder)[-1]] - unlist(ladder[4, -1]))) < 1e-12)
counts <- read.csv(file.path(.eli19_dir, "controles_folds.csv"))
stopifnot(all(counts$overlap_votes[counts$scenario == "cv5"] == 0L),
          all(counts$overlap_sessions[counts$scenario == "cv5"] == 0L))
paired <- read.csv(gzfile(file.path(.eli19_dir, "predicciones_por_voto_cv.csv.gz")))
stopifnot(!anyDuplicated(paired$id), setequal(paired$id, d$id),
          all(paired$y %in% c(0, 1)),
          max(abs(paired$p_A - plogis(paired$score_A - paired$score_B))) < 1e-12)
cat("PASS: complete ladder, 48 x 7 table, session isolation and paired CV exports.\n")
cat("ALL OPPONENT-STRENGTH VALIDATIONS PASSED.\n")
