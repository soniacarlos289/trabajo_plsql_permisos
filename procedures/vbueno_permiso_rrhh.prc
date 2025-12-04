/**
 * VBUENO_PERMISO_RRHH
 *
 * @description
 * Procedimiento para que RRHH otorgue el Visto Bueno final a permisos
 * que ya han sido aprobados por JS y JA. Transiciona el permiso de estado
 * 22 (Pendiente Vo RRHH) a 80 (Concedido) o 32 (Denegado RRHH).
 *
 * @details
 * Operaciones principales:
 * - Validar existencia del permiso y estado 22
 * - Verificar firmas de jerarquía (JS/JA)
 * - Autorizar (estado→80) o Denegar (estado→32) el permiso
 * - Actualizar Finger si el funcionario ficha y tiene justificación
 * - Enviar notificaciones por correo (funcionario, JS, JA)
 * - Registrar operación en histórico_operaciones
 * - Para denegación: revertir descuento de bolsa (permiso_denegado)
 *
 * Estados soportados:
 * - Entrada: 22 (Pendiente Vo RRHH)
 * - Salida Autorizado: 80 (Concedido)
 * - Salida Denegado: 32 (Denegado RRHH)
 *
 * @param V_ID_FIRMA             1=Autorizado, 0=Denegado
 * @param V_ID_FUNCIONARIO_FIRMA ID funcionario RRHH que firma (aprueba/deniega)
 * @param V_ID_PERMISO           ID del permiso a dar Vo
 * @param V_ID_MOTIVO            Motivo de denegación (si corresponde)
 * @param todo_ok_Basico         OUT 0=Éxito, 1=Error
 * @param msgBasico              OUT Mensaje resultado
 *
 * @notes
 * - Solo procesa permisos en estado 22 (Pendiente Vo RRHH)
 * - Actualiza finger solo si: funcionario ficha + justificación='SI' (excepto 15000)
 * - Permiso compensatorio 15000: usa mete_fichaje_finger_NEW
 * - Otros permisos: usa actualiza_finger
 * - Casos especiales: notificación adicional a hprieto si JS es rmontejo o slopez
 * - Para denegación: llama permiso_denegado para revertir bolsa
 *
 * @see envia_correo_informa_new   Construye mensaje correo según tipo permiso
 * @see envio_correo                Envía notificación por email
 * @see actualiza_finger            Actualiza sistema Finger para permisos normales
 * @see mete_fichaje_finger_NEW     Registra fichaje para compensatorios (15000)
 * @see permiso_denegado            Revierte descuento bolsa en denegación
 *
 * @author Sistema Permisos RRHH
 * @date   Actualizado 30/09/2019 (mete_fichaje compensatorios)
 * @version 3.0
 */
