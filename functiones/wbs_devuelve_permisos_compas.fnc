create or replace function rrhh.wbs_devuelve_permisos_compas(i_id_funcionario IN VARCHAR2,cuantos_permisos in number) return varchar2 is
--cuantos_permisos 0 ---> todas
--cuantos_permisos 2 ---> solo las dos ultimas
  Resultado varchar2(12000);
    observaciones varchar2(12000);

      saldo_horario varchar2(123);
      fichaje_teletrabajo varchar2(123);
      firma_planificacion varchar2(123);
      datos    varchar2(12000);
      datos_tmp    varchar2(12000);
      contador number;
      i_mes number;
      i_anio number;
      --Funcionarios en activo   
  CURSOR C0 is
    select  distinct
      json_object('id_funcionario' is  pe.id_funcionario,'nombre' is pe.nombre,'ape1' is pe.ape1,'ape2' is pe.ape2,'foto' 
         is 'http://probarcelo.aytosa.inet/fotos_empleados/' || pe.id_funcionario || '.jpg','hasta' is  per.fecha_fin)
     from funcionario_firma f ,funcionario_firma f2,personal_new pe, permiso per
     where f.ID_FUNCIONARIO = i_id_funcionario and per.id_funcionario=pe.id_funcionario 
         and        f.id_js=f2.id_js and f2.id_funcionario=pe.id_funcionario and
        sysdate between per.fecha_inicio and per.fecha_fin  and per.id_estado='80'
        order by 1;
  
   begin   
     
   datos:='';
   contador:=0;
  --abrimos cursor.    
  OPEN C0;
  LOOP
    FETCH C0
      into datos_tmp;
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
        
   resultado:= '"fuera_oficina": [' || datos || ']';  
   return(Resultado);
  end;
/

