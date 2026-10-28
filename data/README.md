# data/

`lmarena_votes.csv`: 135,634 votos (1 fila por voto, 30 columnas), sin el texto de las conversaciones. **No se edita a mano.** Las columnas están descritas en `docs/03-datos.md`.

**Fuente:** LMArena, *arena-human-preference-140k*, https://huggingface.co/datasets/lmarena-ai/arena-human-preference-140k (votos del 17/4 al 24/7/2025). Prompts de usuarios bajo CC-BY-4.0.

**Cómo regenerarlo:** bajar los 7 archivos `train-0000X-of-00007.parquet` de la carpeta `data/` del dataset en Hugging Face a una carpeta local, cambiar `data_folder` al principio de `R/lmarena_tests.R` y correr la sección 1 del script.

```r
library(readr)
votes <- read_csv("data/lmarena_votes.csv")
```
