CREATE OR REPLACE PROCEDURE RRHH."VBUENO_AUSENCIA_RRHH" (V_ID_FIRMA             in varchar2,
                                                   V_ID_FUNCIONARIO_FIRMA in number,
                                                   V_ID_AUSENCIA          in number,
                                                   V_ID_MOTIVO            in VARCHAR2,
                                                   todo_ok_Basico         out integer,
                                                   msgBasico              out varchar2) is

  i_no_hay_ausencias   number;
  i_no_hay_firma       number;
  i_id_funcionario     varchar2(6);
  i_firma              varchar2(256);
  i_id_estado          varchar2(2);
  i_id_js              varchar2(6);
  i_id_delegado_js     varchar2(6);
  i_id_ja              varchar2(6);
  i_id_delegado_ja     varchar2(6);
  i_DESC_TIPO_AUSENCIA varchar2(512);
  i_CADENA2            varchar2(512);

  correo_v_funcionario varchar2(512);
  i_nombre_peticion    varchar2(512);
  correo_js            varchar2(512);
  correo_ja            varchar2(512);
  i_sender             varchar2(256);
  i_recipient          varchar2(256);
  I_ccrecipient        varchar2(256);
  i_subject            varchar2(256);
  I_message            varchar2(15120);
  i_id_ano             number(4);
  i_dias               number(4);
  i_desc_mensaje       varchar2(15120);
  v_id_tipo_ausencia   varchar2(3);

  v_fecha_inicio date;
  v_fecha_fin    date;
  V_HORA_INICIO  varchar2(5);
  V_HORA_FIN     varchar2(5);
  V_TOTAL_HORAS  number;
   i_ficha    number;
 i_codpers varchar(5);
  v_total_horas_mete varchar2(12);

