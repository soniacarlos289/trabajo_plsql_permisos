create or replace function rrhh.wbs_devuelve_saldo_bolsas(i_id_funcionario IN VARCHAR2, opcion in varchar2,anio in varchar2) return varchar2 is
  Resultado varchar2(12000);
    observaciones varchar2(12000);
      --opcion
      --r resumen saldos
      --p bolsa de productividad con movimientos.
      --e bolsa de horas_extras con movimientos.
      --c bolsa de conciliciaion co movimientos.
      bolsa_horas_extras_r varchar2(1232);
      bolsa_horas_extras_d varchar2(1232);
      bolsa_horas_conciliacion_r varchar2(1232);
      bolsa_horas_conciliacion_d varchar2(1232);
      bolsa_horas_productividad_r varchar2(1232);
      bolsa_horas_productividad_d varchar2(1232);
      
      d_fecha_movimiento date;
      i_periodo number;
      
      datos    varchar2(12000);
      datos_tmp    varchar2(12000);
      contador number;    
   CURSOR C_conciliacion is
    select  
     distinct json_object('id_anio' is id_ano,'fecha' is to_char(fecha_movimiento,'dd/mm/yyyy'), 'Tipo_Horas' is DECODE(id_TIPO_MOV,1,'EXCESO SALDO','PERMISO'),'total_horas' is nvl(devuelve_min_fto_hora(exceso),0))       
      ,fecha_movimiento
      from BOLSA_CONCILIA_MOV   WHERE  (ANULADO IS NULL OR ANULADO='0') and id_funcionario =  i_id_funcionario and id_ano = anio order by fecha_movimiento;   
   
    CURSOR C_productividad is
    SELECT  distinct
    json_object('fecha' is to_char(FECHA_MOVIMIENTO,'DD/MM/YYYY'),
                'periodo' is periodo,
                'descripcion' is desc_tipo_movimiento,            
               'total_horas' is nvl(devuelve_min_fto_hora(EXCESO_en_horas*60+EXCESOs_en_minutos),0)),   periodo     
    FROM 
        BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT 
    WHERE bm.id_funcionario =i_id_funcionario  and  bm.anulado(+)=0 and bm.id_ano = anio  and  
          bm.anulado(+)=0 and BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO 
   order by  periodo;

   CURSOR C_horas_extras is
    SELECT  distinct
    json_object('anio' is anio,
                'fecha' is to_char(FECHA_HORAS,'DD/MM/YYYY'),
                'hora_inicio' is HORA_INICIO,       
                'hora_fin' is HORA_FIN,       
                'tipo_horas' is DESC_TIPO_HORAS,           
                'total_horas' is TOTAL_HORAS  )     
     FROM RRHH.HORAS_EXTRAS, RRHH.TR_TIPO_HORA  
     WHERE RRHH.TR_TIPO_HORA.ID_TIPO_HORAS = HORAS_EXTRAS.ID_TIPO_HORAS AND  
           HORAS_EXTRAS.ID_ANO =anio AND ID_FUNCIONARIO =i_id_funcionario and 
                (anulado='NO' or anulado is null);

   begin   
      bolsa_horas_extras_r:='';
      bolsa_horas_extras_d:='';
      bolsa_horas_conciliacion_r:='';
      bolsa_horas_conciliacion_d:='';
      bolsa_horas_productividad_r:='';
      bolsa_horas_productividad_d:='';
      
     BEGIN
      select json_object('bolsa_horas_conciliacion' is  devuelve_min_fto_hora(3000-utilizadas)),  
         '{"periodos_consulta_anio":[2025,2024]},' ||  json_object(        'periodo_anio' is anio,
      'horas_saldo' is  '50 horas','horas_disponibles' is  devuelve_min_fto_hora(3000-utilizadas),
      'horas_utilizadas' is  nvl(devuelve_min_fto_hora(utilizadas),0),'horas_recuperadas' is  nvl(devuelve_min_fto_hora(nvl(exceso_jornada,0)),0),
      'horas_faltan' is   nvl(devuelve_min_fto_hora(nvl(decode(sign(utilizadas-exceso_jornada), -1, 0, 1, utilizadas-exceso_jornada) ,0)),'0 Horas')) 
      
      into  bolsa_horas_conciliacion_r,bolsa_horas_conciliacion_d
       from BOLSA_CONCILIA  
      WHERE  id_funcionario = i_id_funcionario and rownum<2 and id_ano = anio;   
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
         bolsa_horas_conciliacion_r:='"bolsa_horas_conciliacion":"0 horas "';
        bolsa_horas_conciliacion_d:='{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' ||anio ||',"horas_saldo":"0 horas","horas_disponibles":"0 horas ","horas_utilizadas":"0","horas_recuperadas":"0","horas_faltan":"0 Horas"}';

     WHEN OTHERS THEN                        
         bolsa_horas_conciliacion_r:='"bolsa_horas_conciliacion":"0 horas "';
         bolsa_horas_conciliacion_d:='{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' ||anio ||',"horas_saldo":"0 horas","horas_disponibles":"0 horas ","horas_utilizadas":"0","horas_recuperadas":"0","horas_faltan":"0 Horas"}';

     END;
     
     BEGIN
      select
       json_object('bolsa_horas_productividad' is devuelve_min_fto_hora(75*60-sum(HORAS_EXCESOS))) ,
      '{"periodos_consulta_anio":[2025,2024]},' ||  json_object( 
          'periodo_anio' is anio,'bolsa_horas_productividad' is devuelve_min_fto_hora(75*60-sum(HORAS_EXCESOS)))
       into  bolsa_horas_productividad_r, bolsa_horas_productividad_d
      from bolsa_saldo  
      WHERE id_funcionario = i_id_funcionario and rownum<2 and id_ano = anio;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
           bolsa_horas_productividad_r:='"bolsa_horas_productividad":"0 horas "';           
           bolsa_horas_productividad_d:='{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' || anio ||',"bolsa_horas_productividad":"0 horas "}';
     WHEN OTHERS THEN                        
            bolsa_horas_productividad_r:='"bolsa_horas_productividad":"0 horas "';
            bolsa_horas_productividad_d:='{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' || anio ||',"bolsa_horas_productividad":"0 horas "}';
     END;

      BEGIN
      SELECT  json_object('bolsa_horas_extras' is  devuelve_min_fto_hora(total-utilizadas)),
              '{"periodos_consulta_anio":[2025,2024,2023,2022,2021]},' ||  json_object( 
          'periodo_anio' is anio,'horas_total' is devuelve_min_fto_hora(total),'horas_disponible' is devuelve_min_fto_hora(total-utilizadas),
           'horas_utilizadas' is devuelve_min_fto_hora(utilizadas),'saldo_bolsa' is devuelve_min_fto_hora(total-utilizadas))         
      into  bolsa_horas_extras_r, bolsa_horas_extras_d
       FROM horas_extras_ausencias  
       WHERE id_funcionario= i_id_funcionario and rownum<2; 
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
           bolsa_horas_extras_r:='{"bolsa_horas_extras":"0 horas "}';
          bolsa_horas_extras_d:= '{"periodos_consulta_anio":[2025,2024,2023,2022,2021]},{"periodo_anio":' || anio ||',"horas_total":"0 horas","horas_disponible":"0 horas","horas_utilizadas":"0 horas","saldo_bolsa":"0 horas"}';

     WHEN OTHERS THEN                        
            bolsa_horas_extras_r:='{"bolsa_horas_extras":"0 horas "}';
            bolsa_horas_extras_d:= '{"periodos_consulta_anio":[2025,2024,2023,2022,2021]},{"periodo_anio":' || anio ||',"horas_total":"0 horas","horas_disponible":"0 horas","horas_utilizadas":"0 horas","saldo_bolsa":"0 horas"}';
     END;
     bolsa_horas_extras_r:= replace(replace(bolsa_horas_extras_r,'{',''),'}',''); 
     bolsa_horas_conciliacion_r:= replace(replace( bolsa_horas_conciliacion_r,'{',''),'}','');
     bolsa_horas_productividad_r:= replace(replace(bolsa_horas_productividad_r,'{',''),'}','');
    CASE  opcion

      WHEN 'r' THEN
       resultado:=    bolsa_horas_extras_r || ',' || bolsa_horas_conciliacion_r || ',' || bolsa_horas_productividad_r;
      WHEN 'p' THEN 
         contador:=0;
         OPEN  C_productividad;
        LOOP
          FETCH  C_productividad
            into datos_tmp,i_periodo;
          EXIT WHEN  C_productividad%NOTFOUND;
          
              
           if contador =0 then   
             datos:= datos_tmp; 
           else
             datos:= datos  || ',' || datos_tmp;   
           end if;
            contador:=contador+1;    
        END LOOP;
        CLOSE  C_productividad;        
        resultado:= bolsa_horas_productividad_d || ',{'  || '"movimientos_bolsa": [' || datos || ']}';  
        
      WHEN 'c' THEN   
        datos:='';
        contador:=0;
        --abrimos cursor.    
        OPEN  C_conciliacion;
        LOOP
          FETCH  C_conciliacion
            into datos_tmp, d_fecha_movimiento;
          EXIT WHEN  C_conciliacion%NOTFOUND;
            
            contador:=contador+1;      
           if contador =1 then   
             datos:= datos_tmp; 
           else
             datos:= datos  || ',' || datos_tmp;   
           end if; 
             
        END LOOP;
        CLOSE  C_conciliacion;        
        resultado:= bolsa_horas_conciliacion_d || ',{'  || '"movimientos_concilia": [' || datos || ']}';  
        
      WHEN 'e' THEN  
           datos:='';
        contador:=0;
        --abrimos cursor.    
        OPEN C_horas_extras;
        LOOP
          FETCH  C_horas_extras
            into datos_tmp;
          EXIT WHEN C_horas_extras%NOTFOUND;
            
            contador:=contador+1;      
                  
           if contador =1 then   
             datos:= datos_tmp; 
           else
             datos:= datos  || ',' || datos_tmp;   
           end if; 
        END LOOP;
        CLOSE  C_horas_extras;      
        resultado:= bolsa_horas_extras_d || ',{'  || '"movimientos_horas": [' || datos || ']}';  
      
    END CASE;           
  
   return(Resultado);
  end;
/

