# evaluar(): the ONE function that measures every method the same way (Mark, part B).
# Load it alone, without running R/03:   source("R/03b_evaluar.R")
#
# Used by R/03_evaluacion.R for every row of R/resultados/evaluacion.csv, and meant for
# whoever evaluates a new method on the July votes (for example the combined
# Bradley-Terry in R/07, Nessim). The July test votes are saved in
# R/resultados/test_julio_votos.csv (20,416 decisive votes, same order as the baselines).
#
# Inputs, one element per test vote:
#   p_model_a : probability that model_a wins, strictly between 0 and 1.
#               For a model with a "strength" per model and question (logit scale):
#               p_model_a = plogis(strength_a - strength_b).
#   winner    : "model_a" or "model_b" (only votes with a winner; a tie has no winner to hit)
#
# Prediction: model_a if p_model_a > 0.5, otherwise model_b.
# accuracy_percent = % of votes where the predicted winner really won (IC 95% = prop.test).
# logloss = -mean(y*log(p) + (1-y)*log(1-p)), with y = 1 if model_a won. Lower is better.
#
# Example:
#   test <- read.csv("R/resultados/test_julio_votos.csv")
#   evaluar(p, test$winner, method = "my_method", tie_handling = "half")

evaluar <- function(p_model_a, winner, method = NA_character_, tie_handling = NA_character_) {
  stopifnot(is.numeric(p_model_a), length(p_model_a) == length(winner),
            !anyNA(p_model_a), all(winner %in% c("model_a", "model_b")),
            all(p_model_a > 0 & p_model_a < 1))
  y       <- as.numeric(winner == "model_a")
  correct <- (p_model_a > 0.5) == (y == 1)
  n       <- length(y)
  k       <- sum(correct)
  ci      <- prop.test(k, n)$conf.int
  data.frame(method = method, tie_handling = tie_handling,
             test_votes_evaluated = n, correct = k,
             accuracy_percent  = round(100 * k / n, 1),
             ci95_low_percent  = round(100 * ci[1], 1),
             ci95_high_percent = round(100 * ci[2], 1),
             logloss = round(-mean(y * log(p_model_a) + (1 - y) * log(1 - p_model_a)), 4),
             stringsAsFactors = FALSE)
}
