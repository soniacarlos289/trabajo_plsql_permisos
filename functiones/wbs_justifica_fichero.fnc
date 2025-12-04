create or replace function rrhh.wbs_justifica_fichero(enlace_fichero IN VARCHAR2,fichero in blob) return varchar2 is
  Resultado varchar2(12000);
    observaciones varchar2(12000);

    
   begin   
     observaciones:='nulo' || enlace_fichero;
   if (enlace_fichero is not null or enlace_fichero>0)  and (fichero is not null)   then
     observaciones:='insertado ';
     BEGIN
       insert into ficheros_justificantes values(enlace_fichero,'',fichero);   
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          observaciones:='Error insercion';
     WHEN DUP_VAL_ON_INDEX THEN                        
            observaciones:='Error insercion fichero ya existe';
     
     END;
     end if;
    
   resultado:= observaciones;  
   return(Resultado);
  end;
/

