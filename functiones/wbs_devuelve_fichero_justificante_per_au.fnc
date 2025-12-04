create or replace function rrhh.wbs_devuelve_fichero_justificante_per_au(v_id_enlace IN VARCHAR2)
    return clob is

  Resultado clob;
  observaciones varchar2(12000);

  saldo_horario       varchar2(123);
  fichaje_teletrabajo varchar2(123);
  firma_planificacion varchar2(123);
  datos               varchar2(12000);
  datos_tmp           clob;
  contador            number;
  i_mes               number;
  i_anio              number;
  
begin

  datos    := '';
  contador := 0;
   

  if v_id_enlace > 0 then
   
  BEGIN     
           select distinct  
             '  "file": [ {    "mime": "application/pdf","data": "' || base64encode(fichero) || '"}]'
             into datos_tmp   
             from ficheros_justificantes                 
            where id=v_id_enlace;
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                   datos_tmp:='';
  
   
       
   
  ENd;
  
  ENd if;
 resultado :=  datos_tmp;
  return(Resultado);
end;
/

