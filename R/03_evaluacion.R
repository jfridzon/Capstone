# Evaluation: train/test split and the baseline to beat (general ranking)
# Task 3 in docs/07 (Mark). Run from the repo root: source("R/03_evaluacion.R")
#
# What this script does now:
# 1. Cleans the votes with the rules in docs/03 (1st vote only, 48 models with 1,000+ votes)
# 2. Splits them: train = April 17 to June 30, test = July (a session is never split)
# 3. General ranking = Bradley-Terry (logistic regression on paired comparisons),
#    NO question characteristics, fitted on train only. 1 strength per model.
# 4. Baseline accuracy: in each decisive July vote, predict that the model with the
#    higher strength wins, and measure the % of correct predictions.
# 5. Second baseline (the one in docs/tareas/mark.md): general win rate in train.
#    Both baselines are scored on the same July votes and saved in evaluacion.csv.
# 6. Our method: the 48 regressions of R/02 (Jaime), fitted on train only. In each July
#    vote, each model's win probability is computed with the characteristics of THAT
#    question, and the model with the higher probability is predicted to win.
#    Scored on the same July votes as the baselines, plus a paired comparison.
#    Fitted twice (docs/12, decision 1): tie and both_bad = 0.5 ("half point", the main
#    one) and only decisive votes ("exclude", the sensitivity check). Each method is scored
#    with accuracy and log-loss (lower is better) on the same July votes.
#
# 7. Ridge: the same regressions with a penalty. Lambda is chosen by cross-validation inside
#    train only (grouped by session) and July is scored once.
# 10. Check: a random 80/20 split by session (5 seeds) with all 48 models.
# Every method is measured with evaluar() (R/03b_evaluar.R): accuracy and log-loss.
#
# Not here: the combined Bradley-Terry with question characteristics is Nessim's task
# (R/07, docs/tareas/nessim.md). He can score it with evaluar() on the July votes saved in
# R/resultados/test_julio_votos.csv.

library(dplyr)
library(readr)
source("R/03b_evaluar.R")   # evaluar(): accuracy and log-loss, the same for every method

# ---- Settings ---------------------------------------------------------------

in_file    <- "data/lmarena_votes.csv"
out_folder <- "R/resultados"
min_votes  <- 1000                   # a model needs this many 1st votes (docs/03)
cutoff     <- as.Date("2025-07-01")  # train: before this date. test: this date or later

# Ties and both_bad (decision #1, closed on 2/11 in docs/12): the 48 regressions use
# "half point" in the fit, and "exclude" stays as a sensitivity check. Section 6 runs both.
# THIS setting only controls the general ranking and win rate of sections 3 to 5; leave it
# on "exclude" (what the earlier results use).
#   "exclude" = only decisive votes
#   "half"    = tie and both_bad count as 0.5 in the training fit
# The July test always uses decisive votes only, because we predict a winner.
tie_handling <- "exclude"
stopifnot(tie_handling %in% c("exclude", "half"))

# ---- 1. Load and clean (rules in docs/03) -------------------------------------

votes <- read_csv(in_file, show_col_types = FALSE,
                  col_select = c(id, model_a, model_b, winner, evaluation_session_id,
                                 evaluation_order, timestamp))

first_votes <- votes |> filter(evaluation_order == 1)

model_votes <- bind_rows(count(first_votes, model = model_a),
                         count(first_votes, model = model_b)) |>
  group_by(model) |>
  summarise(votes = sum(n), .groups = "drop")

keep <- model_votes |> filter(votes >= min_votes) |> pull(model)

clean <- first_votes |>
  filter(model_a %in% keep, model_b %in% keep) |>
  mutate(decisive = winner %in% c("model_a", "model_b"),
         split    = ifelse(as.Date(timestamp, tz = "UTC") < cutoff, "train", "test"))

# Check against the numbers in docs/03
cat("1st votes:", nrow(first_votes), "(docs/03: 108,315)\n")
cat("Models kept:", length(keep), "(docs/03: 48)\n")
cat("Votes after cleaning:", nrow(clean), "(docs/03: 106,630)\n")
cat("Decisive votes:", sum(clean$decisive), "(docs/03: 77,863)\n")
# Same model on both sides: excluded from the fit and from the July test below
cat("Same-model votes:", sum(clean$model_a == clean$model_b),
    "| decisive:", sum(clean$model_a == clean$model_b & clean$decisive),
    "| in test:", sum(clean$model_a == clean$model_b & clean$split == "test"), "\n")

