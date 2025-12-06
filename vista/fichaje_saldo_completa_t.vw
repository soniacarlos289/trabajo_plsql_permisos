/*
================================================================================
  VISTA: rrhh.fichaje_saldo_completa_t
================================================================================
  PROPÓSITO:
    Vista de saldo de fichaje con formato especial para tabla HTML, incluyendo
    indicador de fila impar/par para estilos alternados. Combina fichajes,
    permisos, ausencias y fichajes abiertos.

  CAMPOS RETORNADOS:
    - impar: '0' o '1' para alternar estilos de fila
    - f: Fecha para ordenamiento
    - fecha: Enlace HTML al detalle del día
    - mes_fecha: Código MMAAAA para filtros
    - entrada/salida: Horas de entrada y salida
    - horas_fichadas/horas_hacer: Horas fichadas y a realizar
    - dminutos: Diferencia en minutos (texto)
    - observaciones: Texto con incidencias o enlaces
    - mes_fecha_ano: Período completo
    - id_funcionario: Identificador del funcionario

  FUENTES DE DATOS (UNION de 4 consultas):
    1. PRESENCI + PERSFICH: Fichajes de presencia
    2. PERMISO + TR_TIPO_PERMISO: Permisos activos
    3. AUSENCIA + TR_TIPO_AUSENCIA: Ausencias activas
    4. FICHABIE: Fichajes abiertos (sin cierre)

  FILTROS APLICADOS:
    - codinci = '000': Solo incidencia normal
    - Estados activos (no en 30, 31, 32, 40, 41)
    - Anulado = 'NO' o NULL
    - Excluye sábados sin fichaje (día 6)

  DEPENDENCIAS:
    - Tablas: presenci, persfich, permiso, ausencia, fichabie
    - Tablas auxiliares: webperiodo, calendario_laboral, persona, apliweb_usuario
    - Tablas de catálogo: tr_tipo_permiso, tr_tipo_ausencia

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW RRHH.FICHAJE_SALDO_COMPLETA_T AS
SELECT to_char(mod(rownum, 2)) as impar,
       FECHA as F,
       '<a href=\"../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(FECHA, 'DD/MM/') || '20' || to_CHAR(FECHA, 'yy') || '\">' ||
       to_CHAR(FECHA, 'DD/MM/yy') || '</a>' AS FECHA,
       to_CHAR(FECHA, 'MM') || '20' || to_CHAR(FECHA, 'YY') AS MES_FECHA,
       ENTRADA,
       SALIDA,
       horas_fichadas,
       horas_hacer,
       to_char(to_number(NVL(ROUND(nvl(diferencia_minutos, 0)), 0))) AS DmINUTOS,
       observaciones,
       fecha_mes_ano as mes_fecha_ano,
                id_funcionario
  FROM (SELECT to_DATE(R.FECHA, 'dd/mm/yy') AS FECHA,
               to_char(B.HINICIO, 'hh24:mi') AS ENTRADA,
               to_char(B.HFIN, 'hh24:mi') AS SALIDA,
               to_char(b.hcomputablef, 'hh24:mi') Horas_fichadas,
               DECODE(to_char(b.hcomputableo, 'hh24:mi'),
                      '00:00',
                      '00:00',
                      to_char(r.horteo, 'hh24:mi')) horas_hacer,
               (to_date('30/12/1899' || to_char(b.hcomputablef, 'hh24:mi'),
                        'DD/MM/YYYY HH24:MI') -
               DECODE(to_char(b.hcomputableo, 'hh24:mi'),
                       '00:00',
                       b.hcomputableo,
                       r.horteo)) * 60 * 24 as diferencia_minutos,
               DECODE(substr(to_char(b.hcomputablef, 'hh24:mi'), 1, 2),
                      '00',
                      DECODE(substr(to_char(b.hcomputablef, 'hh24:mi'), 4, 2),
                             '00',
                             'Posible Incidencia.Ficheje repetido.',
                             '01',
                             'Posible Incidencia.Ficheje repetido.',
                             '02',
                             'Posible Incidencia.Fichaje repetido.',
                             ''),
                      DECODE(B.HINICIO,
                             NULL,
                             'SIN FICHAJE EN EL D�A   <img src=\"../../imagen/icono_advertencia.jpg\" alt=\"INCIDENCIA\"  width=\"22\" height=\"22\" border=\"0\" >',
                             '')) as observaciones,
               C.MES || C.ANO as fecha_mes_ano,
               lpad(u.id_funcionario, 6, '0') as id_funcionario
          FROM PRESENCI     R,
               PERSFICH     B,
               WEBPERIODO   C,
               PERSONA      P,
               APLIWEB_USUARIO    U,
               CALENDARIO_LABORAL CA
         WHERE lpad(r.codpers, 6, '0') = lpad(u.id_fichaje, 6, '0')
           and r.fecha = CA.ID_DIA
           and lpad(p.codigo, 6, '0') = lpad(u.id_fichaje, 6, '0')
           and lpad(B.NPERSONAL(+), 6, '0') = lpad(r.codpers, 6, '0')
           and CA.id_ano = c.ANO
           AND CA.ID_DIA BETWEEN C.INICIO AND C.FIN
           AND CA.ID_DIA = R.FECHA
           AND R.FECHA = b.FECHA(+)
           and r.codinci = '000'
           and ca.id_dia < sysdate - 1
           and (to_char(CA.ID_DIA, 'd') <> 6 OR
                (to_char(CA.ID_DIA, 'd') = 6 and B.HINICIO is not null))
        UNION
        SELECT DISTINCT to_DATE(CA.ID_DIA, 'dd/mm/yy') AS fecha,
                        A.hora_inicio AS entrADA,
                        A.hora_fin AS SALIDA,
                        '00:00' as horas_fichadas,
                        '00:00' horas_hacer,
                        DECODE(a.ID_TIPO_PERMISO, 15000, 0, total_horas) as total_horas,
                        '<a href=\"../Permisos/ver.jsp?ID_PERMISO=' ||
                        ID_PERMISO || '\" >' ||
                        substr(DESC_TIPO_PERMISO, 1, 35) || '</a>' AS observaciones,
                        C.MES || C.ANO as fecha_mes_ano,
               lpad(u.id_funcionario, 6, '0') as id_funcionario
          FROM RRHH.PERMISO         A,
               RRHH.TR_TIPO_PERMISO B,
               WEBPERIODO     c,
               PERSONA        P,
               CALENDARIO_LABORAL   CA,
               APLIWEB_USUARIO      U
         WHERE lpad(a.id_funcionario, 6, '0') =
               lpad(u.id_funcionario, 6, '0')
           and lpad(p.codigo, 6, '0') = lpad(u.id_fichaje, 6, '0')
           and a.id_tipo_permiso = b.id_tipo_permiso
           and a.id_ano = b.id_ano
           and a.id_estado not in ('30', '31', '32', '40', '41')
           and ((A.FECHA_INICIO BETWEEN C.INICIO AND C.FIN) or
                (A.FECHA_fin BETWEEN C.INICIO AND C.FIN))
           and CA.ID_DIA BETWEEN A.FECHA_INICIO AND A.FECHA_fin
           And ANULADO = 'NO'
        UNION
        SELECT to_DATE(id_dia, 'dd/mm/yy') AS fecha,
               to_char(a.fecha_inicio, 'hh24:mi') as entrADA,
               to_char(a.fecha_fin, 'hh24:mi') as SALIDA,
               '00:00' as horas_fichadas,
               '00:00' horas_hacer,
               0 total_horas,
               '<a href=\"../Ausencias/ver.jsp?ID_AUSENCIA=' || ID_AUSENCIA ||
               '\" >' || substr(DESC_TIPO_AUSENCIA, 1, 35) || '</a>' AS observaciones,
               C.MES || C.ANO as fecha_mes_ano  ,
               lpad(u.id_funcionario, 6, '0') as id_funcionario
          FROM RRHH.ausencia         A,
               RRHH.TR_TIPO_ausencia B,
               WEBPERIODO      c,
               PERSONA         P,
               CALENDARIO_LABORAL    CA,
               APLIWEB_USUARIO       U
         WHERE lpad(a.id_funcionario, 6, '0') =
               lpad(u.id_funcionario, 6, '0')
           and lpad(p.codigo, 6, '0') = lpad(u.id_fichaje, 6, '0')
           and CA.id_ano = c.ANO
           AND CA.ID_DIA BETWEEN C.INICIO AND C.FIN
           AND a.id_tipo_ausencia = b.id_tipo_ausencia
           and a.id_ano = ca.id_ano
           and a.id_estado not in ('30', '31', '32', '40', '41')
           and ((A.FECHA_INICIO BETWEEN C.INICIO AND C.FIN) or
                (A.FECHA_fin BETWEEN C.INICIO AND C.FIN))
           and (to_date(id_dia, 'dd/mm/yy') BETWEEN
                to_date(to_char(A.FECHA_INICIO, 'DD/MM/yy'), 'DD/MM/yy') and
                to_date(to_char(A.FECHA_FIN, 'DD/MM/yy'), 'DD/MM/yy'))
           And (ANULADO = 'NO' OR ANULADO IS NULL)
        union
        SELECT to_DATE(id_dia, 'dd/mm/yy') AS fecha,
               to_char(f.hora, 'hh24:mi') as entrADA,
               '' as SALIDA,
               '00:00' as horas_fichadas,
               '00:00' horas_hacer,
               0 total_horas,
               'FICHAJE ABIERTO' AS observaciones,
               C.MES || C.ANO as fecha_mes_ano,
               lpad(u.id_funcionario, 6, '0') as id_funcionario
          FROM fichabie     F,
               WEBPERIODO   c,
               PERSONA      P,
               CALENDARIO_LABORAL CA,
               APLIWEB_USUARIO    U
         WHERE lpad(p.codigo, 6, '0') = lpad(u.id_fichaje, 6, '0')
           and lpad(F.Clave, 6, '0') = lpad(u.id_fichaje, 6, '0')
           and CA.id_ano = c.ANO
           AND CA.ID_DIA BETWEEN C.INICIO AND C.FIN
           AND F.FECHA = CA.ID_DIA);

