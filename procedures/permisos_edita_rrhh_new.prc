CREATE OR REPLACE PROCEDURE RRHH."PERMISOS_EDITA_RRHH_NEW"
       (
            V_OBSERVACIONES in  varchar2,
            V_ID_PERMISO in number,
            V_ID_ESTADO_PERMISO in number,
            V_JUSTIFICACION in varchar2,
            V_ID_USUARIO in varchar2,
            todo_ok_Basico out integer,msgBasico out varchar2,
            V_FECHA_FIN in date,
            V_DESCUENTO_BAJAS in  varchar2,
            V_DESCUENTO_DIAS in  varchar2
            ) is

I_id_permiso number;
I_id_ano number(4);
I_id_funcionario number(6);
I_id_tipo_permiso number(5);
I_id_estado_permiso number(2);
I_fecha_inicio date;
I_fecha_fin date;
I_hora_inicio varchar2(5);
I_hora_fin   varchar2(5);
i_permiso_no_encontrado number;
i_cambia_estado number;
i_ficha number;
i_codpers number;
i_justificacion varchar2(2);
i_observaciones varchar2(1500);
v_dni  varchar2(10);
i_dias_descuenta number;

  correo_v_funcionario varchar2(512);
  i_nombre_peticion    varchar2(512);
  correo_js            varchar2(512);
  correo_ja            varchar2(512);
  i_sender             varchar2(256);
  i_recipient          varchar2(256);
  I_ccrecipient        varchar2(256);
  i_subject            varchar2(256);
  I_message            varchar2(15120);
  i_dias               number(4);
  i_desc_mensaje       varchar2(15120);
  i_contador           number;
  i_mensaje            varchar2(25000);
  i_ID_GRADO           varchar2(300);
  i_num_dias           number;
  i_t1                 varchar2(5);
  i_t2                 varchar2(5);
  i_t3                 varchar2(5);
   I_id_tipo_dias           varchar2(5);
   i_DESC_TIPO_PERMISO    varchar2(15120);
   i_CADENA2              varchar2(15120);
   i_id_js number;
   i_tipo_funcionario number;
   i_DESCUENTO_BAJAS   varchar2(5);

begin
todo_ok_basico:=0;
msgBasico:='';

-- 10 Solicitado
-- 20 Pde. Firma Jefe Secc.
-- 21 Pde. Firma Jefe Area
-- 22 Pde Vo de RRHH.
-- 30 Rechazado Jefe Secc.
-- 31 Rechazado Jefe Area.
-- 32 Denegado RRHH
-- 41 Anulado por USUARIO //añadido 03/03/2017
-- 40 Anulado RRHH
-- 80 Concedido  RRHH

/*msgBasico:='Estoy haciendo tareas de Administracion. Hasta las 11:00 no se podran meter permisos. :) ' ||V_JUSTIFICACION ;
 return;
   rollback;*/

i_permiso_no_encontrado:=0;
--cambiada
BEGIN
    select
                id_permiso,
                p.id_ano,
                id_funcionario,
                p.id_tipo_permiso,
                id_estado,
                p.fecha_inicio,
                p.fecha_fin,
                hora_inicio,
                hora_fin,
                DECODE(p.JUSTIFICACION,'NO','NO','SI'), --chm 14/02/2018,
                DECODE(observaciones,NULL,'0',OBSERVACIONES),
                ID_GRADO,
                p.id_tipo_dias,
                DES_TIPO_PERMISO_LARGA,
                DECODE(p.id_tipo_permiso,
                  '15000',
                  'Fecha Inicio: ' || to_char(p.FECHA_INICIO, 'DD-MON-YY') ||
                  chr(10) || 'Hora de Inicio: ' || HORA_INICIO || chr(10) ||
                  'Hora Fin: ' || HORA_FIN,
                  'Fecha Inicio: ' || to_char(p.FECHA_INICIO, 'DD-MON-YY') ||
                  chr(10) || 'Fecha Fin:    ' ||
                  to_char(p.FECHA_FIN, 'DD-MON-YY') || chr(10) ||
                  'Numero de Dias: ' || p.NUM_DIAS),
                p.NUM_DIAS,
                tu1_14_22,
                tu2_22_06,
                tu3_04_14,
                firmado_js,
                NVL(descuento_bajas,'NO') --firmado js

      into      I_id_permiso,
                I_id_ano,
                I_id_funcionario,
                I_id_tipo_permiso,
                I_id_estado_permiso,
                I_fecha_inicio,
                I_fecha_fin,
                I_hora_inicio,
                I_hora_fin     ,
                i_justificacion,
                i_observaciones,
                I_ID_GRADO,
                I_id_tipo_dias,
                i_DESC_TIPO_PERMISO,
                i_CADENA2,
                i_dias,
                i_t1,
                i_t2,
                i_t3,
                i_id_js,
                i_DESCUENTO_BAJAS

      from permiso p, tr_tipo_permiso tr
     where id_permiso = v_id_permiso
       and tr.id_ano = p.id_ano
       and p.id_tipo_permiso = tr.id_tipo_permiso;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       i_permiso_no_encontrado:=1;
  END;

