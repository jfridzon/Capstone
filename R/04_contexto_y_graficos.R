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
