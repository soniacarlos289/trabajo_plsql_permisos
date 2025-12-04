CREATE OR REPLACE PROCEDURE RRHH.A_buscar_REFENCIA_CATASTRAL IS
    CURSOR c_viviendas IS
        SELECT o.dboid,0 as COD_INE, o.via_sigla,o.via_nombre,
           lpad(o.VIA_NUMERO,4,'0') as VIA_NUMERO,
            --   DECODE(replace(FBLOCK, ' ',null),null,o.escalera,FBLOCK) AS BLOQUE,
                 DECODE( replace(o.FBLOCK, ' ',null),null,o.escalera, replace(o.FBLOCK, ' ',null)) AS BLOQUE,          
               DECODE(lpad(replace(o.PLANTA,'P'),4,'0'),'0BAJ','0000','00BJ','0000')   AS PLANTA,
               lpad(o.puerta,4,'0') AS PUERTA
      FROM temp_vivienda_mytao_final o
      where  (length(o.indicador_libre)<15 or  o.indicador_libre is null ) and rownum<10000
        -- and (planta is null or planta='PBJ' or planta='BAJ') 
      
       --and rownum<1000
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
             select distinct t.referencia_catastral
              INTO v_civ
              from  temp_catastro_origen t where uso='V'  and referencia_catastral is not null
                       AND lpad(t.numero,4,'0') = rec.VIA_NUMERO
                       AND (nvl(t.bloque, ' ') = rec.BLOQUE OR rec.BLOQUE is null)
                       AND (t.planta= rec.PLANTA OR rec.PLANTA IS NULL)
                       AND (t.puerta=rec.puerta OR rec.puerta IS NULL) and rownum<2;
          
      
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
END A_buscar_REFENCIA_CATASTRAL;
/