/*msgBasico:='Estoy haciendo tareas de Administracion. Hasta las 11:00 no se podran meter permisos. :) ' ||V_JUSTIFICACION
|| 'bb' ||i_JUSTIFICACION ;
 return;
   rollback; */

IF i_permiso_no_encontrado <> 0 THEN
     todo_ok_basico:=1;
     msgBasico:='Operacion no realizada. Permiso no encontrado. d' || V_ID_PERMISO;
     RETURN;
END IF;

--chm 01/04/2017
 --Compruebo el tipo de funcionario de la solicitud
 i_tipo_funcionario:=10;
  BEGIN
    select tipo_funcionario2
      into i_tipo_funcionario
      from personal_new pe
     where id_funcionario = i_id_funcionario  and rownum<2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_tipo_funcionario:=-1;
  END;

  IF i_tipo_funcionario = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;


--El permiso solo puede pasar de concedido a anulado
--A?adido El permiso solo puede pasar de Pde Firma RRHH a anulado
--A?adido El permiso solo puede pasar de Pde Firma JS a anulado.A?adido 6 de abril 2010
--A?adido El permiso solo puede pasar de DENEGADO RRHH a anulado
--AÑADIDO EL PERMISO AUTORIZADO A DENEGADO PARA RRHH
--NO puede cambiar de estado.
i_cambia_estado:=0;
IF  ((I_id_estado_permiso=80 OR I_id_estado_permiso=22 OR I_id_estado_permiso=20) AND
    (V_ID_ESTADO_PERMISO=80 OR V_ID_ESTADO_PERMISO=40) ) OR
    (V_ID_ESTADO_PERMISO=32 AND I_ID_ESTADO_PERMISO=80) --80 autorizado a 32 denegado.
    THEN
  --todo correcto
  i_cambia_estado:=0;
ELSE IF I_id_estado_permiso <> v_id_estado_permiso THEN
     i_cambia_estado:=1;
     END IF;
END IF;

--Si cambio el tipo error
IF i_cambia_estado <> 0 THEN
     todo_ok_basico:=1;
     msgBasico:='Operacion no realizada. Los unicos cambios permitidos es de Concedido --> Anulado y Pde Firma --> Anulado.' ||  I_id_estado_permiso || ' ' || v_id_estado_permiso;
     RETURN;
END IF;