begin

  todo_ok_basico := 0;
  msgBasico      := '';

  --Compruebo que el permiso esta en la tabla
  i_no_hay_ausencias := 0;
  BEGIN
    select total_horas,
           substr(to_char(a.FECHA_INICIO, 'DD/MM/YYYY HH24:MI'), 12, 5) as HORA_INICIO,
           substr(to_char(a.FECHA_FIN, 'DD/MM/YYYY HH24:MI'), 12, 5) as HORA_FIN,
           a.FECHA_INICIO,
           a.fecha_fin,
           a.id_tipo_ausencia,
           a.id_ano,
           a.id_estado,
           id_funcionario,
           DESC_TIPO_AUSENCIA
      into V_TOTAL_HORAS,
           V_HORA_INICIO,
           V_HORA_FIN,
           v_fecha_inicio,
           v_fecha_fin,
           v_id_tipo_ausencia,
           i_id_ano,
           i_id_estado,
           i_id_funcionario,
           i_DESC_TIPO_AUSENCIA
      from ausencia a, tr_tipo_ausencia tr
     where id_ausencia = v_id_ausencia
       and a.id_tipo_ausencia = tr.id_tipo_ausencia
       and (anulado = 'NO' OR ANULADO IS NULL);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_ausencias := -1;
  END;

  IF i_no_hay_ausencias = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada.Ausencia no existe.';
    RETURN;
  END IF;

  --Busco que la persona que firma sea la correcta
  BEGIN
    select id_js, id_delegado_js, id_ja, id_delegado_ja
      into i_id_js, i_id_delegado_js, i_id_ja, i_id_delegado_ja
      from funcionario_firma
     where id_funcionario = i_id_funcionario;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_firma := -1;
  END;

  IF i_no_hay_firma = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. No hay personas para firmar.';
    RETURN;
  END IF;

  --Buscamos el correo en la usuario.intranet.
  BEGIN
    select MIN(peticion), MIN(nombre_peticion), MIN(js), MIN(ja)
      into correo_v_funcionario, i_nombre_peticion, correo_js, correo_ja

      from (select login || '@aytosalamanca.es' as peticion,substr(  DIST_NAME,  INSTR(DIST_NAME,'=',1) +1,INSTR(DIST_NAME,',',1) -INSTR(DIST_NAME,'=',1)-1) as nombre_peticion,''as js ,'' as ja from apliweb_usuario where id_funcionario=to_char(I_ID_FUNCIONARIO)
     union
     select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js,'' as ja  from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0')
      union
    select '' as peticion ,'' as nombre_peticion ,'' as ja,login || '@aytosalamanca.es' as ja from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_ja,6,'0')
);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END;

  --Si No hay jefes para firmar el permiso.
  IF i_id_js = '' AND i_id_ja = '' then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
    RETURN;
  END IF;

  --Actualizar ausencias
  IF i_id_estado = 22 then
    --Visto Bueno por parte de RRHH.

    IF V_ID_FIRMA = 1 THEN
      --AUTORIZADO
      update ausencia
         set id_estado    = 80,
             firmado_rrhh = V_ID_FUNCIONARIO_FIRMA,
             FECHA_RRHH   = SYsDATE
       where id_funcionario = i_id_funcionario
         and id_ausencia = V_id_ausencia
         and rownum < 2;
      --busco que la actualizacion sera correcta.
      IF SQL%ROWCOUNT = 0 then
        todo_ok_basico := 1;
        msgBasico      := 'Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
        RETURN;
      END IF;

      --ENVIO DE CORREO AL FUNCIONARIO, JEFE DE AREA, JEFE DE SERV/SECC
      i_sender      := 'permisos.rrhh@aytosalamanca.es';
      I_ccrecipient := correo_js || ';' || correo_ja;
      i_recipient   := correo_v_funcionario;
      I_message     := 'La Ausencia sido Concedido.' || chr(10) || chr(10) ||
                       'Solicitud de Ausencia de: ' || i_nombre_peticion ||
                       chr(10) || 'Tipo Ausencia: ' || i_DESC_TIPO_AUSENCIA ||
                       chr(10) || i_CADENA2;
      i_subject     := 'Ausencia Concedido.';
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject,
                   I_message);

      --Insert en el historico
      insert into historico_operaciones
      values
        (sec_operacion.nextval,
         V_ID_AUSENCIA,
         80,
         i_id_ano,
         V_ID_FUNCIONARIO_FIRMA,
         to_char(sysdate, 'DD/MM/YYYY'),
         to_char(sysdate, 'HH:MI'),
         'VBUENO RRHH',
         V_ID_FUNCIONARIO_FIrMA,
         to_char(sysdate, 'DD/MM/YYYY'));

      i_firma := 'Operacion realizada. La Ausencia esta concedida.';

      --Metemos la ausencia en el finger. --a?adido dia 6 de abril 2010
      --El funcionario Ficha ??
      v_total_horas_mete:=lpad(trunc(v_total_horas/60),2,'0') || ':' || lpad(mod(v_total_horas,60),2,'0');

                 i_ficha:=1;
                 BEGIN
                      SELECT
                              distinct codpers
                              into i_codpers
                      FROM
                              personal_new p  ,presenci pr,
                              apliweb_usuario u
                      WHERE
                              p.id_funcionario=I_ID_FUNCIONARIO  and
                              lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and --cambiado 29/03/2010
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
                 EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
                 END;

         if i_ficha=1 then
            mete_fichaje_finger_new(i_id_ano ,
                                i_id_funcionario ,
                                v_fecha_inicio,
                                V_hora_inicio ,
                                V_hora_fin ,
                                i_codpers ,
                                 v_total_horas_mete ,'00000',
                                todo_ok_basico ,
                                msgbasico);
         end if;



    ELSE
      IF V_ID_FIRMA = 0 THEN
        --denegado
        update ausencia
           set id_estado     = 32,
               firmado_rrhh  = V_ID_FUNCIONARIO_FIRMA,
               motivo_denega = V_ID_MOTIVO,
               FECHA_rrhh    = SYsDATE
         where id_funcionario = i_id_funcionario
           and id_ausencia = V_id_ausencia
           and rownum < 2;
        --busco que la actualizacion sera correcta.
        IF SQL%ROWCOUNT = 0 then
          todo_ok_basico := 1;
          msgBasico      := 'Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
          RETURN;
        END IF;
        --ENVIO DE CORREO AL FUNCIONARIO CON LA DENEGACION
        --ENVIO DE CORREO AL FUNCIONARIO, JEFE DE AREA, JEFE DE SERV/SECC
        i_sender      := 'permisos.rrhh@aytosalamanca.es';
        I_ccrecipient := correo_js || ';' || correo_ja;
        i_recipient   := correo_v_funcionario;
        I_message     := 'Denegacion de la Ausencia' || chr(10) ||
                         'Motivo de Denegacion: ' || v_id_motivo || chr(10) ||
                         i_DESC_TIPo_AUSENCIA || chr(10) || i_CADENA2;
        i_subject     := 'Denegacion de Permiso por RRHH.';
        envio_correo(i_sender,
                     i_recipient,
                     I_ccrecipient,
                     i_subject,
                     I_message);

        --Insert en el historico
        insert into historico_operaciones
        values
          (sec_operacion.nextval,
           V_ID_AUSENCIA,
           32,
           i_id_ano,
           V_ID_FUNCIONARIO_FIRMA,
           to_char(sysdate, 'DD/MM/YYYY'),
           to_char(sysdate, 'HH:MI'),
           'VBUENO RRHH',
           V_ID_FUNCIONARIO_FIrMA,
           to_char(sysdate, 'DD/MM/YYYY'));
        i_firma := 'Operacion realizada. La Ausencia se ha denegado correctamente.';

      END IF;
    END IF;

  END IF;

  todo_ok_basico := 0;
  msgBasico      := i_firma;
  commit;

end VBUENO_AUSENCIA_RRHH;
/