# ---- 2. Train / test split -----------------------------------------------------

# A session must not be split between train and test
sessions <- clean |>
  group_by(evaluation_session_id) |>
  summarise(n_splits = n_distinct(split), .groups = "drop")
stopifnot(all(sessions$n_splits == 1))

print(clean |> count(split, decisive))

write_csv(clean |> select(id, split, decisive),
          file.path(out_folder, "split_train_test.csv"))

# ---- 3. General ranking: Bradley-Terry without characteristics, train only ------
# Row = 1 vote. y = 1 if model_a won, 0 if model_b won (0.5 for tie/both_bad if "half").
# Predictors = 1 column per model: +1 if it is model_a, -1 if it is model_b, 0 if absent.
# No intercept. The model with the most train votes is the reference (strength 0).

train <- clean |>
  filter(split == "train") |>
  mutate(y = case_when(winner == "model_a" ~ 1,
                       winner == "model_b" ~ 0,
                       tie_handling == "half" ~ 0.5,
                       TRUE ~ NA_real_)) |>
  filter(!is.na(y),
         model_a != model_b)  # same model on both sides says nothing about strength

train_models <- sort(unique(c(train$model_a, train$model_b)))
train_votes  <- sapply(train_models, function(m) sum(train$model_a == m | train$model_b == m))
reference    <- train_models[which.max(train_votes)]
others       <- setdiff(train_models, reference)

design <- matrix(0, nrow(train), length(others), dimnames = list(NULL, others))
ia <- match(train$model_a, others)
ib <- match(train$model_b, others)
design[cbind(which(!is.na(ia)), ia[!is.na(ia)])] <-  1
design[cbind(which(!is.na(ib)), ib[!is.na(ib)])] <- -1

fit <- glm.fit(design, train$y,
               family = if (tie_handling == "half") quasibinomial() else binomial())
stopifnot(fit$converged)

ranking <- tibble(model = c(reference, others),
                  strength = c(0, unname(fit$coefficients))) |>
  mutate(train_votes = unname(train_votes[model])) |>
  arrange(desc(strength)) |>
  mutate(rank = row_number(), .before = 1)

cat("\nReference model (strength 0):", reference, "\n")
print(head(ranking, 10))
write_csv(ranking, file.path(out_folder, "ranking_general_train.csv"))

# ---- 4. Baseline accuracy in July -----------------------------------------------
# Only decisive July votes where both models were in train.

test_decisive <- clean |> filter(split == "test", decisive, model_a != model_b)

test_used <- test_decisive |>
  filter(model_a %in% ranking$model, model_b %in% ranking$model) |>
  mutate(strength_a = ranking$strength[match(model_a, ranking$model)],
         strength_b = ranking$strength[match(model_b, ranking$model)],
         predicted  = ifelse(strength_a > strength_b, "model_a", "model_b"),
         correct    = predicted == winner)

n_used    <- nrow(test_used)
n_correct <- sum(test_used$correct)
ci        <- prop.test(n_correct, n_used)$conf.int

baseline <- tibble(tie_handling = tie_handling,
                   train_votes_used = nrow(train),
                   models_in_train = length(train_models),
                   test_votes_decisive = nrow(test_decisive),
                   test_votes_excluded_model_not_in_train = nrow(test_decisive) - n_used,
                   test_votes_evaluated = n_used,
                   correct = n_correct,
                   accuracy_percent = round(100 * n_correct / n_used, 1),
                   ci95_low_percent = round(100 * ci[1], 1),
                   ci95_high_percent = round(100 * ci[2], 1))

cat("\nBaseline (general ranking) in July:\n")
print(as.data.frame(baseline))
write_csv(baseline, file.path(out_folder, "test_baseline_ranking_general.csv"))

# ---- 5. Second baseline: general win rate ----------------------------------------
# Win rate of each model in train, all kinds of question together:
# votes won / votes played. Same train votes as the Bradley-Terry fit (decisive only;
# with tie_handling = "half", tie and both_bad add 0.5). In each July vote we predict
# that the model with the higher win rate wins. It does not take the rival into
# account, which is the limit of this baseline (docs/04, level 1).

