# Base larga: contrato de uso

Generador: R/01_preparar_datos.R. No editar a mano el CSV derivado.
Cada voto genera dos filas: model y rival se invierten entre lados.
won: 1 gana, 0 pierde; NA en tie y both_bad mientras no haya acuerdo.
won_medio_punto_escenario: alternativa de 0.5 para tie y both_bad.
Esa columna no constituye una decision del grupo ni un predictor.
Antes de glm se debe elegir explicitamente una politica de respuesta.
Propuesta a discutir: excluir tie y both_bad del ajuste binario principal
y conservarlos para un analisis de sensibilidad. No esta aprobada.
both_bad no es necesariamente un empate de calidad; conviene separarlo.
Si se usa 0.5, no describirlo como una victoria binaria observada.
Predictores acordados: las 11 columnas de predictores.csv.
month queda disponible como metadato; su uso no se impone.
No se incluyen tokens, precios ni formato de las respuestas.
rival es identidad, no fuerza del rival. Ese control sigue abierto.
No agrupar versiones ni construir thinking sin decision del grupo.
requiere_revision senala casos para revisar, no autoriza eliminarlos.
No entrenar automaticamente con esos casos sin revisarlos.
Mark debe conservar juntas las dos filas de cada voto y cada sesion
en train/test, y aprender umbrales/fuerzas del rival solo con train.
La seleccion de modelos reproduce el universo descriptivo documentado.
No se ajustaron regresiones ni se eligio una particion.
Archivo original intacto: hash MD5 verificado en integridad.csv.
