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

