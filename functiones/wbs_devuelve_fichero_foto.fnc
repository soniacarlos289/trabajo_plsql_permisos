create or replace function rrhh.wbs_devuelve_fichero_foto(v_id_funcionario IN VARCHAR2)
    return clob is

  Resultado clob;
  observaciones varchar2(12000);

  saldo_horario       varchar2(123);
  fichaje_teletrabajo varchar2(123);
  firma_planificacion varchar2(123);
  datos               clob;
  datos_tmp           clob;
  contador            number;
  i_mes               number;
  i_anio              number;
  
begin

  datos    := '';
  contador := 0;
   

 

   
  BEGIN     
           select  
            ',"foto": [ {    "mime": "application/jpg","data": "' || base64encode(foto) || '"}]'
                        
             into datos_tmp   
             from foto_funcionario                
            where id_funcionario=v_id_funcionario;
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                   datos_tmp:='';
  
   
       
   
  ENd;
  
  
 resultado :=  datos_tmp;
  return(Resultado);
end;
/

