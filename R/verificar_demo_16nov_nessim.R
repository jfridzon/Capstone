# Nessim, demo 16/11: technical verification; final team rehearsal is pending.
# Prepared with ChatGPT/Codex assistance. Run from the repository root:
# Rscript --vanilla R/verificar_demo_16nov_nessim.R
out <- "R/resultados/nessim_demo_2026-11-16"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
protected <- c("data", "entregas", "R/resultados/auc")
files <- unlist(lapply(protected, list.files, recursive = TRUE,
                       full.names = TRUE))
before <- tools::md5sum(files)
pdf(tempfile("nessim-demo-", fileext = ".pdf"), width = 8, height = 7)
source("R/14_demo_rstudio.R")
dev.off()
stopifnot(identical(before, tools::md5sum(files)))
write.csv(AUC_48x7, file.path(out, "auc_48x7.csv"))
write.csv(auc_folds, file.path(out, "auc_por_voto.csv"), row.names = FALSE)
# Generate the PR table from the saved CSV values, without copying numbers.
pr_table <- c(
  paste("| Model |", paste(names(AUC_48x7), collapse = " | "), "|"),
  paste("|---|", paste(rep("---:", ncol(AUC_48x7)), collapse = "|"), "|"),
  vapply(seq_len(nrow(AUC_48x7)), function(i) {
    paste("|", rownames(AUC_48x7)[i], "|",
          paste(sprintf("%.4f", as.numeric(AUC_48x7[i, ])), collapse = " | "),
          "|")
  }, character(1)))
writeLines(pr_table, file.path(out, "tabla_pr.md"))
writeLines(c(capture.output(sessionInfo()),
             "Protected file hashes unchanged.",
             "Technical run only; teammate confirmations and RStudio rehearsal pending."),
           file.path(out, "validacion.txt"))
cat("Protected file hashes unchanged. Final team rehearsal pending.\n")