win_rates <- bind_rows(train |> transmute(model = model_a, score = y),
                       train |> transmute(model = model_b, score = 1 - y)) |>
  group_by(model) |>
  summarise(train_votes = n(), win_rate = mean(score), .groups = "drop") |>
  arrange(desc(win_rate)) |>
  mutate(rank = row_number(), .before = 1)

stopifnot(setequal(win_rates$model, ranking$model))   # same 44 models as Bradley-Terry
cat("\nGeneral win rate in train (top 10):\n")
print(head(win_rates, 10))
write_csv(win_rates, file.path(out_folder, "winrate_general_train.csv"))

# Same July votes as the Bradley-Terry baseline (test_used), so both are comparable
test_wr <- test_used |>
  mutate(win_rate_a = win_rates$win_rate[match(model_a, win_rates$model)],
         win_rate_b = win_rates$win_rate[match(model_b, win_rates$model)],
         predicted_wr = ifelse(win_rate_a > win_rate_b, "model_a", "model_b"),
         correct_wr   = predicted_wr == winner)

# Every method is scored with 2 numbers on the same July votes:
#   accuracy = % of votes where the predicted winner really won
#   log-loss = how good the probabilities are (lower is better). Every method gives
#              P(model_a wins) = plogis(strength_a - strength_b) on the logit scale
# `scores` keeps, for each method: the tie policy used in its fit, P(model_a wins) and
# whether the predicted winner was right. `evaluacion` and the later tables come from it.
y_a <- as.numeric(test_used$winner == "model_a")   # 1 if model_a won the vote
loss_by_vote <- function(p) -(y_a * log(p) + (1 - y_a) * log(1 - p))

scores <- list(
  general_bradley_terry = list(policy = "exclude",
                               p = plogis(test_used$strength_a - test_used$strength_b),
                               correct = test_used$correct),
  general_win_rate      = list(policy = "exclude",
                               p = plogis(qlogis(test_wr$win_rate_a) - qlogis(test_wr$win_rate_b)),
                               correct = test_wr$correct_wr))

# evaluar() (R/03b_evaluar.R) measures every method; here it is applied to all of `scores`.
# The July votes it measures are saved so anyone can score a new method on exactly them.
accuracy_table <- function(scores) {
  bind_rows(lapply(names(scores), function(m)
    evaluar(scores[[m]]$p, test_used$winner, method = m, tie_handling = scores[[m]]$policy)))
}

write_csv(test_used |> select(id, model_a, model_b, winner),
          file.path(out_folder, "test_julio_votos.csv"))

evaluacion <- accuracy_table(scores)
# The old `correct` (higher strength wins) and the new rule (p > 0.5) must agree
stopifnot(evaluacion$correct == vapply(scores, function(s) sum(s$correct), numeric(1)))

cat("\nBoth baselines in July (same votes):\n")
print(as.data.frame(evaluacion))
cat("July votes where the two baselines predict a different winner:",
    sum(test_wr$predicted != test_wr$predicted_wr), "\n")
write_csv(evaluacion, file.path(out_folder, "evaluacion.csv"))

# ---- 6. Our method: the 48 regressions (R/02_regresiones_por_modelo.R) ----------------
# R/02 is loaded into its own environment: it also defines objects called `ranking`,
# `in_file` and `out_folder`, which would overwrite ours here. `correr_02 = FALSE` loads
# only its functions (it does not refit on all the votes or write its result files).

env02   <- new.env()
old_opt <- options(correr_02 = FALSE)
sys.source("R/02_regresiones_por_modelo.R", envir = env02)
options(old_opt)

predictors <- env02$predictores   # the 11 characteristics, all known BEFORE the answer

# Nessim's long base (docs/10): 2 rows per vote, 1 per model
long_base <- env02$cargar_base()
long_base$split <- clean$split[match(long_base$id, clean$id)]
stopifnot(!anyNA(long_base$split))

# The July votes are the same as in the baselines (test_used). Characteristics of each
# question: 1 row per vote from the long base.
questions <- long_base[!duplicated(long_base$id), c("id", predictors)]
test_q    <- questions[match(test_used$id, questions$id), predictors]
stopifnot(!anyNA(test_q))

