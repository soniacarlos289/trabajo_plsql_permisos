create or replace force view rrhh.fichaje_saldo_hacer as
(
select ow.mes||ow.ano as periodo,id_funcionario,cl.id_dia,cl.laboral,

DECODE(cl.laboral,'NO',0,

      sum(

         ((f.horas_jornada-to_Date('01/01/1900 00:00','DD/mm/yyyy hh24:mi'))*60*24)*(devuelve_dia_jornada(dias_semana,cl.id_dia )))) as horas_hacer
from  fichaje_funcionario_jornada f,calendario_laboral cl,webperiodo ow

where

      cl.id_dia  between f.fecha_inicio and nvl(f.fecha_fin ,sysdate-1) and
      cl.id_dia  between ow.inicio and ow.fin
    --  and (cl.laboral='SI' or (cl.laboral='NO' and to_char(cl.id_dia,'d')=7) )--quitamos el domingo and to_char(cl.id_dia,'d')=7)
       and
       cl.id_dia<sysdate-1
group by ow.mes||ow.ano, id_funcionario,cl.id_dia,cl.laboral )
;

