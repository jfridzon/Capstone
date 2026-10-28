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
#
# Still to add here, when R/02_regresiones_por_modelo.R exists (docs/07):
# accuracy of the 48 regressions vs this baseline, and the combined Bradley-Terry.

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
  filter(!is.na(y))

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

test_decisive <- clean |> filter(split == "test", decisive)

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