# Fits the regressions on TRAIN ONLY and scores the July votes.
#   policy: "medio_punto" (tie and both_bad = 0.5, the main one) or "excluir" (decisive only)
#   rival : TRUE adds the rival's general win rate as a 12th predictor (check only, decision 5)
# preparar_respuesta() applies Jaime's choices: the tie policy and leaving out the 28 votes
# Nessim flagged for review (all of them are in train, so July is untouched).
# With half points the response is not only 0/1, so R/02 uses quasibinomial.
score_regressions <- function(policy, rival = FALSE) {
  train_long <- env02$preparar_respuesta(long_base[long_base$split == "train", ],
                                         politica = policy)
  fits <- env02$ajustar_modelos(train_long, rival = rival)
  stopifnot(length(fits) == length(train_models),
            all(vapply(fits, function(f) f$converged, logical(1))))

  # General win rate of each model in these same train rows (used by the rival check and
  # as the win-rate baseline with half points)
  rate <- tapply(train_long$y, train_long$model, mean)

  qa <- qb <- test_q
  if (rival) {
    qa$fuerza_rival <- unname(rate[test_used$model_b])   # model_a plays against model_b
    qb$fuerza_rival <- unname(rate[test_used$model_a])
  }
  p_a <- env02$probabilidad(fits, test_used$model_a, qa)   # P(model_a wins), own regression
  p_b <- env02$probabilidad(fits, test_used$model_b, qb)   # P(model_b wins), own regression
  stopifnot(!anyNA(p_a), !anyNA(p_b))

  list(policy = c(excluir = "exclude", medio_punto = "half")[[policy]],
       p = plogis(qlogis(p_a) - qlogis(p_b)),               # as docs/tareas/mark.md asks
       correct = ifelse(p_a > p_b, "model_a", "model_b") == test_used$winner,
       ties_exact = sum(p_a == p_b),
       train_votes = nrow(train_long) / 2,
       smallest_regression = min(vapply(fits, function(f) f$n_votos, numeric(1))),
       rate = rate)
}

runs <- list(half    = score_regressions("medio_punto"),
             exclude = score_regressions("excluir"),
             half_rival    = score_regressions("medio_punto", rival = TRUE),
             exclude_rival = score_regressions("excluir",     rival = TRUE))

cat("\nRegressions: train votes used (half point / exclude):",
    runs$half$train_votes, "/", runs$exclude$train_votes,
    "| baselines (decisive only):", nrow(train), "\n")
cat("Regressions fitted:", length(train_models), "| smallest one uses",
    runs$exclude$smallest_regression, "votes (exclude),",
    runs$half$smallest_regression, "votes (half point)\n")
cat("July votes where both probabilities are exactly equal:",
    sum(vapply(runs, function(r) r$ties_exact, numeric(1))), "(all 4 runs)\n")

# Win-rate baseline with half points: the same idea as `general_win_rate`, but the rate
# comes from the same train rows as the half-point regressions (ties count 0.5)
rate_half <- runs$half$rate
stopifnot(setequal(names(rate_half), train_models))
wr_a <- rate_half[test_used$model_a]
wr_b <- rate_half[test_used$model_b]

scores$general_win_rate_half_point <-
  list(policy = "half", p = plogis(qlogis(unname(wr_a)) - qlogis(unname(wr_b))),
       correct = ifelse(wr_a > wr_b, "model_a", "model_b") == test_used$winner)
scores$regressions_48_half_point         <- runs$half[c("policy", "p", "correct")]
scores$regressions_48_exclude            <- runs$exclude[c("policy", "p", "correct")]
scores$regressions_48_rival_check_half_point <- runs$half_rival[c("policy", "p", "correct")]
scores$regressions_48_rival_check_exclude    <- runs$exclude_rival[c("policy", "p", "correct")]

evaluacion <- accuracy_table(scores)

cat("\nAll methods in July (same votes):\n")
print(as.data.frame(evaluacion |> select(method, tie_handling, correct, accuracy_percent,
                                         ci95_low_percent, ci95_high_percent, logloss)))
write_csv(evaluacion, file.path(out_folder, "evaluacion.csv"))

