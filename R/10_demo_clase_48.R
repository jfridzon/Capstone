# =============================================================================
#  The 48 regressions, step by step  (IDS 3000, LMArena project, Nov 4 2026)
#  Run each block with Cmd + Enter (Mac) or Ctrl + Enter (Windows), in order.
#  Base R only. Takes about 1 minute in total.
#  Run from the repo root (open Capstone.Rproj). The glm() is written out in full so summary() shows it.
#  Prepared with Claude (Anthropic). Same numbers as R/03 (Mark): 65.1% vs 64.5% in July.
# =============================================================================


# ---- 1. The data ------------------------------------------------------------
# One row = one AI model in one vote (each vote gives 2 rows, one per model).
votes <- read.csv(gzfile("data/derivados/base_regresiones_2026-10-28_v2.csv.gz"))
split <- read.csv("R/resultados/split_train_test.csv")          # train = Apr-Jun, test = July
votes <- merge(votes, split[, c("id", "split")], by = "id")
votes <- votes[!votes$requiere_revision, ]                # 28 flagged votes left out

# Response y: 1 = won, 0 = lost, 0.5 = tie or both bad
votes$y <- votes$won_medio_punto_escenario

head(votes[, c("model", "rival", "winner", "y", "is_code", "math",
               "creative_writing", "complexity", "technical_accuracy")], 10)
table(votes$y)
length(unique(votes$model))                               # 48 models


# ---- 2. ONE regression: o3 ---------------------------------------------------
# Fit with April-June only. July is kept for the test (block 5).
train <- votes[votes$split == "train", ]

fit_o3 <- glm(y ~ is_code + math + creative_writing + instruction_following +
                  complexity + creativity + domain_knowledge + problem_solving +
                  real_world + specificity + technical_accuracy,
              family = quasibinomial,
              data   = train[train$model == "o3-2025-04-16", ])
summary(fit_o3)


# ---- 3. Same regression for another model: MiniMax M1 -----------------------
fit_minimax <- glm(y ~ is_code + math + creative_writing + instruction_following +
                       complexity + creativity + domain_knowledge + problem_solving +
                       real_world + specificity + technical_accuracy,
                   family = quasibinomial,
                   data   = train[train$model == "minimax-m1", ])
summary(fit_minimax)


# ---- 4. All the models: the same glm(), once per model -----------------------
formula_48 <- y ~ is_code + math + creative_writing + instruction_following +
                  complexity + creativity + domain_knowledge + problem_solving +
                  real_world + specificity + technical_accuracy

fits <- list()
for (m in unique(train$model)) {
  fits[[m]] <- glm(formula_48, family = quasibinomial, data = train[train$model == m, ])
}
length(fits)   # 44: the other 4 models only appear in July, so they have no train data

# Coefficients of every model, one row per model (log-odds)
coefs <- t(sapply(fits, coef))
round(coefs[order(-coefs[, "mathTRUE"]), c("(Intercept)", "is_codeTRUE", "mathTRUE",
                                           "creative_writingTRUE")], 3)[1:10, ]


# ---- 5. Predict ONE real July vote: o3 vs MiniMax M1 -------------------------
# A July math question: math, complexity, domain_knowledge, specificity and
# technical_accuracy = TRUE; the other 6 features = FALSE.
question <- data.frame(is_code = FALSE, math = TRUE, creative_writing = FALSE,
                       instruction_following = FALSE, complexity = TRUE,
                       creativity = FALSE, domain_knowledge = TRUE,
                       problem_solving = FALSE, real_world = FALSE,
                       specificity = TRUE, technical_accuracy = TRUE)

predict(fit_o3,      newdata = question, type = "response")   # o3:      0.57
predict(fit_minimax, newdata = question, type = "response")   # MiniMax: 0.72
# -> we predict MiniMax M1. The person picked MiniMax M1.
# The overall ranking would pick o3 (higher overall win rate):
win_rate <- tapply(train$y, train$model, mean)
round(win_rate[c("o3-2025-04-16", "minimax-m1")], 3)


# ---- 6. The test: predict ALL July votes -------------------------------------
# Rule: for each July vote, ask each model's own regression; the higher score wins.
# Only decisive votes (someone won) and models that appear in train.
july <- votes[votes$split == "test" & votes$lado == "model_a" & votes$es_decisivo &
              votes$model %in% names(fits) & votes$rival %in% names(fits) &
              !votes$mismo_modelo, ]
nrow(july)     # 20,416 July votes

score <- function(models, data) {
  out <- numeric(nrow(data))
  for (m in unique(models)) {
    i <- which(models == m)
    out[i] <- predict(fits[[m]], newdata = data[i, ], type = "response")
  }
  out
}
score_a <- score(july$model, july)
score_b <- score(july$rival, july)

winner_real       <- ifelse(july$won == 1, july$model, july$rival)
winner_48         <- ifelse(score_a > score_b, july$model, july$rival)
winner_one_ranking <- ifelse(win_rate[july$model] > win_rate[july$rival], july$model, july$rival)

results <- data.frame(
  method   = c("Coin flip", "One overall ranking", "48 regressions"),
  accuracy = c(50,
               round(100 * mean(winner_one_ranking == winner_real), 1),
               round(100 * mean(winner_48 == winner_real), 1)))
results        # 50 / 64.5 / 65.1


# ---- 7. By question type -----------------------------------------------------
by_type <- sapply(c("is_code", "math", "creative_writing", "instruction_following"), function(f) {
  k <- july[[f]]
  c(votes          = sum(k),
    one_ranking    = round(100 * mean((winner_one_ranking == winner_real)[k]), 1),
    regressions_48 = round(100 * mean((winner_48 == winner_real)[k]), 1))
})
t(by_type)     # the 48 regressions are better in all 4 types

# When the two methods disagree, who is right more often?
disagree <- winner_48 != winner_one_ranking
c(votes_where_they_disagree = sum(disagree),
  regressions_right = sum((winner_48 == winner_real)[disagree]),
  ranking_right     = sum((winner_one_ranking == winner_real)[disagree]))
