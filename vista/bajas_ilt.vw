create or replace force view rrhh.bajas_ilt as
(
select distinct id_permiso  as id_baja,
        id_funcionario,
        id_ano,
        fecha_inicio,
        '' as fecha_presentacion,
        FECHA_SOLI,
        nvl(fecha_fin,sysdate+1) as fecha_fin,--nuevo chm 09/10/2017
        fecha_fin as fecha_fin_real,
        '' as fecha_confirmacion,
        TIPO_BAJA as id_tipo_baja,
        '' baja_cobra_100,
        id_usuario,
        fecha_modi,
        observaciones,
        anulado as anulada,
        '' fecha_anulada
         from permiso where id_tipo_permiso='11300'
         and id_estado=80 and (anulado ='NO' or anulado is null) )
;