# ---- 7. Ridge: the same 48 regressions with a penalty (docs/12, "Ridge") --------------
# Ridge shrinks the 11 effects of each regression toward 0, which helps the models with few
# votes. How strong the penalty is (lambda) is chosen ONLY with train votes: 5-fold
# cross-validation grouped by session, lowest log-loss wins. July is never used to choose;
# it is scored once, with the chosen lambda. The penalty is on the 11 effects, not on the
# intercept. The predictors are TRUE/FALSE (0/1), not rescaled.
# R/02 has no ridge, so the fit is written here (IRLS, like R/08). With lambda = 0 it gives
# the same coefficients as glm(), which is checked below.

lambdas <- c(0, 10, 30, 100, 300)   # docs/tareas/mark.md

num_predictors <- function(d) { d[predictors] <- lapply(d[predictors], as.numeric); d }

ridge_fit <- function(X, y, lambda) {
  b   <- rep(0, ncol(X))
  pen <- c(0, rep(lambda, ncol(X) - 1))
  for (it in 1:100) {
    mu   <- plogis(drop(X %*% b))
    w    <- mu * (1 - mu)
    step <- drop(solve(crossprod(X, X * w) + diag(pen, ncol(X)),
                       crossprod(X, y - mu) - pen * b))
    b    <- b + step
    if (max(abs(step)) < 1e-10) return(b)
  }
  stop("ridge_fit did not converge")
}

# 1 regression per model. d = long rows (1 per model per vote) with the response in y.
# Returns a matrix: 1 row per model, columns = intercept + the 11 characteristics.
fit_models <- function(d, lambda, min_votes = 100) {
  coefs <- list()
  for (m in sort(unique(d$model))) {
    f <- d[d$model == m, ]
    if (nrow(f) < min_votes) next          # same rule as R/02
    coefs[[m]] <- setNames(ridge_fit(cbind(1, as.matrix(f[predictors])), f$y, lambda),
                           c("intercept", predictors))
  }
  do.call(rbind, coefs)
}

# P(model_a wins) = plogis(strength_a - strength_b) for vote rows with lado == "model_a".
# Each strength is that model's own regression evaluated with the characteristics of the
# question. NA if the model or its rival has no regression.
p_model_a <- function(B, votes) {
  Xq <- cbind(1, as.matrix(votes[predictors]))
  ok <- votes$model %in% rownames(B) & votes$rival %in% rownames(B)
  p  <- rep(NA_real_, nrow(votes))
  p[ok] <- plogis(rowSums(Xq[ok, , drop = FALSE] * B[votes$model[ok], , drop = FALSE]) -
                  rowSums(Xq[ok, , drop = FALSE] * B[votes$rival[ok], , drop = FALSE]))
  p
}

# Cross-validation inside the rows given (train only). A session is never split between
# folds. The held-out score uses decisive votes only, like the July test.
cv_lambda <- function(d, lambdas, k = 5, seed = 1) {
  sessions <- unique(d$evaluation_session_id)
  set.seed(seed)
  fold_of <- setNames(sample(rep_len(1:k, length(sessions))), sessions)
  fold    <- unname(fold_of[as.character(d$evaluation_session_id)])
  do.call(rbind, lapply(lambdas, function(l) {
    loss <- 0; right <- 0; n <- 0
    for (f in 1:k) {
      B <- fit_models(d[fold != f, ], l)
      v <- d[fold == f & d$lado == "model_a" & d$es_decisivo, ]
      p <- p_model_a(B, v)
      stopifnot(!anyNA(p))
      y     <- as.numeric(v$won)
      loss  <- loss - sum(y * log(p) + (1 - y) * log(1 - p))
      right <- right + sum((p > 0.5) == (y == 1))
      n     <- n + length(y)
    }
    data.frame(lambda = l, cv_votes = n, cv_accuracy_percent = round(100 * right / n, 2),
               cv_logloss = round(loss / n, 6))
  }))
}

# Train rows of the main version (half point), as numbers
train_half <- num_predictors(env02$preparar_respuesta(long_base[long_base$split == "train", ],
                                                      politica = "medio_punto"))

# Check: lambda = 0 gives the glm() coefficients of R/02
B0  <- fit_models(train_half, 0)
glm_fits <- env02$ajustar_modelos(train_half)
coef_gap <- max(vapply(names(glm_fits), function(m) max(abs(coef(glm_fits[[m]]) - B0[m, ])),
                       numeric(1)))
