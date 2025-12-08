/**
 * VBUENO_AUSENCIA_RRHH
 *
 * @description
 * Permite a RRHH dar el visto bueno final (autorizar o denegar) a ausencias
 * que están en estado 22 (Pendiente visto bueno RRHH).
 *
 * @details
 * Transiciones de estado posibles desde estado 22:
 * - 22 → 80 (Concedido): RRHH autoriza la ausencia
 * - 22 → 32 (Denegado): RRHH deniega la ausencia
 *
 * Operaciones realizadas al AUTORIZAR (V_ID_FIRMA=1):
 * - Cambio estado a 80 (Concedido)
 * - Registrar firmado_rrhh y fecha_rrhh
 * - Insertar ausencia en finger (sistema fichaje) si el usuario ficha
 * - Envío correo notificación a funcionario, JS y JA
 * - Registrar operación en histórico
 *
 * Operaciones realizadas al DENEGAR (V_ID_FIRMA=0):
 * - Cambio estado a 32 (Denegado RRHH)
 * - Registrar motivo denegación
 * - Envío correo notificación con motivo a funcionario, JS y JA
 * - Registrar operación en histórico
 * - NO se revierte bolsa (ya fue descontada en inserción)
 *
 * Estados ausencias:
 * 10=Solicitado, 20=Pde JS, 21=Pde JA, 22=Pde RRHH
 * 30=Rechazado JS, 31=Rechazado JA, 32=Denegado RRHH
 * 40=Anulado RRHH, 41=Anulado Usuario, 80=Concedido
 *
 * @param V_ID_FIRMA             IN 1=Autorizar, 0=Denegar
 * @param V_ID_FUNCIONARIO_FIRMA IN ID del funcionario RRHH que firma
 * @param V_ID_AUSENCIA          IN ID de la ausencia a firmar
 * @param V_ID_MOTIVO            IN Motivo denegación (solo si V_ID_FIRMA=0)
 * @param todo_ok_Basico         OUT 0=Éxito, 1=Error
 * @param msgBasico              OUT Mensaje resultado
 *
 * @notes
 * - Solo válido para ausencias en estado 22 (Pendiente RRHH)
 * - Valida jerarquía firmas (JS/JA) desde funcionario_firma
 * - Finger: solo mete si usuario ficha (codpers en presenci)
 * - Formato total_horas para finger: HH:MI (ej: 08:30)
 * - Correos enviados: funcionario (TO), JS y JA (CC)
 *
 * @see mete_fichaje_finger_new  Inserción en sistema finger
 * @see envio_correo             Envío notificación
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 06/04/2010 (finger integration)
 * @version 2.0
 */
