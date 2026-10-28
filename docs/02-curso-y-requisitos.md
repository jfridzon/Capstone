# 02. El curso y lo que pide

**IDS 3000-241 Business Intelligence Capstone.** Prof. Avi Giloni (Chair, Information and Decision Science, Sy Syms). Clase los lunes de 4:30 a 5:45, y el calendario también tiene miércoles.

La clase es el proyecto. En clase los grupos trabajan y el profesor pasa por los grupos asesorando.

## Cómo se evalúa

| Parte | Peso | Quién |
|---|---|---|
| Assignments / reflections | 10% | Individual, se entrega en clase y hay que estar presente |
| **Updates formales individuales** | **20%** | Individual. Cada ~2 semanas en clase: 2 o 3 slides con resultados, pasos hechos, próximos pasos y **cómo tu trabajo individual aporta a la meta del grupo**. Hay que estar presente |
| **Reporte escrito** | **40%** | Grupo. Técnico, para un data scientist. Tiene que incluir el código (R Markdown o similar) y ser replicable |
| **Presentación** | **30%** | Grupo. 15 a 20 minutos para gente de negocio, no para estadísticos. Con un apéndice para preguntas técnicas |

Consecuencia práctica: cada persona necesita una parte del trabajo que sea **claramente suya** y que pueda mostrar en sus updates. Ver `docs/07`.

## Software

R y RStudio (desde 2027 el curso pasa a Python, este semestre se puede usar cualquiera de los 2). El grupo trabaja en **R**.

## Política de IA

El syllabus permite IA generativa y asistiva **sin restricción**, pero **todo contenido producido con IA generativa tiene que citarse** (formato MLA o APA). No citarla puede contar como plagio. Las entregas pasan por Turnitin.

## Las fases del proyecto

**Phase 0 (definición del problema).** Para hasta 3 proyectos posibles: el problema, el cliente, si hay datos históricos, si es muy difícil conseguirlos y qué sería un proyecto exitoso.

**Phase 1 (disponibilidad de datos).** Para 1 proyecto:
1. ¿Qué se predice? Si no es una predicción, hay que hablar con el profesor.
2. ¿Está ese valor explícito en los datos? Si no, ¿hay un proxy?
3. ¿Qué predictores se quieren usar? ¿Están en los datos, salen de una transformación o de un proxy?
   - 3a. Los predictores tienen que conocerse **en el momento de tomar la decisión**, no después. Si no, no se puede predecir con datos nuevos.

El profesor lo explicó en clase el 23/9: primero se define lógicamente qué se quiere predecir y con qué, y después se busca si eso está en los datos. No al revés ("tirar todos los datos y ver qué sale").

**Phase 2, Part 1 (data dictionary).** 3 columnas: nombre de la variable, qué se hace con ella (respuesta, predictor, transformar para generar predictor, no relevante, desconocido) y descripción.

**Updated data dictionary.** El mismo Excel más una hoja con solo las variables de respuesta, predictores y por transformar, con el rango (cuantitativas), los niveles (categóricas) y los valores faltantes.

## Calendario tentativo (syllabus)

| Fechas | Etapa |
|---|---|
| 31/8 a 23/9 | Análisis exploratorio y definición del problema |
| 7/10 a 19/10 | Definición del problema y posibles enfoques |
| 21/10 y 26/10 | Recolectar, scrapear y generar datos |
| 28/10 y 2/11 | Limpiar datos y preparar análisis |
| 4/11 a 16/11 | Analytics y predicción estadística |
| 18/11 a 30/11 | App / software |
| 2/12 y 7/12 | Dashboards |
| 9/12 a 23/12 | Reporte y presentación |
| Por definir | Entrega final y presentaciones en clase. El horario de examen final de la sección 241 es el lunes 28/12, de 9:30 a 11:45, y podría usarse para presentaciones (confirmar con el profesor) |

No hay exámenes.
