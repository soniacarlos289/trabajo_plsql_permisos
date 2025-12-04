create or replace force view rrhh.permisos_en_dia as
select id_funcionario,fecha_inicio,fecha_fin from rrhh.permiso
where  id_estado='80'
union
select id_funcionario,fecha_inicio,fecha_fin from rrhh.ausencia where
 id_estado='80';