CREATE OR REPLACE PROCEDURE RRHH.VBUENO_PERMISO_RRHH (
  V_ID_FIRMA             IN VARCHAR2,
  V_ID_FUNCIONARIO_FIRMA IN NUMBER,
  V_ID_PERMISO           IN NUMBER,
  V_ID_MOTIVO            IN VARCHAR2,
  todo_ok_Basico         OUT INTEGER,
  msgBasico              OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_PENDIENTE_RRHH   CONSTANT VARCHAR2(2) := '22';
  C_ESTADO_CONCEDIDO        CONSTANT VARCHAR2(2) := '80';
  C_ESTADO_DENEGADO_RRHH    CONSTANT VARCHAR2(2) := '32';
  C_PERMISO_COMPENSATORIO   CONSTANT VARCHAR2(5) := '15000';
  C_EMAIL_DOMAIN            CONSTANT VARCHAR2(30) := '@aytosalamanca.es';
  C_EMAIL_RRHH              CONSTANT VARCHAR2(50) := 'permisos.rrhh@aytosalamanca.es';
  C_EMAIL_HPRIETO           CONSTANT VARCHAR2(50) := 'hprieto@aytosalamanca.es';
  
  -- Variables permiso
  i_no_hay_permisos       NUMBER;
  i_no_hay_firma          NUMBER;
  i_id_funcionario        VARCHAR2(6);
  i_id_ano                NUMBER(4);
  i_id_tipo_permiso       VARCHAR2(5);
  i_total_horas           VARCHAR2(5);
  i_hora_inicio           VARCHAR2(5);
  i_hora_fin              VARCHAR2(5);
  i_fecha_inicio          DATE;
  i_fecha_fin             DATE;
  i_id_estado             VARCHAR2(2);
  i_DESC_TIPO_PERMISO     VARCHAR2(200);
  i_CADENA2               VARCHAR2(4000);
  i_id_grado              VARCHAR2(200);
  i_id_tipo_dias          VARCHAR2(200);
  i_num_dias              NUMBER;
  v_id_justificacion      VARCHAR2(2);
  
  -- Variables jerarquía
  i_id_js                 VARCHAR2(6);
  i_id_delegado_js        VARCHAR2(6);
  i_id_ja                 VARCHAR2(6);
  i_id_delegado_ja        VARCHAR2(6);
  v_tipo_funcionario      VARCHAR2(10);
  
  -- Variables finger/fichaje
  i_ficha                 NUMBER;
  i_codpers               VARCHAR2(6);
  
  -- Variables correo
  correo_v_funcionario    VARCHAR2(200);
  i_nombre_peticion       VARCHAR2(200);
  correo_js               VARCHAR2(200);
  correo_ja               VARCHAR2(200);
  i_sender                VARCHAR2(100);
  i_recipient             VARCHAR2(100);
  I_ccrecipient           VARCHAR2(100);
  i_subject               VARCHAR2(100);
  I_message               VARCHAR2(4000);
  v_mensaje               VARCHAR2(4000);
  v_t1                    VARCHAR2(5);
  v_t2                    VARCHAR2(5);
  v_t3                    VARCHAR2(5);
  
  -- Variables control
  i_firma                 VARCHAR2(200);

BEGIN

  todo_ok_basico := 0;
  msgBasico := '';
  
  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR EXISTENCIA Y ESTADO DEL PERMISO
  --------------------------------------------------------------------------------
  
  i_no_hay_permisos := 0;
  
  BEGIN
    SELECT p.id_ano,
           id_grado,
           p.id_tipo_dias,
           p.NUM_DIAS,
           LPAD(TRUNC(p.total_horas / 60), 2, '0') || ':' || LPAD(MOD(p.total_horas, 60), 2, '0'),
           p.hora_inicio,
           p.hora_fin,
           p.id_tipo_permiso,
           p.fecha_inicio,
           p.fecha_fin,
           id_estado,
           id_funcionario,
           DES_TIPO_PERMISO_LARGA,
           DECODE(p.id_tipo_permiso, C_PERMISO_COMPENSATORIO,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') || CHR(10) ||
                  'Hora de Inicio: ' || HORA_INICIO || CHR(10) || 'Hora Fin: ' || HORA_FIN,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') || CHR(10) ||
                  'Fecha Fin:    ' || TO_CHAR(p.FECHA_FIN, 'DD-MON-YY') || CHR(10) ||
                  'Numero de Dias: ' || p.NUM_DIAS),
           tu1_14_22,
           tu2_22_06,
           tu3_04_14,
           DECODE(p.JUSTIFICACION, 'NO', 'NO', 'SI')
    INTO   i_id_ano,
           i_id_grado,
           i_id_tipo_dias,
           i_num_dias,
           i_total_horas,
           i_hora_inicio,
           i_hora_fin,
           i_id_tipo_permiso,
           i_fecha_inicio,
           i_fecha_fin,
           i_id_estado,
           i_id_funcionario,
           i_DESC_TIPO_PERMISO,
           i_CADENA2,
           v_t1,
           v_t2,
           v_t3,
           v_id_justificacion
    FROM   permiso p, tr_tipo_permiso tr
    WHERE  id_permiso = v_id_permiso
      AND  p.id_tipo_permiso = tr.id_tipo_permiso
      AND  p.id_ano = tr.id_ano
      AND  (anulado = 'NO' OR ANULADO IS NULL);
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_permisos := -1;
  END;
  
  IF i_no_hay_permisos = -1 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Permiso no existe.';
    RETURN;
  END IF;


  IF i_no_hay_permisos = -1 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Permiso no existe.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER TIPO DE FUNCIONARIO
  --------------------------------------------------------------------------------
  
  v_tipo_funcionario := '10';
  
  BEGIN
    SELECT tipo_funcionario2
    INTO   v_tipo_funcionario
    FROM   personal_new
    WHERE  id_funcionario = i_id_funcionario
      AND  ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_tipo_funcionario := '-1';
  END;
  
  IF v_tipo_funcionario = '-1' THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: OBTENER JERARQUÍA DE FIRMAS (JS/JA)
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT DISTINCT id_js,
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
  
  -- Obtener correos electrónicos
  BEGIN
    SELECT MIN(peticion),
           MIN(nombre_peticion),
           MIN(js),
           MIN(ja)
    INTO   correo_v_funcionario,
           i_nombre_peticion,
           correo_js,
           correo_ja
    FROM (
      SELECT login || C_EMAIL_DOMAIN AS peticion,
             SUBSTR(DIST_NAME, INSTR(DIST_NAME, '=', 1) + 1, 
                    INSTR(DIST_NAME, ',', 1) - INSTR(DIST_NAME, '=', 1) - 1) AS nombre_peticion,
             '' AS js,
             '' AS ja
      FROM   apliweb_usuario
      WHERE  id_funcionario = TO_CHAR(i_ID_FUNCIONARIO)
      UNION
      SELECT '' AS peticion,
             '' AS nombre_peticion,
             login || C_EMAIL_DOMAIN AS js,
             '' AS ja
      FROM   apliweb_usuario
      WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_js, 6, '0')
      UNION
      SELECT '' AS peticion,
             '' AS nombre_peticion,
             '' AS ja,
             login || C_EMAIL_DOMAIN AS ja
      FROM   apliweb_usuario
      WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_ja, 6, '0')
    );
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END;
  
  -- Validar existencia de jefes
  IF i_id_js = '' AND i_id_ja = '' THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
    RETURN;
  END IF;

  IF i_id_js = '' AND i_id_ja = '' THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: PROCESAR AUTORIZACIÓN O DENEGACIÓN
  --------------------------------------------------------------------------------
  
  IF i_id_estado = C_ESTADO_PENDIENTE_RRHH THEN
    
    -- ============================================================================
    -- OPCIÓN 1: AUTORIZADO (V_ID_FIRMA=1) → Estado 80 (Concedido)
    -- ============================================================================
    
    IF V_ID_FIRMA = '1' THEN
      
      -- Actualizar estado a Concedido
      UPDATE permiso
      SET    id_estado = C_ESTADO_CONCEDIDO,
             firmado_rrhh = V_ID_FUNCIONARIO_FIRMA,
             FECHA_RRHH = SYSDATE
      WHERE  id_funcionario = i_id_funcionario
        AND  id_permiso = V_id_permiso
        AND  ROWNUM < 2;
      
      IF SQL%ROWCOUNT = 0 THEN
        todo_ok_basico := 1;
        msgBasico := 'Operacion no realizada. Pongase contacto Carlos(Informatica). Ext 9650.';
        RETURN;
      END IF;
      
      --------------------------------------------------------------------------------
      -- FASE 5: ACTUALIZAR SISTEMA FINGER (si ficha)
      --------------------------------------------------------------------------------
      
      i_ficha := 1;
      
      BEGIN
        SELECT DISTINCT codpers
        INTO   i_codpers
        FROM   personal_new p, presenci pr, apliweb_usuario u
        WHERE  p.id_funcionario = i_ID_FUNCIONARIO
          AND  LPAD(p.id_funcionario, 6, '0') = LPAD(u.id_funcionario, 6, '0')
          AND  u.id_fichaje IS NOT NULL
          AND  u.id_fichaje = pr.codpers
          AND  codinci <> 999
          AND  ROWNUM < 2;
          
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_ficha := 0;
      END;
      
      -- Actualizar finger según tipo de permiso
      IF i_FICHA = 1 AND i_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO 
         AND v_id_justificacion = 'SI' THEN
        
        -- Permisos normales con justificación: actualizar finger
        actualiza_finger(
          i_id_ano,
          i_id_funcionario,
          i_id_tipo_permiso,
          i_fecha_inicio,
          i_fecha_fin,
          i_codpers,
          i_id_estado,
          todo_ok_basico,
          msgbasico
        );
        
        IF todo_ok_basico = 1 THEN
          ROLLBACK;
          RETURN;
        END IF;
        
      ELSIF i_FICHA = 1 AND i_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO THEN
        
        -- Permiso compensatorio (15000): registrar fichaje
        mete_fichaje_finger_NEW(
          i_id_ano,
          i_id_funcionario,
          i_fecha_inicio,
          i_hora_inicio,
          i_hora_fin,
          i_codpers,
          0,
          '00000',
          todo_ok_basico,
          msgbasico
        );
        
      END IF;
      END IF;
      
      --------------------------------------------------------------------------------
      -- FASE 6: ENVIAR NOTIFICACIONES - PERMISO CONCEDIDO
      --------------------------------------------------------------------------------
      
      -- Construir mensaje de notificación
      envia_correo_informa_new(
        '3',
        i_ID_TIPO_PERMISO,
        i_nombre_peticion,
        i_DESC_TIPo_PERMISO,
        v_id_motivo,
        i_fecha_inicio,
        i_fecha_fin,
        i_hora_inicio,
        i_hora_fin,
        i_id_grado,
        i_id_tipo_dias,
        i_num_dias,
        v_t1,
        v_t2,
        v_t3,
        V_TIPO_FUNCIONARIO,
        v_mensaje
      );
      
      -- Enviar correo al funcionario (con copia a JS y JA)
      i_sender := C_EMAIL_RRHH;
      I_ccrecipient := correo_js || ';' || correo_ja;
      i_recipient := correo_v_funcionario;
      I_message := v_mensaje;
      i_subject := 'Permiso Concedido.';
      
      envio_correo(
        i_sender,
        i_recipient,
        I_ccrecipient,
        i_subject,
        I_message
      );
      
      -- Notificación especial para casos específicos (Ramon Montejo / Sonia López)
      IF i_id_js = 'rmontejo' OR i_id_js = 'slopez' THEN
        envio_correo(
          i_sender,
          C_EMAIL_HPRIETO,
          I_ccrecipient,
          i_subject,
          I_message
        );
      END IF;
      
      -- Registrar en histórico
      INSERT INTO historico_operaciones
      VALUES (
        sec_operacion.NEXTVAL,
        V_ID_PERMISO,
        C_ESTADO_PENDIENTE_RRHH,
        i_id_ano,
        V_ID_FUNCIONARIO_FIRMA,
        TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
        TO_CHAR(SYSDATE, 'HH:MI'),
        'VBUENO RRHH',
        V_ID_FUNCIONARIO_FIrMA,
        TO_CHAR(SYSDATE, 'DD/MM/YYYY')
      );
      
      i_firma := 'Operacion realizada. El permiso concedido';
      
    -- ============================================================================
    -- OPCIÓN 2: DENEGADO (V_ID_FIRMA=0) → Estado 32 (Denegado RRHH)
    -- ============================================================================
    
    ELSIF V_ID_FIRMA = '0' THEN
      
      -- Actualizar estado a Denegado
      UPDATE permiso
      SET    id_estado = C_ESTADO_DENEGADO_RRHH,
             firmado_RRHH = V_ID_FUNCIONARIO_FIRMA,
             motivo_denega = V_ID_MOTIVO,
             FECHA_RRHH = SYSDATE
      WHERE  id_funcionario = i_id_funcionario
        AND  id_permiso = V_id_permiso
        AND  ROWNUM < 2;
      
      IF SQL%ROWCOUNT = 0 THEN
        todo_ok_basico := 1;
        msgBasico := 'Operacion no realizada. Pongase contacto RRHH. Error Update Firma.';
        RETURN;
      END IF;
      
      --------------------------------------------------------------------------------
      -- FASE 7: ENVIAR NOTIFICACIONES - PERMISO DENEGADO
      --------------------------------------------------------------------------------
      
      -- Construir mensaje de denegación
      envia_correo_informa_new(
        '0',
        i_ID_TIPO_PERMISO,
        i_nombre_peticion,
        i_DESC_TIPo_PERMISO,
        v_id_motivo,
        i_fecha_inicio,
        i_fecha_fin,
        i_hora_inicio,
        i_hora_fin,
        i_id_grado,
        i_id_tipo_dias,
        i_num_dias,
        v_t1,
        v_t2,
        v_t3,
        V_TIPO_FUNCIONARIO,
        v_mensaje
      );
      
      -- Enviar correo de denegación
      i_sender := C_EMAIL_RRHH;
      I_ccrecipient := correo_js || ';' || correo_ja || ';';
      i_recipient := correo_v_funcionario;
      I_message := v_mensaje;
      i_subject := 'Denegacion de Permiso por RRHH.';
      
      envio_correo(
        i_sender,
        i_recipient,
        I_ccrecipient,
        i_subject,
        I_message
      );
      
      -- Notificación especial para casos específicos
      IF i_id_js = 'rmontejo' OR i_id_js = 'slopez' THEN
        envio_correo(
          i_sender,
          C_EMAIL_HPRIETO,
          I_ccrecipient,
          i_subject,
          I_message
        );
      END IF;
      
      -- Registrar en histórico
      INSERT INTO historico_operaciones
      VALUES (
        sec_operacion.NEXTVAL,
        V_ID_PERMISO,
        C_ESTADO_DENEGADO_RRHH,
        i_id_ano,
        V_ID_FUNCIONARIO_FIRMA,
        TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
        TO_CHAR(SYSDATE, 'HH:MI'),
        'VBUENO RRHH',
        V_ID_FUNCIONARIO_FIrMA,
        TO_CHAR(SYSDATE, 'DD/MM/YYYY')
      );
      
      --------------------------------------------------------------------------------
      -- FASE 8: REVERTIR DESCUENTO DE BOLSA (permisos únicos)
      --------------------------------------------------------------------------------
      
      permiso_denegado(v_id_permiso, todo_ok_basico, msgbasico);
      
      IF todo_ok_basico = 1 THEN
        RETURN;
      ELSE
        i_firma := 'Operacion realizada. El permiso se ha denegado correctamente.';
      END IF;
      
    END IF; -- Fin V_ID_FIRMA
    
  ELSE
    -- Estado no es 22 (no está pendiente de Vo RRHH)
    todo_ok_basico := 1;
    msgBasico := 'Operacion realizada.';
    RETURN;
  END IF;
  
  -- Todo ha ido bien
  todo_ok_basico := 0;
  msgBasico := i_firma;
  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en vbueno_permiso_rrhh: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en vbueno_permiso_rrhh: ' || SQLERRM;
    
END VBUENO_PERMISO_RRHH;
/

