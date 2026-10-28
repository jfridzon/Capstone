# Capstone: ¿qué modelo de IA es mejor para cada tipo de tarea?

Repo de contexto compartido para el equipo (5 integrantes) y para las IAs (Claude, ChatGPT, etc.) que cada uno use mientras avanza en el proyecto. La idea: en vez de que cada persona tenga su propio hilo de conversación con su IA sin visibilidad de lo que hicieron los demás, este repo es la fuente única de verdad. Cualquier IA puede leerlo y partir de ahí.

**Curso:** IDS 3000 Business Intelligence Capstone (Yeshiva University, Sy Syms, Prof. Avi Giloni).
**Grupo:** Nessim Betesh, Marco Fnounou, Mark Benzaquen, Eli Wulfsohn y Jaime Fridzon.

## Estado actual (26 oct 2026)

**El proyecto: ¿qué modelo de IA es mejor para cada tipo de tarea?**

- Las empresas pagan por IA y casi siempre eligen 1 solo modelo (ChatGPT, Claude, Gemini, etc.) para todo, pero cada modelo es mejor en cosas distintas.
- Usamos 135,634 votos reales de LMArena, donde una persona hace una pregunta, 2 modelos anónimos responden y la persona vota cuál respuesta es mejor.
- Con una regresión logística estimamos qué tan fuerte es cada modelo según las características de la pregunta (código, math, escritura creativa, dificultad, etc.) y sacamos un ranking de modelos para cada tipo de tarea.

**Ya entregado:** Phase 0 y Phase 1 (7/10), Individual Work (12/10), data dictionary (14/10), updated data dictionary (19/10), explicación del método (21/10) y los datos con los tests (22/10). Todo está en `entregas/`.

**En discusión ahora:** el profesor quiere ver exactamente cómo se hace la predicción con regresión logística. Ver `docs/04-metodo.md` y las decisiones abiertas en `docs/07-pendientes-y-roles.md`.

## Por dónde empezar

Si eres una persona o una IA que llega nueva al proyecto, lee en este orden:

| # | Archivo | Qué tiene |
|---|---|---|
| 0 | [`AGENTS.md`](AGENTS.md) | **Reglas para las IAs** (y para todos). Léelo antes de tocar nada |
| 1 | [`docs/01-contexto.md`](docs/01-contexto.md) | El proyecto completo: problema, cliente, idea, estado actual |
| 2 | [`docs/02-curso-y-requisitos.md`](docs/02-curso-y-requisitos.md) | Qué pide el curso, cómo se evalúa, calendario |
| 3 | [`docs/03-datos.md`](docs/03-datos.md) | El dataset: de dónde viene, cómo se recolectó, columnas, reglas de limpieza |
| 4 | [`docs/04-metodo.md`](docs/04-metodo.md) | Cómo hacemos la predicción: respuesta, predictores, modelos, prueba |
| 5 | [`docs/05-resultados.md`](docs/05-resultados.md) | Todos los números que ya tenemos |
| 6 | [`docs/06-historial-y-profesor.md`](docs/06-historial-y-profesor.md) | Cronología del proyecto, lo que se le mandó al profesor y lo que pidió |
| 7 | [`docs/07-pendientes-y-roles.md`](docs/07-pendientes-y-roles.md) | Quién hace qué y qué falta decidir |
| 8 | [`docs/08-como-trabajar-en-el-repo.md`](docs/08-como-trabajar-en-el-repo.md) | Ramas, pull requests, permisos |

## Estructura

```
AGENTS.md    → reglas para las IAs (CLAUDE.md y .github/copilot-instructions.md apuntan aquí)
docs/        → contexto, datos, método, resultados, historial, pendientes (01 a 08) + el texto original de Phase 0 y Phase 1
data/        → lmarena_votes.csv (los 135,634 votos) y su descripción
R/           → código en R y sus resultados (R/resultados/)
entregas/    → lo que ya se le mandó al profesor, con fecha (no se edita)
projects/    → resumen de Phase 0 y Phase 1 del proyecto
```

## Cómo usar este repo (humanos e IA)

1. Clona el repo o descárgalo.
2. Antes de pedirle algo a tu IA, dale `AGENTS.md` y `docs/01-contexto.md` como contexto, más el documento de `docs/` que tenga que ver con tu tarea. Así no se repite trabajo ni se contradice lo que ya está.
3. **No se escribe directo en `main`.** Crea una rama (`tunombre/tema`), haz tus cambios ahí y abre un pull request. Lo aprueba uno de los responsables (Mark, Nessim o Jaime). Ver `docs/08`.
4. No borres lo que ya está. Si algo contradice lo existente, deja una nota explicando el cambio en vez de sobrescribir en silencio.
5. Haz commits con un mensaje claro de qué agregaste y de qué conversación o fecha viene.
6. Este repo es **público**: nada de datos personales, notas, contraseñas ni API keys.
