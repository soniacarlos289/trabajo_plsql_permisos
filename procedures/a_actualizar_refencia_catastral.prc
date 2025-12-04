CREATE OR REPLACE PROCEDURE RRHH.A_actualizar_REFENCIA_CATASTRAL IS
    CURSOR c_viviendas IS
        SELECT dboid,t.codigoine as COD_INE, via_sigla,via_nombre,
           lpad(VIA_NUMERO,4,'0') as via_numero,
               replace(FBLOCK, ' ',null) AS BLOQUE,
            --     DECODE( replace(FBLOCK, ' ',null),null,o.escalera, replace(FBLOCK, ' ',null)) AS BLOQUE,          
               DEcode(PLANTA,'BAJ',null, PLANTA)  AS PLANTA,  --,'BAJ',null
                PUERTA  AS PUERTA
      FROM temp_vivienda_mytao_final o, TEMP_INE_AYTO t where  t.codigotao=o.via_codigo and indicador_libre is null
         and (planta is null or planta='PBJ' or planta='BAJ') -- and via_nombre='ABAJO' and via_numero='2'
      
--       and rownum<1000
     ;-- and o.via_nombre='ALARCON';  
/*
CURSOR c_viviendas_2 IS
        SELECT dboid,t.codigoine as COD_INE,TRANSLATE(substr(VIA_NOMBRE,1,20),'ÁÉÍÓÚáéíóúÑñ',         'AEIOUaeiouNn') as VIA_NOMBRE, VIA_SIGLA, lpad(VIA_NUMERO,4,'0') as VIA_NUMERO,
               NVL(REPLACE(FBLOCK, ' ', '00'), '00') AS BLOQUE,               
                  NVL(PLANTA, 'VA')                AS PLAN,
                lpad(DECODE(NVL(PUERTA, 'A'),
                      'DR','DC',
                      'ENT','EN',
                      'B IZ','BI',
                
               NVL(PUERTA, '0000')),4,'0')
               
                AS PUERTA
        FROM temp_vivienda_mytao o, TEMP_INE_AYTO t where  t.codigotao=o.via_codigo and indicador_libre is ;*/


    v_count NUMBER;
    v_encontrado number;
    v_civ varchar2(24);
    v_civ_varios  number;
BEGIN
  v_civ_varios  :=0;
    v_encontrado:=0;
    
    FOR rec IN c_viviendas LOOP
      Begin
           /*  SELECT civ
            INTO v_civ 
            FROM temp_inmuebles_2_ori t
            WHERE t.cvia  =rec.COD_INE
              AND lpad(t.numer,4,'0') = rec.VIA_NUMERO
              AND (t.esc = rec.BLOQUE OR rec.BLOQUE is null)
              AND (lpad(replace(t.plan,'P',''),4,'0') = rec.PLANTA OR rec.PLANTA IS NULL)
              AND (lpad(t.puer,4,'0') = lpad(rec.puerta,4,'0') OR rec.puerta IS NULL) and rownum<2 ;*/
              
               SELECT indicador_libre INTO v_civ 
                 FROM temp_vivienda_mytao_final o where   indicador_libre is not null
                 and  o.codigo_ine  =rec.COD_INE
                    AND lpad(o.via_numero,4,'0') = rec.VIA_NUMERO
                    AND (replace(FBLOCK, ' ',null) = rec.BLOQUE OR rec.BLOQUE is null)
              AND (o.planta = rec.PLANTA OR rec.PLANTA IS NULL)
              AND (o.puerta=rec.puerta OR rec.puerta IS NULL) ;               
       EXCEPTION
     WHEN NO_DATA_FOUND THEN           
         v_civ  :='0';
    WHEN TOO_MANY_ROWS THEN            
         v_civ_varios  := v_civ_varios+1;
          v_civ  :='0';
          DBMS_OUTPUT.PUT_LINE('NO: ' ||rec.COD_INE|| ' '|| rec.via_nombre  || rec.via_numero  || ' blo'||rec.BLOQUE || ' '|| rec.PLANTA || ' '|| rec.Puerta);  
          
        END;  
        IF v_civ  <>  '0' THEN
          v_encontrado:=v_encontrado+1;
          
          insert into temp_inmueble_rf
  (dboid, civ)
values
  (rec.dboid, v_civ);
     /*   ELSE
          
             
          Begin
             SELECT civ
        INTO v_civ 
        FROM temp_inmuebles t
        WHERE t.cvia_ine  =rec.COD_INE
          AND lpad(t.numer,4,'0') = rec.VIA_NUMERO
          AND (t.esc = rec.BLOQUE OR rec.BLOQUE is null)
          AND (t.plan = rec.PLANTA OR rec.PLANTA IS NULL)
          AND (t.puer = rec.puerta OR rec.puerta IS NULL) and rownum<2;
           EXCEPTION
         WHEN NO_DATA_FOUND THEN           
             v_civ  :='0';
        WHEN TOO_MANY_ROWS THEN            
             v_civ_varios  := v_civ_varios+1;
              v_civ  :='0';
                 END;  
               IF v_civ  <>  '0' THEN
                        v_encontrado:=v_encontrado+1;
                        
                        insert into temp_inmueble_rf
                (dboid, civ)
              values
                (rec.dboid, v_civ);  
  
                 END IF;    */
          
        END IF;
        
                
        
    END LOOP;
    
    
            DBMS_OUTPUT.PUT_LINE('Encontrados: ' ||v_encontrado);  
            DBMS_OUTPUT.PUT_LINE('Repetidos: ' ||v_civ_varios);  
commit;
END  A_actualizar_REFENCIA_CATASTRAL;
/

