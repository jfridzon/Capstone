# Eli, fase 2 (issue #16). Asistencia de ChatGPT/OpenAI.
# Desde la raiz: source("R/04_contexto_y_graficos.R")
# La fase 1 queda disponible como ejecutar_contexto_fase1(), sin repetirla.
ejecutar_contexto_fase1 <- function() {
# Eli: contexto y graficos. Ejecutar desde la raiz:
# source("R/04_contexto_y_graficos.R")
# R base; preparado con asistencia de ChatGPT (OpenAI), 28/10/2026.
# Analisis descriptivo: largo NO es predictor ni una estimacion causal.
input <- "data/lmarena_votes.csv"
source_file <- "R/resultados/fuentes_eli_2026-10-28/leaderboard_oficial.csv"
stopifnot(file.exists(input), file.exists(source_file))
v <- read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
tags <- c("is_code", "math", "creative_writing", "instruction_following")
req <- c("id", "model_a", "model_b", "winner", "evaluation_order",
         "answer_a_tokens", "answer_b_tokens", tags)
stopifnot(all(req %in% names(v)), !anyNA(v[req]),
          all(v$winner %in% c("model_a", "model_b", "tie", "both_bad")))
for (col in c("answer_a_tokens", "answer_b_tokens", "evaluation_order"))
  stopifnot(is.numeric(v[[col]]), all(is.finite(v[[col]])), all(v[[col]] >= 0))
for (tag in tags) {
  x <- toupper(as.character(v[[tag]]))
  stopifnot(all(x %in% c("TRUE", "FALSE")))
  v[[tag]] <- x == "TRUE"
}
run <- format(Sys.time(), "%Y-%m-%d_%H%M%S", tz = "UTC")
out <- file.path("R/resultados", paste0("eli_contexto_", run))
graphs <- file.path("R/resultados/graficos", paste0("eli_contexto_", run))
if (dir.exists(out) || dir.exists(graphs)) stop("La carpeta ya existe; espera un segundo.")
dir.create(out, recursive = TRUE); dir.create(graphs, recursive = TRUE)
save_csv <- function(d, name) write.csv(d, file.path(out, name), row.names = FALSE, na = "")
ci <- function(w, n) if (n > 0) unname(binom.test(w, n)$conf.int) else c(NA_real_, NA_real_)
cohorts <- list(all_votes = v, first_vote = v[v$evaluation_order == 1, , drop = FALSE])
length_summary <- function(d, cohort, task) {
  decisive <- d$winner %in% c("model_a", "model_b")
  same <- d$answer_a_tokens == d$answer_b_tokens
  e <- decisive & !same
  w <- sum((d$winner[e] == "model_a") == (d$answer_a_tokens[e] > d$answer_b_tokens[e]))
  n <- sum(e); bounds <- ci(w, n)
  data.frame(cohort, task, total_votes = nrow(d), non_decisive = sum(!decisive),
             decisive_equal_length = sum(decisive & same), eligible_votes = n,
             longer_wins = w, share_longer_wins = if (n) w/n else NA_real_,
             ci95_low = bounds[1], ci95_high = bounds[2])
}
ls <- list(); model_rows <- list()
for (cohort in names(cohorts)) {
  d <- cohorts[[cohort]]
  ls[[length(ls)+1]] <- length_summary(d, cohort, "All tasks")
  for (tag in tags) ls[[length(ls)+1]] <- length_summary(d[d[[tag]], , drop=FALSE], cohort, tag)
  d <- d[d$winner %in% c("model_a", "model_b") & d$answer_a_tokens != d$answer_b_tokens, ]
  long <- rbind(data.frame(model=d$model_a, won=d$winner=="model_a", longer=d$answer_a_tokens>d$answer_b_tokens),
                data.frame(model=d$model_b, won=d$winner=="model_b", longer=d$answer_b_tokens>d$answer_a_tokens))
  for (m in sort(unique(long$model))) {
    z <- long[long$model==m, ]; a <- z[z$longer, ]; b <- z[!z$longer, ]
    ac <- ci(sum(a$won), nrow(a)); bc <- ci(sum(b$won), nrow(b))
    model_rows[[length(model_rows)+1]] <- data.frame(cohort, model=m,
      longer_votes=nrow(a), longer_wins=sum(a$won),
      win_rate_when_longer=if(nrow(a)) mean(a$won) else NA_real_,
      longer_ci_low=ac[1], longer_ci_high=ac[2],
      shorter_votes=nrow(b), shorter_wins=sum(b$won),
      win_rate_when_shorter=if(nrow(b)) mean(b$won) else NA_real_,
      shorter_ci_low=bc[1], shorter_ci_high=bc[2])
  }
}
lengths <- do.call(rbind, ls); models <- do.call(rbind, model_rows)
stopifnot(all(lengths$total_votes == lengths$non_decisive + lengths$decisive_equal_length + lengths$eligible_votes),
          all(abs(lengths$longer_wins/lengths$eligible_votes - lengths$share_longer_wins)<1e-12))
save_csv(lengths, "largo_resumen.csv"); save_csv(models, "largo_por_modelo.csv")
# Ranking descriptivo original de Test 2: todos los votos; empate/both_bad = 0.
# No es el ranking Bradley-Terry de train de Mark ni una prueba fuera de muestra.
long <- rbind(data.frame(model=v$model_a, won=v$winner=="model_a"),
              data.frame(model=v$model_b, won=v$winner=="model_b"))
ranking <- do.call(rbind, lapply(split(long, long$model), function(z)
  data.frame(model=z$model[1], votes=nrow(z), wins=sum(z$won), win_rate=mean(z$won))))
ranking <- ranking[ranking$votes>=200, ]; ranking <- ranking[order(-ranking$win_rate, ranking$model), ]
ranking$rank <- rank(-ranking$win_rate, ties.method="average"); rownames(ranking)<-NULL
save_csv(ranking, "ranking_descriptivo.csv")
# Coincidencia exacta de identificadores. No agrupamos preview/thinking ni hacemos fuzzy matching.
off <- read.csv(source_file, stringsAsFactors=FALSE)
stopifnot(all(c("model_name", "rating", "rank", "category", "leaderboard_publish_date") %in% names(off)),
          !anyDuplicated(off$model_name), all(off$category=="overall"),
          length(unique(off$leaderboard_publish_date))==1,
          all(off$leaderboard_publish_date >= "2025-07-01" & off$leaderboard_publish_date <= "2025-07-24"))
matched <- merge(ranking, off, by.x="model", by.y="model_name", suffixes=c("_ours", "_official"))
stopifnot(nrow(matched)>=3)
matched$ours_common_rank <- rank(-matched$win_rate, ties.method="average")
matched$official_common_rank <- rank(matched$rank_official, ties.method="average")
matched$rank_difference <- matched$ours_common_rank-matched$official_common_rank
matched <- matched[order(-abs(matched$rank_difference), matched$model), ]
save_csv(matched, "comparacion_leaderboard.csv")
save_csv(ranking[!ranking$model %in% off$model_name, ], "modelos_sin_coincidencia.csv")
save_csv(data.frame(snapshot_date=unique(off$leaderboard_publish_date),
                   official_subset="text_style_control", matched_models=nrow(matched),
                   unmatched_ours=sum(!ranking$model %in% off$model_name),
                   spearman=cor(matched$win_rate, -matched$rank_official, method="spearman")),
         "correlacion_rangos.csv")
# Los graficos llevan ingles para la presentacion.
labels <- c("All tasks"="All tasks", is_code="Code", math="Math",
            creative_writing="Creative writing", instruction_following="Instruction following")
length_plot <- function(cohort) {
  d <- lengths[lengths$cohort==cohort, ]; y <- rev(seq_len(nrow(d)))
  png(file.path(graphs,paste0("longer_wins_",cohort,".png")),1600,950,res=150)
  on.exit(dev.off()); par(mar=c(5,10,5,2))
  plot(100*d$share_longer_wins,y,xlim=c(45,70),ylim=c(.5,nrow(d)+.5),yaxt="n",pch=19,col="#2563EB",
       xlab="Votes won by the longer answer (%)",ylab="",
       main=if(cohort=="first_vote") "Answer length and preference: first votes" else "Answer length and preference: all votes")
  axis(2,at=y,labels=unname(labels[d$task]),las=1); abline(v=50,lty=2,col="gray50")
  segments(100*d$ci95_low,y,100*d$ci95_high,y,col="#2563EB")
  text(100*d$share_longer_wins,y,sprintf("%.1f%% (n=%s)",100*d$share_longer_wins,format(d$eligible_votes,big.mark=",",trim=TRUE)),pos=3,cex=.8)
  mtext("Decisive votes; unequal lengths; all models. Association, not causation.",3,line=.5,cex=.7)
}
for(cohort in names(cohorts)) length_plot(cohort)
png(file.path(graphs,"top15_win_rate.png"),1800,1200,res=150)
par(mar=c(5,21,5,2)); d<-ranking[rev(seq_len(min(15,nrow(ranking)))), ]
bp<-barplot(100*d$win_rate,names.arg=d$model,horiz=TRUE,las=1,col="#2563EB",xlim=c(0,65),
            xlab="Wins / all appearances (%)",main="Top 15 models: descriptive win rate",cex.names=.75)
text(100*d$win_rate,bp,sprintf(" %.1f%%",100*d$win_rate),pos=4,cex=.8)
mtext("All votes; at least 200 appearances. Ties and both-bad count as zero wins.",3,line=.5,cex=.7)
dev.off()
png(file.path(graphs,"ranking_official_vs_ours.png"),1300,1100,res=150)
plot(matched$official_common_rank,matched$ours_common_rank,pch=19,col="#2563EB",
     xlab="Official style-controlled rank (common models)",ylab="Our descriptive rank (common models)",
     main=paste("Rank comparison - official snapshot",unique(off$leaderboard_publish_date)))
abline(0,1,lty=2,col="gray50");dev.off()
# Mapa de calor: copia de los coeficientes publicados por Jaime, sin reentrenar.
coef_file <- "R/resultados/fuentes_eli_2026-10-28/coeficientes_jaime_2026-10-28.csv"
co <- read.csv(coef_file, stringsAsFactors=FALSE)
features <- c(tags, "complexity", "creativity", "domain_knowledge", "problem_solving",
              "real_world", "specificity", "technical_accuracy")
co$feature <- sub("TRUE$", "", co$termino)
co <- co[co$feature %in% features, ]
stopifnot(!anyDuplicated(co[c("modelo", "feature")]), all(is.finite(co$estimado)))
model_names <- sort(unique(co$modelo))
mat <- matrix(NA_real_, nrow=length(model_names), ncol=length(features),
              dimnames=list(model_names,features))
mat[cbind(match(co$modelo, model_names), match(co$feature,features))] <- co$estimado
stopifnot(!anyNA(mat))
save_csv(data.frame(modelo=rownames(mat), mat, check.names=FALSE), "matriz_coeficientes_jaime.csv")
limit <- max(abs(mat))
palette <- colorRampPalette(c("#B91C1C", "#FFFFFF", "#1D4ED8"))(101)
png(file.path(graphs,"heatmap_modelo_caracteristica.png"),2400,2400,res=160)
layout(matrix(c(1,2), nrow=1), widths=c(8,1))
par(mar=c(12,22,5,1))
image(seq_along(features),seq_along(model_names),t(mat[rev(seq_along(model_names)), ,drop=FALSE]),
      col=palette,zlim=c(-limit,limit),axes=FALSE,xlab="",ylab="",
      main="Question characteristics and model win probability")
axis(1,at=seq_along(features),labels=c("Code","Math","Creative writing","Instructions",
     "Complexity","Creativity","Domain knowledge","Problem solving","Real world",
     "Specificity","Technical accuracy"),las=2,cex.axis=.8)
axis(2,at=seq_along(model_names),labels=rev(model_names),las=1,cex.axis=.65)
mtext("Jaime's fitted coefficients (log-odds); all-data fit; descriptive, not test performance.",3,line=.5,cex=.7)
par(mar=c(12,1,5,4))
image(1,seq(-limit,limit,length.out=101),matrix(seq(-limit,limit,length.out=101),nrow=1),
      col=palette,zlim=c(-limit,limit),axes=FALSE,xlab="",ylab="")
axis(4,las=1);mtext("Coefficient",4,line=3)
dev.off()

# Comprobaciones de conteos de participaciones, sin asumir independencia estadistica.
for(cohort in names(cohorts)) {
  a<-lengths[lengths$cohort==cohort & lengths$task=="All tasks", ]
  b<-models[models$cohort==cohort, ]
  stopifnot(sum(b$longer_votes)==a$eligible_votes, sum(b$shorter_votes)==a$eligible_votes,
            sum(b$longer_wins)==a$longer_wins)
}
writeLines(c("Asociacion descriptiva; no causal. Largo no es predictor.",
 "Etiquetas solapadas; no sumar sus conteos.",
 "Sin filtro de 48 modelos ni eliminacion automatica de casos senalados por Nessim.",
 "IC binomiales nominales: no corrigen dependencia por sesion ni comparaciones multiples.",
 "Comparacion externa descriptiva; puede compartir votos con nuestro dataset, no es validacion independiente.",
 "El leaderboard ajusta por rival/estilo y usa otro universo e historial de votos.",
 "No se agrupan versiones. Coincidencia exacta de IDs; se exportan los no coincidentes.",
 "Diferencias de puestos calculadas dentro del conjunto de modelos comunes.",
 paste("MD5 coeficientes Jaime:", unname(tools::md5sum(coef_file))),
 paste("MD5 datos:",unname(tools::md5sum(input))),
 paste("MD5 snapshot:",unname(tools::md5sum(source_file))),
 paste("Graficos:",graphs)),file.path(out,"notas.txt"))
capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
print(read.csv(file.path(out,"correlacion_rangos.csv")))
cat("Resultados:",out,"\nGraficos:",graphs,"\n")

}

