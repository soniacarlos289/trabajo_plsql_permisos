create or replace function rrhh.wbs_justifica_fichero_sin(v_id_permiso in varchar2, v_id_ausencia in varchar2,fichero in blob) return varchar2 is
  Resultado varchar2(12000);
    observaciones varchar2(12000);
    enlace_fichero varchar2(123);
    i_encontrado number;
    i_existe number;
    
   begin   
     
   enlace_fichero:='';
   i_encontrado:=1;
   i_existe:=0;
   
     BEGIN
       select id_ano||id_funcionario|| id_permiso
       into enlace_fichero
       from permiso
       where id_permiso=v_id_permiso and rownum<2;      
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_encontrado:=0;
     END;
   
     if i_encontrado = 0 then
       BEGIN
         select id_ano||id_funcionario|| id_ausencia
         into enlace_fichero
         from ausencia
         where id_ausencia=v_id_ausencia and rownum<2;      
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            i_encontrado:=0;
       END;          
     end if;
   
   
     observaciones:='nulo' || enlace_fichero;
          
   if (enlace_fichero is not null or enlace_fichero>0)  and (fichero is not null)   then
     observaciones:='Fichero insertado correctamente';
     BEGIN
       insert into ficheros_justificantes values(enlace_fichero,'',fichero);   
     EXCEPTION
     WHEN NO_DATA_FOUND THEN

          observaciones:='Error insercion';
     WHEN DUP_VAL_ON_INDEX THEN                        
             i_existe:=1;
            observaciones:='Error insercion fichero ya existe';
     
     END;
      
     if   i_existe =1 then
       update  ficheros_justificantes 
        set fichero=fichero
        where id=enlace_fichero;
        
         observaciones:='Fichero actualizado correctamente';
    end if;
   end if;
   commit; 
   resultado:= observaciones;  
   return(Resultado);
  end;
/

