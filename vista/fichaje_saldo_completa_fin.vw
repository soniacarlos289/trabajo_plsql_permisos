CREATE OR REPLACE FORCE VIEW RRHH.FICHAJE_SALDO_COMPLETA_FIN AS
select  ID_DIA,
          '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,


        to_char(fecha_fichaje_entrada, 'hh24:mi') as ENTRADA,
        to_char(fecha_fichaje_salida, 'hh24:mi') as SALIDA,
        t.horas_fichadas as horas_saldo ,
        t.horas_fichadas-t.horas_saldo as fuera_saldo,
        Horas_hacer,
        ff.horas_fichadas horas_fichada_dia,
     --ff.horas_fichadas-horas_hacer-nvl(t.horas_fichadas-t.horas_saldo,0) as diferencia,
        ff.horas_saldo - ff.horas_hacer  as diferencia,
        ff.horas_fuera_saldo,

         ow.MES || ow.ANO as periodo,
         ff.id_funcionario,
       observaciones_permiso_en_dia_a(ff.id_funcionario,id_dia,round( Horas_hacer),
                                              round( t.horas_saldo),t.turno, to_char(fecha_fichaje_entrada, 'hh24:mi'),
                                              to_char(fecha_fichaje_salida, 'hh24:mi')
                                              ) as Observaciones
  from fichaje_funcionario t, webperiodo ow,fichaje_funcionario_resu_dia ff
 where
       t.id_funcionario(+)= ff.id_funcionario
   and id_dia between ow.inicio and ow.fin
   and id_dia < to_date(to_char(sysdate, 'dd/mm/yyyy'), 'dd/mm/yyyy')
   and to_date(to_char(fecha_fichaje_entrada(+), 'dd/mm/yyyy'), 'dd/mm/yyyy')=id_dia
   and ((ff.horas_saldo<>0 OR ff.horas_hacer<>0)  OR  PERMISO_EN_DIA(ff.ID_FUNCIONARIO,ff.id_dia)<>0)
   --group by id_dia
union
             SELECT to_DATE(id_dia, 'dd/mm/yy') AS  ID_DIA,
               '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE( to_char(ID_DIA, 'dd/mm/yy'), 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,
               to_char(a.fecha_inicio, 'hh24:mi') as entrADA,
               to_char(a.fecha_fin, 'hh24:mi') as SALIDA,
                0 horas_saldo ,
        0 as fuera_saldo,
        0 Horas_hacer,
        0 horas_fichada_dia,
         0 as diferencia,
        0 horas_fuera_saldo,
         C.MES || C.ANO as periodo,
         a.id_funcionario,
               '<a href="../Ausencias/ver.jsp?ID_AUSENCIA=' || ID_AUSENCIA ||
               '" >' || substr(DESC_TIPO_AUSENCIA, 1, 35) || '</a>' || ' Justificada:' || JUSTIFICADO AS observaciones

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
   and id_dia between c.inicio and c.fin
   and id_dia < to_date(to_char(sysdate, 'dd/mm/yyyy'), 'dd/mm/yyyy')
;

