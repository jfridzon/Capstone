# Nessim: verify the available demo, not the pending 18/11 integration.
# Prepared with ChatGPT/Codex assistance. Run from the repository root:
# Rscript --vanilla R/verificar_demo_18nov_nessim.R
out <- "R/resultados/nessim_demo_2026-11-18"
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
stopifnot(isTRUE(all.equal(marco_live, marco_saved, check.attributes = FALSE)))
write.csv(AUC_48x7, file.path(out, "auc_48x7.csv"))
write.csv(demo_18nov_dependencies, file.path(out, "dependencias.csv"),
          row.names = FALSE)
# Existing per-vote results only; this is not the pending opponent ladder.
auc_demo_18nov <- rbind(
  data.frame(evaluation = "All data (in sample)",
             votes = auc_all$votes, AUC_48 = auc_all$AUC_48,
             AUC_general = auc_all$AUC_general),
  data.frame(evaluation = paste("Fold", auc_folds$fold),
             votes = auc_folds$votes, AUC_48 = auc_folds$AUC_48,
             AUC_general = auc_folds$AUC_general)
)
write.csv(auc_demo_18nov, file.path(out, "auc_por_voto.csv"), row.names = FALSE)
pr_table <- c(
  "| Evaluation | Votes | 48 regressions | General ranking |",
  "|---|---:|---:|---:|",
  vapply(seq_len(nrow(auc_demo_18nov)), function(i) {
    row <- auc_demo_18nov[i, ]
    sprintf("| %s | %d | %.4f | %.4f |", row$evaluation, row$votes,
            row$AUC_48, row$AUC_general)
  }, character(1))
)
writeLines(pr_table, file.path(out, "tabla_pr.md"))
writeLines(c(capture.output(sessionInfo()),
             "Pre-existing protected/result files and hashes unchanged.",
             "Available sections verified; 18/11 integration still pending.",
             "This does not replace Nessim's personal RStudio rehearsal."),
           file.path(out, "validacion.txt"))
cat("Pre-existing protected/result files and hashes unchanged.\n")
cat("Available sections verified; 18/11 integration still pending.\n")
