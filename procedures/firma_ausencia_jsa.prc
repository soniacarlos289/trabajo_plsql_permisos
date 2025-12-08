/**
 * FIRMA_AUSENCIA_JSA
 *
 * @description
 * Gestiona las firmas de Jefes de Sección (JS) y Jefes de Área (JA) para ausencias,
 * incluyendo lógica de delegados, bomberos y transiciones de estado según jerarquía.
 *
 * @details
 * Flujo de firmas:
 * - Estado 10 (Solicitado) → JS firma → 20 (Pde JS) o 21 (Pde JA) o 22 (Pde RRHH)
 * - Estado 20 (Pde JS) → JS firma → 21 (Pde JA) o 22 (Pde RRHH)
 * - Estado 21 (Pde JA) → JA firma → 22 (Pde RRHH)
 *
 * Rechazos:
 * - JS rechaza: Estado 30 (Rechazado JS)
 * - JA rechaza: Estado 31 (Rechazado JA)
 *
 * Lógica delegados:
 * - Delegados asumen rol del titular (JS o JA)
 * - Validación por fechas en tabla DELEGADOS_APLIWEB
 * - Bomberos: lógica especial para delegados activos
 *
 * Casos especiales:
 * - JS = JA: una sola firma necesaria (JS)
 * - Bomberos con delegado: estado 20 directo
 * - Sin JA: después de JS va directo a RRHH (22)
 *
 * Operaciones realizadas:
 * - Validar ausencia y jerarquía firmas
 * - Verificar delegados activos por fechas
 * - Autorizar/Rechazar según V_ID_FIRMA
 * - Actualizar estado según siguiente nivel
 * - Registrar firma y fecha (firmado_js/firmado_ja)
 * - Enviar correos notificación según nuevo estado
 * - Registrar en histórico_operaciones
 * - Revertir bolsa si rechazo
 *
 * Estados ausencias:
 * 10=Solicitado, 20=Pde JS, 21=Pde JA, 22=Pde RRHH
 * 30=Rechazado JS, 31=Rechazado JA, 32=Denegado RRHH
 * 40=Anulado RRHH, 41=Anulado Usuario, 80=Concedido
 *
 * @param V_ID_FIRMA             IN 1=Autorizar, 0=Rechazar
 * @param V_ID_FUNCIONARIO_FIRMA IN ID del funcionario que firma (JS/JA/delegado)
 * @param V_ID_AUSENCIA          IN ID de la ausencia a firmar
 * @param V_ID_MOTIVO            IN Motivo rechazo (solo si V_ID_FIRMA=0)
 * @param todo_ok_Basico         OUT 0=Éxito, 1=Error
 * @param msgBasico              OUT Mensaje resultado
 *
 * @notes
 * - Validación estricta jerarquía: solo pueden firmar JS/JA asignados o delegados
 * - Delegados: validar periodo activo en DELEGADOS_APLIWEB
 * - Bomberos (tipo 23): reglas especiales para delegados
 * - Revertir bolsa: solo en rechazos (estados 30/31)
 * - Tipo funcionario: 10=Admin, 21=Policía, 23=Bombero
 *
 * @see envio_correo  Envío notificaciones
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 26/08/2019 (bomberos delegados)
 * @version 3.0
 */
