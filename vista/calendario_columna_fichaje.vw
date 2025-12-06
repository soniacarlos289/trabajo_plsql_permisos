/*
================================================================================
  VISTA: rrhh.calendario_columna_fichaje
================================================================================
  PROPÓSITO:
    Genera una representación visual del calendario de fichaje en formato HTML
    para mostrar en la interfaz web. Cada día del mes se representa como una
    celda HTML con colores según el estado del día (laboral/no laboral/permiso).

  CAMPOS RETORNADOS:
    - ano: Año del calendario
    - mes: Mes del calendario
    - id_funcionario: Identificador del funcionario (0 si es calendario general)
    - id_dia: Fecha del día
    - desc_columna: Descripción de la columna base
    - columna1-columna7: Celdas HTML para cada día de la semana (con enlaces)
    - s_columna1-s_columna7: Celdas HTML simples (solo número del día)
    - d_columna1-d_columna7: Celdas HTML con enlace a incidencias

  CÓDIGOS DE COLOR:
    - #FFFFFF (blanco): Día laboral normal
    - #FA5858 (rojo): Día no laboral (festivo/fin de semana)
    - #F5ECCE (amarillo): Día actual (hoy)
    - Otros: Según configuración de permisos (DESC_COLUMNA)

  ESTRUCTURA DE COLUMNAS:
    - columna1-7: Representan Domingo a Sábado (según to_char(id_dia,'d'))
    - Cada versión (columna, s_columna, d_columna) tiene un formato diferente:
      * columna: Con enlace a detalle del día
      * s_columna: Solo número del día, sin enlace
      * d_columna: Con enlace a incidencias

  JOINS UTILIZADOS:
    - calendario_laboral (ca): Días del calendario
    - webperiodo (w): Definición de períodos
    - calendario_fichaje (cf): Datos de fichaje del calendario (LEFT OUTER JOIN)

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    ADVERTENCIA: Vista compleja con múltiples DECODEs anidados
    =========================================================================
    - Cada DECODE se evalúa para cada fila, lo cual puede ser costoso
    - La generación de HTML en la vista es un patrón común pero no óptimo
    - Considerar mover la generación de HTML a la capa de presentación

    - El filtro ano > 2015 limita los datos históricos
    - El LEFT OUTER JOIN con calendario_fichaje usa sintaxis (+) Oracle

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_cal_lab_periodo ON calendario_laboral(id_dia, ano, mes);
    - CREATE INDEX idx_cal_fich_fechas ON calendario_fichaje(fecha_inicio, fecha_fin);

  DEPENDENCIAS:
    - Tabla: calendario_laboral
    - Tabla: webperiodo  
    - Vista: calendario_fichaje

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
create or replace force view rrhh.calendario_columna_fichaje as
(
select ano,mes,nvl(id_funcionario,0) as id_funcionario, id_dia,desc_columna,

 DECODE ((to_char(id_dia,'d')) ,
            1, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a  href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                      ''||  DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')

  as columna1,
   DECODE ((to_char(id_dia,'d')) ,
            2, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna2,
 DECODE ((to_char(id_dia,'d')) ,
            3, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna3,
 DECODE ((to_char(id_dia,'d')) ,
            4, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                       DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')

  as columna4,
   DECODE ((to_char(id_dia,'d')) ,
            5, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna5,
 DECODE ((to_char(id_dia,'d')) ,
            6, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'  ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna6,
     DECODE ((to_char(id_dia,'d')) ,
            7, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858>' ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'
                                    ,      'SI','<td bgcolor=FFFFFF>'  ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</div></a>'   ||'</td>'),
                        DESC_COLUMNA ||'<a href=../Finger/detalle_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</a>'   || '</td>')
           ,'')
  as columna7,

DECODE ((to_char(id_dia,'d')) ,
            1, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')

  as s_columna1,
   DECODE ((to_char(id_dia,'d')) ,
            2, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                            'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna2,
 DECODE ((to_char(id_dia,'d')) ,
            3, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna3,
 DECODE ((to_char(id_dia,'d')) ,
            4, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')

  as s_columna4,
   DECODE ((to_char(id_dia,'d')) ,
            5, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna5,
 DECODE ((to_char(id_dia,'d')) ,
            6, DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna6,
     DECODE ((to_char(id_dia,'d')) ,
            7,DECODE(DESC_COLUMNA,
                       '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">' || to_number((to_char(id_dia,'dd'))) || '</td>' ,
                                                           'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">') || to_number((to_char(id_dia,'dd'))) || '</td>'),
                        DESC_COLUMNA || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
  as s_columna7,DECODE ((to_char(id_dia,'d')) ,
          1, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna1,

DECODE ((to_char(id_dia,'d')) ,
          2, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA   ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna2,

DECODE ((to_char(id_dia,'d')) ,
          3, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna3,

DECODE ((to_char(id_dia,'d')) ,
          4, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna4,

DECODE ((to_char(id_dia,'d')) ,
          5, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna5,

DECODE ((to_char(id_dia,'d')) ,
          6, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>' , 'SI',DECODE( to_char(id_dia,'dd/mm/yyyy'),to_char(sysdate,'dd/mm/yyyy'),'<td bgcolor=#F5ECCE align="center">','<td bgcolor=FFFFFF align="center">')
              ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))
              || '</td>'),  DESC_COLUMNA ||'<a href=incidencia_dia.jsp?ID_DIA='   ||       to_CHAR(id_dia, 'DD/MM/YYYY') ||     '><div align="center">' || to_number((to_char(id_dia,'dd')))|| '</td>')
           ,'')
as d_columna6,

DECODE ((to_char(id_dia,'d')) ,
          7, DECODE(DESC_COLUMNA,
              '<td bgcolor=FFFFFF>',DECODE(LABORAL,'NO','<td bgcolor=#FA5858 align="center">'
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

