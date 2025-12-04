create or replace force view rrhh.v_bolsa_movimiento as
select distinct DECODE(ID_ACUMULADOR,1,1,0) as Acumulador, bm.ID_FUNCIONARIO,
Exceso_en_horas,Excesos_en_minutos,b.id_ano,periodo,bm.id_tipo_movimiento,desc_tipo_movimiento
,Fecha_movimiento
from bolsa_funcionario b, BOLsA_MOVimiento bm, BOLSA_TIPO_MOvimiento tim
where b.ID_FUNCIONARIO= bm.ID_FUNCIONARIO
and b.id_ano= bm.id_ano
and bm.id_tipo_movimiento=tim.id_tipo_movimiento;

