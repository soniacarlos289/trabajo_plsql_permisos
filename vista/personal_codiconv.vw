/*
================================================================================
  VISTA: rrhh.personal_codiconv
================================================================================
  PROPÓSITO:
    Proporciona información del personal con código de convenio desde la tabla
    personal_v_codiesco, extrayendo solo la versión más reciente de cada empleado.

  CAMPOS RETORNADOS:
    - codienti: Código de entidad
    - versempl: Versión del empleado
    - id_funcionario: Código del empleado
    - categoria: Categoría fija ('C')
    - puesto: Puesto fijo ('001')
    - tipo_funcionario: Tipo basado en prefijo del código (P/B/N)
    - activo: Indicador fijo ('SI')
    - jornada: Jornada fija ('37')
    - fecha_antiguedad: Fecha de trienio
    - fecha_baja: Fecha de baja procesada
    - contratacion: Código de escala
    - codiconv: Código de convenio

  FILTROS APLICADOS:
    - Solo la versión máxima (más reciente) de cada empleado

  DEPENDENCIAS:
    - Vista/Tabla: personal_v_codiesco
    - Tabla: personal_vmaa

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
create or replace force view rrhh.personal_codiconv as
(
select distinct p.codienti, p.versempl,p.CODIEMPL id_funcionario,
    'C' CATEGORIA,'001' PUESTO ,
   --p.nombre,
   --p.apellid1 ape1,
   --p.apellid2 ape2,
   decode(substr(lpad(p.codiempl,6,0),1,3),201,'P',203,'B','N') as TIPO_FUNCIONARIO,
  -- p.TDOMEMPL ||'  '|| p.DDOMEMPL ||'  '|| p.NDOMEMPL||'  '|| p.ODOMEMPL as DIRECCION,
  -- p.PTELEMPL ||  p.NTELEMPL as TELEFONO,
  -- p.FINGRESO FECHA_INGRESO,
  'SI' ACTIVO,
  '37' JORNADA,
--   p.PSSOEMPL  ||'/'|| p.NSSOEMPL  ||'/'|| p.DSSOEMPL  as NUMERO_SS,
  -- p.NDNIEMPL DNI,
  -- p.DDNIEMPL DNI_LETRA ,
   p.FTRIENIO FECHA_ANTIGUEDAD,
   DECODE(p.FECHBAJA,NULL,DECODE(p.CODIEMPL,NULL,'01/01/1900',p.FECHBAJA),p.FECHBAJA) AS FECHA_BAJA,
   P.CODIESCO as CONTRATACION,codiconv
   from  personal_v_codiesco p
     where
        (versempl,codiempl) in
         ( select MAX(versempl),CODIEMPL from personal_vmaa
           group by codiempl)
)
;