CREATE OR REPLACE PROCEDURE RRHH.VBUENO_AUSENCIA_RRHH (
  V_ID_FIRMA             IN VARCHAR2,
  V_ID_FUNCIONARIO_FIRMA IN NUMBER,
  V_ID_AUSENCIA          IN NUMBER,
  V_ID_MOTIVO            IN VARCHAR2,
  todo_ok_Basico         OUT INTEGER,
  msgBasico              OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_PDE_RRHH   CONSTANT VARCHAR2(2) := '22';
  C_ESTADO_CONCEDIDO  CONSTANT VARCHAR2(2) := '80';
  C_ESTADO_DENEGADO   CONSTANT VARCHAR2(2) := '32';
  C_FIRMA_AUTORIZA    CONSTANT VARCHAR2(1) := '1';
  C_FIRMA_DENIEGA     CONSTANT VARCHAR2(1) := '0';
  
  -- Variables ausencia
  i_no_hay_ausencias   NUMBER;
  i_no_hay_firma       NUMBER;
  i_id_funcionario     VARCHAR2(6);
  i_firma              VARCHAR2(100);
  i_id_estado          VARCHAR2(2);
  i_id_js              VARCHAR2(6);
  i_id_delegado_js     VARCHAR2(6);
  i_id_ja              VARCHAR2(6);
  i_id_delegado_ja     VARCHAR2(6);
  i_DESC_TIPO_AUSENCIA VARCHAR2(100);
  i_CADENA2            VARCHAR2(100);
  i_id_ano             NUMBER(4);
  i_dias               NUMBER(4);
  v_id_tipo_ausencia   VARCHAR2(3);
  v_fecha_inicio       DATE;
  v_fecha_fin          DATE;
  V_HORA_INICIO        VARCHAR2(5);
  V_HORA_FIN           VARCHAR2(5);
  V_TOTAL_HORAS        NUMBER;
  v_total_horas_mete   VARCHAR2(12);
  
  -- Variables finger
  i_ficha   NUMBER;
  i_codpers VARCHAR2(5);
  
  -- Variables correo
  correo_v_funcionario VARCHAR2(100);
  i_nombre_peticion    VARCHAR2(100);
  correo_js            VARCHAR2(100);
  correo_ja            VARCHAR2(100);
  i_sender             VARCHAR2(100);
  i_recipient          VARCHAR2(100);
  I_ccrecipient        VARCHAR2(100);
  i_subject            VARCHAR2(100);
  I_message            VARCHAR2(4000);
  i_desc_mensaje       VARCHAR2(4000);

BEGIN

  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR AUSENCIA Y OBTENER DATOS
  --------------------------------------------------------------------------------
  
  todo_ok_basico := 0;
  msgBasico := '';
  i_no_hay_ausencias := 0;
  
  BEGIN
    SELECT total_horas,
           SUBSTR(TO_CHAR(a.FECHA_INICIO, 'DD/MM/YYYY HH24:MI'), 12, 5) AS HORA_INICIO,
           SUBSTR(TO_CHAR(a.FECHA_FIN, 'DD/MM/YYYY HH24:MI'), 12, 5) AS HORA_FIN,
           a.FECHA_INICIO,
           a.fecha_fin,
           a.id_tipo_ausencia,
           a.id_ano,
           a.id_estado,
           id_funcionario,
           DESC_TIPO_AUSENCIA
    INTO   V_TOTAL_HORAS,
           V_HORA_INICIO,
           V_HORA_FIN,
           v_fecha_inicio,
           v_fecha_fin,
           v_id_tipo_ausencia,
           i_id_ano,
           i_id_estado,
           i_id_funcionario,
           i_DESC_TIPO_AUSENCIA
    FROM   ausencia a,
           tr_tipo_ausencia tr
    WHERE  id_ausencia = V_id_ausencia
      AND  a.id_tipo_ausencia = tr.id_tipo_ausencia
      AND  (anulado = 'NO' OR ANULADO IS NULL);
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_ausencias := -1;
  END;
  
  IF i_no_hay_ausencias = -1 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada.Ausencia no existe.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 2: VALIDAR JERARQUÍA FIRMAS
  --------------------------------------------------------------------------------
  
  i_no_hay_firma := 0;
  
  BEGIN
    SELECT id_js,
           id_delegado_js,
           id_ja,
           id_delegado_ja
    INTO   i_id_js,
           i_id_delegado_js,
           i_id_ja,
           i_id_delegado_ja
    FROM   funcionario_firma
    WHERE  id_funcionario = i_id_funcionario;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_firma := -1;
  END;
  
  IF i_no_hay_firma = -1 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. No hay personas para firmar.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: OBTENER CORREOS ELECTRÓNICOS
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT MIN(peticion),
           MIN(nombre_peticion),
           MIN(js),
           MIN(ja)
    INTO   correo_v_funcionario,
           i_nombre_peticion,
           correo_js,
           correo_ja
    FROM   (SELECT login || '@aytosalamanca.es' AS peticion,
                   SUBSTR(DIST_NAME, INSTR(DIST_NAME, '=', 1) + 1, INSTR(DIST_NAME, ',', 1) - INSTR(DIST_NAME, '=', 1) - 1) AS nombre_peticion,
                   '' AS js,
                   '' AS ja
            FROM   apliweb_usuario
            WHERE  id_funcionario = TO_CHAR(i_id_funcionario)
            UNION
            SELECT '' AS peticion,
                   '' AS nombre_peticion,
                   login || '@aytosalamanca.es' AS js,
                   '' AS ja
            FROM   apliweb_usuario
            WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_js, 6, '0')
            UNION
            SELECT '' AS peticion,
                   '' AS nombre_peticion,
                   '' AS ja,
                   login || '@aytosalamanca.es' AS ja
            FROM   apliweb_usuario
            WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_ja, 6, '0'));
            
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END;
  
  IF i_id_js = '' AND i_id_ja = '' THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: VALIDAR ESTADO Y PROCESAR FIRMA RRHH
  --------------------------------------------------------------------------------
  
  IF i_id_estado = C_ESTADO_PDE_RRHH THEN
    
    --------------------------------------------------------------------------------
    -- FASE 5A: AUTORIZAR AUSENCIA (V_ID_FIRMA=1 → estado 80)
    --------------------------------------------------------------------------------
    
    IF V_ID_FIRMA = C_FIRMA_AUTORIZA THEN
      
      -- Actualizar ausencia a concedida (80)
      UPDATE ausencia
      SET    id_estado = C_ESTADO_CONCEDIDO,
             firmado_rrhh = V_ID_FUNCIONARIO_FIRMA,
             FECHA_RRHH = SYSDATE
      WHERE  id_funcionario = i_id_funcionario
        AND  id_ausencia = V_id_ausencia
        AND  ROWNUM < 2;
      
      IF SQL%ROWCOUNT = 0 THEN
        todo_ok_basico := 1;
        msgBasico := 'Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
        RETURN;
      END IF;
      
      -- Preparar correo concesión
      i_sender := 'permisos.rrhh@aytosalamanca.es';
      I_ccrecipient := correo_js || ';' || correo_ja;
      i_recipient := correo_v_funcionario;
      I_message := 'La Ausencia sido Concedido.' || CHR(10) || CHR(10) ||
                   'Solicitud de Ausencia de: ' || i_nombre_peticion || CHR(10) ||
                   'Tipo Ausencia: ' || i_DESC_TIPO_AUSENCIA || CHR(10) || i_CADENA2;
      i_subject := 'Ausencia Concedido.';
      
      envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
      
      -- Registrar en histórico
      INSERT INTO historico_operaciones
      VALUES (sec_operacion.NEXTVAL,
              V_ID_AUSENCIA,
              C_ESTADO_CONCEDIDO,
              i_id_ano,
              V_ID_FUNCIONARIO_FIRMA,
              TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
              TO_CHAR(SYSDATE, 'HH:MI'),
              'VBUENO RRHH',
              V_ID_FUNCIONARIO_FIRMA,
              TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
      
      i_firma := 'Operacion realizada. La Ausencia esta concedida.';
      
      --------------------------------------------------------------------------------
      -- FASE 6: INSERTAR EN FINGER (si el usuario ficha)
      --------------------------------------------------------------------------------
      
      v_total_horas_mete := LPAD(TRUNC(v_total_horas / 60), 2, '0') || ':' || LPAD(MOD(v_total_horas, 60), 2, '0');
      i_ficha := 1;
      
      BEGIN
        SELECT DISTINCT codpers
        INTO   i_codpers
        FROM   personal_new p,
               presenci pr,
               apliweb_usuario u
        WHERE  p.id_funcionario = i_id_funcionario
          AND  LPAD(p.id_funcionario, 6, 0) = LPAD(u.id_funcionario, 6, 0)
          AND  u.id_fichaje IS NOT NULL
          AND  u.id_fichaje = pr.codpers
          AND  codinci <> 999
          AND  ROWNUM < 2;
          
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_ficha := 0;
      END;
      
      IF i_ficha = 1 THEN
        mete_fichaje_finger_new(
          i_id_ano,
          i_id_funcionario,
          v_fecha_inicio,
          V_hora_inicio,
          V_hora_fin,
          i_codpers,
          v_total_horas_mete,
          '00000',
          todo_ok_basico,
          msgbasico
        );
      END IF;
      
    --------------------------------------------------------------------------------
    -- FASE 5B: DENEGAR AUSENCIA (V_ID_FIRMA=0 → estado 32)
    --------------------------------------------------------------------------------
    
    ELSIF V_ID_FIRMA = C_FIRMA_DENIEGA THEN
      
      -- Actualizar ausencia a denegada (32)
      UPDATE ausencia
      SET    id_estado = C_ESTADO_DENEGADO,
             firmado_rrhh = V_ID_FUNCIONARIO_FIRMA,
             motivo_denega = V_ID_MOTIVO,
             FECHA_rrhh = SYSDATE
      WHERE  id_funcionario = i_id_funcionario
        AND  id_ausencia = V_id_ausencia
        AND  ROWNUM < 2;
      
      IF SQL%ROWCOUNT = 0 THEN
        todo_ok_basico := 1;
        msgBasico := 'Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
        RETURN;
      END IF;
      
      -- Preparar correo denegación
      i_sender := 'permisos.rrhh@aytosalamanca.es';
      I_ccrecipient := correo_js || ';' || correo_ja;
      i_recipient := correo_v_funcionario;
      I_message := 'Denegacion de la Ausencia' || CHR(10) ||
                   'Motivo de Denegacion: ' || V_id_motivo || CHR(10) ||
                   i_DESC_TIPo_AUSENCIA || CHR(10) || i_CADENA2;
      i_subject := 'Denegacion de Permiso por RRHH.';
      
      envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
      
      -- Registrar en histórico
      INSERT INTO historico_operaciones
      VALUES (sec_operacion.NEXTVAL,
              V_ID_AUSENCIA,
              C_ESTADO_DENEGADO,
              i_id_ano,
              V_ID_FUNCIONARIO_FIRMA,
              TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
              TO_CHAR(SYSDATE, 'HH:MI'),
              'VBUENO RRHH',
              V_ID_FUNCIONARIO_FIRMA,
              TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
      
      i_firma := 'Operacion realizada. La Ausencia se ha denegado correctamente.';
      
    END IF;
    
  END IF;
  
  todo_ok_basico := 0;
  msgBasico := i_firma;
  
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en vbueno_ausencia_rrhh: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en vbueno_ausencia_rrhh: ' || SQLERRM;
    
END VBUENO_AUSENCIA_RRHH;
/

