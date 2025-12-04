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