cat("\nRidge check: lambda = 0 vs glm(), largest coefficient difference:", signif(coef_gap, 2), "\n")
stopifnot(coef_gap < 1e-6, nrow(B0) == length(train_models))

cv <- cv_lambda(train_half, lambdas)
lambda_star <- cv$lambda[which.min(cv$cv_logloss)]
cat("\nCross-validation inside train (5 folds by session), lower log-loss is better:\n")
print(cv)
cat("Chosen lambda:", lambda_star, "\n")
write_csv(cv, file.path(out_folder, "ridge_validacion_cruzada.csv"))

# July, scored ONCE with the chosen lambda. Same 20,416 votes, same order as test_used.
july_rows <- num_predictors(long_base[long_base$lado == "model_a" & long_base$id %in% test_used$id, ])
july_rows <- july_rows[match(test_used$id, july_rows$id), ]
stopifnot(identical(july_rows$model, test_used$model_a), identical(july_rows$rival, test_used$model_b))

# Check: lambda = 0 reproduces the July probabilities of section 6
stopifnot(max(abs(p_model_a(B0, july_rows) - scores$regressions_48_half_point$p)) < 1e-6)

p_ridge <- p_model_a(fit_models(train_half, lambda_star), july_rows)
stopifnot(!anyNA(p_ridge))
scores$regressions_48_ridge_half_point <-
  list(policy = "half", p = p_ridge, correct = (p_ridge > 0.5) == (y_a == 1))

evaluacion <- accuracy_table(scores)
cat("\nAll methods in July, with ridge (lambda =", lambda_star, "):\n")
print(as.data.frame(evaluacion |> select(method, tie_handling, correct, accuracy_percent, logloss)))
write_csv(evaluacion, file.path(out_folder, "evaluacion.csv"))

# ---- 8. Paired comparison -----------------------------------------------------------
# The same votes are scored by both methods, so the intervals above overlap a lot and do not
# say whether the difference is real. What matters are the votes where ONLY ONE method is
# right: if neither method were better, each would win about half of them (exact binomial
# test, the same idea as McNemar's test). For log-loss: the average, over the votes, of
# (loss of the base method - loss of the new one); positive = the new method is better.
# The p-value and the intervals are nominal: they ignore that models repeat across votes.

paired <- function(label, new, base) {
  n         <- length(new$correct)
  only_new  <- sum(new$correct & !base$correct)
  only_base <- sum(!new$correct & base$correct)
  diff      <- (only_new - only_base) / n                     # accuracy difference, in proportion
  se        <- sqrt(only_new + only_base - (only_new - only_base)^2 / n) / n   # paired Wald
  gain      <- loss_by_vote(base$p) - loss_by_vote(new$p)     # per vote, positive = new is better
  se_gain   <- sd(gain) / sqrt(n)
  tibble(comparison = label, test_votes = n,
         only_new_right = only_new, only_base_right = only_base,
         difference_points = round(100 * diff, 2) + 0,      # + 0 turns -0 into 0
         ci95_low_points   = round(100 * (diff - 1.96 * se), 2) + 0,
         ci95_high_points  = round(100 * (diff + 1.96 * se), 2) + 0,
         p_value = round(binom.test(only_new, only_new + only_base, p = 0.5)$p.value, 4),
         logloss_gain = round(mean(gain), 4) + 0,
         logloss_gain_ci95_low  = round(mean(gain) - 1.96 * se_gain, 4) + 0,
         logloss_gain_ci95_high = round(mean(gain) + 1.96 * se_gain, 4) + 0)
}

s <- scores
paired_tbl <- bind_rows(
  paired("regressions_48_half_point vs general_win_rate_half_point", s$regressions_48_half_point, s$general_win_rate_half_point),
  paired("regressions_48_half_point vs general_bradley_terry",       s$regressions_48_half_point, s$general_bradley_terry),
  paired("regressions_48_exclude vs general_win_rate",               s$regressions_48_exclude,    s$general_win_rate),
  paired("regressions_48_exclude vs general_bradley_terry",          s$regressions_48_exclude,    s$general_bradley_terry),
  paired("regressions_48_half_point vs regressions_48_exclude",      s$regressions_48_half_point, s$regressions_48_exclude),
  paired("rival_check_half_point vs regressions_48_half_point",      s$regressions_48_rival_check_half_point, s$regressions_48_half_point),
  paired("rival_check_exclude vs regressions_48_exclude",            s$regressions_48_rival_check_exclude,    s$regressions_48_exclude),
  paired("ridge_half_point vs regressions_48_half_point",            s$regressions_48_ridge_half_point, s$regressions_48_half_point),
  paired("ridge_half_point vs general_win_rate_half_point",          s$regressions_48_ridge_half_point, s$general_win_rate_half_point),
  paired("ridge_half_point vs general_bradley_terry",                s$regressions_48_ridge_half_point, s$general_bradley_terry))

