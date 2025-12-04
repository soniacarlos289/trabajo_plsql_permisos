create or replace procedure rrhh.CALCULA_PERMISOS_LOS_ANIOS
 (V_ID_FUNCIONARIO in number,V_ID_ANO in varchar)  is 

  -- Local variables here
  i integer;
  i_id_funcionario varchar2(6);
  i_id_ano number(4);
  i_compensatorios number;
  i_asuntos_propios_bomberos number;
  i_asuntos_propios number;
  i_num_dias_extras number; 
  i_fecha_ingreso date;
  i_antiguedad number;
  i_dias_factor number;
  i_contratacion number;
  i_tipo_funcionario2 number;
  id_tipo_funcionario_p number;
  i_id_tipo_permiso varchar2(5);
  i_num_dias number;
  i_unico varchar2(2);
  i_tipo_dias varchar2(1);
  i_inserta number;
  
  
  --Obtengo los permisos.
  cursor c1  (i_ano number,i_funcionario number) is
     select 
         distinct id_funcionario,fecha_ingreso,
                --  nvl(to_char(fecha_baja,'yyyy'),'0')-to_char(fecha_ingreso,'yyyy') as Antiguedad,
                  nvl(to_char(fecha_baja,'yyyy'),'0')-to_char(fecha_antiguedad,'yyyy') as Antiguedad,
                  NVL(FECHA_FIN_CONTRATO,to_date('31/12/' || i_ano ,'DD/MM/YYYY'))-fecha_ingreso as dias_factor,
                  contratacion,tipo_funcionario2
     from personal_new pe 
     where 
         (fecha_baja is null or fecha_baja > to_date('31/12/' || i_ano ,'DD/MM/YYYY')
              and fecha_baja <= to_date('31/12/2090' ,'DD/MM/YYYY'))  and 
         (fecha_fin_contrato>  to_date('01/12/' || i_ano ,'DD/MM/YYYY') or fecha_fin_contrato is null)                  
              and ('0'=i_funcionario OR pe.id_funcionario=i_funcionario)       
     order by id_funcionario;              

--RECORREMOS TODOS LOS PERMISOS DE UN AÑO   
Cursor c2 (i_ano number) is
         select    lpad(ID_TIPO_PERMISO,5,'0'), NUM_DIAS , UNICO,tipo_dias,id_tipo_funcionario                     
                 from tr_tipo_permiso              
                 where  id_ano=v_id_ano 
                    and id_tipo_permiso not in('01501','01502','01503','01504','03060','03070','03080') --Permisos que no se tienen que calcular.
          /*  AND (        (
              id_tipo_permiso in ('03010','03020','03030','03040','03050')--,'03040','03050','03060')
              and FECHA_INICIO+120 > sysdate    )  OR  ( fecha_inicio=
               to_date('01/01/' || i_ano ,'DD/MM/YYYY')) )*/
               ORDER BY id_tipo_permiso;
                       
       
