/*
================================================================================
  VISTA: rrhh.fichaje_saldo_completa_new
================================================================================
  PROPÓSITO:
    Vista completa que consolida información de fichajes, permisos, ausencias
    y horas extras en un solo resultado. Proporciona una visión unificada del
    saldo de horas para la interfaz web.

  CAMPOS RETORNADOS:
    - f: Fecha del día (para ordenamiento)
    - fecha: Enlace HTML al detalle del día
    - entrada: Hora de entrada (formato HH24:MI)
    - salida: Hora de salida (formato HH24:MI)
    - horas_fichadas_m: Horas fichadas en minutos (-1 para permisos/ausencias)
    - horas_hacer_m: Horas a hacer en minutos
    - horas_fichadas: Horas fichadas en formato HH:MM
    - horas_hacer: Horas a hacer en formato HH:MM
    - diferencia_minutos/total_horas: Saldo del día
    - fuera_saldo: Horas fuera del cómputo
    - observaciones: Enlaces HTML a permisos/ausencias/horas extras
    - mes_fecha_ano: Período (MMAAAA)
    - id_funcionario: Identificador del funcionario

  FUENTES DE DATOS (UNION de 4 consultas):
    1. resumen_saldo + personal_new: Fichajes reales
    2. permiso + tr_tipo_permiso: Permisos activos
    3. ausencia + tr_tipo_ausencia: Ausencias activas
    4. horas_extras + tr_tipo_hora: Horas extraordinarias

  FILTROS APLICADOS EN CADA UNION:
    - Estados activos (no en 30, 31, 32, 40, 41)
    - Anulado = 'NO' o NULL
    - Fechas dentro del período

  FUNCIONES UTILIZADAS:
    - devuelve_observaciones_fichaje(): Genera texto de observaciones

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    ADVERTENCIA: Vista muy compleja - 4 UNIONs con múltiples JOINs
    =========================================================================
    - Cada UNION realiza múltiples joins que se ejecutan independientemente
    - La generación de HTML debería moverse a la capa de presentación
    - Considerar usar UNION ALL si se garantiza no duplicados

    POSIBLES OPTIMIZACIONES:
    1. Crear vistas intermedias para cada tipo de registro
    2. Mover la generación de enlaces HTML a la aplicación
    3. Indexar las tablas de catálogo (tr_tipo_permiso, etc.)

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_permiso_estado ON permiso(id_estado, anulado);
    - CREATE INDEX idx_ausencia_estado ON ausencia(id_estado, anulado);
    - CREATE INDEX idx_horas_extras_fecha ON horas_extras(fecha_horas);

  DEPENDENCIAS:
    - Vista: resumen_saldo
    - Vista: personal_new
    - Tabla: permiso, tr_tipo_permiso
    - Tabla: ausencia, tr_tipo_ausencia
    - Tabla: horas_extras, tr_tipo_hora
    - Tabla: webperiodo
    - Tabla: calendario_laboral
    - Tabla: persona, apliweb_usuario
    - Función: devuelve_observaciones_fichaje()

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW RRHH.FICHAJE_SALDO_COMPLETA_NEW AS
select distinct ID_DIA as F,
               '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,
               to_char(fecha_fichaje_entrada, 'hh24:mi') AS ENTRADA,
               to_char(fecha_fichaje_salida, 'hh24:mi') AS SALIDA,
                HR  as Horas_fichadas_m,
                decode(tipo_funcionario2,21,0,23,0,HH) as horas_hacer_m,
                lpad(TRUNC((HR)/60),2,'0') ||':'  ||
                lpad(nvl(TRUNC(HR) -TRUNC((HR)/60)*60,0),2,'0') as Horas_fichadas,
                lpad(nvl(TRUNC((HH)/60),0),2,'0') ||':'  ||
                 lpad(round(nvl((HH -TRUNC((HH)/60)*60),0)),2,'0') as horas_hacer,
                nvl(saldo_dia,0) as diferencia_minutos,fuera_saldo,
                devuelve_observaciones_fichaje(p.id_funcionario,tipo_funcionario2,
                                               observaciones ,
                                           id_dia,
                                            round(hh),
                                            round(hr))
                  as observaciones,
                periodo as mes_fecha_ano,
                to_number(p.id_funcionario) as id_funcionario
         from resumen_saldo r,personal_new p
         where r.id_funcionario=p.id_funcionario

        UNION
        SELECT DISTINCT   to_DATE(CA.ID_DIA, 'dd/mm/yy') as F,
                         '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE( to_char(CA.ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE( to_char(CA.ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE( to_char(CA.ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,
                        A.hora_inicio AS entrADA,
                        A.hora_fin AS SALIDA,
                        -1 as horas_fichadas_m,
                        0 horas_hacer_m,
                        '00:00' as horas_fichadas,
                        '00:00' horas_hacer,
                        0   as total_horas,0 as fuera_saldo,
                        '<a href="../Permisos/ver.jsp?ID_PERMISO=' ||
                        ID_PERMISO || '" >' ||
                        substr(DESC_TIPO_PERMISO, 1, 35) || '</a>  '|| 'Justificado:' || a.Justificacion  AS observaciones,
                        C.MES || C.ANO as mes_fecha_ano,
                to_number(a.id_funcionario) as id_funcionario
          FROM RRHH.PERMISO         A,
               RRHH.TR_TIPO_PERMISO B,
               WEBPERIODO     c,
               CALENDARIO_LABORAL   CA

         WHERE

           a.id_tipo_permiso = b.id_tipo_permiso
           and a.id_ano = b.id_ano
           and a.id_estado not in ('30', '31', '32', '40', '41')
           and ((A.FECHA_INICIO BETWEEN C.INICIO AND C.FIN) or
                (NVL(A.FECHA_fin,SYSDATE) BETWEEN C.INICIO AND C.FIN))
           and CA.ID_DIA BETWEEN decode(sign(A.FECHA_INICIO -C.INICIO) ,1,A.FECHA_INICIO,C.INICIO) AND nvl(A.FECHA_fin,sysdate)
           And ANULADO = 'NO'
           union
             SELECT to_DATE(id_dia, 'dd/mm/yy') AS fecha,
               '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,
               to_char(a.fecha_inicio, 'hh24:mi') as entrADA,
               to_char(a.fecha_fin, 'hh24:mi') as SALIDA,
               -1 as horas_fichadas_m,
               0 horas_hacer_m,
               '00:00' as horas_fichadas,
              '00:00' horas_hacer,
               0 as total_horas,0 as fuera_saldo,
               '<a href="../Ausencias/ver.jsp?ID_AUSENCIA=' || ID_AUSENCIA ||
               '" >' || substr(DESC_TIPO_AUSENCIA, 1, 35) || '</a>' || ' Justificada:' || JUSTIFICADO AS observaciones,
               C.MES || C.ANO as mes_fecha_ano ,
               to_number(a.id_funcionario) as id_funcionario
          FROM RRHH.ausencia         A,
               RRHH.TR_TIPO_ausencia B,
               WEBPERIODO      c,
               PERSONA         P,
               CALENDARIO_LABORAL    CA,
               APLIWEB_USUARIO       U
         WHERE a.id_funcionario =
               u.id_funcionario
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
               '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,
               hora_inicio as entrADA,
               hora_fin as SALIDA,
               -1 as horas_fichadas_m,
               0 horas_hacer_m,
               '00:00' as horas_fichadas,
              '00:00' horas_hacer,
               0 as total_horas,0 as fuera_saldo,
               '<a href="../Horas/editar.jsp?ID_HORA=' || ID_HORA ||  '3035='  ||A.id_ano ||
               '" >' || substr(DESC_TIPO_HORAS, 1, 35) || '</a>' AS observaciones,
               C.MES || C.ANO as mes_fecha_ano ,
               to_number(a.id_funcionario) as id_funcionario
          FROM RRHH.HORAS_EXTRAS       A,
               RRHH.TR_TIPO_HORA    TR,

               WEBPERIODO      c,
               CALENDARIO_LABORAL    CA

         WHERE

                a.id_tipo_horas=tr.id_tipo_horas
           and a.fecha_horas=ca.id_dia
           and CA.id_ano = c.ANO
           AND CA.ID_DIA BETWEEN C.INICIO AND C.FIN
         --  and a.id_ano = ca.id_ano
           and (A.FECHA_HORAS BETWEEN C.INICIO AND C.FIN)

           And (A.ANULADO = 'NO' OR A.ANULADO IS NULL)
;

