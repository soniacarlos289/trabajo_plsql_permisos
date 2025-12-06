/*
================================================================================
  VISTA: rrhh.personal_pruebas
================================================================================
  PROPÓSITO:
    Vista de prueba/desarrollo similar a personal_new pero con datos adicionales
    de la tabla nomina.datapers_v y diferentes transformaciones.

  NOTA: El nombre sugiere que esta vista es para pruebas y podría ser
        candidata para revisión en producción.

  CAMPOS RETORNADOS:
    - codienti, versempl: Identificadores de entidad y versión
    - id_funcionario: ID del funcionario (con transformación especial)
    - categoria: Categoría fija ('C')
    - puesto: Puesto fijo ('001')
    - tipo_funcionario2: De datapers_v, con valor por defecto 10
    - nombre, ape1, ape2: Datos del funcionario
    - tipo_funcionario: Tipo basado en prefijo del código
    - direccion, telefono: Datos de contacto
    - fecha_ingreso, fecha_antiguedad: Fechas importantes
    - activo: Indicador fijo ('SI')
    - jornada: Jornada fija ('37')
    - numero_ss: Número de Seguridad Social formateado
    - dni, dni_letra: Documento de identidad
    - fecha_baja: Fecha de baja procesada
    - contratacion: Código de escala

  DEPENDENCIAS:
    - Tabla: personal_vmaa
    - Vista: nomina.datapers_v

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
create or replace force view rrhh.personal_pruebas as
(
select distinct p.codienti, p.versempl,DECODE(p.CODIENTI,2,DECODE(p.CODIEMPL,'1312','771312',p.CODIEMPL),p.CODIEMPL) as  id_funcionario,
    'C' CATEGORIA,'001' PUESTO ,
    DECODE(entero_03,NULL,10,entero_03) as TIPO_FUNCIONARIO2,
   p.nombre,
   p.apellid1 ape1,
   p.apellid2 ape2,
   decode(substr(lpad(p.codiempl,6,0),1,3),201,'P',203,'B','N') as TIPO_FUNCIONARIO,
   p.TDOMEMPL ||'  '|| p.DDOMEMPL ||'  '|| p.NDOMEMPL||'  '|| p.ODOMEMPL as DIRECCION,
   p.PTELEMPL ||  p.NTELEMPL as TELEFONO,
   p.FINGRESO FECHA_INGRESO,
  'SI' ACTIVO,
  '37' JORNADA,
   p.PSSOEMPL  ||'/'|| p.NSSOEMPL  ||'/'|| p.DSSOEMPL  as NUMERO_SS,
   p.NDNIEMPL DNI,
   p.DDNIEMPL DNI_LETRA ,
   p.FTRIENIO FECHA_ANTIGUEDAD,
   DECODE(p.FECHBAJA,NULL,DECODE(p.CODIEMPL,NULL,'01/01/1900',p.FECHBAJA),p.FECHBAJA) AS FECHA_BAJA,
   P.CODIESCO as CONTRATACION
   from  personal_vmaa p, nomina.datapers_v d
        where
        (p.versempl,p.codiempl) in
         ( select DECODE(CODIEMPL,60849,3,(MAX(versempl))),CODIEMPL from personal_vmaa
           group by codiempl)  and
        p.versempl=d.versempl and
        p.codiempl=d.codiempl
);

