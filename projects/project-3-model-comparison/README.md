# El proyecto: ¿qué modelo de IA es mejor para cada tipo de tarea?

## Phase 0 (resumen, versión completa en `entregas/2026-10-07 phase-0-1-email.md`)

1. **Problema:** las empresas eligen 1 modelo de IA para todo, por marca o por un ranking general, aunque cada modelo es mejor en cosas distintas y los precios varían mucho.
2. **Cliente:** una empresa que usa IA para el trabajo de sus empleados y quiere saber qué modelo usar para cada tipo de trabajo.
3. **Datos históricos:** sí. LMArena publicó 135,634 votos (17/4 al 24/7/2025) en Hugging Face, gratis.
4. **¿Difícil de conseguir?** No. Es 1 solo dataset, sin uniones entre fuentes.
5. **Éxito:** predecir al ganador en votos nunca vistos mejor que el ranking general, más una herramienta donde eliges el tipo de tarea y te da el top 3.

## Phase 1 (resumen)

- **Se predice:** si un modelo gana o pierde una comparación contra otro, según las características de la pregunta.
- **¿Está en los datos?** Sí, explícito: la columna `winner`.
- **Predictores explícitos:** qué modelo y contra qué modelo, `is_code`, `math`, `creative_writing`, `instruction_following` y los 7 criterios de la pregunta, más el idioma.
- **Derivados:** compañía del modelo, si es versión "thinking", inglés sí o no, mes.
- **Externo:** precio de cada modelo (tabla propia, pendiente).
- **Leakage:** todo se conoce antes de que el modelo responda. El largo y el formato de la respuesta se conocen después, así que **no** son predictores.

## Dónde está todo

| Tema | Archivo |
|---|---|
| Contexto y estado | `docs/01-contexto.md` |
| Datos | `docs/03-datos.md`, `data/lmarena_votes.csv` |
| Método | `docs/04-metodo.md` |
| Resultados | `docs/05-resultados.md`, `R/` |
| Historial con el profesor | `docs/06-historial-y-profesor.md` |
| Pendientes y roles | `docs/07-pendientes-y-roles.md` |
