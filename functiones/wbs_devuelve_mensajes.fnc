create or replace function rrhh.wbs_devuelve_mensajes(i_id_funcionario IN VARCHAR2
                                                               )
  return clob is
 
  
  --
  Resultado    clob;
  observaciones varchar2(12000);

  saldo_horario       varchar2(123);
  fichaje_teletrabajo varchar2(123);
  firma_planificacion varchar2(123);
  datos              clob;
  datos_tmp           clob;
  contador            number;
  i_mes               number;
  i_anio              number;

  d_id_dia            date;
  v_id_funcionario_tt varchar2(123);
  v_nombres_tt        varchar2(123);
  v_desc_permiso_tt   varchar2(123);
  v_anio              varchar2(123);
  
  d_datos_fecha_entrada date;
  
  --Funcionarios mensajes  
  CURSOR Cmensajes_funcionario is
     
         select distinct  json_object(
                              --  'id_funcionario' is id_funcionario,
                                --'id_dia' is to_char(fecha_mensaje,'dd/mm/yyyy'),
                                'notificacion' is TRANSLATE(REGEXP_REPLACE( mensaje, '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC ')
                                
                                )
                                
                                , fecha_mensaje
       
   from funcionario_mensaje where id_funcionario=i_id_funcionario
   order by fecha_mensaje desc;

       
begin

  datos    := '';
  contador := 0;
 
    --abrimos cursor.    
    OPEN Cmensajes_funcionario;
    LOOP
      FETCH Cmensajes_funcionario
        into datos_tmp,
             d_id_dia;
      EXIT WHEN Cmensajes_funcionario%NOTFOUND;
    
      contador := contador + 1;
    
      if contador = 1 then
        datos := datos_tmp;
      else if contador < 5 THEN
        datos := datos || ',' || datos_tmp;
            end if; 
      end if;
    
    END LOOP;
    CLOSE Cmensajes_funcionario;
  
    resultado := '"notificaciones": [' || datos || ']';
  
  

  return(Resultado);

end;
/

