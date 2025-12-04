create or replace force view rrhh.personal_edad_tramos as
select '18_a_29' as id_anno,count(*) as num_funcionario from personal where to_char(sysdate,'yyyy')- to_char(fecha_nacimiento,'yyyy') between 18 and 29 and (fecha_baja is null  or fecha_baja> sysdate)
union
select '30_a_39' as id_anno,count(*) as num_funcionario from personal where to_char(sysdate,'yyyy')- to_char(fecha_nacimiento,'yyyy') between 30 and 39 and (fecha_baja is null  or fecha_baja> sysdate)
union
select '40_a_49' as id_anno,count(*) as num_funcionario from personal where to_char(sysdate,'yyyy')- to_char(fecha_nacimiento,'yyyy') between 40 and 49 and (fecha_baja is null  or fecha_baja> sysdate)
union
select '50_a_59' as id_anno,count(*) as num_funcionario from personal where to_char(sysdate,'yyyy')- to_char(fecha_nacimiento,'yyyy') between 50 and 59 and (fecha_baja is null  or fecha_baja> sysdate)
union
select '60_o_mas' as id_anno,count(*) as num_funcionario from personal where to_char(sysdate,'yyyy')- to_char(fecha_nacimiento,'yyyy') between 60 and 99 and (fecha_baja is null  or fecha_baja> sysdate);