--ANULACION
IF V_ID_ESTADO_PERMISO=40 OR V_ID_ESTADO_PERMISO=32 THEN
   --ANULACION
   permiso_denegado(v_id_permiso,
                    todo_ok_basico ,
                    msgbasico );
   IF todo_ok_basico=1 then

        rollback;
    return;
    END IF;


  IF V_ID_ESTADO_PERMISO=40 THEN
   UPDATE PERMISO
   SET ANULADO='SI',
       id_Estado='40',fecha_anulacion=sysdate
   WHERE   ID_PERMISO=V_ID_PERMISO and rownum<2;
  ELSE
    UPDATE PERMISO
   SET  id_Estado='32',
        observaciones=V_observaciones      ,
        fecha_modi=sysdate
   WHERE   ID_PERMISO=V_ID_PERMISO and rownum<2;
  END IF;

  --El funcionario Ficha ??
   i_ficha:=1;
    BEGIN
           SELECT
                  distinct codpers
                  into i_codpers
           FROM
                              personal_new p  ,presenci pr,
                               apliweb_usuario  u
           WHERE
                              p.id_funcionario=I_ID_FUNCIONARIO  and
                               LPAD(p.id_funcionario,6,'0')=LPAD(u.id_funcionario,6,'0') AND
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
    END;


    IF I_FICHA = 1  AND I_ID_TIPO_PERMISO<>'15000'  then


        -- Actualizamos el finger
        actualiza_finger(i_id_ano ,
                       i_id_funcionario ,
                       i_id_tipo_permiso ,
                       i_fecha_inicio ,
                       i_fecha_fin ,
                       i_codpers,
                       v_id_estado_permiso,--CAMBIADO AL NUEVO ESTADO
                       todo_ok_basico ,
                       msgbasico);
        --Hay errores fin
        IF todo_ok_basico=1 then
             rollback;
             return;
        END IF;
    ELSE IF I_FICHA = 1  AND i_ID_TIPO_PERMISO='15000' AND (V_ID_ESTADO_PERMISO=40
      OR V_ID_ESTADO_PERMISO=32)
      THEN


                   --anula_fichaje en la tabla transacciones y en persfich
                       ANULA_FICHAJE_FINGER_15000(i_id_ano ,
                                i_id_funcionario ,
                                i_fecha_inicio,
                                i_hora_inicio ,
                                i_hora_fin ,
                                i_codpers ,
                               0 ,'15000',
                                todo_ok_basico ,
                               msgbasico);
           --Hay errores fin
           IF todo_ok_basico=1 then
             rollback;
             return;
            END IF;
     END IF;



    END IF;
    --DENEGADO POR RRHH ENVIO MENSAJE AL FUNCIONARIO
    IF   V_ID_ESTADO_PERMISO=32 THEN

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
            I_message     := '';

         --chm 1/04/2017,DENEGACION
         envia_correo_informa_new('0',  i_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPo_PERMISO,
                        V_OBSERVACIONES,--motivo
                       i_fecha_inicio ,
                       i_fecha_fin ,
                       i_hora_inicio ,
                       i_hora_fin ,
                       i_id_grado ,
                       i_id_tipo_dias,
                       i_num_dias,
                       i_t1,
                       i_t2,
                       i_t3,
                       i_TIPO_FUNCIONARIO,
                       i_mensaje);

        I_message := i_mensaje;

        --chm 03/04/2017
        i_subject := 'Denegacion de Permiso por RRHH.';
        envio_correo(i_sender,
                     i_recipient,
                     I_ccrecipient,
                     i_subject,
                     I_message);



    END IF;--si es una denegación

