CREATE OR REPLACE PROCEDURE RRHH."VBUENO_RRHH"
     (V_ID_FIRMA in varchar2,
        V_ID_FUNCIONARIO_FIRMA in number,
        V_ID_PERMISO in number,
        V_ID_MOTIVO in  VARCHAR2,
        todo_ok_Basico out integer,msgBasico out varchar2) is

i_no_hay_permisos number;
i_no_hay_firma number;
i_id_funcionario varchar2(6);
i_id_ano number(4);
i_id_tipo_permiso varchar2(5);
i_total_horas varchar2(5);
i_hora_inicio varchar2(5);
i_hora_fin varchar2(5);

i_fecha_inicio date;
i_fecha_fin date;
 i_ficha  number;
 i_codpers varchar2(6);
 i_firma varchar2(256);
i_id_estado varchar2(2);
i_contador number;
i_id_js varchar2(6);
i_id_delegado_js varchar2(6);
i_id_ja varchar2(6);
i_id_delegado_ja  varchar2(6);
i_DESC_TIPO_PERMISO varchar2(512);
i_CADENA2 varchar2(512);

correo_v_funcionario varchar2(512);
i_nombre_peticion varchar2(512);
correo_js varchar2(512);
correo_ja varchar2(512);
i_sender varchar2(256);
 i_recipient varchar2(256);
 I_ccrecipient varchar2(256);
 i_subject varchar2(256);
 I_message varchar2(512);
 v_mensaje varchar2(15012);
 i_id_grado varchar2(100);
  i_num_DIAs varchar2(100);
           i_id_tipo_dias varchar2(100);
begin

todo_ok_basico:=0;
msgBasico:='';

--Compruebo que el permiso esta en la tabla
i_no_hay_permisos:=0;
BEGIN
    select p.id_ano ,p.id_grado,   p.NUM_DIAS,
           p.id_tipo_dias,
           lpad(trunc(p.total_horas/60),2,'0') || ':' || lpad(mod(p.total_horas,60),2,'0') ,
           p.hora_inicio,
           p.hora_fin,
           p.id_tipo_permiso ,
           p.fecha_inicio ,
           p.fecha_fin ,
           id_estado,id_funcionario,DES_TIPO_PERMISO_LARGA, DECODE(p.id_tipo_permiso,'15000',
     'Fecha Inicio: ' || to_char(p.FECHA_INICIO,'DD-MON-YY') || chr(10)||'Hora de Inicio: ' || HORA_INICIO ||  chr(10)||'Hora Fin: ' || HORA_FIN,
     'Fecha Inicio: ' || to_char(p.FECHA_INICIO,'DD-MON-YY') || chr(10) ||'Fecha Fin:    ' || to_char(p.FECHA_FIN,'DD-MON-YY') ||  chr(10) ||'Numero de Dias: ' || p.NUM_DIAS)

    into i_id_ano ,i_id_grado,i_num_DIAs ,
           i_id_tipo_dias,
         i_total_horas,
         i_hora_inicio ,
         i_hora_fin ,
         i_id_tipo_permiso ,
         i_fecha_inicio ,
         i_fecha_fin ,
         i_id_estado,
         i_id_funcionario,
         i_DESC_TIPO_PERMISO,
         i_CADENA2
    from permiso p,tr_tipo_permiso  tr
    where id_permiso=v_id_permiso and
          p.id_tipo_permiso=tr.id_tipo_permiso and
          (anulado='NO' OR ANULADO IS NULL);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         i_no_hay_permisos:=-1;
END;

IF  i_no_hay_permisos = -1 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Permiso no existe.';
             RETURN;
END IF;

--Busco que la persona que firma sea la correcta en RRHH
--De momento nada
/*BEGIN
    select id_js,
           id_delegado_js,
           id_ja,
           id_delegado_ja
     into  i_id_js,
           i_id_delegado_js,
           i_id_ja,
           i_id_delegado_ja
     from funcionario_firma
    where id_funcionario=i_id_funcionario and
           (id_JS= V_ID_FUNCIONARIO_FIRMA OR
            id_DELEGADO_JS= V_ID_FUNCIONARIO_FIRMA OR
            id_JA= V_ID_FUNCIONARIO_FIRMA OR
            id_DELEGADO_JA= V_ID_FUNCIONARIO_FIRMA);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
     i_no_hay_firma:=-1;
END;

IF  i_no_hay_firma=-1 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada. No hay personas para firmar.';
             RETURN;
END IF;
*/

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


