create or replace function rrhh.wbs_devuelve_saldo_horario(i_id_funcionario IN VARCHAR2, opcion in varchar2,anio in varchar2,v_mes in varchar2) return varchar2 is
  Resultado varchar2(12000);
    observaciones varchar2(12000);
      --opcion
      --r resumen saldo
     
      saldo_horario_r varchar2(1232);
      saldo_horario_d varchar2(1232);
     
      v_entrada varchar2(123);
      d_fecha_movimiento date;
      i_periodo number;
      
      datos    varchar2(12000);
      datos_tmp    varchar2(12000);
      contador number; 
      
        datos_p    varchar2(12000);
      datos_tmp_p    varchar2(12000);
      contador_p number;    
       v_id_periodo varchar2(12000);
       v_id_mes varchar2(12000);
        v_id_anio varchar2(12000);
      d_id_dia date;
   CURSOR C_periodo is
    select  distinct 
      
       json_object('id' is ano||mes,'anio' is ano,'mes' is mes,'Desde' is TO_CHAR(INICIO,'dd/mm/yyyy'), 
       'Hasta' is TO_CHAR(FIN,'dd/mm/yyyy')
        ,'opcion_menu' is
      rpad(DECODE(MES,1,'ENERO',2,'FEBRERO',3,'MARZO',4,'ABRIL',5,'MAYO',6,'JUNIO',7,'JULIO',8,'AGOSTO',9,'SEPTIEMBRE',10,'OCTUBRE',11,'NOVIEMBRE',
       12,'DICIEMBRE'),13,' ') || ' Desde:' || TO_CHAR(INICIO,'dd-mon-yyyy') || ' a ' ||  TO_CHAR(FIN,'dd-mon-yyyy')),ano||mes as mes
     FROM WEBPERIODO  WHERE ANO=anio order by mes;

   --cambiado el 24/04/2025
   /*CURSOR C_fichajes_dia is
    SELECT  distinct
    json_object('hora' is to_char(HORA,'hh24:mi')),hora
    from persona p, transacciones t ,funcionario_fichaje ff
    where codigo=ff.codpers   and p.numtarjeta=t.pin and t.fecha=to_char(sysdate,'DD/mm/YYYY') 
     and ff.id_funcionario= i_id_funcionario 
     and numero<>'MA' and tipotrans in ('2','55','39','4865','4356','4098') ORDER BY HORA;*/
     
      CURSOR C_fichajes_dia is
    SELECT  distinct
    json_object('hora' is HORA),to_date('31/12/1899' || hora,'DD/mm/yyyy hh24:mi') as hora
    from fichaje_diarios ff
    where  ff.id_funcionario= i_id_funcionario 
     ORDER BY HORA;
                  
    CURSOR C_fichajes_periodo is    
    select distinct to_char(fecha_fichaje_entrada, 'hh24:mi') AS ENTRADA, 
            json_object('fecha' is to_char(id_dia, 'dd/mm/yyyy'),  
               'entrada' is to_char(fecha_fichaje_entrada, 'hh24:mi'),        
               'salida' is  to_char(fecha_fichaje_salida, 'hh24:mi'),
               'saldo_dia' is 'Jornada: ' || DECODE(trunc(hh), 0, '                                  ', devuelve_min_fto_hora(hh)) || '--Fichadas: ' || devuelve_min_fto_hora(hr)
               
                ),id_dia
      from resumen_saldo r,personal_new p          
     where r.id_funcionario=p.id_funcionario and        
      p.id_funcionario =  i_id_funcionario  
      and periodo= lpad(V_mes,2,'0') ||  anio                
     and id_dia<to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy')       and (HR> 0 )          ORDER BY  id_dia,ENTRADA;
     
    CURSOR Cpermisos_periodo is 
     select  distinct json_object('id_tipo_permiso' is tr.id_tipo_permiso,
                            'permiso' is desc_tipo_permiso,
                            'fecha' is to_char(id_dia, 'dd/mm/yyyy'),
                            'estado' is tp.desc_estado_permiso,
                            'id_estado_permiso' is tp.id_estado_permiso),
                id_dia
  from calendario_laboral ca,
       webperiodo   w,
       CALENDARIO_FICHAJE CF,
       tr_tipo_permiso    tr,
      tr_estado_permiso  tp
 where tp.id_estado_permiso=cf.id_tipo_estado
     and   w.MES|| w.ANO =lpad(V_mes,2,'0') ||  anio    
     and id_funcionario in (i_id_funcionario )    
     and ca.id_dia between cf.fecha_inicio(+) and nvl(cf.fecha_fin(+),sysdate)
     and ca.id_dia between w.inicio and w.fin and
     tr.id_tipo_permiso=cf.id_tipo_permiso and
     tr.id_ano= w.ANO
     order by id_dia asc ;
     
     
   begin   
      saldo_horario_r:='';
      saldo_horario_d:='';
      --json_object('periodos_consulta_mes_anioo' is

     BEGIN
      select replace(replace(json_object('saldo_horario' is  devuelve_min_fto_hora(nvl(sum(horas_saldo-horas_hacer),0))),'{',''),'}',''),
       
-- '{"periodos_consulta_anio":[2024,2023],' ||
       replace(replace(json_object( 
     'saldo_horario' is  devuelve_min_fto_hora(nvl(sum(horas_saldo-horas_hacer),0))),'{',''),'}','')
     
      into  saldo_horario_r, saldo_horario_d
       from fichaje_funcionario_resu_dia t,       webperiodo ow 
     where id_funcionario =   i_id_funcionario and 
           mes||ano = lpad(V_mes,2,'0') ||  anio     and  
           t.id_dia  between ow.inicio and ow.fin  and t.id_dia<to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'); 
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        saldo_horario_r:='{"saldo_horario":"0 horas "}';
     WHEN OTHERS THEN                        
        saldo_horario_r:='{"saldo_horario":"0 horas "}';
     END;
      datos:= '';
      datos_tmp:='';
      contador:=0;
      datos_p:= '';
      datos_tmp_p:='';
      contador_p:=0;
      
     --consulta opciones periodos
     OPEN C_periodo;
        LOOP
          FETCH  C_periodo
            into datos_tmp_p, i_periodo;
          EXIT WHEN  C_periodo%NOTFOUND;
           contador_p:=contador_p+1;  
            --datos_tmp:='{' || datos_tmp ||'}';    
           if contador_p =1 then   
             datos_p:=  '{"periodos_consulta":[' ||datos_tmp_p ; 
           else
             datos_p:= datos_p  || ',' || datos_tmp_p;   
           end if; 
                      
        END LOOP;
      CLOSE  C_periodo; 
     datos_p:= datos_p  || '],';
     
 datos_p:=  datos_p  || '"periodo_seleccionado":[ {"anio":' ||anio  || ',"mes":"'||v_mes || '"}],';

 v_id_periodo:=DEVUELVE_PERIODO(to_char(sysdate,'dd/mm/yyyy'));    
    if  length(v_id_periodo) = 5  then
       v_id_mes:=substr(v_id_periodo,1,1);
        v_id_anio:=substr(v_id_periodo,2,4);
  datos_p:=  datos_p  || '"periodo_actual":[ {"anio":' ||v_id_anio  || ',"mes":"'||v_id_mes || '"}],';
   else if length(v_id_periodo) = 6  then
          v_id_mes:=substr(v_id_periodo,1,2);
          v_id_anio:=substr(v_id_periodo,3,4);
          datos_p:=  datos_p  || '"periodo_actual":[ {"anio":' ||v_id_anio  || ',"mes":"'||v_id_mes || '"}],';
         end if;     
   end if;
 
 
 
     --fichajes día
     OPEN C_fichajes_dia;
        LOOP
          FETCH  C_fichajes_dia
            into datos_tmp, d_fecha_movimiento;
          EXIT WHEN  C_fichajes_dia%NOTFOUND;
           contador:=contador+1;  
            --datos_tmp:='{' || datos_tmp ||'}';    
           if contador =1 then   
             datos:=  datos_tmp; 
           else
             datos:= datos  || ',' || datos_tmp;   
           end if; 
                      
        END LOOP;
      CLOSE   C_fichajes_dia;        
      
       
    CASE  opcion

      WHEN 'r' THEN        
         --datos:= replace(replace( datos,'{',''),'}',''); 
  
      resultado:=     saldo_horario_r || ','  || '"fichajes": [' || datos || ']'; 
      
     
      WHEN 'd' THEN 
        
      resultado:= datos_p|| saldo_horario_d || ','  || '"fichajes": [' || datos || ']';  
       datos:= '';
      datos_tmp:='';
      contador:=0;
        OPEN C_fichajes_periodo;
        LOOP
          FETCH  C_fichajes_periodo
            into  v_entrada,datos_tmp,d_id_dia;
          EXIT WHEN  C_fichajes_periodo%NOTFOUND;
            
            contador:=contador+1;  
           -- datos_tmp:='{' || datos_tmp ||'}';      
           if contador =1 then   
             datos:= datos_tmp; 
           else
             datos:= datos  || ',' || datos_tmp;   
           end if; 
                      
        END LOOP;
      CLOSE   C_fichajes_periodo;  
            
      resultado:=  resultado || ','  || '"fichajes_periodo": [' || datos || ']';  
      contador:=0;
      datos:= '';
         datos_tmp:='';
      OPEN Cpermisos_periodo;
        LOOP
          FETCH  Cpermisos_periodo
            into datos_tmp,  d_fecha_movimiento;
          EXIT WHEN  Cpermisos_periodo%NOTFOUND;
            
            contador:=contador+1;      
           if contador =1 then   
             datos:= datos_tmp; 
           else
             datos:= datos  || ',' || datos_tmp;   
           end if; 
                      
        END LOOP;
      CLOSE  Cpermisos_periodo;        
        resultado:= resultado || ','  || '"permisos_en_periodo": [' || datos || ']}';  

        
      
    END CASE;           
  
   return(Resultado);
  end;
/

