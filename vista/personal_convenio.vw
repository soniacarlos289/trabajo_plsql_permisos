create or replace force view rrhh.personal_convenio as
select id_funcionario,pp.nombre,pp.ape1,pp.ape2, descconv  from rrhh.personal_vmaa p,
              nomina.convenio c, personal pp where  ffinempl is  null and p.codiconv=c.codiconv
              and pp.id_funcionario=p.codiempl and (pp.fecha_baja is  null or fecha_baja > sysdate)
              order by 5,1;

