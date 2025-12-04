create or replace force view rrhh.calendario_final as
select cl.id_dia,laboral_dia(id_funcionario,id_dia) as des_col ,mes,ano,id_funcionario,ano as id_ano,cl.observacion,COMPENSABLE
from  personal_new f,calendario_laboral cl, webperiodo ow

where
      cl.id_dia  between ow.inicio and ow.fin

order by id_dia;

