--------------------------------------------------------------------------------
-- PROCEDURE: PERMISOS_EDITA_RRHH_NEW
--------------------------------------------------------------------------------
-- Propósito: Editar permisos existentes desde RRHH
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Permite a RRHH modificar permisos ya registrados. Soporta:
--   - Cambio de estado: Concedido(80) → Anulado(40)
--   - Cambio de estado: Pendiente(20/22) → Anulado(40)
--   - Cambio de estado: Concedido(80) → Denegado(32)
--   - Modificación de justificación (SI/NO)
--   - Modificación de observaciones
--   - Actualización fecha fin (bajas por enfermedad 11300)
--   - Aplicación descuento a bolsa (bajas 11300)
--
-- Estados de permiso:
--   10 - Solicitado
--   20 - Pendiente Firma Jefe Sección
--   21 - Pendiente Firma Jefe Área
--   22 - Pendiente Visto Bueno RRHH
--   30 - Rechazado Jefe Sección
--   31 - Rechazado Jefe Área
--   32 - Denegado RRHH
--   40 - Anulado RRHH
--   41 - Anulado por Usuario
--   80 - Concedido RRHH
--
-- Parámetros:
--   V_OBSERVACIONES       - Nuevas observaciones (IN)
--   V_ID_PERMISO          - ID del permiso a editar (IN)
--   V_ID_ESTADO_PERMISO   - Nuevo estado del permiso (IN)
--   V_JUSTIFICACION       - Nueva justificación SI/NO (IN)
--   V_ID_USUARIO          - Usuario RRHH que edita (IN)
--   todo_ok_Basico        - 0=OK, 1=Error (OUT)
--   msgBasico             - Mensaje resultado (OUT)
--   V_FECHA_FIN           - Nueva fecha fin (bajas) (IN)
--   V_DESCUENTO_BAJAS     - Descontar de bolsa SI/NO (IN)
--   V_DESCUENTO_DIAS      - Número de días a descontar (IN)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   02/05/2017 - CHM - Descuento bolsa para bajas 11300
--   21/03/2017 - CHM - Actualización fecha fin bajas
--   01/04/2017 - CHM - Validación tipo funcionario
--   03/04/2017 - CHM - Correo denegación
--   14/02/2018 - CHM - Actualización finger al cambiar justificación
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH."PERMISOS_EDITA_RRHH_NEW" (
            V_OBSERVACIONES IN VARCHAR2,
            V_ID_PERMISO IN NUMBER,
            V_ID_ESTADO_PERMISO IN NUMBER,
            V_JUSTIFICACION IN VARCHAR2,
            V_ID_USUARIO IN VARCHAR2,
            todo_ok_Basico OUT INTEGER,
            msgBasico OUT VARCHAR2,
            V_FECHA_FIN IN DATE,
            V_DESCUENTO_BAJAS IN VARCHAR2,
            V_DESCUENTO_DIAS IN VARCHAR2
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  
  -- Estados de permiso
  C_ESTADO_PENDIENTE_JS CONSTANT NUMBER := 20;
  C_ESTADO_PENDIENTE_RRHH CONSTANT NUMBER := 22;
  C_ESTADO_DENEGADO_RRHH CONSTANT NUMBER := 32;
  C_ESTADO_ANULADO_RRHH CONSTANT NUMBER := 40;
  C_ESTADO_CONCEDIDO CONSTANT NUMBER := 80;
  
  -- Tipos de permiso
  C_PERMISO_BAJA_SIN_DESCUENTO CONSTANT VARCHAR2(5) := '11300';
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  
  -- Límites y valores
  C_MAX_DESCUENTO_DIAS CONSTANT NUMBER := 3;
  C_FLAG_SI CONSTANT VARCHAR2(2) := 'SI';
  C_FLAG_NO CONSTANT VARCHAR2(2) := 'NO';
  C_CODINCI_EXCLUIR CONSTANT NUMBER := 999;
  C_EMAIL_DOMAIN CONSTANT VARCHAR2(20) := '@aytosalamanca.es';
  C_EMAIL_PERMISOS CONSTANT VARCHAR2(30) := 'permisos@aytosalamanca.es';
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES (OPTIMIZADAS)
  --------------------------------------------------------------------------------
  
  -- Datos del permiso
  I_id_permiso NUMBER;
  I_id_ano NUMBER(4);
  I_id_funcionario NUMBER(6);
  I_id_tipo_permiso VARCHAR2(5);
  I_id_estado_permiso NUMBER(2);
  I_fecha_inicio DATE;
  I_fecha_fin DATE;
  I_hora_inicio VARCHAR2(5);
  I_hora_fin VARCHAR2(5);
  i_justificacion VARCHAR2(2);
  i_observaciones VARCHAR2(1500);
  i_ID_GRADO VARCHAR2(50);
  i_num_dias NUMBER;
  I_id_tipo_dias VARCHAR2(5);
  i_DESC_TIPO_PERMISO VARCHAR2(200);
  i_CADENA2 VARCHAR2(500);
  i_DESCUENTO_BAJAS VARCHAR2(5);
  
  -- Turnos (bomberos)
  i_t1 VARCHAR2(1);
  i_t2 VARCHAR2(1);
  i_t3 VARCHAR2(1);
  
  -- Control
  i_permiso_no_encontrado NUMBER(1);
  i_cambia_estado NUMBER(1);
  i_ficha NUMBER(1);
  i_codpers VARCHAR2(5);
  i_dias_descuenta NUMBER;
  i_id_js NUMBER(6);
  i_tipo_funcionario NUMBER(2);
  
  -- Correos y mensajes
  correo_v_funcionario VARCHAR2(100);
  i_nombre_peticion VARCHAR2(200);
  correo_js VARCHAR2(100);
  i_sender VARCHAR2(100);
  i_recipient VARCHAR2(100);
  I_ccrecipient VARCHAR2(100);
  i_subject VARCHAR2(200);
  I_message VARCHAR2(4000);
  i_mensaje VARCHAR2(4000);

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';
  i_permiso_no_encontrado := 0;
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER DATOS DEL PERMISO ACTUAL
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT id_permiso,
           p.id_ano,
           id_funcionario,
           p.id_tipo_permiso,
           id_estado,
           p.fecha_inicio,
           p.fecha_fin,
           hora_inicio,
           hora_fin,
           DECODE(p.JUSTIFICACION, C_FLAG_NO, C_FLAG_NO, C_FLAG_SI),
           DECODE(observaciones, NULL, '0', OBSERVACIONES),
           ID_GRADO,
           p.id_tipo_dias,
           DES_TIPO_PERMISO_LARGA,
           DECODE(p.id_tipo_permiso,
                  C_PERMISO_COMPENSATORIO,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') ||
                  CHR(10) || 'Hora de Inicio: ' || HORA_INICIO || CHR(10) ||
                  'Hora Fin: ' || HORA_FIN,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY) ||
                  CHR(10) || 'Fecha Fin:    ' ||
                  TO_CHAR(p.FECHA_FIN, 'DD-MON-YY') || CHR(10) ||
                  'Numero de Dias: ' || p.NUM_DIAS),
           p.NUM_DIAS,
           tu1_14_22,
           tu2_22_06,
           tu3_04_14,
           firmado_js,
           NVL(descuento_bajas, C_FLAG_NO)
      INTO I_id_permiso,
           I_id_ano,
           I_id_funcionario,
           I_id_tipo_permiso,
           I_id_estado_permiso,
           I_fecha_inicio,
           I_fecha_fin,
           I_hora_inicio,
           I_hora_fin,
           i_justificacion,
           i_observaciones,
           I_ID_GRADO,
           I_id_tipo_dias,
           i_DESC_TIPO_PERMISO,
           i_CADENA2,
           i_num_dias,
           i_t1,
           i_t2,
           i_t3,
           i_id_js,
           i_DESCUENTO_BAJAS
      FROM permiso p
      JOIN tr_tipo_permiso tr 
        ON tr.id_ano = p.id_ano 
       AND p.id_tipo_permiso = tr.id_tipo_permiso
     WHERE id_permiso = v_id_permiso;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_permiso_no_encontrado := 1;
  END;
  
  -- Validar existencia del permiso
  IF i_permiso_no_encontrado <> 0 THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operación no realizada. Permiso no encontrado: ' || V_ID_PERMISO;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: OBTENER TIPO DE FUNCIONARIO
  -- Actualización: 01/04/2017 - CHM
  --------------------------------------------------------------------------------
  
  i_tipo_funcionario := 10; -- Valor por defecto
  
  BEGIN
    SELECT tipo_funcionario2
      INTO i_tipo_funcionario
      FROM personal_new pe
     WHERE id_funcionario = i_id_funcionario 
       AND ROWNUM < 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_tipo_funcionario := -1;
  END;
  
  IF i_tipo_funcionario = -1 THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operación no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: VALIDAR CAMBIO DE ESTADO PERMITIDO
  -- Solo se permiten estos cambios:
  --   - Concedido(80) / Pendiente(20,22) → Anulado(40)
  --   - Concedido(80) → Denegado(32)
  --------------------------------------------------------------------------------
  
  i_cambia_estado := 0;
  
  IF ((I_id_estado_permiso IN (C_ESTADO_CONCEDIDO, C_ESTADO_PENDIENTE_RRHH, C_ESTADO_PENDIENTE_JS) AND
       V_ID_ESTADO_PERMISO IN (C_ESTADO_CONCEDIDO, C_ESTADO_ANULADO_RRHH)) OR
      (V_ID_ESTADO_PERMISO = C_ESTADO_DENEGADO_RRHH AND 
       I_ID_ESTADO_PERMISO = C_ESTADO_CONCEDIDO)) THEN
    -- Cambio permitido
    i_cambia_estado := 0;
  ELSIF I_id_estado_permiso <> v_id_estado_permiso THEN
    -- Cambio no permitido
    i_cambia_estado := 1;
  END IF;
  
  IF i_cambia_estado <> 0 THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operación no realizada. Los únicos cambios permitidos son: ' ||
                 'Concedido → Anulado y Pde Firma → Anulado. ' ||
                 'Estado actual: ' || I_id_estado_permiso || 
                 ', Estado solicitado: ' || v_id_estado_permiso;
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



    END IF;--si es una denegaci�n

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
            IF  (V_DESCUENTO_BAJAS='SI') AND i_DESCUENTO_BAJAS='NO'   then --a�adido 2/05/2017

                IF    V_DESCUENTO_BAJAS='SI' AND V_DESCUENTO_DIAS IS  NULL   THEN
                       msgBasico:='Descuento a bolsa n�mero de d�as tiene que ser mayor que 0.';
                      return;
                      rollback;
                END IF;

                IF   V_DESCUENTO_DIAS > 3 AND V_DESCUENTO_DIAS IS NOT NULL   THEN
                       msgBasico:='Descuento a bolsa son solo maximo 3 d�as.';
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

