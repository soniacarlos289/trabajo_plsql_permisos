CREATE OR REPLACE PROCEDURE RRHH."FIRMA_AUSENCIA_JSA"
       (V_ID_FIRMA in varchar2,
        V_ID_FUNCIONARIO_FIRMA in number,
        V_ID_AUSENCIA in number,
        V_ID_MOTIVO in  VARCHAR2,
        todo_ok_Basico out integer,msgBasico out varchar2) is

i_no_hay_ausencias number;
i_no_hay_firma number;
i_id_funcionario varchar2(6);
 i_firma varchar2(256);
i_id_estado varchar2(2);
i_id_js varchar2(6);
i_id_delegado_js varchar2(6);
   i_id_delegado_js2    varchar2(6);
      i_id_delegado_js3    varchar2(6);
        i_id_delegado_js4    varchar2(6);
i_id_ja varchar2(6);
i_id_delegado_ja  varchar2(6);
i_id_delegado_firma number;


i_DESC_TIPO_AUSENCIA varchar2(512);
i_CADENA2 varchar2(512);

correo_v_funcionario varchar2(512);
i_nombre_peticion varchar2(512);
correo_js varchar2(512);
correo_ja varchar2(512);
i_sender varchar2(256);
 i_recipient varchar2(256);
 I_ccrecipient varchar2(256);
 i_subject varchar2(256);
 I_message varchar2(15120);
 i_id_ano number(4);
 i_dias number(4);
 i_desc_mensaje varchar2(15120);
 v_id_tipo_ausencia varchar2(3);
 i_contador number;
 v_fecha_inicio date;
 v_fecha_fin date;
 V_HORA_INICIO varchar2(5);
 V_HORA_FIN varchar2(5);
 V_TOTAL_HORAS number;
 v_tipo_funcionario varchar2(6);
begin

todo_ok_basico:=0;
msgBasico:='';

--Compruebo que el permiso esta en la tabla
i_no_hay_ausencias:=0;
BEGIN
    select total_horas,substr(to_char(a.FECHA_INICIO,'DD/MM/YYYY HH24:MI'),12,5) as HORA_INICIO,
           substr(to_char(a.FECHA_FIN,'DD/MM/YYYY HH24:MI'),12,5) as  HORA_FIN,a.FECHA_INICIO,a.fecha_fin,a.id_tipo_ausencia,
    a.id_ano,a.id_estado,id_funcionario,DESC_TIPO_AUSENCIA
    into V_TOTAL_HORAS,V_HORA_INICIO,V_HORA_FIN,v_fecha_inicio,v_fecha_fin,v_id_tipo_ausencia,
    i_id_ano,i_id_estado,i_id_funcionario,i_DESC_TIPO_AUSENCIA
    from ausencia a,tr_tipo_ausencia  tr
    where id_ausencia=v_id_ausencia and
          a.id_tipo_ausencia=tr.id_tipo_ausencia and
          (anulado='NO' OR ANULADO IS NULL);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         i_no_hay_ausencias:=-1;
END;


i_cadena2:='Fecha Ausencia: ' || to_char(V_FECHA_INICIO,'DD-MON-YY') ||  chr(10)||'Hora de Inicio:     ' || V_HORA_INICIO ||  chr(10)||'Hora Fin: ' || V_HORA_FIN;

IF  i_no_hay_ausencias = -1 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Ausencia no existe.';
             RETURN;
END IF;
--chm 10/02/2017
 --Compruebo el tipo de funcionario de la solicitud
 v_tipo_funcionario:=10;
  BEGIN
    select tipo_funcionario2
      into v_tipo_funcionario
      from personal_new pe
     where id_funcionario = i_id_funcionario  and rownum<2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_tipo_funcionario:=-1;
  END;

  IF v_tipo_funcionario = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
