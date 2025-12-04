CREATE OR REPLACE PROCEDURE RRHH."PERMISOS_ANULA_USUARIO"
       (    V_ID_PERMISO in number,
            V_ID_FUNCIONARIO in varchar2,
            todo_ok_Basico out integer,
            msgBasico out varchar2

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
fecha_hoy date;

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
                p.justificacion,
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
                firmado_js --firmado js

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
                i_id_js

      from permiso p, tr_tipo_permiso tr
     where id_permiso = v_id_permiso
       and tr.id_ano = p.id_ano
       and p.id_tipo_permiso = tr.id_tipo_permiso;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       i_permiso_no_encontrado:=1;
  END;


IF i_permiso_no_encontrado <> 0 THEN
     todo_ok_basico:=1;
     msgBasico:='Operacion no realizada. Permiso no encontrado. d' || V_ID_PERMISO;
     RETURN;
END IF;

IF  V_ID_FUNCIONARIO <>i_id_funcionario THEN
     todo_ok_basico:=1;
     msgBasico:='Operacion no realizada. Avisar a RRHH.'  || V_ID_FUNCIONARIO  || '--' || i_id_funcionario;
     RETURN;
END IF;
IF I_id_tipo_permiso = '11100' OR  I_id_tipo_permiso = '11300' then
   msgbasico:='No se puede Anular permisos de Bajas. Solamente por RRHH.';
   todo_ok_basico:='1';
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


select to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy') into fecha_hoy from dual;

--La fecha de hoy mayor a la fecha de inicio al permiso
IF FECHA_HOY < I_FECHA_INICIO THEN

--ANULACION PERMISO
IF ( I_ID_ESTADO_PERMISO=20 OR I_ID_ESTADO_PERMISO=21 OR I_ID_ESTADO_PERMISO=22 OR
     I_ID_ESTADO_PERMISO=80)      THEN   --ANULACION

   permiso_denegado(v_id_permiso,
                    todo_ok_basico ,
                    msgbasico );


   IF todo_ok_basico=1 then
      msgBasico      := 'Operacion no realizada.PERMISO DENEGADO.';
        rollback;
        return;
   END IF;

   --ANULADO POR USUARIO
   UPDATE PERMISO
   SET  id_Estado='41',
        observaciones=i_observaciones || 'Anulación por el usuario'     ,
        fecha_modi=sysdate
   WHERE   ID_PERMISO=V_ID_PERMISO and rownum<2;

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


    IF I_FICHA = 1  AND I_ID_TIPO_PERMISO<>'15000' then
        -- Actualizamos el finger
        actualiza_finger(i_id_ano ,
                       i_id_funcionario ,
                       i_id_tipo_permiso ,
                       i_fecha_inicio ,
                       i_fecha_fin ,
                       i_codpers,
                      '41',--CAMBIADO AL NUEVO ESTADO
                       todo_ok_basico ,
                       msgbasico);
        --Hay errores fin
        IF todo_ok_basico=1 then
             rollback;
             return;
        END IF;
    ELSE IF I_FICHA = 1  AND i_ID_TIPO_PERMISO='15000' AND (i_ID_ESTADO_PERMISO=40
          OR i_ID_ESTADO_PERMISO=32   OR i_ID_ESTADO_PERMISO=41)
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


          --ENVIO DE CORREO AL JEFE FUNCIONARIO CON LA ANULACIón
           i_sender      := correo_v_funcionario;
           I_ccrecipient := '';
          i_recipient   := correo_v_funcionario;
            I_message     := '';

         --chm 1/04/2017,DENEGACION
         envia_correo_informa_new('0',  i_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPo_PERMISO,
                        'Anulación por el Usuario',--motivo
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
        i_subject := 'Anulación de Permiso por USUARIO.';
        envio_correo(i_sender,
                     correo_js,
                     I_ccrecipient,
                     i_subject,
                     I_message);

      /*   envio_correo(i_sender ,     'carlos@aytosalamanca.es' ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message || ' ' ||  V_ID_PERMISO || ' ' ||   V_ID_FUNCIONARIO);
      */
 END IF;

  msgbasico:='Permiso anulado correctamente.';
  todo_ok_basico:='0';
commit;

ELSE
  msgbasico:='Para anular la Fecha de Inicio del permiso tiene que ser menor que la fecha actual .';
  todo_ok_basico:='1';
   RETURN;

END IF;


end PERMISOS_ANULA_USUARIO;
/

