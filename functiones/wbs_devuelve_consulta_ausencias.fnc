create or replace function rrhh.wbs_devuelve_consulta_ausencias(i_id_funcionario IN VARCHAR2,opcion in varchar2,anio in number) return clob is
--opcion
      --121312 id_ausencia
      -- 0 per_solicitados ausencias_solicitados.
     --1 ausencias disponibles
      
    Resultado clob;
  
    datos_ausencias_solicitados clob;
    datos_ausencias_sin_disfrutar clob;
    datos_ausencias_disponibles clob;
      saldo_horario varchar2(123);
   cabecera_periodos_consulta varchar2(12300);
    d_fecha date;
      datos    clob;
      datos_tmp    clob;
      contador number;
      datos_p    clob;
      datos_tmp_p    clob;
      contador_p number;
      i_permiso number;

      --permisos solicitados   
  CURSOR Causencias_solicitados is
           
       SELECT  distinct json_object( 
                  'anio' is ausencia.id_ano,
                  'id_ausencia' is ausencia.id_ausencia,
                  'tipo_ausencia' is cambia_acentos(SUBSTR((DESC_TIPO_AUSENCIA), 1, 36)),
                  'id_tipo_ausencia' is ausencia.id_tipo_ausencia,
                  'estado' is   cambia_acentos(DESC_ESTADO_PERMISO) || DEcode(id_estado_permiso,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                  'id_estado_ausencia' is ausencia.id_estado,
                  'motivo_denega' is DECODE(motivo_denega,null,''),
                  'fecha_inicio' is TO_CHAR(FECHA_INICIO, 'DD/MM/YYYY HH24:MI'), 
                  'fecha_fin' is TO_CHAR(FECHA_FIN, 'DD/MM/YYYY HH24:MI'), 
                  'justificado' is DECODE(JUSTIFICADO,'--',null,CHEQUEA_ENLACE_FICHERO_JUSTI(ID_ANO,ID_FUNCIONARIO,ID_AUSENCIA)),
                  'hora_inicio' is  SUBSTR(TO_CHAR(FECHA_INICIO, 'DD/MM/YYYY HH24:MI'), 12, 5), 
                  'hora_fin' is SUBSTR(TO_CHAR(FECHA_FIN, 'DD/MM/YYYY HH24:MI'), 12, 5) 
                  ), fecha_inicio as fecha_inicio2
  FROM RRHH.AUSENCIA , RRHH.TR_TIPO_AUSENCIA, TR_ESTADO_permiso tre
 WHERE TRE.ID_ESTADO_permiso = AUSENCIA.ID_ESTADO
   AND ID_FUNCIONARIO =  i_id_funcionario
  AND AUSENCIA.ID_ANO  =anio and (AUSENCIA.ID_AUSENCIA = opcion or opcion='0')
   AND AUSENCIA.ID_TIPO_AUSENCIA = TR_TIPO_AUSENCIA.ID_TIPO_AUSENCIA
   and (ANULADO = 'NO' or ANULADO is null) and TR_TIPO_AUSENCIA.id_tipo_ausencia <> '998'
 ORDER BY FECHA_INICIO2 DESC;
  
 
 cursor Causencias_disponibles is 
 SELECT  distinct                 
 json_object('id_tipo_ausencia' is id_tipo_ausencia
             ,'desc_tipo_ausencia' is desc_tipo_ausencia) from
   
(     SELECT id_tipo_ausencia, desc_tipo_ausencia
  from tr_tipo_ausencia
 where id_tipo_ausencia < 500
   and id_tipo_ausencia <> '050'
   and id_tipo_ausencia > 0 and id_tipo_ausencia <> '998'
union
select t.id_tipo_ausencia,
       desc_tipo_ausencia || '. Horas Disponibles este año: ' ||
       trunc((Total - utILIZADAs) / 60, 2) || ' h.' as desc_tipo_ausencia
  FROM bolsa_concilia h, tr_tipo_ausencia t
 WHERE id_funcionario =i_id_funcionario
   and '050' = t.id_tipo_ausencia 
   and h.ID_ANO=anio 
   and tr_ANULADO = 'NO'
union
select t.id_tipo_ausencia,
       desc_tipo_ausencia || 'Horas Disponibles este mes: ' ||
       trunc((Total_HORAS - TOTAL_UTILIZADAs) / 60, 2) || 'h.' as desc_tipo_ausencia
  FROM hora_sindical h, tr_tipo_ausencia t
 WHERE id_funcionario = i_id_funcionario
   and h.id_tipo_ausencia = t.id_tipo_ausencia
   and id_mes = to_number(to_char(sysdate, 'mm'))
   and h.ID_ANO =anio 
   and tr_ANULADO = 'NO'
)
 order by 1;
      
  
 
   begin   
     
   datos:='';
    datos_tmp:='{""}';
   contador:=0;
    datos_p:='';
    datos_tmp_p:='{""}';
   contador_p:=0;
  --abrimos cursor.    
   
  
  
      OPEN Causencias_solicitados;
      LOOP
        FETCH Causencias_solicitados
          into datos_tmp,d_fecha;
        EXIT WHEN Causencias_solicitados%NOTFOUND;
          contador:=contador+1;      
         if contador =1 then   
           datos:= datos_tmp; 
         else
           datos:= datos  || ',' || datos_tmp;   
         end if;              
      END LOOP;      
      CLOSE Causencias_solicitados;
      
      
      OPEN Causencias_disponibles;
      LOOP
        FETCH Causencias_disponibles
          into datos_tmp_p;
        EXIT WHEN Causencias_disponibles%NOTFOUND;
          contador_p:=contador_p+1;      
         if contador_p =1 then   
           datos_p:= datos_tmp_p; 
         else
           datos_p:= datos_p  || ',' || datos_tmp_p;   
         end if;              
      END LOOP;      
      CLOSE Causencias_disponibles;
      
      
      if opcion='0' then
       datos_ausencias_solicitados:= '{"ausencias_solicitadas": [' || datos || ']}';
       cabecera_periodos_consulta:='{"periodos_consulta_anio":[2024,2023]},'; 
        resultado:=     cabecera_periodos_consulta  ||datos_ausencias_solicitados;
      else if opcion <> '1' then        
          datos_ausencias_solicitados:='';
          cabecera_periodos_consulta:='';
           Resultado:= '{"ausencia_detalle": [' || datos_tmp || ']}';  
           else 
             cabecera_periodos_consulta:='{"periodos_consulta_anio":[2024,2023]},'; 
             datos_ausencias_disponibles:= '{"ausencias_disponibles": [' || datos_p || ']}';    
             resultado:=     cabecera_periodos_consulta  ||datos_ausencias_disponibles;   
           end if;
         end if;
     
 
      
  
   return(Resultado);
  end;
/