ELSE --no es anulacion


        --ACTUALIZACION DE JUSTIFICACION
        IF  i_justificacion<>V_JUSTIFICACION THEN
            update permiso
            set justificacion=V_JUSTIFICACION
             ,
                fecha_modi=sysdate
            where id_permiso=i_id_permiso and rownum<2;

            --chm 14/02/2018
             IF i_justificacion='NO' and i_justificacion<>V_JUSTIFICACION THEN
               --El funcionario Ficha ??
            i_ficha:=1;
                     BEGIN
           SELECT
                  distinct codpers
                  into i_codpers
           FROM
                              personal_new p  ,presenci pr,
                               apliweb_usuario  u
           WHERE
                              p.id_funcionario=I_ID_FUNCIONARIO  and
                               LPAD(p.id_funcionario,6,'0')=LPAD(u.id_funcionario,6,'0') AND
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
              END;

                               --chm 13/02/2019
            -- i_id_funcionario,i_fecha_inicio,
              /* finger_regenera_saldo(i_id_funcionario,
                                     DEVUELVE_PERIODO(TO_CHAR(i_fecha_inicio,'dd/mm/yyyy')),
                                     0);
                 finger_regenera_saldo(i_id_funcionario,
                                     DEVUELVE_PERIODO(TO_CHAR(I_fecha_Fin,'dd/mm/yyyy')),
                                     0);                      */
             --  finger_calcula_saldo(i_id_funcionario,to_date(i_fecha_inicio,'dd/mm/yyyy'));


               actualiza_finger(i_id_ano ,
                       i_id_funcionario ,
                       i_id_tipo_permiso ,
                       i_fecha_inicio ,
                       i_fecha_fin ,
                       i_codpers,
                       v_id_estado_permiso,
                       todo_ok_basico ,
                       msgbasico);


              END IF;



        END IF;

        IF  i_observaciones<>V_observaciones THEN
            update permiso
            set observaciones=V_observaciones
             ,    fecha_modi=sysdate
            where id_permiso=i_id_permiso and rownum<2;
        END IF;




        --chm 21/03/2017
        --ACTUALIZAMOS LA FECHA FIN PARA LAS BAJAS
        IF  i_ID_TIPO_PERMISO='11300'  THEN

            --Descuento por baja por enfermedad justificadas 02/05/2017
            IF  (V_DESCUENTO_BAJAS='SI') AND i_DESCUENTO_BAJAS='NO'   then --añadido 2/05/2017

                IF    V_DESCUENTO_BAJAS='SI' AND V_DESCUENTO_DIAS IS  NULL   THEN
                       msgBasico:='Descuento a bolsa número de días tiene que ser mayor que 0.';
                      return;
                      rollback;
                END IF;

                IF   V_DESCUENTO_DIAS > 3 AND V_DESCUENTO_DIAS IS NOT NULL   THEN
                       msgBasico:='Descuento a bolsa son solo maximo 3 días.';
                      return;
                      rollback;
               END IF;

               i_dias_descuenta:= nvl(V_DESCUENTO_DIAS,0);

               MOV_BOLSA_DESCUENTO_ENFERME
               (i_ID_ANO ,i_ID_FUNCIONARIO , i_tipo_funcionario,
               i_FECHA_INICIO , i_dias_descuenta,    ---------v_num_dias ,
                todo_ok_basico, msgbasico);

               IF todo_ok_basico=1 then
                     -- msgsalida:=msgbasico;
                      rollback;
                      return;
               END IF;

                update permiso
                    set descuento_bajas=V_DESCUENTO_BAJAS,
                        descuento_dias=i_dias_descuenta,
                        fecha_modi=sysdate
               where id_permiso=i_id_permiso and rownum<2;

            END IF;

            update permiso
            set fecha_fin=V_FECHA_FIN ,
                num_dias=V_FECHA_FIN- i_fecha_inicio+1 ,
                fecha_modi=sysdate
            where id_permiso=i_id_permiso and rownum<2;

             --El funcionario Ficha ??
             i_ficha:=1;
             BEGIN
                 SELECT
                  distinct codpers
                  into i_codpers
                  FROM
                              personal_new p  ,presenci pr,
                               apliweb_usuario  u
                  WHERE
                              p.id_funcionario=I_ID_FUNCIONARIO  and
                               LPAD(p.id_funcionario,6,'0')=LPAD(u.id_funcionario,6,'0') AND
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
              END;

             IF i_ficha = 1 THEN
                -- Actualizamos el finger
                actualiza_finger(i_id_ano ,
                       i_id_funcionario ,
                       i_id_tipo_permiso ,
                       i_fecha_inicio ,
                       V_FECHA_FIN,
                       i_codpers,
                       v_id_estado_permiso,
                       todo_ok_basico ,
                       msgbasico);
              END IF;
        END IF;--FIN baja

        --Faltaria OBSERVACIONES

END IF;

msgbasico:='Todo Correcto.';
  todo_ok_basico:='0';
commit;

end PERMISOS_EDITA_RRHH_NEW;
/

