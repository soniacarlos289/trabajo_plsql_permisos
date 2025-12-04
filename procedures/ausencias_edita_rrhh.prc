create or replace procedure rrhh.AUSENCIAS_EDITA_RRHH(
          V_ID_AUSENCIA in  number,
          V_ID_ESTADO_AUSENCIA in number,
          V_JUSTIFICACION varchar2,V_OBSERVACIONES varchar2,
          msgsalida out varchar2,todook out varchar2) is

i_ficha number;
v_num_dias number;
v_id_tipo_dias_per varchar2(1);
v_codpers varchar2(5);
i_total_horas number;
i_todo_ok_B number;
msgBasico  varchar2(256);
v_id_tipo_dias_ent  varchar2(256);
i_codpers varchar(5);
i_id_funcionario number;
v_num_dias_tiene_per number;
i_formato_fecha_inicio date;
i_formato_fecha_fin date;
i_diferencia_TOTAL date;
i_total_dias number;
i_contador number;
i_cambia_estado number;
 I_id_estado_ausencia number;
 i_ausencia_no_encontrado number;
  i_observaciones varchar2(1000);
  i_justificacion varchar2(2);
i_total_utilizadas number;
i_id_ano number;
i_id_tipo_ausencia number;
i_id_mes number;
i_fecha_inicio varchar2(12);
i_fecha_fin varchar2(12);
i_hora_inicio  varchar2(12);
i_hora_fin varchar2(12);
i_id_js number;
  correo_v_funcionario varchar2(512);
  i_nombre_peticion    varchar2(512);
  correo_js            varchar2(512);
  correo_ja            varchar2(512);
  i_sender             varchar2(256);
  i_recipient          varchar2(256);
  I_ccrecipient        varchar2(256);
  i_subject            varchar2(256);
  I_message            varchar2(15120);
 i_desc_mensaje varchar2(25120);
 i_DESC_TIPO_AUSENCIA varchar2(512);

begin
todook:=0;
 I_id_estado_ausencia:=0;

/* msgsalida:= V_ID_AUSENCIA || ' .'||
          V_ID_ESTADO_AUSENCIA || ' .'||
          V_JUSTIFICACION|| ' .'||V_OBSERVACIONES ;
          return;
*/
i_ausencia_no_encontrado:=0;
--obtenemos los datos del permiso actual.
BEGIN

         select  t.id_estado,OBSERVACIONES,t.JUSTIFICADO,t.total_horas,
         to_char(t.fecha_inicio,'MM') ,t.id_ano,t.id_tipo_ausencia,t.id_funcionario,
          to_char(t.fecha_inicio,'DD/mm/yyyy') as fecha_inicio,
           to_char(t.fecha_fin,'DD/mm/yyyy') as fecha_fin,
       to_char(t.fecha_inicio,'HH24:mi') hora_inicio,
       to_char(t.fecha_fin,'HH24:mi') hora_fin,t.firmado_js,DESC_TIPO_AUSENCIA
         into   I_id_estado_ausencia,
         i_observaciones ,
  i_justificacion,i_total_utilizadas,i_id_mes,i_id_ano,i_id_tipo_ausencia,
  i_id_funcionario,i_fecha_inicio,i_fecha_fin,i_hora_inicio,i_hora_fin,i_id_js,
  i_DESC_TIPO_AUSENCIA
    from ausencia t,tr_tipo_ausencia  tr
    where ID_AUSENCIA=V_ID_AUSENCIA and
          t.id_tipo_ausencia=tr.id_tipo_ausencia;
EXCEPTION
WHEN NO_DATA_FOUND THEN
                   i_ausencia_no_encontrado:=1;

END;

