--------------------------------------------------------------------------------
-- PROCEDURE: PERMISOS_ANULA_USUARIO
--------------------------------------------------------------------------------
-- Propósito: Anular permiso solicitado por el usuario antes de su inicio
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Permite al usuario anular su solicitud de permiso siempre que:
--   - El permiso aún no haya comenzado (fecha inicio > fecha actual)
--   - El permiso no sea de tipo baja por enfermedad (11100, 11300)
--   - El usuario sea el propietario de la solicitud
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
--   41 - Anulado por USUARIO (añadido 03/03/2017)
--   80 - Concedido RRHH
--
-- Parámetros:
--   V_ID_PERMISO      - ID del permiso a anular
--   V_ID_FUNCIONARIO  - ID del funcionario que solicita la anulación
--   todo_ok_Basico    - 0=OK, 1=Error (OUT)
--   msgBasico         - Mensaje resultado (OUT)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   01/04/2017 - CHM - Validación tipo funcionario
--   03/03/2017 - CHM - Añadido estado 41 (Anulado por usuario)
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH.PERMISOS_ANULA_USUARIO(
  V_ID_PERMISO     IN NUMBER,
  V_ID_FUNCIONARIO IN VARCHAR2,
  todo_ok_Basico   OUT INTEGER,
  msgBasico        OUT VARCHAR2
) IS
  
  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  
  -- Estados de permiso
  C_ESTADO_PENDIENTE_JS CONSTANT NUMBER := 20;
  C_ESTADO_PENDIENTE_JA CONSTANT NUMBER := 21;
  C_ESTADO_PENDIENTE_RRHH CONSTANT NUMBER := 22;
  C_ESTADO_CONCEDIDO CONSTANT NUMBER := 80;
  C_ESTADO_RECHAZADO_JS CONSTANT NUMBER := 30;
  C_ESTADO_RECHAZADO_JA CONSTANT NUMBER := 31;
  C_ESTADO_DENEGADO_RRHH CONSTANT NUMBER := 32;
  C_ESTADO_ANULADO_RRHH CONSTANT NUMBER := 40;
  C_ESTADO_ANULADO_USUARIO CONSTANT NUMBER := 41;
  
  -- Tipos de permiso especiales
  C_PERMISO_BAJA_ENFERMEDAD_1 CONSTANT VARCHAR2(5) := '11100';
  C_PERMISO_BAJA_ENFERMEDAD_2 CONSTANT VARCHAR2(5) := '11300';
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  
  -- Códigos incidencia
  C_CODINCI_EXCLUIR CONSTANT NUMBER := 999;
  
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
  I_id_tipo_dias VARCHAR2(1);
  I_ID_GRADO VARCHAR2(50);
  i_num_dias NUMBER(5, 2);
  i_justificacion VARCHAR2(2);
  i_observaciones VARCHAR2(1500);
  
  -- Turnos (bomberos)
  i_t1 VARCHAR2(1);
  i_t2 VARCHAR2(1);
  i_t3 VARCHAR2(1);
  
  -- Control
  i_permiso_no_encontrado NUMBER(1) := 0;
  i_ficha NUMBER(1) := 0;
  i_codpers VARCHAR2(5);
  i_tipo_funcionario NUMBER(2);
  i_id_js NUMBER;
  fecha_hoy DATE;
  
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
  i_DESC_TIPO_PERMISO VARCHAR2(200);
  i_CADENA2 VARCHAR2(500);

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER DATOS DEL PERMISO
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT p.id_permiso,
           p.id_ano,
           p.id_funcionario,
           p.id_tipo_permiso,
           p.id_estado,
           p.fecha_inicio,
           p.fecha_fin,
           p.hora_inicio,
           p.hora_fin,
           p.justificacion,
           DECODE(p.observaciones, NULL, '0', p.observaciones) AS observaciones,
           p.ID_GRADO,
           p.id_tipo_dias,
           tr.DES_TIPO_PERMISO_LARGA,
           DECODE(p.id_tipo_permiso,
                  C_PERMISO_COMPENSATORIO,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') ||
                  CHR(10) || 'Hora de Inicio: ' || p.HORA_INICIO || CHR(10) ||
                  'Hora Fin: ' || p.HORA_FIN,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') ||
                  CHR(10) || 'Fecha Fin: ' || TO_CHAR(p.FECHA_FIN, 'DD-MON-YY') || 
                  CHR(10) || 'Numero de Dias: ' || p.NUM_DIAS) AS cadena,
           p.NUM_DIAS,
           p.tu1_14_22,
           p.tu2_22_06,
           p.tu3_04_14,
           p.firmado_js
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
           i_id_js
      FROM permiso p
      JOIN tr_tipo_permiso tr 
        ON tr.id_ano = p.id_ano 
       AND tr.id_tipo_permiso = p.id_tipo_permiso
     WHERE p.id_permiso = v_id_permiso;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_permiso_no_encontrado := 1;
  END;
  
  -- Validar si el permiso existe
  IF i_permiso_no_encontrado <> 0 THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operación no realizada. Permiso no encontrado: ' || V_ID_PERMISO;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: VALIDACIONES DE SEGURIDAD
  --------------------------------------------------------------------------------
  
  -- Validación 1: El usuario debe ser el propietario del permiso
  IF V_ID_FUNCIONARIO <> I_id_funcionario THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operación no realizada. Avisar a RRHH.';
    RETURN;
  END IF;
  
  -- Validación 2: No se pueden anular permisos de baja
  IF I_id_tipo_permiso IN (C_PERMISO_BAJA_ENFERMEDAD_1, C_PERMISO_BAJA_ENFERMEDAD_2) THEN
    msgBasico := 'No se puede anular permisos de Bajas. Solamente por RRHH.';
    todo_ok_basico := C_ERROR;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: OBTENER TIPO DE FUNCIONARIO
  -- Actualización: 01/04/2017 - CHM
  --------------------------------------------------------------------------------
  
  i_tipo_funcionario := 10; -- Valor por defecto
  
  BEGIN
    SELECT tipo_funcionario2
      INTO i_tipo_funcionario
      FROM personal_new
     WHERE id_funcionario = I_id_funcionario
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
  -- FASE 5: VALIDACIÓN DE FECHAS
  -- El permiso solo se puede anular si aún no ha comenzado
  --------------------------------------------------------------------------------
  
  SELECT TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY') 
    INTO fecha_hoy 
    FROM DUAL;
  
  IF fecha_hoy >= I_FECHA_INICIO THEN
    msgBasico := 'Para anular, la Fecha de Inicio del permiso tiene que ser mayor que la fecha actual.';
    todo_ok_basico := C_ERROR;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: ANULACIÓN DEL PERMISO
  -- Solo si está en estados: Pendiente (20, 21, 22) o Concedido (80)
  --------------------------------------------------------------------------------
  
  IF I_ID_ESTADO_PERMISO IN (C_ESTADO_PENDIENTE_JS, 
                              C_ESTADO_PENDIENTE_JA, 
                              C_ESTADO_PENDIENTE_RRHH, 
                              C_ESTADO_CONCEDIDO) THEN
    
    -- Denegar el permiso (revertir cambios en contadores)
    permiso_denegado(
      v_id_permiso,
      todo_ok_basico,
      msgBasico
    );
    
    IF todo_ok_basico = C_ERROR THEN
      msgBasico := 'Operación no realizada. PERMISO DENEGADO.';
      ROLLBACK;
      RETURN;
    END IF;
    
    -- Actualizar estado del permiso a "Anulado por Usuario"
    UPDATE PERMISO
       SET id_Estado = C_ESTADO_ANULADO_USUARIO,
           observaciones = i_observaciones || ' Anulación por el usuario',
           fecha_modi = SYSDATE
     WHERE ID_PERMISO = V_ID_PERMISO
       AND ROWNUM < 2;
    
    --------------------------------------------------------------------------------
    -- FASE 7: ACTUALIZAR SISTEMA DE FICHAJE (SI APLICA)
    --------------------------------------------------------------------------------
    
    -- Verificar si el funcionario tiene fichaje activo
    i_ficha := 1;
    BEGIN
      SELECT DISTINCT codpers
        INTO i_codpers
        FROM personal_new p
        JOIN apliweb_usuario u 
          ON LPAD(p.id_funcionario, 6, '0') = LPAD(u.id_funcionario, 6, '0')
        JOIN presenci pr 
          ON u.id_fichaje = pr.codpers
       WHERE p.id_funcionario = I_ID_FUNCIONARIO
         AND u.id_fichaje IS NOT NULL
         AND pr.codinci <> C_CODINCI_EXCLUIR
         AND ROWNUM < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_ficha := 0;
    END;
    
    -- Actualizar fichaje según tipo de permiso
    IF I_FICHA = 1 AND I_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO THEN
      -- Actualizar finger para permisos generales
      actualiza_finger(
        i_id_ano,
        i_id_funcionario,
        i_id_tipo_permiso,
        i_fecha_inicio,
        i_fecha_fin,
        i_codpers,
        C_ESTADO_ANULADO_USUARIO, -- Nuevo estado
        todo_ok_basico,
        msgBasico
      );
      
      IF todo_ok_basico = C_ERROR THEN
        ROLLBACK;
        RETURN;
      END IF;
      
    ELSIF I_FICHA = 1 AND I_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO AND
          I_ID_ESTADO_PERMISO IN (C_ESTADO_ANULADO_RRHH, C_ESTADO_DENEGADO_RRHH, C_ESTADO_ANULADO_USUARIO) THEN
      -- Anular fichaje compensatorio en transacciones y persfich
      ANULA_FICHAJE_FINGER_15000(
        i_id_ano,
        i_id_funcionario,
        i_fecha_inicio,
        i_hora_inicio,
        i_hora_fin,
        i_codpers,
        0,
        C_PERMISO_COMPENSATORIO,
        todo_ok_basico,
        msgBasico
      );
      
      IF todo_ok_basico = C_ERROR THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
    
    --------------------------------------------------------------------------------
    -- FASE 8: ENVIAR NOTIFICACIONES POR CORREO
    --------------------------------------------------------------------------------
    
    -- Obtener correos del funcionario y jefe de sección
    BEGIN
      SELECT MIN(peticion), 
             MIN(nombre_peticion), 
             MIN(js)
        INTO correo_v_funcionario, 
             i_nombre_peticion, 
             correo_js
        FROM (SELECT login || '@aytosalamanca.es' AS peticion,
                     SUBSTR(DIST_NAME, INSTR(DIST_NAME, '=', 1) + 1, 
                            INSTR(DIST_NAME, ',', 1) - INSTR(DIST_NAME, '=', 1) - 1) AS nombre_peticion,
                     '' AS js
                FROM apliweb_usuario
               WHERE id_funcionario = TO_CHAR(I_ID_FUNCIONARIO)
              UNION
              SELECT '' AS peticion,
                     '' AS nombre_peticion,
                     login || '@aytosalamanca.es' AS js
                FROM apliweb_usuario
               WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_js, 6, '0'));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_js := '';
    END;
    
    -- Preparar correo
    i_sender := correo_v_funcionario;
    I_ccrecipient := '';
    i_recipient := correo_v_funcionario;
    
    -- Generar mensaje de anulación
    -- Actualización: 01/04/2017 - CHM
    envia_correo_informa_new(
      '0',
      i_ID_TIPO_PERMISO,
      i_nombre_peticion,
      i_DESC_TIPO_PERMISO,
      'Anulación por el Usuario',
      i_fecha_inicio,
      i_fecha_fin,
      i_hora_inicio,
      i_hora_fin,
      i_id_grado,
      i_id_tipo_dias,
      i_num_dias,
      i_t1,
      i_t2,
      i_t3,
      i_TIPO_FUNCIONARIO,
      i_mensaje
    );
    
    I_message := i_mensaje;
    i_subject := 'Anulación de Permiso por USUARIO.';
    
    -- Enviar correo al jefe de sección
    envio_correo(
      i_sender,
      correo_js,
      I_ccrecipient,
      i_subject,
      I_message
    );
    
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 9: FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  msgBasico := 'Permiso anulado correctamente.';
  todo_ok_basico := C_OK;
  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo robusto de excepciones no controladas
    todo_ok_basico := C_ERROR;
    msgBasico := 'Error inesperado al anular permiso: ' || SQLERRM ||
                 ' | Permiso: ' || V_ID_PERMISO ||
                 ' | Funcionario: ' || V_ID_FUNCIONARIO;
    ROLLBACK;
    
END PERMISOS_ANULA_USUARIO;
/

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
-- 41 Anulado por USUARIO //a�adido 03/03/2017
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
        observaciones=i_observaciones || 'Anulaci�n por el usuario'     ,
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


          --ENVIO DE CORREO AL JEFE FUNCIONARIO CON LA ANULACI�n
           i_sender      := correo_v_funcionario;
           I_ccrecipient := '';
          i_recipient   := correo_v_funcionario;
            I_message     := '';

         --chm 1/04/2017,DENEGACION
         envia_correo_informa_new('0',  i_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPo_PERMISO,
                        'Anulaci�n por el Usuario',--motivo
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
        i_subject := 'Anulaci�n de Permiso por USUARIO.';
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