ejecutar_graficos_fase2 <- function(carpeta = file.path("R/resultados/graficos", paste0("eli_fase2_", Sys.Date()))) {
  dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
  e <- read.csv("R/resultados/evaluacion.csv", stringsAsFactors = FALSE)
  stopifnot(all(c("method", "test_votes_evaluated", "accuracy_percent", "logloss") %in% names(e)),
            !anyDuplicated(e$method))
  # Versiones principales con medio punto; Bradley-Terry general es su referencia publicada.
  methods <- c("general_win_rate_half_point", "general_bradley_terry",
               "regressions_48_half_point", "regressions_48_ridge_half_point",
               "combined_bradley_terry")
  titles <- c("Overall win rate", "Overall Bradley-Terry", "Task regressions",
              "Task regressions + ridge", "Combined regression")
  d <- e[match(methods[methods %in% e$method], e$method), ]
  stopifnot(nrow(d) >= 3, all(is.finite(d$accuracy_percent)),
    all(is.finite(d$logloss)), length(unique(d$test_votes_evaluated)) == 1)
  d$label <- titles[match(d$method, methods)]
  write.csv(d, file.path(carpeta, "evaluacion_graficada.csv"), row.names = FALSE)
  pending <- if (!"combined_bradley_terry" %in% d$method)
    "Combined regression: pending, no result supplied." else "Combined regression included."
  draw <- function(metric, title, xlab, digits) {
    png(file.path(carpeta, paste0(metric, ".png")), 1800, 1050, res = 160)
    par(mar = c(7, 15, 6, 3), bg = "white", fg = "#14243A", col.axis = "#14243A")
    y <- rev(seq_len(nrow(d))); x <- d[[metric]]
    xr <- range(x); pad <- max(diff(xr)*.65, if (metric == "logloss") .002 else .5)
    plot(x, y, xlim = xr + c(-pad, pad), ylim = c(.5, length(y)+.5),
      yaxt = "n", pch = 19, cex = 1.5, col = "#167A83", xlab = xlab,
      ylab = "", main = "", bty = "n")
    title(main = title, line = 4)
    axis(2, at = y, labels = d$label, las = 1, tick = FALSE, cex.axis = .9)
    text(x, y, labels = formatC(x, format = "f", digits = digits), pos = 3, cex = 1)
    mtext(paste(format(unique(d$test_votes_evaluated), big.mark = ","),
      "decisive July votes. Same test votes for all methods."), 3, line = .6, cex = .8)
    mtext(pending, 1, line = 5.5, cex = .75)
    dev.off()
  }
  draw("accuracy_percent", "Task features bring a small gain in accuracy", "Correct predictions (%) - higher is better", 1)
  draw("logloss", "Probability quality varies across methods", "Log-loss - lower is better (axis zoomed)", 4)
  # Carga funciones sin ejecutar ni sobrescribir los archivos de Nessim/Mark.
  env <- new.env(parent = globalenv())
  prior <- getOption("correr_02"); options(correr_02 = FALSE)
  on.exit(options(correr_02 = prior), add = TRUE)
  sys.source("R/02_regresiones_por_modelo.R", envir = env)
  base <- env$cargar_base()
  datos <- env$preparar_respuesta(base, politica = "medio_punto", sin_revision = TRUE)
  ajustes <- env$ajustar_modelos(datos)
  co <- env$tabla_coeficientes(ajustes)
  # Cuenta julio en la misma base y con la misma exclusion de revision del ajuste.
  # Si la base usa 'mes' en vez de timestamp, se deriva de los datos originales por id.
  raw <- read.csv("data/lmarena_votes.csv", stringsAsFactors = FALSE)
  july_ids <- raw$id[substr(raw$timestamp, 1, 7) == "2025-07"]
  july <- datos[datos$id %in% july_ids, ]
  counts <- table(july$model)
  eligible <- sort(names(counts[counts >= 100]))
  features <- env$predictores
  co$feature <- sub("TRUE$", "", co$termino)
  co <- co[co$modelo %in% eligible & co$feature %in% features, ]
  stopifnot(!anyDuplicated(co[c("modelo", "feature")]), all(is.finite(co$estimado)))
  mat <- matrix(NA_real_, length(eligible), length(features), dimnames = list(eligible, features))
  mat[cbind(match(co$modelo, eligible), match(co$feature, features))] <- co$estimado
  stopifnot(!anyNA(mat), all(counts[eligible] >= 100))
  write.csv(co, file.path(carpeta, "coeficientes_medio_punto.csv"), row.names = FALSE)
  write.csv(data.frame(modelo = names(counts), votos_julio = as.integer(counts),
    incluido = counts >= 100), file.path(carpeta, "modelos_julio.csv"), row.names = FALSE)
  write.csv(data.frame(modelo = rownames(mat), mat, check.names = FALSE),
    file.path(carpeta, "matriz_heatmap.csv"), row.names = FALSE)
  palette <- colorRampPalette(c("#B04B3D", "#FFFFFF", "#167A83"))(101)
  limit <- max(abs(mat)); n <- nrow(mat)
  png(file.path(carpeta, "heatmap_medio_punto_julio.png"), 2500, max(1600, 45*n + 650), res = 170)
  layout(matrix(c(1,2), nrow=1), widths=c(9,1))
  par(mar=c(12,23,6,1))
  image(seq_along(features), seq_len(n), t(mat[rev(seq_len(n)), , drop=FALSE]),
    axes=FALSE, xlab="", ylab="", col=palette, zlim=c(-limit,limit),
    main="")
  title(main="How question features relate to model preference", line=4.3)
  axis(1, at=seq_along(features), labels=c("Code", "Math", "Creative writing", "Instructions",
    "Complexity", "Creativity", "Domain knowledge", "Problem solving", "Real world",
    "Specificity", "Technical accuracy"), las=2, cex.axis=.85)
  axis(2, at=seq_len(n), labels=rev(eligible), las=1, cex.axis=.75)
  mtext("Green: higher preference score. Red: lower. Each feature holds the others constant.",3,line=2.5,cex=.8)
  mtext(paste(n,"models with 100+ July votes. All-data fit, ties/both-bad = 0.5. Descriptive effects."),3,line=.5,cex=.75)
  par(mar=c(12,1,6,5))
  image(1, seq(-limit,limit,length.out=101), matrix(seq(-limit,limit,length.out=101),nrow=1),
    axes=FALSE,xlab="",ylab="",col=palette,zlim=c(-limit,limit))
  axis(4,las=1);mtext("Coefficient (log-odds)",4,line=3)
  dev.off()
  writeLines(c(pending, "Accuracy/log-loss use the supplied evaluation.csv without refitting Mark's evaluation.",
    "Win-rate and task models fit ties/both-bad as 0.5. Published overall BT excludes ties.",
    "Accuracy is rounded in the input CSV. Log-loss uses the precision supplied by Mark.",
    "Heatmap refits R/02 functions on all data with half points, no ridge, revision flags excluded.",
    "July appearances use the same cleaned long base. Heatmap is descriptive, not causal or a test result.",
    paste("MD5 evaluacion:", unname(tools::md5sum("R/resultados/evaluacion.csv"))),
    paste("MD5 R/02:", unname(tools::md5sum("R/02_regresiones_por_modelo.R")))),
    file.path(carpeta,"notas.txt"))
  capture.output(sessionInfo(), file=file.path(carpeta,"sessionInfo.txt"))
  print(d);cat("Heatmap:",n,"models\n"); invisible(carpeta)
}
if (isTRUE(getOption("correr_04", TRUE))) ejecutar_graficos_fase2()