--Actualizar permisos
IF i_id_estado =22 then --Visto Bueno por parte de RRHH

            IF V_ID_FIRMA=1 THEN --AUTORIZADO
                update permiso
                set    id_estado=80  ,firmado_rrhh=V_ID_FUNCIONARIO_FIRMA,FECHA_RRHH=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_permiso=V_id_permiso and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto Carlos(Informatica). Ext 9553. ';
                   RETURN;
                END IF;


                --El funcionario Ficha ??

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
                              to_char(p.id_funcionario)=u.id_funcionario and
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
                 EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
                 END;


                 IF I_FICHA = 1  AND I_ID_TIPO_PERMISO<>'15000' then
                  -- Actualizamos el finger
                  actualiza_finger(i_id_ano ,
                                i_id_funcionario ,
                                i_id_tipo_permiso ,
                                i_fecha_inicio ,
                                i_fecha_fin ,
                                i_codpers,
                                i_id_estado,
                                todo_ok_basico ,
                                 msgbasico);
                    --Hay errores fin
                        IF todo_ok_basico=1 then
                           rollback;
                           return;
                        END IF;
                ELSE IF I_FICHA = 1  AND I_ID_TIPO_PERMISO='15000' THEN
                   --mete_fichaje en la tabla transacciones y en persfich
                       mete_fichaje_finger_new(i_id_ano ,
                                i_id_funcionario ,
                                i_fecha_inicio,
                                i_hora_inicio ,
                                i_hora_fin ,
                                i_codpers ,
                                i_total_horas ,'15000',
                                todo_ok_basico ,
                                msgbasico);
                        END IF;
                   END IF;


                --ENVIO DE CORREO AL FUNCIONARIO, JEFE DE AREA, JEFE DE SERV/SECC
                 i_sender:=''; --Falta poner direccion RRHH
                 I_ccrecipient:=correo_js ||';' || correo_ja;
                 i_recipient:= correo_v_funcionario;
                 I_message:=
                            'El permiso ha sido Concedido.' || chr(10)||   chr(10)||
                            'Solicitud de Permiso de: '|| i_nombre_peticion || chr(10)||
                            'Tipo permiso: '  || i_DESC_TIPo_PERMISO || chr(10)||
                             i_CADENA2;
                 i_subject:='Permiso Concedido.';

                 --configuracion formato_correo
                 --Descripcion del permiso .
                 --CHM 14/12/2016
                  envia_correo_informa('3',  i_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPO_PERMISO ,
                       '' , --desc motivo
                       i_fecha_inicio ,
                       i_fecha_fin ,
                       i_hora_inicio ,
                       i_hora_fin ,
                       i_id_grado ,
                       i_id_tipo_dias,
                       i_num_dias,
                       v_mensaje);

                  I_message:= v_mensaje;

                  envio_correo(i_sender ,
                              i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                               I_message);


                 /*
                 --Insert en el historico
                 insert into historico_operaciones values(i_secuencia,i_tipo_operacion,i_clase_operacion,
                       i_id_ano, SYSDATE,i_hora,i_orden_sql,i_usuario,i_fecha_modi);
                 */

                 --Insert en el historico
                 insert into historico_operaciones
                        values(sec_operacion.nextval,
                                V_ID_PERMISO ,
                               22,
                               i_id_ano,
                               V_ID_FUNCIONARIO_FIRMA,
                              to_char(sysdate,'DD/MM/YYYY'),
                               to_char(sysdate,'HH:MI'),
                               'VBUENO RRHH',
                               V_ID_FUNCIONARIO_FIrMA,
                               to_char(sysdate,'DD/MM/YYYY'));

                 i_firma:='Operacion realizada. El permiso concedido';

            ELSE  IF V_ID_FIRMA=0 THEN --denegado
               update permiso
                set    id_estado=32  ,firmado_RRHH=V_ID_FUNCIONARIO_FIRMA,motivo_denega=V_ID_MOTIVO,FECHA_RRHH=SYsDATE
                where  id_funcionario=i_id_funcionario and
                       id_permiso=V_id_permiso and
                       rownum  < 2 ;
                            --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                   todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
                END IF;
                 --ENVIO DE CORREO AL FUNCIONARIO ,JA y JS CON LA DENEGACION
                 i_sender:=''; --Falta poner direccion RRHH
                 I_ccrecipient:=correo_js ||';' || correo_ja;
                 i_recipient:= correo_v_funcionario;
                 I_message:= 'Denegacion de la Solicitud del Permiso' || chr(10) ||
                             'Motivo de Denegacion: '|| v_id_motivo || chr(10)||
                             i_DESC_TIPo_PERMISO || chr(10)||
                             i_CADENA2;
                 i_subject:='Denegacion de Permiso por RRHH.';

                 --configuracion formato_correo
                 --Descripcion del permiso .
                 --CHM 14/12/2016
                  envia_correo_informa('0',  i_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPO_PERMISO ,
                       v_id_motivo , --desc motivo
                       i_fecha_inicio ,
                       i_fecha_fin ,
                       i_hora_inicio ,
                       i_hora_fin ,
                       i_id_grado ,
                       i_id_tipo_dias,
                       i_num_dias,
                       v_mensaje);

                  I_message:= v_mensaje;
                 envio_correo(i_sender ,
                              i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message);



                --Insert en el historico
                 insert into historico_operaciones
                        values(sec_operacion.nextval,
                                V_ID_PERMISO ,
                               32,
                               i_id_ano,
                               V_ID_FUNCIONARIO_FIRMA,
                              to_char(sysdate,'DD/MM/YYYY'),
                               to_char(sysdate,'HH:MI'),
                               'VBUENO RRHH',
                               V_ID_FUNCIONARIO_FIrMA,
                               to_char(sysdate,'DD/MM/YYYY'));

                   -- Actualizo el permiso si es UNICO
                    permiso_denegado(v_id_permiso, todo_ok_basico ,msgbasico);
                    IF  todo_ok_basico= 1 THEN
                      RETURN;
                    ELSE
                      i_firma:='Operacion realizada. El permiso se ha denegado correctamente.';
                    END IF;
                 END IF;
             END IF;

ELSE
      todo_ok_basico:=1;
      msgBasico:='Operacion realizada.';
     RETURN;
END IF;

--Todo ha ido bien
todo_ok_basico:=0;
msgBasico:=i_firma;
commit;

end VBUENO_RRHH;
/

