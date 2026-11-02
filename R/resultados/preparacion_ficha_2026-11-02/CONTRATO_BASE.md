# Contrato vigente de la base de Nessim
votos_filtrados.csv conserva todos los campos y valores originales.
votos_largo.csv usa exactamente las columnas de docs/tareas/nessim.md.
lado: a/b. resultado: gano/perdio/empate/ambos_malos.
won: 1/0 para victoria/derrota; NA para empate o ambos_malos.
No se eligio una politica final para los resultados no decisivos.
Propuesta pendiente: ajuste binario con decisivos y sensibilidad aparte.
No se agrupan versiones ni se elige control del rival o particion.
sum_user_tokens y language se conservan por la ficha; no se agregan
automaticamente como predictores. Las 11 caracteristicas siguen acordadas.
Las bases conservan casos senalados; ver banderas_por_voto.csv.
No usar esas banderas como predictores ni eliminar casos sin revision.
Las 2 filas de un voto y las sesiones deben permanecer juntas al evaluar.
La base larga comprimida de octubre se mantiene intacta como historico.
Original verificado con MD5. Codigo preparado con asistencia de IA.
