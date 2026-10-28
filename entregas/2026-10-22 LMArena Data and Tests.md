LMArena Data and Tests

The data

LMArena released 135,634 votes from April 17 to July 24, 2025 for free on Hugging Face (https://huggingface.co/datasets/lmarena-ai/arena-human-preference-140k), where each vote is a person comparing the answers of 2 anonymous models out of 53 and picking model A, model B, tie, or both bad. The original is 7 parquet files and about 1.6 GB, almost all of it the full text of the chats, so lmarena_votes.csv keeps 1 row per vote with every column except the 3 chat text columns (conversation_a, conversation_b and full_conversation). The question labels and the answer counts come nested in the original, so I pulled each one out into its own column, and the header, list and bold counts are added up into 1 number per answer. The results are 48,563 votes for model A, 49,785 for model B, 21,532 ties and 15,754 both bad. The column names follow our data dictionary, except instruction_following is the "if" label and answer_a_tokens / answer_b_tokens are sum_assistant_a_tokens / sum_assistant_b_tokens. lmarena_tests.R builds the CSV from the 7 original files and runs the 3 tests below.

Test 1: top models against every other model

Top is the 4 models we named in our Phase 0 email (Claude Opus 4, o3, Gemini 2.5 Pro and Grok 4) plus the thinking version of Opus 4 and the 2 preview versions of Gemini 2.5 Pro, so a version of a top model never counts on the other side. I kept only the votes where exactly 1 of the 2 models is a top model, 35,694 votes. The other model won 28.0% of them (95% confidence interval 27.6% to 28.5%), the top model won 46.2%, 16.0% were ties and 9.8% both bad. Until we add the price table, "other" means any of the remaining 46 models and not strictly a cheaper one, since some of them, like Claude Sonnet 4, are paid models too.

Test 2: win rate by type of task

Each vote becomes 2 rows, 1 per model, with won = 1 if that model won the vote and 0 if it lost, tied or both were bad. I calculated each model's win rate inside each task label (all votes, math, creative writing, code and instruction following), keeping only models with 200+ votes in that task. Gemini 2.5 Pro is 1st in every task except instruction following, where its March preview is 1st, but below it the order changes. In math, MiniMax M1 is 2nd (19th overall) and Gemini 2.5 Flash is 3rd (10th overall), above o3 at 6th and Claude Opus 4 at 18th. In creative writing, Grok 3 preview is 2nd (8th overall) and Gemma 3 is 17th, below Claude Opus 4 at 13th, which means what we wrote about Gemma 3 from the 1st file doesn't hold on the full data. However, a lot of models in the middle are only 2 or 3 points apart with a few hundred votes each, so this is a first look at the rankings and not a tested result yet. The full table is in test2_rank_by_task.csv.

Test 3: does the longer answer win?

Out of the 98,097 votes with a clear winner and 2 answers of different length, the longer answer won 61.8% of them (95% confidence interval 61.5% to 62.1%). Answer length is only known after the model writes it, so it stays out of the predictors, but it clearly matters to how people vote and we will have to account for it when we explain the results.
