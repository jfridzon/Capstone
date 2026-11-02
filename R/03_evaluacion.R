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
#
# Still to add here (second part of docs/tareas/mark.md): the combined Bradley-Terry
# with question characteristics (docs/04).

library(dplyr)
library(readr)

# ---- Settings ---------------------------------------------------------------

in_file    <- "data/lmarena_votes.csv"
out_folder <- "R/resultados"
min_votes  <- 1000                   # a model needs this many 1st votes (docs/03)
cutoff     <- as.Date("2025-07-01")  # train: before this date. test: this date or later

# OPEN DECISION #1 in docs/07 (the group decides): ties and both_bad.
#   "exclude" = only decisive votes (what has been used so far)
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

accuracy_row <- function(method, correct_votes) {
  n  <- length(correct_votes)
  k  <- sum(correct_votes)
  ci <- prop.test(k, n)$conf.int
  tibble(method = method, tie_handling = tie_handling,
         test_votes_evaluated = n, correct = k,
         accuracy_percent = round(100 * k / n, 1),
         ci95_low_percent = round(100 * ci[1], 1),
         ci95_high_percent = round(100 * ci[2], 1))
}

evaluacion <- bind_rows(accuracy_row("general_bradley_terry", test_used$correct),
                        accuracy_row("general_win_rate", test_wr$correct_wr))

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
policy_02  <- c(exclude = "excluir", half = "medio_punto")[[tie_handling]]

# Nessim's long base (docs/10): 2 rows per vote, 1 per model
long_base <- env02$cargar_base()
long_base$split <- clean$split[match(long_base$id, clean$id)]
stopifnot(!anyNA(long_base$split))

# TRAIN ONLY. preparar_respuesta() applies Jaime's choices: the tie policy and leaving out
# the 28 votes Nessim flagged for review (all of them are in train, so July is untouched).
train_long <- env02$preparar_respuesta(long_base[long_base$split == "train", ],
                                       politica = policy_02)
cat("\nRegressions: train votes used:", nrow(train_long) / 2,
    "| baselines used:", nrow(train), "(difference = the votes flagged for review)\n")

fits <- env02$ajustar_modelos(train_long)
stopifnot(length(fits) == length(train_models),
          all(vapply(fits, function(f) f$converged, logical(1))))
cat("Regressions fitted:", length(fits), "| smallest one uses",
    min(vapply(fits, function(f) f$n_votos, numeric(1))), "votes\n")

# The July votes are the same as in the baselines (test_used). Characteristics of each
# question: 1 row per vote from the long base.
questions <- long_base[!duplicated(long_base$id), c("id", predictors)]
test_q    <- questions[match(test_used$id, questions$id), predictors]
stopifnot(!anyNA(test_q))

# Win probability of model_a and of model_b for the characteristics of that vote
p_a <- env02$probabilidad(fits, test_used$model_a, test_q)
p_b <- env02$probabilidad(fits, test_used$model_b, test_q)
stopifnot(!anyNA(p_a), !anyNA(p_b))
cat("July votes where both probabilities are exactly equal:", sum(p_a == p_b), "\n")

test_reg <- test_used |>
  mutate(predicted_reg = ifelse(p_a > p_b, "model_a", "model_b"),
         correct_reg   = predicted_reg == winner)

# Secondary check, NOT a decision (open decision #5 in docs/07): the same regressions with
# the rival's general win rate as a 12th predictor (ajustar_modelos(rival = TRUE)).
# The rival's win rate comes from train only, like in R/02.
fits_rival <- env02$ajustar_modelos(train_long, rival = TRUE)
rival_rate <- tapply(train_long$y, train_long$model, mean)
p_a_r <- env02$probabilidad(fits_rival, test_used$model_a,
                            cbind(test_q, fuerza_rival = unname(rival_rate[test_used$model_b])))
p_b_r <- env02$probabilidad(fits_rival, test_used$model_b,
                            cbind(test_q, fuerza_rival = unname(rival_rate[test_used$model_a])))
