# Model recommender

Download [ArenaGuide.html](mvp/ArenaGuide.html) and open the downloaded file in a browser. It runs offline and includes both the model finder and validation dashboard. Use the task preset or select any combination of the eleven features. The dashboard compares the general ranking, the 48 regressions and Bradley–Terry on the same held-out folds. The separate per-model chart reproduces the four comparisons developed by Eli and validated by Mark.

To rebuild the portable file from project inputs, run `Rscript R/generar_mvp.R` with the jsonlite package installed. It exports the fitted coefficients, exact frequencies of observed question profiles, recorded prices and published validation results. The browser weights each observed profile by its real frequency. Run `Rscript app/mvp/tests/check.R` with Chrome installed to verify the interface against R and the published output.

### Shiny version

Open `Capstone.Rproj` from a complete checkout. In the RStudio console, install Shiny once with `install.packages("shiny")`, then run:

```r
shiny::runApp("app")
```

Select one or more question features and an output price ceiling, or pick a quick example. Clear all features to average across all eligible historical questions. With multiple features selected, the app uses questions that have all of them. Other features may also be present.

The score averages each model’s fitted probability of winning over the selected questions from decisive LMArena votes in April–July 2025. The 48 binomial regressions use the same eleven question features. The app ranks eligible models by this score. It requires at least 100 July appearances and a recorded official output price, including for “No limit.” The budget is USD per million output tokens. The input rate and date of each price appear alongside it. Actual invoice amounts depend on usage.

From the repository root, run `Rscript --vanilla R/verificar_app_final.R` to check the Shiny server, chart, and table against the published rankings for four task profiles and four budgets. For model calculations alone, add `--model-only`.

OpenAI Codex assisted with the app revision, checks and documentation.
