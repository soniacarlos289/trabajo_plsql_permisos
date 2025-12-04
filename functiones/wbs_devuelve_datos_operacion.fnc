create or replace function rrhh.wbs_devuelve_datos_operacion(v_resultado IN VARCHAR2,v_observaciones in varchar2) return varchar2 is
   Resultado varchar2(12000);
   observaciones varchar2(12000);
   begin

    BEGIN
     select 
         distinct '"operacion": [' ||
         json_object('resultado' is  v_resultado,'observaciones' is v_observaciones) || ']'
         into observaciones         
     from dual; 
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
         observaciones:='Operacion incorrecta';  
    WHEN OTHERS THEN                        
         observaciones:='Operacion incorrecta';  
   END;
          
   resultado:= observaciones;  
   return(Resultado);
  end;
/

