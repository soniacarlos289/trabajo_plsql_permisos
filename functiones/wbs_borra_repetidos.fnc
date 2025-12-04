create or replace function rrhh.wbs_borra_repetidos return varchar2 is
--cuantos_permisos 0 ---> todas
--cuantos_permisos 2 ---> solo las dos ultimas
  Resultado varchar2(12000);
    observaciones varchar2(12000);

     id_r varchar2(12000);
      id_ra varchar2(12000);
      --Funcionarios en activo
  CURSOR C0 is
    select  id_funcionario from personal_t
    group by  id_funcionario
    having count(*) > 1;

   begin


  --abrimos cursor.
  OPEN C0;
  LOOP
    FETCH C0
      into id_r;
    EXIT WHEN C0%NOTFOUND;


   delete personal_t where id_funcionario=id_r and rownum<2;
   commit;
  END LOOP;
  CLOSE C0;

   resultado:= 'bien';
   return(Resultado);
  end;
/