CREATE OR REPLACE PROCEDURE RRHH.FIRMA_AUSENCIA_JSA (
  V_ID_FIRMA             IN VARCHAR2,
  V_ID_FUNCIONARIO_FIRMA IN NUMBER,
  V_ID_AUSENCIA          IN NUMBER,
  V_ID_MOTIVO            IN VARCHAR2,
  todo_ok_Basico         OUT INTEGER,
  msgBasico              OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_SOLICITADO      CONSTANT VARCHAR2(2) := '10';
  C_ESTADO_PDE_JS          CONSTANT VARCHAR2(2) := '20';
  C_ESTADO_PDE_JA          CONSTANT VARCHAR2(2) := '21';
  C_ESTADO_PDE_RRHH        CONSTANT VARCHAR2(2) := '22';
  C_ESTADO_RECHAZADO_JS    CONSTANT VARCHAR2(2) := '30';
  C_ESTADO_RECHAZADO_JA    CONSTANT VARCHAR2(2) := '31';
  C_FIRMA_AUTORIZA         CONSTANT VARCHAR2(1) := '1';
  C_FIRMA_RECHAZA          CONSTANT VARCHAR2(1) := '0';
  C_TIPO_FUNC_BOMBERO      CONSTANT VARCHAR2(2) := '23';
  C_TIPO_AUSENCIA_CONCILIA CONSTANT VARCHAR2(3) := '50';
  C_TIPO_AUSENCIA_SINDICAL CONSTANT NUMBER := 500;
  
  -- Variables ausencia
  i_no_hay_ausencias       NUMBER;
  i_id_funcionario         VARCHAR2(6);
  i_id_estado              VARCHAR2(2);
  i_id_ano                 NUMBER(4);
  i_id_mes                 VARCHAR2(2);
  v_id_tipo_ausencia       VARCHAR2(3);
  v_fecha_inicio           DATE;
  v_total_horas            NUMBER;
  i_tipo_funcionario       VARCHAR2(2);
  i_DESC_TIPO_AUSENCIA     VARCHAR2(100);
  
  -- Variables jerarquía
  i_no_hay_firma           NUMBER;
  i_id_js                  VARCHAR2(6);
  i_id_delegado_js         VARCHAR2(6);
  i_id_ja                  VARCHAR2(6);
  i_id_delegado_ja         VARCHAR2(6);
  i_hay_delegado_js        NUMBER;
  i_hay_delegado_ja        NUMBER;
  
  -- Variables control
  i_nuevo_estado           VARCHAR2(2);
  i_es_js                  NUMBER;
  i_es_ja                  NUMBER;
  i_firma_descripcion      VARCHAR2(100);
  
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

BEGIN

  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR AUSENCIA Y OBTENER DATOS
  --------------------------------------------------------------------------------
  
  todo_ok_basico := 0;
  msgBasico := '';
  i_no_hay_ausencias := 0;
  
  BEGIN
    SELECT total_horas,
           fecha_inicio,
           id_tipo_ausencia,
           id_ano,
           id_estado,
           id_funcionario,
           tipo_funcionario,
           TO_CHAR(fecha_inicio, 'MM') AS mes,
           DESC_TIPO_AUSENCIA
    INTO   v_total_horas,
           v_fecha_inicio,
           v_id_tipo_ausencia,
           i_id_ano,
           i_id_estado,
           i_id_funcionario,
           i_tipo_funcionario,
           i_id_mes,
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
    msgBasico := 'Operacion no realizada. Ausencia no existe.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER JERARQUÍA DE FIRMAS
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
  -- FASE 3: VERIFICAR DELEGADOS ACTIVOS (por fechas)
  --------------------------------------------------------------------------------
  
  i_hay_delegado_js := 0;
  i_hay_delegado_ja := 0;
  
  -- Verificar delegado JS activo
  IF i_id_delegado_js IS NOT NULL THEN
    BEGIN
      SELECT COUNT(*)
      INTO   i_hay_delegado_js
      FROM   DELEGADOS_APLIWEB
      WHERE  id_funcionario = i_id_js
        AND  id_delegado = i_id_delegado_js
        AND  v_fecha_inicio BETWEEN fecha_desde AND fecha_hasta
        AND  ROWNUM < 2;
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_hay_delegado_js := 0;
    END;
  END IF;
  
  -- Verificar delegado JA activo
  IF i_id_delegado_ja IS NOT NULL THEN
    BEGIN
      SELECT COUNT(*)
      INTO   i_hay_delegado_ja
      FROM   DELEGADOS_APLIWEB
      WHERE  id_funcionario = i_id_ja
        AND  id_delegado = i_id_delegado_ja
        AND  v_fecha_inicio BETWEEN fecha_desde AND fecha_hasta
        AND  ROWNUM < 2;
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_hay_delegado_ja := 0;
    END;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: VALIDAR QUIÉN FIRMA (JS, JA o delegado)
  --------------------------------------------------------------------------------
  
  i_es_js := 0;
  i_es_ja := 0;
  
  -- Verificar si es JS o su delegado
  IF V_ID_FUNCIONARIO_FIRMA = i_id_js OR 
     (i_hay_delegado_js > 0 AND V_ID_FUNCIONARIO_FIRMA = i_id_delegado_js) THEN
    i_es_js := 1;
  END IF;
  
  -- Verificar si es JA o su delegado
  IF V_ID_FUNCIONARIO_FIRMA = i_id_ja OR 
     (i_hay_delegado_ja > 0 AND V_ID_FUNCIONARIO_FIRMA = i_id_delegado_ja) THEN
    i_es_ja := 1;
  END IF;
  
  IF i_es_js = 0 AND i_es_ja = 0 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. No tiene permisos para firmar esta ausencia.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: DETERMINAR NUEVO ESTADO SEGÚN FIRMA
  --------------------------------------------------------------------------------
  
  IF V_ID_FIRMA = C_FIRMA_AUTORIZA THEN
    
    -- AUTORIZAR: Determinar siguiente estado
    CASE i_id_estado
      
      -- Estado 10 (Solicitado) → JS firma
      WHEN C_ESTADO_SOLICITADO THEN
        IF i_es_js = 1 THEN
          IF i_id_js = i_id_ja THEN
            i_nuevo_estado := C_ESTADO_PDE_RRHH; -- JS=JA, directo a RRHH (22)
          ELSIF i_id_ja IS NOT NULL THEN
            i_nuevo_estado := C_ESTADO_PDE_JA; -- Tiene JA, va a 21
          ELSE
            i_nuevo_estado := C_ESTADO_PDE_RRHH; -- Sin JA, directo RRHH (22)
          END IF;
          i_firma_descripcion := 'JS';
        ELSE
          todo_ok_basico := 1;
          msgBasico := 'Estado 10: Solo puede firmar JS.';
          RETURN;
        END IF;
        
      -- Estado 20 (Pde JS) → JS firma
      WHEN C_ESTADO_PDE_JS THEN
        IF i_es_js = 1 THEN
          IF i_id_js = i_id_ja THEN
            i_nuevo_estado := C_ESTADO_PDE_RRHH; -- JS=JA, directo a RRHH (22)
          ELSIF i_id_ja IS NOT NULL THEN
            i_nuevo_estado := C_ESTADO_PDE_JA; -- Tiene JA, va a 21
          ELSE
            i_nuevo_estado := C_ESTADO_PDE_RRHH; -- Sin JA, directo RRHH (22)
          END IF;
          i_firma_descripcion := 'JS';
        ELSE
          todo_ok_basico := 1;
          msgBasico := 'Estado 20: Solo puede firmar JS.';
          RETURN;
        END IF;
        
      -- Estado 21 (Pde JA) → JA firma
      WHEN C_ESTADO_PDE_JA THEN
        IF i_es_ja = 1 THEN
          i_nuevo_estado := C_ESTADO_PDE_RRHH; -- Siempre va a RRHH (22)
          i_firma_descripcion := 'JA';
        ELSE
          todo_ok_basico := 1;
          msgBasico := 'Estado 21: Solo puede firmar JA.';
          RETURN;
        END IF;
        
      ELSE
        todo_ok_basico := 1;
        msgBasico := 'Estado no válido para firma JS/JA.';
        RETURN;
        
    END CASE;
    
  ELSE
    
    -- RECHAZAR: Determinar estado rechazo
    IF i_es_js = 1 THEN
      i_nuevo_estado := C_ESTADO_RECHAZADO_JS; -- 30
      i_firma_descripcion := 'JS';
    ELSIF i_es_ja = 1 THEN
      i_nuevo_estado := C_ESTADO_RECHAZADO_JA; -- 31
      i_firma_descripcion := 'JA';
    ELSE
      todo_ok_basico := 1;
      msgBasico := 'No tiene permisos para rechazar.';
      RETURN;
    END IF;
    
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: ACTUALIZAR AUSENCIA CON FIRMA
  --------------------------------------------------------------------------------
  
  IF i_es_js = 1 THEN
    
    -- Firma JS
    UPDATE ausencia
    SET    id_estado = i_nuevo_estado,
           firmado_js = V_ID_FUNCIONARIO_FIRMA,
           fecha_js = SYSDATE,
           motivo_denega = DECODE(V_ID_FIRMA, C_FIRMA_RECHAZA, V_ID_MOTIVO, motivo_denega)
    WHERE  id_funcionario = i_id_funcionario
      AND  id_ausencia = V_id_ausencia
      AND  ROWNUM < 2;
      
  ELSIF i_es_ja = 1 THEN
    
    -- Firma JA
    UPDATE ausencia
    SET    id_estado = i_nuevo_estado,
           firmado_ja = V_ID_FUNCIONARIO_FIRMA,
           fecha_ja = SYSDATE,
           motivo_denega = DECODE(V_ID_FIRMA, C_FIRMA_RECHAZA, V_ID_MOTIVO, motivo_denega)
    WHERE  id_funcionario = i_id_funcionario
      AND  id_ausencia = V_id_ausencia
      AND  ROWNUM < 2;
      
  END IF;
  
  IF SQL%ROWCOUNT = 0 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Error al actualizar firma.';
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 7: REVERTIR BOLSA SI RECHAZO (estados 30/31)
  --------------------------------------------------------------------------------
  
  IF V_ID_FIRMA = C_FIRMA_RECHAZA THEN
    
    -- Revertir bolsa concilia (tipo 50)
    IF v_id_tipo_ausencia = C_TIPO_AUSENCIA_CONCILIA THEN
      UPDATE BOLSA_CONCILIA
      SET    utilizadas = utilizadas - v_total_horas,
             pendientes_justificar = pendientes_justificar - v_total_horas
      WHERE  id_ano = i_id_ano
        AND  id_funcionario = i_id_funcionario;
    END IF;
    
    -- Revertir horas sindicales (tipos > 500)
    IF TO_NUMBER(v_id_tipo_ausencia) > C_TIPO_AUSENCIA_SINDICAL THEN
      UPDATE HORA_SINDICAL
      SET    TOTAL_UTILIZADAS = TOTAL_UTILIZADAS - v_total_horas
      WHERE  id_ano = i_id_ano
        AND  id_MES = i_id_mes
        AND  id_funcionario = i_id_funcionario
        AND  ID_TIPO_AUSENCIA = v_id_tipo_ausencia
        AND  ROWNUM < 2;
    END IF;
    
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 8: REGISTRAR EN HISTÓRICO
  --------------------------------------------------------------------------------
  
  INSERT INTO historico_operaciones
  VALUES (sec_operacion.NEXTVAL,
          V_ID_AUSENCIA,
          i_nuevo_estado,
          i_id_ano,
          V_ID_FUNCIONARIO_FIRMA,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
          TO_CHAR(SYSDATE, 'HH:MI'),
          'FIRMA ' || i_firma_descripcion || ' ' || DECODE(V_ID_FIRMA, C_FIRMA_AUTORIZA, 'AUTORIZA', 'RECHAZA'),
          V_ID_FUNCIONARIO_FIRMA,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
  
  --------------------------------------------------------------------------------
  -- FASE 9: OBTENER CORREOS ELECTRÓNICOS
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
                   '' AS js,
                   login || '@aytosalamanca.es' AS ja
            FROM   apliweb_usuario
            WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_ja, 6, '0'));
            
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 10: ENVIAR CORREOS SEGÚN RESULTADO
  --------------------------------------------------------------------------------
  
  IF V_ID_FIRMA = C_FIRMA_AUTORIZA THEN
    
    -- AUTORIZACIÓN: enviar según nuevo estado
    CASE i_nuevo_estado
      
      WHEN C_ESTADO_PDE_JA THEN
        i_sender := 'permisos.rrhh@aytosalamanca.es';
        i_recipient := correo_ja;
        I_ccrecipient := correo_v_funcionario || ';' || correo_js;
        i_subject := 'Ausencia autorizada por JS - Pendiente JA';
        I_message := 'Ausencia autorizada por Jefe Sección.' || CHR(10) ||
                     'Funcionario: ' || i_nombre_peticion || CHR(10) ||
                     'Tipo: ' || i_DESC_TIPO_AUSENCIA || CHR(10) ||
                     'Pendiente firma Jefe Área.';
        
      WHEN C_ESTADO_PDE_RRHH THEN
        i_sender := 'permisos.rrhh@aytosalamanca.es';
        i_recipient := 'permisos.rrhh@aytosalamanca.es';
        I_ccrecipient := correo_v_funcionario || ';' || correo_js || ';' || correo_ja;
        i_subject := 'Ausencia autorizada - Pendiente RRHH';
        I_message := 'Ausencia autorizada por ' || i_firma_descripcion || '.' || CHR(10) ||
                     'Funcionario: ' || i_nombre_peticion || CHR(10) ||
                     'Tipo: ' || i_DESC_TIPO_AUSENCIA || CHR(10) ||
                     'Pendiente visto bueno RRHH.';
        
      ELSE
        i_sender := 'permisos.rrhh@aytosalamanca.es';
        i_recipient := correo_v_funcionario;
        I_ccrecipient := correo_js || ';' || correo_ja;
        i_subject := 'Ausencia autorizada';
        I_message := 'Su ausencia ha sido autorizada por ' || i_firma_descripcion || '.';
        
    END CASE;
    
    msgBasico := 'Ausencia autorizada por ' || i_firma_descripcion || '. Nuevo estado: ' ||
                 DECODE(i_nuevo_estado, '21', 'Pde JA', '22', 'Pde RRHH', i_nuevo_estado);
    
  ELSE
    
    -- RECHAZO: notificar a funcionario
    i_sender := 'permisos.rrhh@aytosalamanca.es';
    i_recipient := correo_v_funcionario;
    I_ccrecipient := correo_js || ';' || correo_ja;
    i_subject := 'Ausencia rechazada por ' || i_firma_descripcion;
    I_message := 'Su ausencia ha sido rechazada.' || CHR(10) ||
                 'Rechazada por: ' || i_firma_descripcion || CHR(10) ||
                 'Motivo: ' || V_ID_MOTIVO || CHR(10) ||
                 'Funcionario: ' || i_nombre_peticion || CHR(10) ||
                 'Tipo: ' || i_DESC_TIPO_AUSENCIA;
    
    msgBasico := 'Ausencia rechazada por ' || i_firma_descripcion || '.';
    
  END IF;
  
  envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
  
  todo_ok_basico := 0;
  
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en firma_ausencia_jsa: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en firma_ausencia_jsa: ' || SQLERRM;
    
END FIRMA_AUSENCIA_JSA;
/