-- CHM 10/02/2017
-- NO ES bombero
-- CHM 10/02/2017
-- NO ES bombero
IF v_tipo_funcionario <> '23' then

  --Busco que la persona que firma sea la correcta
  BEGIN
    select id_js, id_delegado_js, id_ja, id_delegado_ja ,id_delegado_firma, id_delegado_js2,id_delegado_js3,id_delegado_js4
      into i_id_js, i_id_delegado_js, i_id_ja, i_id_delegado_ja
           ,i_id_delegado_firma --añadido 31 mayo 2016. Para poder firmar 2
           ,i_id_delegado_js2,i_id_delegado_js3,i_id_delegado_js4
      from funcionario_firma
     where id_funcionario = i_id_funcionario
       and (id_JS = V_ID_FUNCIONARIO_FIRMA OR
           id_DELEGADO_JS = V_ID_FUNCIONARIO_FIRMA OR
           id_DELEGADO_JS2 = V_ID_FUNCIONARIO_FIRMA OR
           id_DELEGADO_JS3 = V_ID_FUNCIONARIO_FIRMA OR
           id_DELEGADO_JS4 = V_ID_FUNCIONARIO_FIRMA OR
           id_JA = V_ID_FUNCIONARIO_FIRMA OR
           id_DELEGADO_JA = V_ID_FUNCIONARIO_FIRMA);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_firma := -1;
  END;
  ----añadido 31 mayo 2016. Para poder firmar cualquiera de los 2. Por ahora solo policias.
  ------ID_DELEGADO_FIRMA---------------------------------------
  ------ 0 Permite firma al delegado cuando el titular no esta
  ------ 1 Permite firmar siempre
  ----------------------------------------------------------------
  --Meter Sustituto.
  IF (i_id_delegado_js = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js) OR
     (i_id_delegado_js2 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js2) OR
     (i_id_delegado_js3 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js3) OR
     (i_id_delegado_js4 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js4)
    THEN

  --a?adido el 5 de Abril 2010. Funcion nueva /*delegado
  i_contador:= chequeo_entra_delegado(i_id_delegado_js);

    IF i_contador = 0 and i_id_delegado_firma= 0 then ----añadido 31 mayo 2016. Para poder firmar cualquiera de los  2
      todo_ok_basico := 1;
      msgBasico      := 'Operacion no realizada. La delegacion de permisos solo es efectiva cuando el responable esta de Permiso.';
      RETURN;
    ELSE
       -- i_id_js := i_id_delegado_js;
       IF i_id_delegado_js = V_ID_FUNCIONARIO_FIRMA THEN
          i_id_js := i_id_delegado_js;
       ELSE IF   i_id_delegado_js2 = V_ID_FUNCIONARIO_FIRMA          THEN
               i_id_js := i_id_delegado_js2;
            ELSE IF   i_id_delegado_js3 = V_ID_FUNCIONARIO_FIRMA          THEN
                              i_id_js := i_id_delegado_js3;
                 ELSE IF   i_id_delegado_js4 = V_ID_FUNCIONARIO_FIRMA          THEN
                                           i_id_js := i_id_delegado_js4;
                      END IF;
                 END IF;
            END IF   ;
       END IF;
     END IF;
  END IF;

  IF i_no_hay_firma = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. No hay personas para firmar.';
    RETURN;
  END IF;


--Buscamos el correo en la usuario.intranet.
BEGIN
    select MIN(peticion), MIN(nombre_peticion),MIN(js),MIN(ja)
    into correo_v_funcionario,i_nombre_peticion,correo_js,correo_ja

 from (
     select login || '@aytosalamanca.es' as peticion,substr(  DIST_NAME,  INSTR(DIST_NAME,'=',1) +1,INSTR(DIST_NAME,',',1) -INSTR(DIST_NAME,'=',1)-1) as nombre_peticion,''as js ,'' as ja from apliweb_usuario where id_funcionario=to_char(I_ID_FUNCIONARIO)
     union
     select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js,'' as ja  from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0')
      union
    select '' as peticion ,'' as nombre_peticion ,'' as ja,login || '@aytosalamanca.es' as ja from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_ja,6,'0')
);
EXCEPTION
                        WHEN NO_DATA_FOUND THEN
i_id_ja:='';
i_id_js:='';
END;

--Si No hay jefes para firmar el permiso.
IF   i_id_js='' AND i_id_ja='' then
        todo_ok_basico:=1;
        msgBasico:='Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
        RETURN;
END IF;

ELSE
  --añadido chm 25/02/2017
  --BUSQUEDA FIRMA BOMBEROS
  --añadir la función
  i_id_ja:='0';
  i_id_js:='0';
  correo_js:='';
  correo_ja:='';
  -- chm16/09/2022
  --cambio    bomberos_guardias_plani s, eliminar ddblink
  --Comprobamos que esta el jefe de guardia. JA LUIS DAMIAN 961110 ldramos@aytosalamanca.es
  BEGIN --login
    select 'carlos' || '@aytosalamanca.es',lpad(funcionario,6,'0'),'961110','ldramos@aytosalamanca.es'
     into correo_js,i_id_js,i_id_ja,correo_ja
    from     bomberos_guardias_plani s,
         --sige.GUARDIAS@lsige s,

           apliweb_usuario a
    where desde =DECODE( trunc(to_char(sysdate+0/24,'hh24')/8),0,
        to_date(to_char(sysdate-1,'DD/mm/yyyy') || '08:00','DD/mm/yyyy hh24:mi'),
        to_date(to_char(sysdate,'DD/mm/yyyy')   || '08:00','DD/mm/yyyy hh24:mi')

         ) and dotacion='M' and lpad(funcionario,6,'0')=lpad(V_ID_FUNCIONARIO_FIRMA,6,'0')
         and s.funcionario=a.id_funcionario
         and rownum<2;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_id_js:='0';
  END;



  --chm 10/05/2018
  IF V_ID_FUNCIONARIO_FIRMA='961110'   THEN
    i_id_ja:='961110';
    correo_ja:='ldramos@aytosalamanca.es';
  END IF;

  IF V_ID_FUNCIONARIO_FIRMA='600077'  THEN
    i_id_ja:='600077';
    correo_ja:='afiz@aytosalamanca.es';
  END IF;

  IF  i_id_js='0' AND i_id_ja='0' then
        todo_ok_basico:=1;
        msgBasico:='No coincide el jefe de la guardia actual con la persona que firma el permiso.';
        RETURN;
  END IF;

  IF  i_id_js='0' AND i_id_ja='0' then
        todo_ok_basico:=1;
        msgBasico:='No coincide el jefe de la guardia actual con la persona que firma el permiso.';
        RETURN;
  END IF;


--nombre petición y correo
--chm 12/02/2017
BEGIN
select  MIN(correo_funcionario) ,MIN(nombre_peticion)
    into correo_v_funcionario,i_nombre_peticion
 from (
     select login || '@aytosalamanca.es' as correo_funcionario ,TRIM(substr(dist_NAME,4,instr(dist_NAME,',',1)-4)) as nombre_peticion from apliweb_usuario
    where lpad(id_funcionario,6,'0')=lpad(to_char(I_ID_FUNCIONARIO),6,'0')
      );

EXCEPTION
     WHEN NO_DATA_FOUND THEN
     correo_v_funcionario:='';
END;



END IF;--FIN NO ES BOMBERO


--Actualizar ausencias
IF ( (i_id_estado =20 AND V_ID_FUNCIONARIO_FIRMA=I_ID_JS) OR
     (i_id_estado =20 AND V_ID_FUNCIONARIO_FIRMA=I_ID_JA)
       OR (i_id_estado =21  AND v_tipo_funcionario = '23' ) --chm 10/02/2017
   )  then --Firma JS

    --chm 10/02/2017
    if (i_id_estado = 20 and v_tipo_funcionario = '23') then
       i_id_estado:=21;
    else
       --Firma JS
       i_id_estado:=22;
    end if;

            IF V_ID_FIRMA=1 THEN --AUTORIZADO

               if ((i_id_estado = 22  and v_tipo_funcionario <> '23') OR i_id_estado=21 ) then

                update ausencia
                set    id_estado=22  ,firmado_js=V_ID_FUNCIONARIO_FIRMA,FECHA_JS=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;

              End if;

              if (i_id_estado = 22  and v_tipo_funcionario ='23')  then

                     update ausencia
                set    id_estado=22  ,
                       firmado_ja = V_ID_FUNCIONARIO_FIRMA,
                       FECHA_Ja   = SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;
              END IF;

              --ENVIO DE CORREO AL JEFE DE AREA
              i_sender      := correo_js;
              I_ccrecipient := '';
              i_recipient   := correo_ja;
              I_message := '';


             i_firma := 'Operacion realizada. El permiso esta pendiente del VºBº de RRHH.';

             --chm 10/02/2017
             --Envio correo al ja, para el 2º nivel.
              if (i_id_estado = 21 and v_tipo_funcionario = '23') then


                   i_firma := 'Operacion realizada. El permiso esta pendiente del VºBº Jefe de Bomberos.';
                    I_message:=
                            'Esta Ausencia ha sido Autorizado por el Jefe de Serv' || chr(10)||
                            'Necesita su autorizacion para que sea concedido.' || chr(10)||  chr(10)||
                            'Solicitud de Permiso de: '|| i_nombre_peticion || chr(10)||
                            'Tipo permiso: '  || i_DESC_TIPo_AUSENCIA || chr(10)||
                             i_CADENA2;

                            envio_correo(i_sender ,
                                         i_recipient ,
                                         I_ccrecipient ,
                                         i_subject  ,
                                         I_message);
               end if;


               I_message:= i_desc_mensaje;
                i_subject:='Informacion de permiso autorizado.';
                 /*envio_correo(i_sender ,
                              i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message);*/

                 --Insert en el historico
                 insert into historico_operaciones
                        values(sec_operacion.nextval,
                                V_ID_AUSENCIA ,
                               20,
                               i_id_ano,
                               V_ID_FUNCIONARIO_FIRMA,
                              to_char(sysdate,'DD/MM/YYYY'),
                               to_char(sysdate,'HH:MI'),
                               'FIRMA PERMISO JSA',
                               V_ID_FUNCIONARIO_FIrMA,
                               to_char(sysdate,'DD/MM/YYYY'));



            ELSE  IF V_ID_FIRMA=0 THEN --denegado
              IF  ( '961110' <> V_ID_FUNCIONARIO_FIRMA OR v_tipo_funcionario <>'23') THEN

               update ausencia
                set    id_estado=30  ,firmado_js=V_ID_FUNCIONARIO_FIRMA,motivo_denega=V_ID_MOTIVO,FECHA_JS=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;
              ELSE
                  update ausencia
                set    id_estado=31  ,firmado_ja=V_ID_FUNCIONARIO_FIRMA,motivo_denega=V_ID_MOTIVO,FECHA_Ja=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;



              END IF;


                 --ENVIO DE CORREO AL FUNCIONARIO CON LA DENEGACION
                 i_sender:=correo_js;
                 I_ccrecipient:='';
                 i_recipient:=correo_v_funcionario;
                 I_message:= 'Denegacion de la Solicitud del Permiso' || chr(10) ||
                             'Motivo de Denegacion: '|| v_id_motivo || chr(10)||
                             i_DESC_TIPo_AUSENCIA || chr(10)||
                             i_CADENA2;
               I_message:=    '';
               --Descripcion de la ausencia .
              BEGIN
              select CABECERA || ' '||
                     'Ausencia denegada por' ||' '|| v_id_motivo ||' '||
                         SOLICITADO || ' '||
                         i_nombre_peticion ||' '||
                         TIPO_PERMISO ||' '||
                         i_desc_tipo_ausencia||' '||
                         FECHA_INICIO  ||' '||
                         to_char(V_FECHA_INICIO,'DD-MON-YY')  ||' '||
                         DECODE(substr(V_ID_TIPO_AUSENCIA,1,1) ,'5',
                         FECHA_FIN  ||' '||
                         to_char(V_FECHA_FIN,'DD-MON-YY')
                          ,'') ||' '||
                         HORA_INICIO ||' '|| V_HORA_INICIO   ||' '||  --
                         HORA_FIN    ||' '|| V_HORA_FIN      || ' '|| --
                         TOTAL_HORAS ||' '||  lpad(trunc( v_total_horas/60 ),2,'0')  || ':'||
                         lpad(trunc( mod(v_total_horas,60 ) ),2,'0')  || ' '||
                       CABECERA_FI ||' '||
                      'Esta Ausencia ha sido denegada'||' '||
                      CABECERA_FIN_2
            into  i_desc_mensaje
                 from  FORMATO_CORREO
                 where DECODE( substr(V_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
                     )=ID_TIPO_PERMISO;
          EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   i_desc_tipo_ausencia:='';
          END;
                      I_message:= i_desc_mensaje;
                       --chm13/02/2017
                      -- 961110
           IF  ( '961110' = V_ID_FUNCIONARIO_FIRMA) THEN
                  i_subject := 'Denegacion de Permiso por el Jefe de Bomberos.';
                  i_sender:=correo_ja;
         ELSE  IF  v_tipo_funcionario ='23' then
                  i_subject := 'Denegacion de Permiso por el Jefe Guardia.';
               ELSE
                  i_subject := 'Denegacion de Permiso por el Jefe de Secc/Serv.';
               END IF;
         END IF;


                 envio_correo(i_sender ,
                              i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message);

                 --Insert en el historico
                 insert into historico_operaciones
                        values(sec_operacion.nextval,
                                V_ID_AUSENCIA ,
                               30,
                               i_id_ano,
                               V_ID_FUNCIONARIO_FIRMA,
                              to_char(sysdate,'DD/MM/YYYY'),
                               to_char(sysdate,'HH:MI'),
                               'FIRMA PERMISO JSA',
                               V_ID_FUNCIONARIO_FIrMA,
                               to_char(sysdate,'DD/MM/YYYY'));
                  i_firma:='Operacion realizada. La Ausencia se ha denegado correctamente.';

                   END IF;
             END IF;
--quitando un nivel
/* ELSE  IF (i_id_estado =21  AND V_ID_FUNCIONARIO_FIRMA=I_ID_JA) OR
         (i_id_estado =20  AND I_ID_JS = I_ID_JA)--Metido para cuando son misma persona.
          then  -- Firma JA
           IF V_ID_FIRMA=1 THEN --AUTORIZADO
              --Misma persona JEFE de Servicio y AREa
              IF I_ID_JS = I_ID_JA  THEN
                update ausencia
                set    id_estado=22  ,
                       firmado_ja=V_ID_FUNCIONARIO_FIRMA,
                       FECHA_JA=SYsDATE,
                       firmado_js=V_ID_FUNCIONARIO_FIRMA,
                       FECHA_JS=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;
               ELSE
                 update ausencia
                set    id_estado=22  ,firmado_ja=V_ID_FUNCIONARIO_FIRMA,
                          FECHA_JA=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;
               END IF;


                --Insert en el historico
                 insert into historico_operaciones
                        values(sec_operacion.nextval,
                                V_ID_AUSENCIA ,
                               21,
                               i_id_ano,
                               V_ID_FUNCIONARIO_FIRMA,
                              to_char(sysdate,'DD/MM/YYYY'),
                               to_char(sysdate,'HH:MI'),
                               'FIRMA PERMISO JSA',
                               V_ID_FUNCIONARIO_FIrMA,
                               to_char(sysdate,'DD/MM/YYYY'));

                i_firma:='Operacion realizada. La Ausencia esta pendiente del V?B? de RRHH';
            ELSE  IF V_ID_FIRMA=0 THEN --denegado
             --Misma persona JEFE de Servicio y AREa
              IF I_ID_JS = I_ID_JA  THEN
               update ausencia
                set    id_estado=31  ,
                       firmado_ja=V_ID_FUNCIONARIO_FIRMA,
                       firmado_js=V_ID_FUNCIONARIO_FIRMA,
                       motivo_denega=V_ID_MOTIVO,
                       FECHA_Js=SYsDATE,
                       FECHA_JA=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;
              ELSE
                 update ausencia
                set    id_estado=31  ,
                       firmado_ja=V_ID_FUNCIONARIO_FIRMA,
                       motivo_denega=V_ID_MOTIVO,
                       FECHA_JA=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_ausencia=V_id_ausencia and
                       rownum  < 2 ;
                --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;

              END IF;

                 --ENVIO DE CORREO AL FUNCIONARIO CON LA DENEGACION
                 i_sender:=correo_ja;
                 I_ccrecipient:=correo_js;
                 i_recipient:=correo_v_funcionario;
                 I_message:= 'Denegacion de solicitud de la Ausencia' || chr(10) ||
                             'Motivo de Denegacion: '|| v_id_motivo || chr(10)||
                             i_DESC_TIPo_Ausencia || chr(10)||
                             i_CADENA2;

                  I_message:=    '';
               --Descripcion del permiso .
              BEGIN
              select CABECERA || ' '||
                     'Ausencia denegada por' ||' '|| v_id_motivo ||' '||
                         SOLICITADO || ' '||
                         i_nombre_peticion ||' '||
                         TIPO_PERMISO ||' '||
                         i_desc_tipo_ausencia||' '||
                         FECHA_INICIO  ||' '||
                         to_char(V_FECHA_INICIO,'DD-MON-YY')  ||' '||
                         DECODE(substr(V_ID_TIPO_AUSENCIA,1,1) ,'5',
                         FECHA_FIN  ||' '||
                         to_char(V_FECHA_FIN,'DD-MON-YY')
                          ,'') ||' '||
                         HORA_INICIO ||' '|| V_HORA_INICIO   ||' '||  --
                         HORA_FIN    ||' '|| V_HORA_FIN      || ' '|| --
                         TOTAL_HORAS ||' '||  lpad(trunc( v_total_horas/60 ),2,'0')  || ':'||
                         lpad(trunc( mod(v_total_horas,60 ) ),2,'0')  || ' '||
                       CABECERA_FI ||' '||
                      'Esta Ausencia ha sido denegada'||' '||
                      CABECERA_FIN_2
                   into  i_desc_mensaje
                   from  FORMATO_CORREO
                   where DECODE( substr(V_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
                     )=ID_TIPO_PERMISO;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    i_desc_tipo_ausencia:='';
                   END;
                    I_message:= i_desc_mensaje;

                 i_subject:='Denegacion de la Ausencia por el Jefe de Area.';
                 envio_correo(i_sender ,
                              i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message);

                 --Insert en el historico
                 insert into historico_operaciones
                        values(sec_operacion.nextval,
                                V_ID_AUSENCIA ,
                               31,
                               i_id_ano,
                               V_ID_FUNCIONARIO_FIRMA,
                              to_char(sysdate,'DD/MM/YYYY'),
                               to_char(sysdate,'HH:MI'),
                               'FIRMA PERMISO JSA',
                               V_ID_FUNCIONARIO_FIrMA,
                               to_char(sysdate,'DD/MM/YYYY'));
                i_firma:='Operacion realizada. La Ausencia se ha denegado correctamente.';

           END IF;
      END IF;
     ELSE

      todo_ok_basico:=1;
      msgBasico:='Operacion NO realizada.';
     RETURN;
END IF;*/

END IF;

todo_ok_basico:=0;
msgBasico:=i_firma;
commit;

end FIRMA_AUSENCIA_JSA;
/

