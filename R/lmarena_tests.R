# LMArena human preference votes (135,634 votes, April 17 to July 24, 2025)
# Source: https://huggingface.co/datasets/lmarena-ai/arena-human-preference-140k
#
# 1. Reads the 7 parquet files and saves the votes as 1 CSV, without the chat text
# 2. Test 1: top models vs every other model
# 3. Test 2: win rate of each model by type of task (the ranking changes by task)
# 4. Test 3: do people just vote for the longer answer?

library(arrow)
library(dplyr)
library(tidyr)
library(readr)

data_folder <- "~/Downloads/lmarena-140k"   # folder with train-0000X-of-00007.parquet
out_folder  <- "."

# ---- 1. Load the data and save it as a CSV --------------------------------

raw <- open_dataset(data_folder) |>
  select(id, model_a, model_b, winner, evaluation_session_id, evaluation_order,
         timestamp, language, is_code, category_tag, conv_metadata) |>
  collect()

# category_tag and conv_metadata are nested columns, so we pull out each field
tags <- raw$category_tag
meta <- raw$conv_metadata

votes <- raw |>
  select(-category_tag, -conv_metadata) |>
  mutate(
    creative_writing   = tags$`creative_writing_v0.1`$creative_writing,
    complexity         = tags$`criteria_v0.1`$complexity,
    creativity         = tags$`criteria_v0.1`$creativity,
    domain_knowledge   = tags$`criteria_v0.1`$domain_knowledge,
    problem_solving    = tags$`criteria_v0.1`$problem_solving,
    real_world         = tags$`criteria_v0.1`$real_world,
    specificity        = tags$`criteria_v0.1`$specificity,
    technical_accuracy = tags$`criteria_v0.1`$technical_accuracy,
    instruction_following = tags$`if_v0.1`$`if`,
    if_score           = tags$`if_v0.1`$score,
    math               = tags$`math_v0.1`$math,
    sum_user_tokens    = meta$sum_user_tokens,
    turns              = meta$turns,
    # known only after the answers are written - not predictors
    answer_a_tokens    = meta$sum_assistant_a_tokens,
    answer_b_tokens    = meta$sum_assistant_b_tokens,
    headers_a = rowSums(meta$header_count_a), headers_b = rowSums(meta$header_count_b),
    lists_a   = rowSums(meta$list_count_a),   lists_b   = rowSums(meta$list_count_b),
    bold_a    = rowSums(meta$bold_count_a),   bold_b    = rowSums(meta$bold_count_b)
  ) |>
  arrange(timestamp)

write_csv(votes, file.path(out_folder, "lmarena_votes.csv"))
cat("Votes:", nrow(votes), " Models:", n_distinct(c(votes$model_a, votes$model_b)), "\n")
print(table(votes$winner))

# ---- 2. Test 1: top models vs every other model ---------------------------
# Top = the 4 flagship models we named to the professor, plus their thinking /
# preview versions, so a version of a top model never counts as "other".
# Only votes where exactly 1 side is a top model.

top <- c("claude-opus-4-20250514", "claude-opus-4-20250514-thinking-16k",
         "o3-2025-04-16",
         "gemini-2.5-pro", "gemini-2.5-pro-preview-03-25", "gemini-2.5-pro-preview-05-06",
         "grok-4-0709")

top_vs_other <- votes |>
  filter(xor(model_a %in% top, model_b %in% top)) |>
  mutate(other_side = ifelse(model_a %in% top, "model_b", "model_a"),
         result = case_when(winner == other_side ~ "other model won",
                            winner %in% c("model_a", "model_b") ~ "top model won",
                            winner == "tie" ~ "tie",
                            winner == "both_bad" ~ "both bad"))

test1 <- top_vs_other |> count(result) |> mutate(percent = round(100 * n / sum(n), 1))
print(test1)

# 95% confidence interval for the share of votes the other model won
other_won <- sum(top_vs_other$result == "other model won")
print(prop.test(other_won, nrow(top_vs_other))$conf.int)
write_csv(test1, file.path(out_folder, "test1_top_vs_other.csv"))

# ---- 3. Test 2: win rate by type of task -----------------------------------
# Each vote becomes 2 rows, 1 per model. won = 1 if that model won the vote,
# 0 if it lost, tied or both were bad. Only models with 200+ votes in the task.

long <- bind_rows(
  votes |> mutate(model = model_a, won = as.numeric(winner == "model_a")),
  votes |> mutate(model = model_b, won = as.numeric(winner == "model_b")))

tasks <- list(
  "All votes (general ranking)" = rep(TRUE, nrow(long)),
  "Math"                  = long$math,
  "Creative writing"      = long$creative_writing,
  "Code"                  = long$is_code,
  "Instruction following" = long$instruction_following)

min_votes <- 200
test2 <- bind_rows(lapply(names(tasks), function(task) {
  long[tasks[[task]], ] |>
    group_by(model) |>
    summarise(votes = n(), win_rate = round(mean(won), 3), .groups = "drop") |>
    filter(votes >= min_votes) |>
    arrange(desc(win_rate)) |>
    mutate(task = task, rank = row_number(), .before = 1)
}))

general <- test2 |> filter(task == "All votes (general ranking)") |> select(model, general_rank = rank)
test2 <- test2 |> left_join(general, by = "model")

for (task in names(tasks)) {
  cat("\n##", task, "\n")
  print(test2 |> filter(task == !!task) |> select(rank, model, votes, win_rate, general_rank) |> head(10))
}
write_csv(test2, file.path(out_folder, "test2_rank_by_task.csv"))

# ---- 4. Test 3: does the longer answer win? --------------------------------
# Only votes with a clear winner and answers of different length.

length_check <- votes |>
  filter(winner %in% c("model_a", "model_b"), answer_a_tokens != answer_b_tokens) |>
  mutate(longer_won = (winner == "model_a") == (answer_a_tokens > answer_b_tokens))

cat("\nVotes with a clear winner:", nrow(length_check),
    "\nShare where the longer answer won:", round(100 * mean(length_check$longer_won), 1), "%\n")
print(binom.test(sum(length_check$longer_won), nrow(length_check), p = 0.5)$conf.int)
