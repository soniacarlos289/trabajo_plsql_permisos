create or replace procedure rrhh.CHEQUEA_FUNCIONARIO_DIARIO  (   V_ID_FUNCIONARIO in varchar2)
is

  i_id_funcionario    number;
  i_id_funcionario2   number;
  i_puesto           varchar2(3000);
  i_tipo_funcionario2 number;
  i_nombre            varchar2(3000);
  i_ape1              varchar2(3000);
  i_ape2              varchar2(3000);

  i_dni               varchar2(30);
  i_fecha_baja        DATE;
  i_ficha             number;
  i_codpers           varchar(6);
  v_codigo            varchar(5);
  i_inserta           number;
  i_cuerpo            varchar2(30000);
  v_fecha_ingreso     date;
  v_fecha_fin_contrato date;
  
  --Funcionarios en activo   
  CURSOR C1 is
     select distinct id_funcionario,
           puesto,
          nvl(tipo_funcionario2, 0),
          
           nombre,
           ape1,
           ape2,          
           nvl(fecha_baja, to_Date('01/01/2050', 'dd/mm/yyyy')),
           dni,fecha_ingreso,fecha_fin_contrato
      from personal_new
     where (fecha_baja is null or
           (fecha_baja > sysdate and
           fecha_baja < to_date('01/01/2090', 'dd/mm/yyyy')))
       and tipo_funcionario2=10
        and (
         (id_funcionario   =   V_ID_FUNCIONARIO  AND fecha_ingreso > sysdate-15
         )
          OR 
         ( '0'= V_ID_FUNCIONARIO AND     fecha_ingreso > sysdate-15 ) 
         )
     --    and (id_funcionario   =    962830)       
     order by 1 desc;
   
