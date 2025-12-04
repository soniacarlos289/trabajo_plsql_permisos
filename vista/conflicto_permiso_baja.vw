create or replace force view rrhh.conflicto_permiso_baja as
select pe.id_funcionario,
pe.fecha_inicio as fecha_inicio_per,
pe.fecha_fin as fecha_fin_per,
id_tipo_permiso,
b.fecha_inicio as fecha_inicio_baj,
b.fecha_fin as fecha_fin_baj,
ID_TIPO_BAJA
from permiso pe,bajas_ilt b
where pe.fecha_inicio between b.fecha_inicio and b.fecha_fin
and pe.fecha_fin between b.fecha_inicio and b.fecha_fin and
pe.id_ano=b.id_ano and pe.id_funcionario=b.id_funcionario
and pe.id_ano > 2014 and (ANULADO is null or anulado='NO') WITH READ ONLY;