--El permiso solo puede pasar de concedido a anulado
--NO puede cambiar de estado.
i_cambia_estado:=0;
IF  (( I_id_estado_ausencia=80 OR I_id_estado_ausencia=22 OR I_id_estado_ausencia=20) AND
   (V_ID_ESTADO_AUSENCIA=80 OR V_ID_ESTADO_AUSENCIA=40))
    OR
    (V_ID_ESTADO_AUSENCIA=32 AND I_ID_ESTADO_AUSENCIA=80)
     THEN
  --todo correcto
  i_cambia_estado:=0;
ELSE IF I_id_estado_ausencia <> V_ID_ESTADO_AUSENCIA THEN
     i_cambia_estado:=1;
     END IF;
END IF;

--Si cambio el tipo error
IF i_cambia_estado <> 0 THEN
     todook:=1;
     msgBasico:='Operacion no realizada. El unico cambio permitido de estado es de Concedido a Anulado o Concedido a Denegado.';
     RETURN;
END IF;


IF V_ID_ESTADO_AUSENCIA=40 OR V_ID_ESTADO_AUSENCIA=32  THEN

   --Metemos la ausencia en el finger. --a?adido dia 6 de abril 2010
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
                              lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and --cambiado 29/03/2010
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
                 EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
                 END;

         if i_ficha=1 then
            ANULA_FICHAJE_FINGER_15000(i_id_ano ,
                                i_id_funcionario ,
                                i_fecha_inicio,
                                i_hora_inicio ,
                                i_hora_fin ,
                                i_codpers ,
                               0 ,'00000',
                                todook ,
                               msgbasico);
         end if;


   IF V_ID_ESTADO_AUSENCIA=40 THEN
    UPDATE AUSENCIA
    SET ANULADO='SI',
       id_Estado='40',fecha_anulacion=sysdate
    WHERE   ID_AUSENCIA=V_ID_AUSENCIA and rownum < 2;
   ELSE
      UPDATE AUSENCIA
    SET observaciones=V_observaciones      ,
       id_Estado='32'
    WHERE   ID_AUSENCIA=V_ID_AUSENCIA and rownum < 2;

  END IF;

   --chm 13/02/2020