begin
  -- Test statements here
  dbms_OUTPUT.PUT_LINE('Empieza el PL/SQL');

  IF V_ID_ANO = '0' then
    i_id_ano:=to_char(sysdate,'YYYY');
  Else
  --Año calculo permisos  
     i_id_ano:=to_number(V_ID_ANO);
  END IF;
    
     
   OPEN C1(i_id_ano,V_ID_FUNCIONARIO); 
   LOOP
  
      FETCH C1 INTO                  
            i_id_funcionario,i_fecha_ingreso, i_antiguedad,i_dias_factor,i_contratacion,i_tipo_funcionario2;
      EXIT WHEN C1%NOTFOUND;  
         
      
        --Factor muliplicación para los días de vacaciones.      
        i_dias_factor:=i_dias_factor/365;
       
        IF i_antiguedad > 55 then
               i_antiguedad:=0;
        end if;
      
        IF i_antiguedad > 5 then
                i_dias_factor:=1;
        end if;
        
        IF i_dias_factor > 1 then
                i_dias_factor:=1;
         end if;
   
      OPEN C2(i_id_ano); 
      LOOP
  
           FETCH C2 INTO                  
            i_id_tipo_permiso,i_num_dias, i_unico,i_tipo_dias,  id_tipo_funcionario_p;
           EXIT WHEN C2%NOTFOUND;  
           
           i_inserta:=1;--no
           
           --VAcaciones y AP.
           IF  i_id_tipo_permiso = '01000' OR  i_id_tipo_permiso = '02000' then    
                IF   i_id_tipo_permiso = '01000' and  i_dias_factor<> 1 then
                    i_num_dias:=30;
                END IF;     
               i_num_dias:=round(i_num_dias*  i_dias_factor,0);
               i_inserta:=1;--no    
               
               IF i_TIPO_FUNCIONARIO2=21 OR i_TIPO_FUNCIONARIO2=23 THEN
                  i_tipo_dias:='N';--dias naturales para bomberos y policias. 
               END IF;       
               
           else if   i_id_tipo_permiso = '03010' OR  i_id_tipo_permiso = '03020' 
                  OR i_id_tipo_permiso = '03030' OR  i_id_tipo_permiso = '03040'
                  OR i_id_tipo_permiso = '03050' OR  i_id_tipo_permiso = '03060'   then
                    /* compensatorios*/
                    Begin 
                     select count(*) into i_inserta
                     from permiso_funcionario t
                     where id_funcionario=i_id_funcionario AND 
                     ID_TIPO_PERMISO in ('03010','03020','03030','03040','03050','03060') and
                     id_ano=v_id_ano-1;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                       i_inserta:=0;
                    WHEN OTHERS THEN
                       i_inserta:=0;
                    end; 
                    IF i_TIPO_FUNCIONARIO2=10 THEN
                        i_inserta:=1;--si  
                    END IF;
                    if i_inserta> 0 then
                        i_inserta:=1;--si  
                    end if;
                      
                end if;  
           end if;     
           
           IF i_id_tipo_permiso = '01015' then    
           
              BEGIN
               i_inserta:=1; 
               select distinct
                DECODE(i_id_ano-to_number(substr(to_char(fecha_antiguedad,'DD/MM/YYYY'),7,4)),
                       16,1,
                       17,1,
                       18,1,
                       19,1,
                       20,1,
                       21,2,
                       22,2,
                       23,2,
                       24,2,
                       25,2,
                       26,3,
                       27,3,
                       28,3,
                       29,3,
                       30,3,
                       31,4,
                       32,4,
                       33,4,
                       34,4,
                       35,4,
                       36,4,
                       37,4,
                       38,4,
                       39,4,
                       40,4,
                       41,4,
                       42,4,
                       43,4,
                       44,4,
                       45,4,
                       46,4,
                       47,4,
                       48,4,
                       49,4,
                       50,4,
                       51,4,
                       52,4,
                       53,4,
                       54,4,
                       55,4,
                       56,4,
                       57,4,
                       58,4,
                       59,4,
                       60,4,
                       61,4,
                       62,4,
                       63,4,
                       64,4,
                       65,4,
                       66,4,
                       67,4,
                       68,4,
                       69,4,
                       70,4,
                          0) into i_num_dias
                      from personal_new 
                      where 
                        i_id_ano-to_number(substr(to_char(fecha_antiguedad,'DD/MM/YYYY'),7,4)) > 15
                      and id_funcionario=i_id_funcionario; 
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                     i_inserta:=0;
                    WHEN OTHERS THEN
                     i_inserta:=0;
                    end;
                    
                    /* 203353  tiene que tener 13/02/1991 --> trienios*/
 
                    --caMBIAR FECHA DE ANTIGUEDAD 1/02/1985
                    -- 14003
                    -- 14004 


                    --falta dias extras vacaciones
                    --caMBIAR FECHA DE ANTIGUEDAD 1/02/1991
                    -- 2--->solamente 
                    /*
                    10002 Jose Andres Julian Blanco
                    10024 Fernando Paulino Iglesias
                    10003 Enrique Lucas Aparicio
                    10011 Blanca M? Ballina Fernandez
                    10013 Jose Luis Berrocal Delgado
                    10016 Yolanda Felipe Montero
                    10020 Clementina Garcia de Onis Montero
                    10021 Esperanza Gomez Sanchez
                    10023 Carmen Pastor Sanchez
                    10029 Amable Rodriguez Gonzalez
                    10030 Jenaro San Cipriano Gonzalez
                    10028 Aniceto Rodriguez Encinas
                     */

    
                     --Para los de fecha de antiguedad /01/02/1991 
                      IF i_id_funcionario =10002    OR
                         i_id_funcionario =10003    OR
                         i_id_funcionario =10024    OR
                         i_id_funcionario =10011    OR
                         i_id_funcionario =10013    OR
                         i_id_funcionario =10016    OR
                         i_id_funcionario =10020    OR
                         i_id_funcionario =10029    OR
                         i_id_funcionario =10021    OR
                         i_id_funcionario =10023    OR
                         i_id_funcionario =10028    OR
                         i_id_funcionario =10030  Then

                                 i_num_dias:=2;
                                   i_inserta:=1; 
                      END IF;
                      IF i_id_funcionario = (203353) then
                                i_num_dias:=3;
                                  i_inserta:=1; 
                     END IF;  
      
                     --Para los de fecha de antiguedad /01/02/1985
                     IF i_id_funcionario = 14003 OR i_id_funcionario = 14004 THEN 
                                  i_num_dias:=4;
                                    i_inserta:=1; 
                     END IF;
                                         
           end if; --PERMISO 01015
           
           if i_id_tipo_permiso='02015' then
               i_inserta:=1; 
             --falta dias extras vacaciones
             -- 3--->solamente
              /*
              10002 Jose Andres Julian Blanco
              10024 Fernando Paulino Iglesias
              10003 Enrique Lucas Aparicio
              10011 Blanca M? Ballina Fernandez
              10013 Jose Luis Berrocal Delgado
              10016 Yolanda Felipe Montero
              10020 Clementina Garcia de Onis Montero
              10021 Esperanza Gomez Sanchez
              10023 Carmen Pastor Sanchez
              10029 Amable Rodriguez Gonzalez
              10030 Jenaro San Cipriano Gonzalez
              10028 Aniceto Rodriguez Encinas
              */
              /* 203353  tiene que tener 13/02/1991 --> trienios*/
     --Asuntos propios por trienios
                 Begin 
              /*   SELECT  distinct  DECODE(trunc((i_id_ano-to_number(substr(to_char(ftrienio,'DD/mm/yyyy'),7,11)))/3) ,
                6,2,7,2,trunc((i_id_ano-to_number(substr(to_char(ftrienio,'DD/mm/yyyy'),7,11)))/3)-5) as num_dias
                into i_num_dias
                
                   from personal_vmaa p, (select max(versempl)as versempl,codiempl from personal_vmaa where  fechbaja is null group by codiempl )pe where 
                  pe.codiempl=p.codiempl and  pe.versempl=p.versempl and pe.codiempl=i_id_funcionario and
                   trunc((i_id_ano-to_number(substr(to_char(ftrienio,'DD/mm/yyyy'),7,11)))/3) > 5 --and fechbaja is null
                   ; */ 
                   SELECT  distinct 0     into i_num_dias from dual;       
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                     i_inserta:=0;
                    WHEN OTHERS THEN
                     i_inserta:=0;
                    end;
                 IF --Para los de fecha de antiguedad /01/02/1991 
                       i_id_funcionario =10002    OR
                         i_id_funcionario =10003    OR
                         i_id_funcionario =10024    OR
                         i_id_funcionario =10011    OR
                         i_id_funcionario =10013    OR
                         i_id_funcionario =10016    OR
                         i_id_funcionario =10020    OR
                         i_id_funcionario =10029    OR
                         i_id_funcionario =10021    OR
                         i_id_funcionario =10023    OR
                         i_id_funcionario =10028    OR
                         i_id_funcionario =10030  THEN 
                                 i_num_dias:=3;
                                   i_inserta:=1; 
                      END IF;
                      IF i_id_funcionario = (203353) then
                                i_num_dias:=3;
                                  i_inserta:=1; 
                     END IF;  
      
                     --Para los de fecha de antiguedad /01/02/1985
                  IF i_id_funcionario = 14003 OR i_id_funcionario = 14004 THEN 
                                  i_num_dias:=2;
                                    i_inserta:=1; 
                     END IF;
           END IF;   
 
            
           if (i_id_tipo_permiso  = '02030' OR i_id_tipo_permiso  = '02031' ) AND  i_TIPO_FUNCIONARIO2<>23 THEN
              i_inserta := 0;
           
           END IF;
             
                                     
           
           If  i_inserta = 1 then
              Begin 
               insert into  permiso_funcionario
                (id_funcionario, id_tipo_permiso, id_ano, num_dias, completo, unico, id_tipo_dias ) 
               values
                (i_id_funcionario, I_id_tipo_permiso, v_id_ano, i_num_dias, 'SI', i_unico, I_tipo_dias);
              EXCEPTION
                 WHEN DUP_VAL_ON_INDEX THEN
                   i_inserta := 0;
              END;  
           END IF;     
             
      
      
      
      
      END LOOP;
      CLOSE C2;
      
 

    
             
     
 
    
    
        -- Compruebo que el a?o pasado tenia ap bomberos
    /*   Begin 
         select count(*) into  i_asuntos_propios_bomberos
         from permiso_funcionario t
         where id_funcionario=i_id_funcionario AND 
               ID_TIPO_PERMISO  in ('02081','02082','02162','02241','02242') and
               id_ano=i_id_ano-1;
         EXCEPTION
          WHEN NO_DATA_FOUND THEN
             i_asuntos_propios_bomberos:=0;
          WHEN OTHERS THEN
               i_asuntos_propios_bomberos:=0;
        end;
                
        IF     i_asuntos_propios_bomberos > 0 then                          
            INSERT INTO PERMISO_FUNCIONARIO
              (ID_FUNCIONARIO       ,  
               ID_TIPO_PERMISO        ,
               ID_ANO                 ,
               NUM_DIAS               ,
               COMPLETO               ,
               UNICO                  ) 
               (
               select 
                  i_id_funcionario,
                   ID_TIPO_PERMISO       ,         
                   ID_ANO,                          
                      NUM_DIAS ,
                    'SI'  ,
                    UNICO                     
                 from tr_tipo_permiso              
                 where UNICO='SI' AND 
                       ID_TIPO_PERMISO in ('02081') and
                       id_ano=i_id_ano);                             
             commit;                                              
        END IF;
*/
              
  
   commit;                        
  END LOOP;
  CLOSE C1;
  
  dbms_OUTPUT.PUT_LINE('Temino el PL/SQL ');
  

end CALCULA_PERMISOS_LOS_ANIOS;
/

