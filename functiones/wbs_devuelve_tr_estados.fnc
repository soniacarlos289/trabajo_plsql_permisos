create or replace function rrhh.wbs_devuelve_tr_estados(opcion in varchar2,anio in number) return clob is
--opcion
      --1 TR estados de los permisos/ausencias
      --2 TR tipo permiso por aÒo
      --3 TR tipo_ausencia
      --4 TR estado solicitud curso
      --5 tr tipo motivo  incidencia fichaje
      --6 tr grado  permisos
      --7 tr id_tipo_dias
    Resultado clob;
  
      datos    clob;
      datos_tmp    clob;
      contador number;
      datos_p    clob;
      datos_tmp_p    clob;
      contador_p number;
      v__permiso varchar2(23);
      

  --permisos estados
  CURSOR Ctr_estados_permisos is           
       SELECT  distinct json_object( 
                  'id_estado_permiso' is tre.id_estado_permiso,
                  'estado_permiso' is 
                  
                  TRANSLATE(REGEXP_REPLACE(tre.desc_estado_permiso, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC ')
                  
                  ), tre.id_estado_permiso             
  FROM  TR_ESTADO_permiso tre
 ORDER BY tre.id_estado_permiso;
  
 
 cursor  Ctr_tipo_permiso is 
 SELECT  distinct                 
 json_object('id_tipo_permiso' is id_tipo_permiso
             ,'desc_tipo_permiso' is 
              
                  TRANSLATE(REGEXP_REPLACE(desc_tipo_permiso, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC ')
             
             
             ,'anio' is anio),tr.id_tipo_permiso
            
 from tr_tipo_permiso tr 
 where tr.ID_ANO =anio 
 order by tr.id_tipo_permiso;
      
 
 cursor  Ctr_tipo_ausencia is 
 SELECT  distinct                 
 json_object('id_tipo_ausencia' is tr.id_tipo_ausencia
             ,'desc_tipo_permiso' is 
             TRANSLATE(REGEXP_REPLACE(tr.desc_tipo_ausencia, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC ')
             
             ,'anio' is anio),tr.id_tipo_ausencia             
 from tr_tipo_ausencia tr 
 where tr.tr_anulado='NO' and tr.desc_tipo_ausencia<>'0 0'
 order by tr.id_tipo_ausencia;
 
 
 CURSOR Ctr_estados_sol_curso is           
       SELECT  distinct json_object( 
                  'id_estado_sol_curso' is tre.id_estado_sol_curso,
                  'desc_estado_sol_curso' is tre.desc_estado_sol_curso), tre.id_estado_sol_curso             
  FROM  TR_ESTADO_sol_curso tre
 ORDER BY tre.id_estado_sol_curso;
 
 CURSOR Ctr_estados_inc_fichaje is           
       SELECT  distinct json_object( 
                  'id_estado_motivo_fichaje' is tre.id_tipo_incidencia,
                  'desc_estado_motivo_fichaje' is 
                    TRANSLATE(REGEXP_REPLACE(desc_tipo_incidencia, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC ')
                  
                  ), tre.id_tipo_incidencia             
  FROM TR_TIPO_INCIDIENCIA_FICHAJE tre
 ORDER BY tre.id_tipo_incidencia;
 

 CURSOR Ctr_estados_grado is           
       SELECT  distinct json_object( 
                  'id_estado_grado' is tre.id_grado,
                  'desc_estado_grado' is 
                  cambia_acentos(tre.desc_grado)
                  
                  ), tre.id_grado             
  FROM TR_GRADO tre
 ORDER BY tre.id_grado;
  
 CURSOR Ctr_tipo_dias is           
       SELECT  distinct json_object( 
                  'id_tipo_dias' is tre.id_tipo_dias,
                  'desc_tipo_dias' is tre.desc_tipo_dias), tre.id_tipo_dias             
  FROM TR_tipo_dias tre
 ORDER BY tre.id_tipo_dias;
 
   begin   
     
   datos:='';
    datos_tmp:='{""}';
   contador:=0;
    datos_p:='';
    datos_tmp_p:='{""}';
   contador_p:=0;
  --abrimos cursor.    
   
   CASE opcion
       WHEN '1' THEN
          OPEN Ctr_estados_permisos;
      LOOP
        FETCH Ctr_estados_permisos
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_estados_permisos%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_estados_permisos;
      Resultado:= '{"estados_permisos_ausencias": [' || datos || ']}';  
      
       WHEN '2' THEN
          OPEN Ctr_tipo_permiso;
      LOOP
        FETCH Ctr_tipo_permiso
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_tipo_permiso%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_tipo_permiso;
      Resultado:= '{"tipo_permisos_anio": [' || datos || ']}';  
      
       WHEN '3' THEN
          OPEN Ctr_tipo_ausencia;
      LOOP
        FETCH Ctr_tipo_ausencia
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_tipo_ausencia%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_tipo_ausencia;
      Resultado:= '{"tipo_ausencias_anio": [' || datos || ']}';  
    
      WHEN '4' THEN
          OPEN Ctr_estados_sol_curso;
      LOOP
        FETCH Ctr_estados_sol_curso
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_estados_sol_curso%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_estados_sol_curso;
      Resultado:= '{"estados_solicitudes_curso": [' || datos || ']}';  
    
     WHEN '5' THEN
          OPEN Ctr_estados_inc_fichaje;
      LOOP
        FETCH Ctr_estados_inc_fichaje
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_estados_inc_fichaje%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_estados_inc_fichaje;
      Resultado:= '{"estados_incidencia_fichaje": [' || datos || ']}';  
    WHEN '6' THEN
          OPEN Ctr_estados_grado;
      LOOP
        FETCH Ctr_estados_grado
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_estados_grado%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_estados_grado;
      Resultado:= '{"estados_grado_permisos": [' || datos || ']}';  
      WHEN '7' THEN
          OPEN Ctr_tipo_dias;
      LOOP
        FETCH Ctr_tipo_dias
          into datos_tmp,v__permiso;
        EXIT WHEN Ctr_tipo_dias%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Ctr_tipo_dias;
      Resultado:= '{"tipo_dias_permisos": [' || datos || ']}';  
              
   ELSE
         Resultado:= 'ERROR';
          
   END CASE;
      
      --Pantalla de Roles
      --Fichaje teletrabajo, firma y Saldo horario
       
  
   return(Resultado);
  end;
/