cat("\nPaired comparison (new method vs base method):\n")
print(as.data.frame(paired_tbl))
write_csv(paired_tbl, file.path(out_folder, "evaluacion_pareada.csv"))

# ---- 9. By type of question (descriptive)----------------------------------------------
# The labels overlap (a vote can be code AND math), so the groups are not added up. 4 groups
# are looked at, so one of them can look better by chance: read it as a description.
# Accuracy (%) of every method in each group.

task_tags <- c("is_code", "math", "creative_writing", "instruction_following")
groups <- c(list(all = rep(TRUE, nrow(test_used))),
            setNames(lapply(task_tags, function(tg) test_q[[tg]]), task_tags))

by_task <- bind_rows(lapply(names(groups), function(g) {
  i <- groups[[g]]
  bind_cols(tibble(group = g, test_votes = sum(i)),
            as_tibble(lapply(scores, function(sc) round(100 * mean(sc$correct[i]), 1))))
}))

cat("\nAccuracy (%) by type of question, July:\n")
print(as.data.frame(by_task))
write_csv(by_task, file.path(out_folder, "evaluacion_por_tarea.csv"))

# ---- 10. Random split by session (docs/12, decision 4) ---------------------------------
# The main test is July, but it leaves out the 4 models that only appear in July. As a check,
# the 48 models are split at random: 80% of the SESSIONS to train, 20% to test, 5 seeds.
# (a session is never split). In each split, lambda is chosen with cross-validation inside
# that split's own train, the same rule as section 7. The test uses decisive votes where both
# models have a regression, and the three methods are scored on exactly the same votes.
# Same exclusions as R/02: the 28 votes flagged for review are left out.

pool          <- num_predictors(long_base[!long_base$requiere_revision, ])
pool_sessions <- unique(pool$evaluation_session_id)

random_split <- bind_rows(lapply(1:5, function(seed) {
  set.seed(seed)
  test_sessions <- sample(pool_sessions, round(0.2 * length(pool_sessions)))
  is_test <- pool$evaluation_session_id %in% test_sessions
  tr <- pool[!is_test, ]
  tr$y <- tr$won_medio_punto_escenario                 # main version: tie and both_bad = 0.5
  stopifnot(!anyNA(tr$y), !any(tr$evaluation_session_id %in% test_sessions))

  cv_seed <- cv_lambda(tr, lambdas)
  l_star  <- cv_seed$lambda[which.min(cv_seed$cv_logloss)]
  B_zero  <- fit_models(tr, 0)
  B_star  <- fit_models(tr, l_star)

  te <- pool[is_test & pool$lado == "model_a" & pool$es_decisivo, ]
  te <- te[te$model %in% rownames(B_zero) & te$rival %in% rownames(B_zero), ]
  rate <- tapply(tr$y, tr$model, mean)
  p_wr <- plogis(qlogis(unname(rate[te$model])) - qlogis(unname(rate[te$rival])))

  out <- bind_rows(evaluar(p_wr,                   te$winner, "general_win_rate_half_point",   "half"),
                   evaluar(p_model_a(B_zero, te),  te$winner, "regressions_48_half_point",     "half"),
                   evaluar(p_model_a(B_star, te),  te$winner, "regressions_48_ridge_half_point", "half"))
  cbind(seed = seed, models = nrow(B_zero), train_votes = nrow(tr) / 2,
        test_sessions = length(test_sessions),
        lambda = ifelse(out$method == "regressions_48_ridge_half_point", l_star, NA), out)
}))

cat("\nRandom split by session, 5 seeds (all 48 models):\n")
print(random_split |> select(seed, method, lambda, test_votes_evaluated, correct, accuracy_percent, logloss))
write_csv(random_split, file.path(out_folder, "particion_aleatoria.csv"))
