create or replace function rrhh.wbs_devuelve_firma_permisos(i_id_funcionario IN VARCHAR2,cuantos_permisos in number) return varchar2 is
--cuantos_permisos 0 ---> todas
--cuantos_permisos 2 ---> solo las dos ultimas
  Resultado clob;
    observaciones varchar2(12000);

      saldo_horario varchar2(123);
      fichaje_teletrabajo varchar2(123);
      firma_planificacion varchar2(123);
      datos    clob;
      datos_tmp    clob;
      contador number;
      i_permiso number;

      --Funcionarios en activo   
  CURSOR C0 is
    select  distinct
     json_object('id_funcionario' is  pe.id_funcionario,'nombre' is pe.nombre,'ape1' is pe.ape1,'ape2' is pe.ape2,'foto' 
         is 'http/probarcelo.aytosa.inet/wbs_pruebas/persona_' || pe.id_funcionario || '.jpg','tipo' is desc_tipo_permiso,'num_dias' is per.num_dias,
         'fecha_inicio' is per.fecha_inicio,'fecha_fin' is per.fecha_fin
         ),id_permiso
  from funcionario_firma f ,personal_new pe, permiso per,tr_tipo_permiso tr
  where f.id_js =  i_id_funcionario  and per.id_funcionario=pe.id_funcionario 
         and  f.id_funcionario=pe.id_funcionario and tr.id_tipo_permiso=per.id_tipo_permiso and per.id_ano=tr.id_ano
        and per.fecha_soli > sysdate -365  and per.id_estado='20'
       order by id_permiso;

   begin   
     
   datos:='';
   contador:=0;
  --abrimos cursor.    
  OPEN C0;
  LOOP
    FETCH C0
      into datos_tmp,i_permiso;
    EXIT WHEN C0%NOTFOUND;
      
      contador:=contador+1;      
            
    if contador <= cuantos_permisos or contador=0 then
     if contador =1 then   
       datos:= datos_tmp; 
     else
       datos:= datos  || ',' || datos_tmp;   
     end if; 
    end if;       
 
  END LOOP;
  CLOSE C0;
        
   resultado:= '"firma": [' || datos || ']';  
   return(Resultado);
  end;
/

