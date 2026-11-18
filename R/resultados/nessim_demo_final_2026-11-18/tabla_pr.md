| Per-AI-model AUC | All data (in sample) | Mean CV |
|---|---:|---:|
| Coin (constant score) | 0.5000 | 0.5000 |
| Question labels only | 0.5617 | 0.5387 |
| Opponent strength only | 0.6297 | 0.6290 |
| Question labels + opponent strength | 0.6450 | 0.6342 |

| Per-vote AUC | Big 0/1 | Big 0.5 | 48 regressions | General ranking |
|---|---:|---:|---:|---:|
| All data (in sample) | 0.6971 | 0.7002 | 0.7005 | 0.6854 |
| Fold 1 | 0.6911 | 0.6914 | 0.6902 | 0.6844 |
| Fold 2 | 0.6936 | 0.6935 | 0.6921 | 0.6873 |
| Fold 3 | 0.6972 | 0.6973 | 0.6954 | 0.6908 |
| Fold 4 | 0.6790 | 0.6788 | 0.6779 | 0.6735 |
| Fold 5 | 0.6931 | 0.6934 | 0.6912 | 0.6857 |
| Fold mean | 0.6908 | 0.6909 | 0.6894 | 0.6843 |

| Per-vote method (all held-out folds) | Accuracy | Precision | Recall |
|---|---:|---:|---:|
| 48 regressions | 0.6398 | 0.6351 | 0.6385 |
| 48 regressions + opponent strength | 0.6412 | 0.6364 | 0.6406 |
| General ranking | 0.6397 | 0.6346 | 0.6402 |
