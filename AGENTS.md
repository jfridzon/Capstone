# Instrucciones para las IAs que trabajen en este repo

Este archivo es para cualquier asistente de IA (Claude, ChatGPT, Copilot, Cursor, Gemini, etc.) que use un miembro del grupo. Las reglas también aplican a las personas.

## Antes de hacer cualquier cosa

1. Lee `README.md` y `docs/01-contexto.md` completos.
2. Lee el documento de `docs/` que tenga que ver con tu tarea. Si es de datos, `docs/03-datos.md`. Si es de modelos, `docs/04-metodo.md`. Si vas a usar un número, `docs/05-resultados.md`.
3. Revisa `docs/07-pendientes-y-roles.md` para saber qué le toca a tu persona y qué decisiones siguen abiertas. **No tomes por tu cuenta una decisión que está marcada como abierta.** Propónla en el pull request y que el grupo decida.

## Reglas que no se rompen

1. **Nunca hagas push a `main`.** Crea una rama `nombre/tema` (por ejemplo `nessim/limpieza-datos`), haz tus commits ahí y abre un pull request. `main` está protegida y necesita aprobación.
2. **No borres ni sobrescribas nada en `data/` ni en `entregas/`.** `data/` es la fuente de datos y `entregas/` es lo que ya se le mandó al profesor. Si hace falta una versión nueva, se crea un archivo nuevo con fecha nueva.
3. **No reescribas la historia.** Nada de `git push --force`, `git reset --hard` sobre ramas compartidas ni rebase de `main`.
4. **No borres ramas ni archivos de otros**, y no cierres pull requests ni issues de otros.
5. **No inventes números.** Todo número tiene que salir de código que esté en `R/` (y que cualquiera pueda correr) o de `docs/05-resultados.md`. Si calculas algo nuevo, deja el script en `R/` y el resultado en `R/resultados/`.
6. **El repo es público.** No subas correos, notas personales, calificaciones, teléfonos, contraseñas, tokens ni API keys.
7. **Quédate en tu tarea.** No "arregles" ni reorganices cosas que no te pidieron. Si ves un problema, descríbelo en el pull request o en un issue.
8. **Si no estás seguro, pregúntale a tu persona** antes de actuar.

## Cómo trabajamos

- **Lenguaje:** R (el curso usa R y RStudio). Usa rutas relativas al repo, por ejemplo `read_csv("data/lmarena_votes.csv")`.
- **Idioma:** los documentos internos (`docs/`) van en español. Todo lo que se le manda al profesor (correos, reporte, presentación) va en inglés, simple y fácil de entender.
- **Variables:** solo se pueden usar como predictores cosas que se conocen **antes** de que el modelo escriba su respuesta. El largo de la respuesta, los headers, las listas y las negritas **nunca** son predictores. Ver `docs/04-metodo.md`.
- **Cada pull request** dice qué cambió, por qué y qué archivos tocó. Si agrega resultados, también actualiza `docs/05-resultados.md`. Si cambia una decisión, actualiza `docs/07-pendientes-y-roles.md`.
- **Uso de IA:** el syllabus exige citar el contenido generado con IA. Si tu IA escribió una parte de un entregable, se dice.

## Lo que el profesor valora (para todo lo que se le mande)

- Que se entienda rápido y sin esfuerzo. Explicaciones cortas y simples.
- Que quede explícito qué se predice (la variable de respuesta) y con qué predictores.
- Que cada miembro pueda explicar en persona lo que se entregó. No mandes nada que el grupo no entienda.
