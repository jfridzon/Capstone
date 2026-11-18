# Nessim: verify the integrated 18/11 demo and preserve all upstream outputs.
# Prepared with ChatGPT/Codex assistance. Run from the repository root:
# Rscript --vanilla R/verificar_demo_18nov_nessim.R
out <- "R/resultados/nessim_demo_final_2026-11-18"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
# Snapshot every pre-existing data, submission and result file, including names.
protected_files <- function() {
  sort(unlist(lapply(c("data", "entregas", "R/resultados"), function(path) {
    list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  }), use.names = FALSE))
}
files <- protected_files()
files <- files[!startsWith(files, paste0(out, "/"))]
before <- tools::md5sum(files)
# A file device makes the same plots possible without an interactive display.
pdf(tempfile("nessim-demo-18nov-", fileext = ".pdf"), width = 8, height = 7)
source("R/14_demo_rstudio.R")
dev.off()
after_files <- protected_files()
after_files <- after_files[!startsWith(after_files, paste0(out, "/"))]
stopifnot(identical(files, after_files),
          identical(before, tools::md5sum(after_files)))
write.csv(confusion_18nov$tabla, file.path(out, "matriz_confusion.csv"),
          row.names = FALSE)
# Verify Marco's unchanged published table at its stored rounding.
marco_saved <- read.csv(
  "R/resultados/matriz_confusion/matriz_confusion_por_voto.csv",
  stringsAsFactors = FALSE
)
marco_live <- confusion_18nov$tabla
for (metric in c("accuracy", "precision", "recall")) {
  marco_live[[metric]] <- round(marco_live[[metric]], 4)
}
stopifnot(isTRUE(all.equal(marco_live, marco_saved, check.attributes = FALSE)),
          length(confusion_18nov$matrices) == 3L,
          nrow(marco_live) == 21L,
          "48 regressions + opponent strength" %in% marco_live$method)
write.csv(AUC_48x7, file.path(out, "auc_48x7.csv"))
write.csv(demo_18nov_dependencies, file.path(out, "dependencias.csv"),
          row.names = FALSE)
# Recalculated per-vote results from the visible GLM/pROC demo.
auc_demo_18nov <- rbind(
  data.frame(evaluation = "All data (in sample)",
             votes = auc_all$votes, AUC_48 = auc_all$AUC_48,
             AUC_general = auc_all$AUC_general),
  data.frame(evaluation = paste("Fold", auc_folds$fold),
             votes = auc_folds$votes, AUC_48 = auc_folds$AUC_48,
             AUC_general = auc_folds$AUC_general)
)
write.csv(auc_demo_18nov, file.path(out, "auc_por_voto.csv"), row.names = FALSE)
# Check the integrated public outputs against their unchanged source tables.
stopifnot(identical(dim(AUC_rival_48x7), c(48L, 7L)),
          setequal(rownames(AUC_rival_48x7), rownames(AUC_48x7)),
          all(is.finite(as.matrix(AUC_rival_48x7))),
          all(demo_18nov_dependencies$file_present))
eli_saved <- read.csv("R/resultados/fuerza_rival/escalera_auc.csv",
                      check.names = FALSE)
stopifnot(isTRUE(all.equal(AUC_ladder_18nov, eli_saved)))
mark_saved <- read.csv(paste0("R/resultados/regresion_grande_cv_2026-11-18/",
                             "comparacion_por_voto.csv"))
stopifnot(isTRUE(all.equal(AUC_big_18nov, mark_saved)))
# Mark's baseline and 48-regression columns must match the live demo by fold.
cv_big <- AUC_big_18nov[AUC_big_18nov$scenario == "cv5", ]
i <- match(auc_folds$fold, cv_big$fold)
stopifnot(!anyNA(i), all(cv_big$n_votes[i] == auc_folds$votes),
          all(cv_big$auc_48_regresiones[i] == round(auc_folds$AUC_48, 4)),
          all(cv_big$auc_ranking_general[i] == round(auc_folds$AUC_general, 4)))
write.csv(AUC_ladder_18nov, file.path(out, "escalera_auc.csv"), row.names = FALSE)
write.csv(AUC_gains_18nov, file.path(out, "incrementos_auc.csv"), row.names = FALSE)
write.csv(AUC_rival_48x7, file.path(out, "auc_rival_48x7.csv"))
write.csv(AUC_big_18nov, file.path(out, "regresion_grande.csv"), row.names = FALSE)

# Principal PR tables generated from the integrated R objects.
ladder_table <- c(
  "| Per-AI-model AUC | All data (in sample) | Mean CV |",
  "|---|---:|---:|",
  vapply(seq_len(nrow(AUC_ladder_18nov)), function(i) {
    row <- AUC_ladder_18nov[i, ]
    sprintf("| %s | %.4f | %.4f |", row$Method, row$All_data, row$Mean_CV)
  }, character(1)))
big_table <- c(
  "| Per-vote AUC | Big 0/1 | Big 0.5 | 48 regressions | General ranking |",
  "|---|---:|---:|---:|---:|",
  vapply(seq_len(nrow(AUC_big_18nov)), function(i) {
    row <- AUC_big_18nov[i, ]
    label <- if (row$scenario == "all_data") "All data (in sample)" else
      paste("Fold", row$fold)
    sprintf("| %s | %.4f | %.4f | %.4f | %.4f |", label,
            row$auc_big_01, row$auc_big_05, row$auc_48_regresiones,
            row$auc_ranking_general)
  }, character(1)))
confusion_total <- confusion_18nov$tabla[
  confusion_18nov$tabla$fold == "total", ]
confusion_table <- c(
  "| Per-vote method (all held-out folds) | Accuracy | Precision | Recall |",
  "|---|---:|---:|---:|",
  vapply(seq_len(nrow(confusion_total)), function(i) {
    row <- confusion_total[i, ]
    sprintf("| %s | %.4f | %.4f | %.4f |", row$method,
            row$accuracy, row$precision, row$recall)
  }, character(1)))
writeLines(c(ladder_table, "", big_table, "", confusion_table),
           file.path(out, "tabla_pr.md"))
writeLines(c(capture.output(sessionInfo()),
             "Pre-existing protected/result files and hashes unchanged.",
             "Integrated demo verified: Eli #68, Mark #67 and Marco #69.",
             "This does not replace Nessim's personal RStudio rehearsal."),
           file.path(out, "validacion.txt"))
cat("Pre-existing protected/result files and hashes unchanged.\n")
cat("Integrated demo verified: Eli #68, Mark #67 and Marco #69.\n")
