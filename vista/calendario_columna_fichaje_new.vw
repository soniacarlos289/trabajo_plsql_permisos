/*
================================================================================
  VISTA: rrhh.calendario_columna_fichaje_new
================================================================================
  PROPÓSITO:
    Versión mejorada de calendario_columna_fichaje que utiliza la función 
    laboral_dia() para determinar dinámicamente si un día es laboral para 
    cada funcionario específico, en lugar de usar el campo LABORAL estático.

  DIFERENCIA PRINCIPAL CON calendario_columna_fichaje:
    - Usa laboral_dia(id_funcionario, id_dia) en lugar del campo LABORAL
    - Permite determinar días laborales personalizados por funcionario
    - Considera turnos especiales, vacaciones personales, etc.

  CAMPOS RETORNADOS:
    - ano: Año del calendario
    - mes: Mes del calendario
    - id_funcionario: Identificador del funcionario
    - id_dia: Fecha del día
    - desc_columna: Descripción de la columna base
    - columna1-columna7: Celdas HTML para cada día de la semana
    - s_columna1-s_columna7: Celdas HTML simples
    - d_columna1-d_columna7: Celdas HTML con enlace a incidencias

  CÓDIGOS DE COLOR:
    - #FFFFFF (blanco): Día laboral para el funcionario
    - #FA5858 (rojo): Día no laboral para el funcionario
    - #F5ECCE (amarillo): Día actual (hoy)

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    ADVERTENCIA: Uso intensivo de función laboral_dia()
    =========================================================================
    - La función laboral_dia() se llama MÚLTIPLES VECES por cada fila
      (una vez por cada columna DECODE que evalúa el día de la semana)
    - Esto puede resultar en un rendimiento significativamente menor
      que calendario_columna_fichaje
    
    RECOMENDACIONES:
    - Usar solo cuando se necesite el calendario personalizado por funcionario
    - Considerar cachear el resultado de laboral_dia() si es posible
    - Filtrar siempre por id_funcionario en las consultas

    ÍNDICES RECOMENDADOS:
    - Mismos que calendario_columna_fichaje
    - Índices en las tablas que usa laboral_dia()

  DEPENDENCIAS:
    - Tabla: calendario_laboral
    - Tabla: webperiodo
    - Vista: calendario_fichaje
    - Función: laboral_dia()

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
create or replace force view rrhh.calendario_columna_fichaje_new as
(
select ano,mes,nvl(id_funcionario,0) as id_funcionario, id_dia,desc_columna,

 DECODE ((to_char(id_dia,'d')) ,
            1, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a  href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                      ''||  DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')

  as columna1,
   DECODE ((to_char(id_dia,'d')) ,
            2, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna2,
 DECODE ((to_char(id_dia,'d')) ,
            3, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna3,
 DECODE ((to_char(id_dia,'d')) ,
            4, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                       DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')

  as columna4,
   DECODE ((to_char(id_dia,'d')) ,
            5, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna5,
 DECODE ((to_char(id_dia,'d')) ,
            6, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'  ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna6,
     DECODE ((to_char(id_dia,'d')) ,
            7, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna7,

DECODE ((to_char(id_dia,'d')) ,
            1, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')

  as s_columna1,
   DECODE ((to_char(id_dia,'d')) ,
            2, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                            'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna2,
 DECODE ((to_char(id_dia,'d')) ,
            3, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna3,
 DECODE ((to_char(id_dia,'d')) ,
            4, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')

  as s_columna4,
   DECODE ((to_char(id_dia,'d')) ,
            5, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna5,
 DECODE ((to_char(id_dia,'d')) ,
            6, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna6,
     DECODE ((to_char(id_dia,'d')) ,
            7,DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna7,DECODE ((to_char(id_dia,'d')) ,
          1, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna1,

DECODE ((to_char(id_dia,'d')) ,
          2, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA   ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna2,

DECODE ((to_char(id_dia,'d')) ,
          3, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna3,

DECODE ((to_char(id_dia,'d')) ,
          4, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna4,

DECODE ((to_char(id_dia,'d')) ,
          5, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna5,

DECODE ((to_char(id_dia,'d')) ,
          6, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna6,

DECODE ((to_char(id_dia,'d')) ,
          7, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(laboral_dia(id_funcionario,id_dia),'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna7





  from calendario_laboral ca, webperiodo w,
                      CALENDARIO_FICHAJE   CF

   where ca.id_dia between cf.fecha_inicio(+) and nvl(cf.fecha_fin(+),sysdate)
  -- where ca.id_dia between decode(sign(CF.FECHA_INICIO -W.INICIO) ,1,CF.FECHA_INICIO(+),W.INICIO(+)) AND nvl(CF.FECHA_fin(+),sysdate)
   and ca.id_dia between w.inicio and w.fin
   and ano > 2015
   --and mes = '04' and cf.id_funcionario(+)=101259

)
;

