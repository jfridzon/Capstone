# Model recommender

Open `Capstone.Rproj` from a complete checkout. In the RStudio console, install Shiny once with `install.packages("shiny")`, then run:

```r
shiny::runApp("app")
```

Select one or more question features and an output price ceiling, or pick a quick example. Clear all features to average across all eligible historical questions. With multiple features selected, the app uses questions that have all of them. Other features may also be present.

The score averages each model’s fitted probability of winning over the selected questions from decisive LMArena votes in April–July 2025. The 48 binomial regressions use the same eleven question features. The app ranks eligible models by this score. It requires at least 100 July appearances and a recorded official output price, including for “No limit.” The budget is USD per million output tokens. The input rate and date of each price appear alongside it. Actual invoice amounts depend on usage.

From the repository root, run `Rscript --vanilla R/verificar_app_final.R` to check the Shiny server, chart, and table against the published rankings for four task profiles and four budgets. For model calculations alone, add `--model-only`.

OpenAI Codex assisted with the app revision, checks and documentation.
