# Auditoria de limpieza de LMArena

Estado: reportes generados; revisar controles y perfil de faltantes
El CSV original conserva el mismo hash MD5.
No se exporto una base limpia ni se entrenaron modelos.

## Como interpretar los archivos
- perfil_columnas.csv: NA, vacios y espacios por columna.
- controles.csv: problemas detectados; no se reparan automaticamente.
- idiomas.csv: und permanece separado de los faltantes.
- votos_por_modelo.csv: elegibilidad segun dos universos de conteo.
- etapas_filtros.csv: retencion de votos por cada escenario.
- verificacion_won.csv: consistencia de respuestas en votos decisivos.
Si hay controles bloqueantes no se generan escenarios de filtros.

## Decisiones que siguen abiertas
Excluir empates/both_bad es solo el escenario historico documentado.
No se asigna medio punto ni se agrupan versiones de modelos.
won_a, won_b e y se comprueban en memoria; no son una base final.
No se imputa, deduplica ni elimina und o atipicos automaticamente.
Las comparaciones de un modelo consigo mismo y los primeros votos
repetidos por sesion se senalan, pero no se eliminan del diagnostico.
Requieren revision del grupo antes de declarar una base apta para modelar.
Los conteos con todos los datos no definen elegibilidad para modelar.
Mark y el grupo deben acordar el universo del umbral usando train.
No se decide modelo principal, thinking, dificultad ni particion.

Referencias: docs/03-datos.md, docs/04-metodo.md y docs/07-pendientes-y-roles.md.
Script preparado con asistencia de IA; revisarlo antes de usar resultados.