Begin
  i_cuerpo  := '';
  i_inserta := 0;
  --abrimos cursor.
  OPEN C1;

  LOOP
    FETCH C1
      into i_id_funcionario,
           i_puesto,
           i_tipo_funcionario2,
           i_nombre,
           i_ape1,
           i_ape2,
        
           i_fecha_baja,
           i_dni, v_fecha_ingreso   ,
           v_fecha_fin_contrato;
    EXIT WHEN C1%NOTFOUND;
   DBMS_OUTPUT.PUT_LINE(i_tipo_funcionario2 );
    --TIPO FUNCIONARIO
    IF i_tipo_funcionario2 <> 0 then
     DBMS_OUTPUT.PUT_LINE( 'envio correo' );
       I_ID_FUNCIONARIO2 := 1;
      --buscamos en la tabla apliweb.usuario
      BEGIN
        SELECT distinct u.id_fichaje
          into i_codpers
          FROM personal_new p, apliweb_usuario u
         WHERE p.id_funcionario = I_ID_FUNCIONARIO
           and lpad(p.id_funcionario, 6, 0) = lpad(u.id_funcionario, 6, 0)
           and rownum < 2;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          I_ID_FUNCIONARIO2 := 0;
      END;
      
      
      --error no esta en tabla apliweb.usuario
      IF I_ID_FUNCIONARIO2 = 0 THEN
        i_cuerpo  :=  chr(10) || ' Funcionario : ' ||
                     i_id_funcionario || ' ' || i_Nombre || ' ' || i_ape1 || ' ' ||
                     i_ape2;
        i_inserta := i_inserta + 1;
      
        envio_correo('noresponda@aytosalamanca.es',
                     'carlos@aytosalamanca.es',
                     '',
                     'No esta en el APLIWEB.usuario',
                     i_cuerpo);
      
      ELSE
      
        --Comprobamos esta en la tabla funcionario_firma
        i_id_funcionario2 := 1;
        BEGIN
          SELECT distinct id_funcionario
            into i_id_funcionario2
            FROM funcionario_firma
           WHERE id_funcionario = I_ID_FUNCIONARIO
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
      
        IF I_ID_FUNCIONARIO2 = 0 THEN
            i_id_funcionario2 := 1;
         Begin
            insert into funcionario_firma
              (id_funcionario,
               id_js,
               id_delegado_js,
               id_ja,
               id_delegado_ja,
               id_usuario,
               fecha_modi,
               id_ver_plani_1,
               id_ver_plani_2,
               id_ver_plani_3,
               id_delegado_firma)
            values
              (I_ID_FUNCIONARIO,
               0,
               I_ID_FUNCIONARIO,
               0,
               '',
               101217,
               sysdate,
               '',
               '',
               '',
               0);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
             DBMS_OUTPUT.PUT_LINE( 'envio correo' );
             envio_correo('noresponda@aytosalamanca.es',
                     'carlos@aytosalamanca.es',
                     '',
                     'Incluir firmas para funcionario '|| I_ID_FUNCIONARIO ,
                     'Incluir firmas para funcionario '|| I_ID_FUNCIONARIO );
      
          
        END IF;
      
        --Comprobamos esta en la tabla horas_extras_ausencias para las horas extras
        i_id_funcionario2 := 1;
        BEGIN
          SELECT distinct id_funcionario
            into i_id_funcionario2
            FROM horas_extras_ausencias
           WHERE id_funcionario = I_ID_FUNCIONARIO
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
      
        IF I_ID_FUNCIONARIO2 = 0 and I_ID_FUNCIONARIO > 10000 THEN
        
          Begin
            insert into horas_extras_ausencias
              (id_ano, id_funcionario, total, utilizadas)
            values
              (2003, I_ID_FUNCIONARIO, 0, 0);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
          
        END IF;
      
        --Comprobamos esta en la tabla BOLSA_FUNCIONARIO
        i_id_funcionario2 := 1;
        BEGIN
          SELECT distinct id_funcionario
            into i_id_funcionario2
            FROM bolsa_FUNCIONARIO
           WHERE id_funcionario = I_ID_FUNCIONARIO
             and ID_ANO = 2020
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
      
       IF I_ID_FUNCIONARIO2 = 0 and I_ID_FUNCIONARIO > 10000 AND
           (i_tipo_funcionario2 = 10 OR i_tipo_funcionario2 = 40) THEN
                        dbms_OUTPUT.PUT_LINE('Funcionario sin bolsa ' ||  I_ID_FUNCIONARIO);
         Begin
            insert into bolsa_funcionario
              (id_funcionario,
               id_ano,
               dt_start,
               dt_end,
               horas_faltan_exceso,
               horas_productividad,
               id_approle,
               id_secuser,
               dt_last_update,
               tope_horas,
               id_acumulador,
               penal_enero,
               penal_febrero,
               penal_marzo,
               penal_abril,
               penal_mayo,
               penal_julio,
               penal_agosto,
               penal_septiembre,
               penal_octubre,
               penal_noviembre,
               penal_diciembre,
               penal_junio,
               maximo_alcanzado,
               id_usuario,
               fecha_modi,
               penal_enero_mas,
               id_registro)
            values
              (I_ID_FUNCIONARIO,
               2022,
               to_date('05/02/2022', 'DD/mm/YYYY'),
               to_date('05/02/2023', 'DD/mm/YYYY'),
               '',
               '',
               '',
               '',
               sysdate,
               47,
               1,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               0,
               101217,
               sysdate,
               0,
               sec_id_bolsa.nextval);
          
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
          
        END IF;
      
        --Comprobamos las vacaciones 
        i_id_funcionario2 := 1;
        BEGIN
          SELECT distinct id_funcionario
            into i_id_funcionario2
            FROM permiso_funcionario
           WHERE id_funcionario = I_ID_FUNCIONARIO
             and ID_ANO = to_char(sysdate, 'yyyy')
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
      
        IF I_ID_FUNCIONARIO2 = 0 THEN
          i_id_funcionario2 := 1;
          BEGIN
            SELECT distinct id_funcionario
              into i_id_funcionario2
              FROM permiso
             WHERE id_funcionario = I_ID_FUNCIONARIO
               and ID_ANO = to_char(sysdate, 'yyyy')
               and rownum < 2
               and (ANULADO = 'NO' OR ANULADO is null);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              i_id_funcionario2 := 0;
          END;
        
          IF I_ID_FUNCIONARIO2 = 0 THEN
            dbms_OUTPUT.PUT_LINE('Funcionario sin vacaciones ' ||  I_ID_FUNCIONARIO);
            calcula_permisos_los_anios( I_ID_FUNCIONARIO,    to_char(sysdate,'yyyy'));
          
          END IF;
        
        END IF;
        
        --FICHAJES
        --Comprobamos esta en la tabla funcionario_fichaje   
        i_id_funcionario2 := 1;
        BEGIN
          SELECT distinct id_funcionario
            into i_id_funcionario2
            FROM funcionario_fichaje
           WHERE id_funcionario = I_ID_FUNCIONARIO
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
        --insertamos en la tabla si no esta.
        IF i_id_funcionario2 = 0 THEN
          Begin
            insert into funcionario_fichaje
              (id_funcionario,
               id_tipo_fichaje,
               id_usuario,
               fecha_modi,
               pin,
               codpers)
            values
              (i_id_funcionario,
               0,
               '101115',
               sysdate,
               substr(lpad(i_codpers, 5, '0'), 2,4),
               lpad(i_codpers, 5, '0'));
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
        END IF;
        
        --FICHAJES ALERTAS
        --Comprobamos esta en la tabla fichaje_funcionario_alertas  
        i_id_funcionario2 := 1;
        BEGIN
          SELECT distinct id_funcionario
            into i_id_funcionario2
            FROM fichaje_funcionario_alerta
           WHERE id_funcionario = I_ID_FUNCIONARIO
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
        --insertamos en la tabla si no esta.
        IF i_id_funcionario2 = 0 THEN
            dbms_OUTPUT.PUT_LINE('Funcionario sin alertas ' ||  I_ID_FUNCIONARIO);
          Begin
            insert into fichaje_funcionario_alerta
                 (id_funcionario, sin_alertas, alerta_0, alerta_1, alerta_2, alerta_3, alerta_4, alerta_5, alerta_6, alerta_7, alerta_8, alerta_9, alerta_10, alerta_11, alerta_12, alerta_13, alerta_14, alerta_15, audit_usuario, audit_fecha)
               values
                 (I_ID_FUNCIONARIO, 1,1,1, 1,1,1,1,1,1,1,1,
                                    1,1,1, 1,1,1
                 
                  , 101217, sysdate);         
        
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
        END IF;
        
        
     
        --FICHAJES JORNADA
        --Comprobamos esta en la tabla funcionario_fichaje   
        i_id_funcionario2 := 1;
        BEGIN
        select distinct id_funcionario
            into i_id_funcionario2
        from FICHAJE_FUNCIONARIO_JORNADA where
            sysdate between fecha_inicio and nvl(fecha_fin,sysdate+5) 
            and  id_funcionario = I_ID_FUNCIONARIO
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
        --insertamos en la tabla si no esta.
        IF i_id_funcionario2 = 0 THEN
          Begin
             dbms_OUTPUT.PUT_LINE('Funcionario sin jornada ' ||  I_ID_FUNCIONARIO);
           insert into fichaje_funcionario_jornada
           (id_funcionario, id_calendario, fecha_inicio, fecha_fin, horas_semanales, reduccion, horas_jornada, dias, contar_comida, libre, audit_usuario, audit_fecha, bolsa)
            values
            (I_id_funcionario,1,v_fecha_ingreso, V_fecha_fin_contrato, 37,0, to_date('01/01/1900 7:00:00','dd/mm/yyyy hh24:mi:ss')
           , 5, 'NO', 'NO', 101217, sysdate, 1);
                                                                     
        
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
        END IF;
        
             
        --FICHAJE_FUNCIONARIO_RELOJ
        --Comprobamos esta en la tabla funcionario_fichaje   
        i_id_funcionario2 := 1;
        BEGIN
        select distinct id_funcionario
            into i_id_funcionario2
        from FICHAJE_FUNCIONARIO_RELOJ 
        where id_funcionario = I_ID_FUNCIONARIO
             and rownum < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2 := 0;
        END;
        --insertamos en la tabla si no esta.
        IF i_id_funcionario2 = 0 THEN
          Begin
                     insert into fichaje_funcionario_reloj
                     (id_sec_func_reloj, id_funcionario, relojes, audit_usuario, audit_fecha)
                   values
                     (id_sec_fun_reloj.nextval, I_id_funcionario, 10,101217, sysdate);                                                                    
        
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
          Begin
                     insert into fichaje_funcionario_reloj
                     (id_sec_func_reloj, id_funcionario, relojes, audit_usuario, audit_fecha)
                   values
                     (id_sec_fun_reloj.nextval, I_id_funcionario, 17,101217, sysdate);                                                                    
        
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
          Begin
                     insert into fichaje_funcionario_reloj
                     (id_sec_func_reloj, id_funcionario, relojes, audit_usuario, audit_fecha)
                   values
                     (id_sec_fun_reloj.nextval, I_id_funcionario, 18,101217, sysdate);                                                                    
        
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              i_inserta := 0;
          END;
          
              
        END IF;--
        
       i_id_funcionario2 := 1;
    
      
      --si no es un bombero no ficha
      if  i_tipo_funcionario2 <> 23 AND I_ID_FUNCIONARIO2>0  then
         
         --Comprobación si esta en finger.  
        --El funcionario Ficha ??    
        i_ficha:=1;   
        
        BEGIN
          SELECT  
            distinct nvl(codigo,0)
            into i_codpers
          FROM 
            personal_new p  ,persona pr, 
            apliweb_usuario u
          WHERE 
            p.id_funcionario=I_ID_FUNCIONARIO  and
            lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and --cambiado 29/03/2010            
            (u.id_fichaje=pr.codigo   OR
             lpad(u.dni,8,'0')=lpad(pr.dni,8,'0')) and
            rownum <2; 
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             i_codpers:=0;  
        END;
        --no esta en la tabla lo tengo que insertalo
        --la policia se da de alta con su numero de policia

        
        IF i_codpers=0 THEN
        
        begin
         SELECT  
            distinct nvl(codigo,0)
            into i_codpers
          FROM 
           persona pr           
          WHERE 
               lpad(i_dni,8,'0')=lpad(pr.dni,8,'0') and               
            rownum <2; 
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             i_codpers:=0;  
        END;
        END IF;
           dbms_OUTPUT.PUT_LINE('Funcionario  esta en la tabla de omesa ' ||  I_ID_FUNCIONARIO  || ' '|| i_codpers);
       -- i_codpers:=0; 
        i_id_funcionario2:=1;
        BEGIN
         select 1
         into i_id_funcionario2
           from  funcionario_fichaje 
           where  id_tipo_fichaje=9 and id_funcionario=I_ID_FUNCIONARIO and rownum<2;  
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             i_id_funcionario2:=0;  
        END;  
           
       
          v_codigo:=NULL;
                                                         --0
        IF    i_tipo_funcionario2 <> 23-- and i_id_funcionario2=0
            and i_codpers=0 then   
          
          --obtengo un numero de fichaje
         v_codigo:=numero_fichaje_persona;
        -- v_codigo:='4196';
          dbms_OUTPUT.PUT_LINE('Funcionario no esta en la tabla de omesa ' ||  I_ID_FUNCIONARIO  || ' '||v_codigo);
          --INSERTAMOS EN LA TABLA DE OMESA
         BEGIN 
            insert into persona
              (codigo, apellidos, nombre, dni, nss, telefono, domicilio, codpostal, poblacion, provincia,  lugarnac, sexo, empresa, departamento, seccion, categoria, centro, situacion, altasn, horflex, calendario, semana, fechainicio, numtarjeta, ajustecierreautfich, fechabaja, vissalacu, cierrefich, incdiaact, cambioturno, tipofich, fechacambio, fechatomapos, numope, passwd, taqsn, trabsn, admsn, tag, tipcard, foto, ctacont, prefijo1, prefijo2, perfcal, perffes, saltargenpres, obsweb, facvalinci, huella, gesemp, resemp, usuemp, gesdep, resdep, usudep, gessec, ressec, ususec, gesneg, resneg, usuneg, gescen, rescen, usucen, telmovil, email, topeañoccursos, topeañocdedicacion, topeañochextra, topeañocotros1, topeañocotros2, obsgen, fecmod, sitant, sitnue, calidadpatron, numtarjeta2)
            values
              (lpad(v_codigo,5,'0'), i_ape1 || ' '|| i_ape2, i_nombre, i_dni, '' , '','','','','','', 'V','000001','000002','000001','00000000','0000000000','000001','-1', '-1', '002',  '1',  to_date(to_char(sysdate+1,'dd/mm/yyyy'),'dd/mm/yyyy'),  lpad(v_codigo,4,'0'),  'O',  i_fecha_baja , 'S',  'N',  '', '0',  '', '', '',   '', lpad(v_codigo,5,'0'),  '0',  '0',  '0',  '0', '', '', '', '', '', '', '',  '0', '', '', '',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0',  '0', '', '',  '0',  '0',  '0',  '0',   '0', '', '', '', '', '0',  '');
          EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                  i_inserta := 0;
          END; 
        commit;
           i_cuerpo  :=  chr(10) || ' Capturar huella en los terminales de --> ' ||chr(10) || ' Funcionario : ' ||
                     i_id_funcionario || ' ' || i_Nombre || ' ' || i_ape1 || ' ' ||
                     i_ape2 || ' ' || 'Número de fichaje:' || lpad(v_codigo,4,'0') ;
        i_inserta := i_inserta + 1;
      
       envio_correo('carlos@aytosalamanca.es',
                     'carlos@aytosalamanca.es',
                     '',
                     'Funcionario nuevo hay que recoger la huella con el siguiente número',
                     i_cuerpo);
             
       envio_correo('carlos@aytosalamanca.es',
                     'spallares@aytosalamanca.es',
                     '',
                     'Funcionario nuevo hay que recoger la huella con el siguiente número',
                     i_cuerpo);
        
        
         envio_correo('carlos@aytosalamanca.es',
                     'cpelaez@aytosalamanca.es',
                     '',
                     'Funcionario nuevo hay que recoger la huella con el siguiente número',
                     i_cuerpo);
                     
                     BEGIN
                       update funcionario_fichaje 
                       set pin=v_codigo,codpers=lpad(v_codigo,5,'0')
                        where   id_funcionario=I_ID_FUNCIONARIO and rownum<2;  
                    EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                      i_id_funcionario2:=0;  
                       END;  
        
                   END IF;
           If v_codigo is null then
               v_codigo :=i_codpers;
            End if;
      
            --POR SI ACASO ES NULO
          BEGIN
                       update apliweb_usuario
                       set id_fichaje=lpad(v_codigo,5,'0')
                        where   id_funcionario=I_ID_FUNCIONARIO and rownum<2 and id_fichaje is null;  
                    EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                      i_id_funcionario2:=0;  
                       END;  
    
        
        --Comprobamos esta en la tabla funcionario_fichaje   
         i_id_funcionario2:=1;
         BEGIN
          SELECT  
            distinct id_funcionario
            into i_id_funcionario2
          FROM  funcionario_fichaje   
          WHERE id_funcionario=I_ID_FUNCIONARIO and  rownum <2; 
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_funcionario2:=0;  
         END;
         --insertamos en la tabla si no esta.
         IF  i_id_funcionario2 = 0 THEN  
          Begin
           insert into funcionario_fichaje
             (id_funcionario, id_tipo_fichaje, id_usuario, fecha_modi, pin, codpers)
           values
             (i_id_funcionario,0, '101115',sysdate, lpad(v_codigo,4,'0'), lpad(v_codigo,5,'0'));
          EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
                 i_inserta := 0;
          END;          
         END IF;    
      end if;--fin fichaje comprobacion
        
    
    END IF; --No esta en la tabla apliweb
  END IF; --tipo funcionario

END LOOP; CLOSE C1;

   commit;
end CHEQUEA_FUNCIONARIO_DIARIO;
/

