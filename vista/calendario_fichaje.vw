create or replace force view rrhh.calendario_fichaje as
(
select 0 as id_funcionario, '0' as ID_TIPO_PERMISO,0 as ID_TIPO_ESTADO ,'<td bgcolor=FFFFFF>' as  DESC_COLUMNA,

 to_date('01/01/1900','DD/mm/yyyy')as fecha_inicio,to_date('01/01/2100','DD/mm/yyyy') as fecha_fin
 from dual
union
select id_funcionario,t.ID_TIPO_PERMISO,t.ID_TIPO_ESTADO,substr(DESC_TIPO_COLUMNA,1,19) as DESC_COLUMNA,fecha_inicio,fecha_fin
 from RRHH.TR_TIPO_COLUMNA_CALENDARIO t, permiso p
 where p.id_tipo_permiso=t.id_tipo_permiso and
       p.id_estado=t.id_tipo_estado and id_ano > 2019);

