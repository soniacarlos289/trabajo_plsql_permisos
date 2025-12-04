create or replace force view rrhh.fichaje_saldo_fichado as
(
select ow.mes||ow.ano as periodo,id_funcionario,cl.id_dia, horas_saldo  as horas_realizadas,FECHA_FICHAJE_ENTRADA,FECHA_FICHAJE_SALIDA,id_fichaje_dia,turno
,computadas,horas_fichadas,horas_fichadas-horas_saldo as fuera_saldo
from  fichaje_funcionario f,calendario_laboral cl, webperiodo ow

where

      cl.id_dia  = to_date(to_char(f.fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy') and
      cl.id_dia  between ow.inicio and ow.fin and computadas=0 and

       cl.id_dia<sysdate-1
);

