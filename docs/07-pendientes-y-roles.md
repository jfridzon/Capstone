# 07. Roles, pendientes y decisiones abiertas

## Roles (de la entrega Individual Work del 12/10)

Cada update individual (20% de la nota) tiene que mostrar qué hizo **esa persona** y cómo aporta al grupo. Por eso cada quien tiene una parte suya.

| Persona | Usuario GitHub | Su parte |
|---|---|---|
| Marco Fnounou | `marcofnounou-bit` | **Tabla de precios:** el precio de cada modelo según las páginas públicas de precios, emparejado con los nombres de modelo de los datos |
| Nessim Betesh | `NDB13` | **Limpieza:** variable `won`, valores faltantes, modelos con pocos votos |
| Jaime Fridzon | `jfridzon` | **Datos en R y predictores derivados:** juntar los datos en 1 archivo para todos (hecho: `data/lmarena_votes.csv`) y crear predictores como `company` |
| Mark Benzaquen | `markbzq` | **Train/test y ranking general:** partir los datos y construir el ranking general, que es lo que hay que superar |
| Eli Wulfsohn | `eliwulfsohn03` | **Rankings publicados de LMArena y largo de respuesta:** comparar con el leaderboard oficial y revisar si la gente vota por la respuesta más larga (primer resultado: 61.8%) |

Parte de esto ya avanzó con los tests del 22/10 (`docs/05`). Cada quien debería revisar qué le queda de su parte.

## Decisiones abiertas (el grupo decide, no la IA)

1. **Modelo principal:** 48 regresiones (1 por modelo), 1 regresión combinada (Bradley-Terry con covariables) o las 2. Ver `docs/04`.
2. **Empates y both_bad:** se excluyen (lo que se usó hasta ahora) o se cuentan como medio punto (lo que se dijo en Phase 1).
3. **Definición de "difícil":** 6 o más de 7 criterios (regla de LMArena), o usar los 7 criterios por separado como predictores.
4. **Versiones de un mismo modelo:** agrupar o no las preview de Gemini 2.5 Pro con la versión final, y las thinking con la normal.
5. **Variable `thinking`:** cómo etiquetar los modelos que razonan pero no dicen "thinking" en el nombre (o3, deepseek-r1, qwq, magistral, etc.).
6. **Modelos que solo aparecen en julio** (grok-4, kimi-k2, mistral-small-2506, grok-3-mini-high): no se pueden evaluar con train abril-junio. ¿Se usa otra partición (por ejemplo aleatoria por sesión) como chequeo adicional?
7. **Qué hacer si el ranking por características no le gana al ranking general:** reportarlo como hallazgo y mover el valor al ángulo de precio.

## Pendientes

- [ ] Correr la prueba de julio con el método de características (`docs/04`) y comparar con 64.5%.
- [ ] Pasar a scripts de R los análisis de `docs/05` que todavía no están en `R/`: chequeo de asignación aleatoria, cobertura, prueba de julio y top 3.
- [ ] Tabla de precios (Marco).
- [ ] Explicarle al profesor el cambio de 10 cajas a características.
- [ ] Preparar el primer update formal individual (2 o 3 slides cada uno).
- [ ] Calendario: limpieza 28/10 y 2/11, analytics 4/11 a 16/11, app 18/11 a 30/11, dashboards 2/12 y 7/12, reporte y presentación 9/12 a 23/12.