stopifnot(!anyNA(p_a_r), !anyNA(p_b_r))

test_reg <- test_reg |>
  mutate(correct_reg_rival = ifelse(p_a_r > p_b_r, "model_a", "model_b") == winner)

# All methods on the same votes: the baselines come from sections 4 and 5
stopifnot(identical(test_reg$id, test_wr$id))
evaluacion <- bind_rows(evaluacion,
                        accuracy_row("regressions_48", test_reg$correct_reg),
                        accuracy_row("regressions_48_with_rival_check", test_reg$correct_reg_rival))

cat("\nAll methods in July (same votes):\n")
print(as.data.frame(evaluacion |> select(method, correct, accuracy_percent, ci95_low_percent, ci95_high_percent)))
write_csv(evaluacion, file.path(out_folder, "evaluacion.csv"))

# ---- 7. Paired comparison -----------------------------------------------------------
# The same votes are scored by both methods, so the intervals above overlap a lot and do not
# say whether the difference is real. What matters are the votes where ONLY ONE method is
# right: if neither method were better, each would win about half of them (exact binomial
# test, the same idea as McNemar's test). The p-value is nominal: it ignores that models
# repeat across votes.

paired <- function(label, ok_new, ok_base) {
  n         <- length(ok_new)
  only_new  <- sum(ok_new & !ok_base)
  only_base <- sum(!ok_new & ok_base)
  diff      <- (only_new - only_base) / n                     # accuracy difference, in proportion
  se        <- sqrt(only_new + only_base - (only_new - only_base)^2 / n) / n   # paired Wald
  tibble(comparison = label, test_votes = n,
         only_new_right = only_new, only_base_right = only_base,
         difference_points = round(100 * diff, 2) + 0,      # + 0 turns -0 into 0
         ci95_low_points   = round(100 * (diff - 1.96 * se), 2) + 0,
         ci95_high_points  = round(100 * (diff + 1.96 * se), 2) + 0,
         p_value = round(binom.test(only_new, only_new + only_base, p = 0.5)$p.value, 4))
}

paired_tbl <- bind_rows(
  paired("regressions_48 vs general_win_rate",              test_reg$correct_reg,       test_wr$correct_wr),
  paired("regressions_48 vs general_bradley_terry",         test_reg$correct_reg,       test_reg$correct),
  paired("with_rival_check vs general_bradley_terry",       test_reg$correct_reg_rival, test_reg$correct),
  paired("with_rival_check vs regressions_48",              test_reg$correct_reg_rival, test_reg$correct_reg))

cat("\nPaired comparison (new method vs base method):\n")
print(as.data.frame(paired_tbl))
write_csv(paired_tbl, file.path(out_folder, "evaluacion_pareada.csv"))

# ---- 8. By type of question (descriptive) ----------------------------------------------
# The labels overlap (a vote can be code AND math), so the groups are not added up. 4 groups
# are looked at, so one of them can look better by chance: read it as a description.

task_tags <- c("is_code", "math", "creative_writing", "instruction_following")
groups <- c(list(all = rep(TRUE, nrow(test_reg))),
            setNames(lapply(task_tags, function(tg) test_q[[tg]]), task_tags))

by_task <- bind_rows(lapply(names(groups), function(g) {
  i <- groups[[g]]
  tibble(group = g, test_votes = sum(i),
         general_bradley_terry  = round(100 * mean(test_reg$correct[i]), 1),
         general_win_rate       = round(100 * mean(test_wr$correct_wr[i]), 1),
         regressions_48         = round(100 * mean(test_reg$correct_reg[i]), 1),
         with_rival_check       = round(100 * mean(test_reg$correct_reg_rival[i]), 1))
}))

cat("\nAccuracy (%) by type of question, July:\n")
print(as.data.frame(by_task))
write_csv(by_task, file.path(out_folder, "evaluacion_por_tarea.csv"))
