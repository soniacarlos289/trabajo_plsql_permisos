/*
================================================================================
  VISTA: rrhh.personal_convenio
================================================================================
  PROPÓSITO:
    Proporciona información del personal activo junto con su convenio colectivo.
    Útil para reportes de distribución de personal por convenio.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - nombre, ape1, ape2: Datos del funcionario
    - descconv: Descripción del convenio

  JOINS UTILIZADOS:
    - personal_vmaa (p): Datos de nómina del personal
    - nomina.convenio (c): Catálogo de convenios
    - personal (pp): Datos del personal para nombre

  FILTROS APLICADOS:
    - ffinempl IS NULL: Solo empleados sin fecha fin
    - Personal activo (fecha_baja IS NULL OR fecha_baja > SYSDATE)

  DEPENDENCIAS:
    - Tabla: personal_vmaa
    - Tabla: nomina.convenio
    - Tabla: personal

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
create or replace force view rrhh.personal_convenio as
select id_funcionario,pp.nombre,pp.ape1,pp.ape2, descconv  from rrhh.personal_vmaa p,
              nomina.convenio c, personal pp where  ffinempl is  null and p.codiconv=c.codiconv
              and pp.id_funcionario=p.codiempl and (pp.fecha_baja is  null or fecha_baja > sysdate)
              order by 5,1;