--quito las horas de las bolsa concilia
  IF i_ID_TIPO_AUSENCIA = 50 THEN

     UPDATE BOLSA_CONCILIA   SET
     utilizadas=utilizadas-i_total_utilizadas,
     pendientes_justificar=pendientes_justificar-i_total_utilizadas
     where id_ano=i_id_ano AND  id_funcionario=i_ID_FUNCIONARIO;

   END IF;

   --quito las horas sindicales.
   IF i_id_tipo_ausencia > 500 THEN

   UPDATE HORA_SINDICAL
   SET TOTAL_UTILIZADAS=TOTAL_UTILIZADAS-i_total_utilizadas
   where
                id_ano=i_id_ano AND
                id_MES=i_id_mes and
                id_funcionario=i_id_funcionario AND
                ID_TIPO_AUSENCIA= i_id_tipo_ausencia and rownum < 2;

   END IF;

    IF V_ID_ESTADO_AUSENCIA=32 THEN  --DENEGACION POR RRRHH

    --busco correo del funcionario y la persona que firma
          BEGIN
             select MIN(peticion), MIN(nombre_peticion), MIN(js)
             into correo_v_funcionario, i_nombre_peticion, correo_js
             from (select login || '@aytosalamanca.es' as peticion,substr(  DIST_NAME,  INSTR(DIST_NAME,'=',1) +1,INSTR(DIST_NAME,',',1) -INSTR(DIST_NAME,'=',1)-1) as nombre_peticion,'' as js from apliweb_usuario where id_funcionario=to_char(I_ID_FUNCIONARIO)
             union
             select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js  from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0') );
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                i_id_js := '';
          END;


          --ENVIO DE CORREO AL FUNCIONARIO CON LA DENEGACION
           i_sender      := 'permisos@aytosalamanca.es';
           I_ccrecipient := '';
           i_recipient   := correo_v_funcionario;
           I_message     := 'Ausencia denegada por' ||' '|| V_OBSERVACIONES ||'. Fecha inicio: '||
                            i_FECHA_INICIO;

               --Descripcion de la ausencia .
              BEGIN
              select CABECERA || ' '||
                     'Ausencia denegada por' ||' '|| V_OBSERVACIONES ||' '||
                         SOLICITADO || ' '||
                         i_nombre_peticion ||' '||
                         TIPO_PERMISO ||' '||
                         i_desc_tipo_ausencia||' '||
                         FECHA_INICIO  ||' '||
                         i_FECHA_INICIO  ||' '||
                          DECODE(substr(i_ID_TIPO_AUSENCIA,1,1) ,'5',
                         FECHA_FIN  ||' '||
                         i_FECHA_FIN
                          ,'') ||' '||

                         HORA_INICIO ||' '|| i_HORA_INICIO   ||' '||  --
                         HORA_FIN    ||' '|| i_HORA_FIN      || ' '|| --
                         CABECERA_FI ||' '||
                      'Esta Ausencia ha sido denegada'||' '||
                      CABECERA_FIN_2
            into  i_desc_mensaje
                 from  FORMATO_CORREO
                 where DECODE( substr(i_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
                     )=ID_TIPO_PERMISO;
          EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   i_desc_tipo_ausencia:='';
          END;


          I_message:= i_desc_mensaje;
          i_subject := 'Denegacion de Ausencia por RRHH.';
          envio_correo(i_sender ,     i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message);


   end if;-- Denegado
END IF;--FIN ANULADO O DENEGADO

--UPDAte
  IF  i_justificacion<>V_JUSTIFICACION THEN
            update ausencia
            set justificado=V_JUSTIFICACION
            where id_ausencia=v_id_ausencia and rownum<2;

            IF V_JUSTIFICACION = 'SI' THEN
            --chm 09/03/2017
            -- i_id_funcionario,i_fecha_inicio,i_hora_inicio,i_hora_fin
            /*  OMESA.PROCESO_FINGER_AUSENCIA_NEW(i_id_funcionario,
                          to_date(i_fecha_inicio,'dd/mm/yyyy'),
                          i_hora_inicio,
                          i_hora_fin);*/
                --chm 13/02/2019
            -- i_id_funcionario,i_fecha_inicio,

            --chm 30/09/2019
            --cambiado  i_ficha:=1;

             i_ficha:=1;
            /* chm nuevo*/
            /*16/10/2020 */
           BEGIN
            SELECT
                              distinct u.id_fichaje
                             into i_codpers
                      FROM
                              personal_new p  ,persona pr,
                              apliweb_usuario u
                      WHERE
                             p.id_funcionario=I_ID_FUNCIONARIO  and
                              lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and --cambiado 29/03/2010
                              u.id_fichaje is not null and
                              u.id_fichaje=codigo
                             and rownum <2;
            EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
            END;
                  /* codigo viejo*/
                /* BEGIN
                      SELECT
                              distinct codpers
                              into i_codpers
                      FROM
                              personal_new p  ,omesa.presenci pr,
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
                 END;*/

                 if i_ficha=1 then
                    mete_fichaje_finger_NEW(i_id_ano ,
                                        i_id_funcionario ,
                                        i_fecha_inicio,
                                        i_hora_inicio ,
                                        i_hora_fin ,
                                        i_codpers ,
                                        0,'00000',
                                         i_todo_ok_B ,
                                        msgbasico);
                    finger_calcula_saldo(i_id_funcionario,to_date(i_fecha_inicio,'dd/mm/yyyy'));
                 end if;
               --30/09/3019


            END IF;
        END IF;

IF  (i_observaciones<>V_observaciones) OR ( (i_observaciones is null) AND V_observaciones is not null)  THEN
            update ausencia
            set observaciones=V_observaciones
            where id_ausencia=v_id_ausencia and rownum<2;
END IF;



COMMIT;
msgsalida:='La ausencia se ha incorporado al sistema';
todook:=0;
END AUSENCIAS_EDITA_RRHH;
/

