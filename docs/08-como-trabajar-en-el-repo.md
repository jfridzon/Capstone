# 08. Cómo trabajar en el repo

## Para todos (personas e IAs)

1. Bajar los últimos cambios: `git pull origin main`
2. Crear una rama: `git checkout -b tunombre/tema`
3. Trabajar y hacer commits en esa rama.
4. Subir la rama: `git push origin tunombre/tema`
5. Abrir un pull request en GitHub hacia `main`, explicando qué cambió y por qué.
6. Esperar la aprobación de un responsable (abajo). Después se hace merge.

Nunca push directo a `main`, nunca `--force` y nunca borrar `data/` ni `entregas/`. Ver `AGENTS.md`.

## Responsables (pueden aprobar cambios a `main`)

- Jaime Fridzon (`@jfridzon`), dueño del repo
- Nessim Betesh (`@NDB13`)
- Mark Benzaquen (`@markbzq`)

Están en `.github/CODEOWNERS`. Nadie se aprueba su propio pull request: si un responsable hace un cambio, lo aprueba otro responsable.

## Configuración de protección (la hace Jaime, como dueño)

En un repo personal todos los collaborators pueden escribir. Lo que evita que alguien, o la IA de alguien, dañe algo es la **protección de la rama `main`**. En repos públicos es gratis.

En GitHub: **Settings → Rules → Rulesets → New branch ruleset** (o **Settings → Branches → Add rule**), aplicado a la rama `main`, con:

- [x] Restrict deletions (nadie puede borrar `main`)
- [x] Block force pushes
- [x] Require a pull request before merging
  - Required approvals: **1**
  - [x] Require review from Code Owners
  - [x] Dismiss stale pull request approvals when new commits are pushed
- Enforcement status: **Active**

Con eso, cualquier IA o persona puede proponer cambios en su rama, pero solo entran a `main` si Mark, Nessim o Jaime los aprueban. Y como git guarda toda la historia, cualquier error se puede revertir.

**Si el repo vuelve a ser privado:** la protección de ramas en repos privados necesita GitHub Pro, que es gratis para estudiantes con el GitHub Student Developer Pack.

## Datos grandes

`data/lmarena_votes.csv` pesa unos 33 MB, dentro del límite de GitHub (100 MB por archivo). No suban los parquet originales (1.6 GB) ni archivos de más de 50 MB. Están en `.gitignore`.
