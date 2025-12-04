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

