create or replace function rrhh.wbs_devuelve_datos_personales(i_id_funcionario IN VARCHAR2) return varchar2 is
  Resultado varchar2(12000);
    observaciones varchar2(12000);
   begin

    BEGIN
     select 
         distinct '"datos": [' ||
         json_object('id_funcionario' is  pe.id_funcionario,'nombre' is nombre,'ape' is ape1,'ape1' is ape2,'foto' 
         is 'http/probarcelo.aytosa.inet/wbs_pruebas/persona_' || pe.id_funcionario || '.jpg','correo' is login ||'@aytosalamanca.es',
         'nif' is pe.DNI || DNI_LETRA ) || ']'
         into observaciones         
     from personal_new pe ,apliweb_usuario u
     where 
         pe.id_funcionario=i_id_funcionario   and   pe.id_funcionario=u.id_funcionario  
     order by pe.id_funcionario;                
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
        observaciones:='Usuario no encontrado' ;  

    WHEN OTHERS THEN                        
         observaciones:='Usuario no encontrado'; 
        -- observaciones:=''; 
   END;
          
   resultado:= observaciones;  
   return(Resultado);
  end;
/

