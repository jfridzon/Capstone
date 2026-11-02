# 10. Entrega de Nessim: contrato actualizado al 2/11/2026

Preparado con asistencia de ChatGPT/Codex. Implementa el contrato de
**fase 1** de `docs/tareas/nessim.md`. Las decisiones vigentes del grupo
estan en `docs/12-decisiones-2-11.md`; esta exportacion no las modifica.

## Ejecutar desde la raiz

```r
source("R/01_preparar_datos.R")
preparar_datos(nombre = "preparacion_ficha_2026-11-02")
```

Requiere `readr` y `dplyr`. Si ya existe cualquiera de las dos salidas o la
carpeta de reportes, se detiene ANTES de escribir. Para una nueva version:

```r
preparar_datos(
  nombre = "preparacion_revision_nueva",
  salida = "data/derivados/revision_nueva"
)
```

Esto crea una carpeta nueva, sin reemplazar versiones anteriores.

## Archivos que genera

- `data/derivados/votos_filtrados.csv`: una fila por voto, con todos los campos
  del original, en el mismo orden y con los mismos valores. Filtra solo
  `evaluation_order == 1` y comparaciones entre modelos con al menos
  1.000 participaciones, contando ambos lados en el original.
- `data/derivados/votos_largo.csv`: exactamente las columnas de la ficha,
  con `mes`, `modelo`, `rival`, `lado` a/b, `resultado` y `won`, las once
  caracteristicas, `sum_user_tokens` y `language`.
- `R/resultados/preparacion_ficha_2026-11-02/`: auditoria, conteos,
  elegibilidad, banderas por voto y huellas de las salidas.

`resultado` distingue `gano`, `perdio`, `empate` y `ambos_malos` desde la
perspectiva del modelo de cada fila. `won` es 1/0 para victoria/derrota y NA
para empates y ambos_malos. Los dos tipos no decisivos permanecen en ambas bases.

Los CSV se leen directamente con `readr::read_csv()`. `mes` es el numero del
mes UTC. Las caracteristicas son booleanas en el archivo largo.
`sum_user_tokens` y `language` se conservan por la ficha; no se incorporan
por eso automaticamente a la formula de las regresiones.

Los campos de largo y formato de respuesta quedan solo en el archivo ancho,
porque este conserva el original. No aparecen entre los predictores del largo.

## Validaciones

```sh
Rscript R/probar_auditoria.R
Rscript R/probar_preparacion.R
Rscript R/validar_exportaciones_nessim.R
```

El ultimo comando valida los dos CSV predeterminados y guarda su reporte en
la carpeta de la ejecucion del 2/11. Comprueba los valores exportados contra
el original, los dos lados de cada voto y la conservacion de las caracteristicas,
los tokens de la pregunta y el idioma. Los conteos estan en `docs/05`.

## Relacion con las decisiones vigentes

La propuesta inicial de excluir los no decisivos queda como antecedente, no
como politica vigente: el grupo decidio medio punto para el ajuste y excluir
como sensibilidad (`docs/12`). La evaluacion sigue sobre votos decisivos.

Se conserva el contrato de fase 1: `won` no contiene medio punto y `resultado`
permite derivar la respuesta 0.5 en el ajuste posterior. No se reescriben las
bases ni los reportes historicos. Las referencias a propuestas pendientes en
los reportes describen su preparacion; para el estado actual prevalece `docs/12`.

Este generador no agrupa versiones, estima la fuerza del rival ni parte
train/test. Mark conserva su responsabilidad de evaluar sin dividir votos
ni sesiones y sin aprender reglas del test. La fase 2 de Nessim se desarrolla
por separado en la rama y el script indicados en su ficha.

Las autocomparaciones y sesiones con primeros votos repetidos permanecen en
los archivos para reproducir la ficha. Las banderas se guardan por separado;
no son predictores. Mark ya excluye autocomparaciones de su ajuste y evaluacion.

## Compatibilidad con la entrega anterior

`data/derivados/base_regresiones_2026-10-28_v2.csv.gz` permanece intacto.
El nuevo generador produce los dos contratos pedidos; no vuelve a generar el
formato anterior con `model`/`month` ni la columna del escenario de medio punto.
Los scripts de otros integrantes no se modifican. Si consumen el formato
anterior, deben coordinar su migracion a `modelo`/`mes` por separado.
