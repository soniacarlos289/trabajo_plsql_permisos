/**
 * INSERTA_AUSENCIAS
 *
 * @description
 * Procedimiento principal para insertar ausencias de usuarios con workflow completo
 * de aprobación (JS → JA → RRHH). Determina automáticamente el estado inicial
 * según la jerarquía de firmas, delegados y tipo de funcionario.
 *
 * @details
 * Workflow de aprobación:
 * 1. Usuario solicita → Estado 10 (Solicitado)
 * 2. Jefe Sección aprueba → Estado 20 (Pde JS)
 * 3. Jefe Área aprueba → Estado 21 (Pde JA)
 * 4. RRHH aprueba → Estado 80 (Concedido)
 *
 * Determinación estado inicial:
 * - Sin JS ni JA: Estado 22 (directo a RRHH)
 * - Con JS sin delegado: Estado 10 (Solicitado)
 * - Con JS delegado: Estado 20 (Pde JS)
 * - Bomberos con delegado JS: Estado 20 (Pde JS)
 * - JS=JA (mismo): Estado 20 (Pde JS único)
 * - Con JA: Estado 21 (Pde JA)
 *
 * Casos especiales:
 * - Bomberos (tipo 23): lógica delegados diferente
 * - JS=JA: una sola firma necesaria (JS)
 * - Delegados: asumen rol del titular
 *
 * Operaciones realizadas:
 * - Generar secuencias (id_ausencia, id_operacion)
 * - Validar jerarquía firmas y delegados
 * - Determinar estado inicial según reglas
 * - Insertar ausencia con estado calculado
 * - Actualizar bolsa_concilia (tipo 50) o hora_sindical (>500)
 * - Enviar correos notificación según estado
 * - Registrar en histórico_operaciones
 *
 * Estados ausencias:
 * 10=Solicitado, 20=Pde JS, 21=Pde JA, 22=Pde RRHH
 * 30=Rechazado JS, 31=Rechazado JA, 32=Denegado RRHH
 * 40=Anulado RRHH, 41=Anulado Usuario, 80=Concedido
 *
 * @param V_ID_ANO               IN Año ausencia
 * @param V_ID_FUNCIONARIO       IN ID del funcionario solicitante
 * @param V_ID_TIPO_FUNCIONARIO  IN Tipo funcionario (10=Admin, 21=Policía, 23=Bombero)
 * @param V_ID_TIPO_AUSENCIA     IN Tipo ausencia (50=Concilia, >500=Sindical)
 * @param V_FECHA_INICIO         IN Fecha inicio
 * @param V_FECHA_FIN            IN Fecha fin
 * @param V_HORA_INICIO          IN Hora inicio (HH:MI)
 * @param V_HORA_FIN             IN Hora fin (HH:MI)
 * @param V_JUSTIFICACION        IN SI/NO si justificada
 * @param V_TOTAL_HORAS          IN Total horas en minutos
 * @param todo_ok_Basico         OUT 0=Éxito, 1=Error
 * @param msgBasico              OUT Mensaje resultado
 *
 * @notes
 * - Workflow completo con notificaciones por correo
 * - Bolsa concilia (tipo 50): actualiza utilizadas por año
 * - Horas sindicales (>500): actualiza total_utilizadas por mes
 * - Bomberos: lógica especial para delegados
 * - Delegados: consulta en DELEGADOS_APLIWEB por fechas
 *
 * @see envio_correo  Envío notificaciones
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 26/08/2019 (bomberos delegados)
 * @version 3.0
 */
CREATE OR REPLACE PROCEDURE RRHH.INSERTA_AUSENCIAS (
  V_ID_ANO              IN NUMBER,
  V_ID_FUNCIONARIO      IN NUMBER,
  V_ID_TIPO_FUNCIONARIO IN VARCHAR2,
  V_ID_TIPO_AUSENCIA    IN VARCHAR2,
  V_FECHA_INICIO        IN DATE,
  V_FECHA_FIN           IN DATE,
  V_HORA_INICIO         IN VARCHAR2,
  V_HORA_FIN            IN VARCHAR2,
  V_JUSTIFICACION       IN VARCHAR2,
  V_TOTAL_HORAS         IN NUMBER,
  todo_ok_Basico        OUT INTEGER,
  msgBasico             OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_SOLICITADO      CONSTANT VARCHAR2(2) := '10';
  C_ESTADO_PDE_JS          CONSTANT VARCHAR2(2) := '20';
  C_ESTADO_PDE_JA          CONSTANT VARCHAR2(2) := '21';
  C_ESTADO_PDE_RRHH        CONSTANT VARCHAR2(2) := '22';
  C_TIPO_FUNC_BOMBERO      CONSTANT VARCHAR2(2) := '23';
  C_TIPO_AUSENCIA_CONCILIA CONSTANT VARCHAR2(3) := '50';
  C_TIPO_AUSENCIA_SINDICAL CONSTANT NUMBER := 500;
  
  -- Variables
  i_id_ausencia        NUMBER;
  i_id_operacion       NUMBER;
  i_id_estado_ausencia VARCHAR2(2);
  i_no_hay_firma       NUMBER;
  i_id_js              VARCHAR2(6);
  i_id_delegado_js     VARCHAR2(6);
  i_id_ja              VARCHAR2(6);
  i_id_delegado_ja     VARCHAR2(6);
  i_DESC_TIPO_AUSENCIA VARCHAR2(100);
  i_id_mes             VARCHAR2(2);
  i_hay_delegado_js    NUMBER;
  i_hay_delegado_ja    NUMBER;
  
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
  -- FASE 1: VALIDACIONES Y GENERACIÓN DE SECUENCIAS
  --------------------------------------------------------------------------------
  
  todo_ok_basico := 0;
  msgBasico := '';
  i_no_hay_firma := 0;
  i_hay_delegado_js := 0;
  i_hay_delegado_ja := 0;
  
  -- Generar secuencias
  SELECT sec_ausencia.NEXTVAL INTO i_id_ausencia FROM DUAL;
  SELECT sec_operacion.NEXTVAL INTO i_id_operacion FROM DUAL;
  
  -- Obtener mes
  SELECT TO_CHAR(V_FECHA_INICIO, 'MM') INTO i_id_mes FROM DUAL;
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER JERARQUÍA DE FIRMAS
  --------------------------------------------------------------------------------
  
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
    WHERE  id_funcionario = V_ID_FUNCIONARIO;
    
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
  
  -- Verificar delegado JS activo
  IF i_id_delegado_js IS NOT NULL THEN
    BEGIN
      SELECT COUNT(*)
      INTO   i_hay_delegado_js
      FROM   DELEGADOS_APLIWEB
      WHERE  id_funcionario = i_id_js
        AND  id_delegado = i_id_delegado_js
        AND  V_FECHA_INICIO BETWEEN fecha_desde AND fecha_hasta
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
        AND  V_FECHA_INICIO BETWEEN fecha_desde AND fecha_hasta
        AND  ROWNUM < 2;
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_hay_delegado_ja := 0;
    END;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: DETERMINAR ESTADO INICIAL SEGÚN JERARQUÍA Y DELEGADOS
  --------------------------------------------------------------------------------
  
  -- Sin JS ni JA: directo a RRHH (estado 22)
  IF i_id_js IS NULL AND i_id_ja IS NULL THEN
    i_id_estado_ausencia := C_ESTADO_PDE_RRHH; -- 22
    
  -- JS = JA (mismo funcionario): una sola firma (JS) - estado 20
  ELSIF i_id_js = i_id_ja THEN
    i_id_estado_ausencia := C_ESTADO_PDE_JS; -- 20
    
  -- Bomberos con delegado JS: estado 20
  ELSIF V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNC_BOMBERO AND i_hay_delegado_js > 0 THEN
    i_id_estado_ausencia := C_ESTADO_PDE_JS; -- 20
    
  -- Con delegado JS activo: estado 20
  ELSIF i_hay_delegado_js > 0 THEN
    i_id_estado_ausencia := C_ESTADO_PDE_JS; -- 20
    
  -- Con JA (y JS): estado 21 (pendiente JA)
  ELSIF i_id_ja IS NOT NULL THEN
    i_id_estado_ausencia := C_ESTADO_PDE_JA; -- 21
    
  -- Solo JS sin delegado: estado 10 (solicitado)
  ELSIF i_id_js IS NOT NULL THEN
    i_id_estado_ausencia := C_ESTADO_SOLICITADO; -- 10
    
  -- Por defecto: solicitado
  ELSE
    i_id_estado_ausencia := C_ESTADO_SOLICITADO; -- 10
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: INSERTAR AUSENCIA
  --------------------------------------------------------------------------------
  
  INSERT INTO ausencia
  VALUES (i_id_ausencia,
          V_ID_ANO,
          V_ID_FUNCIONARIO,
          V_ID_TIPO_FUNCIONARIO,
          V_ID_TIPO_AUSENCIA,
          i_id_estado_ausencia,
          V_FECHA_INICIO,
          V_FECHA_FIN,
          V_HORA_INICIO,
          V_HORA_FIN,
          V_JUSTIFICACION,
          V_TOTAL_HORAS,
          NULL, -- firmado_js
          NULL, -- fecha_js
          NULL, -- firmado_ja
          NULL, -- fecha_ja
          NULL, -- firmado_rrhh
          NULL, -- fecha_rrhh
          NULL, -- motivo_denega
          'NO', -- anulado
          SYSDATE, -- fecha_alta
          SYSDATE, -- fecha_modi
          NULL); -- ip
  
  --------------------------------------------------------------------------------
  -- FASE 6: ACTUALIZAR BOLSAS (CONCILIA O SINDICAL)
  --------------------------------------------------------------------------------
  
  -- Actualizar bolsa concilia (tipo 50)
  IF V_ID_TIPO_AUSENCIA = C_TIPO_AUSENCIA_CONCILIA THEN
    UPDATE BOLSA_CONCILIA
    SET    utilizadas = utilizadas + V_TOTAL_HORAS,
           pendientes_justificar = pendientes_justificar + V_TOTAL_HORAS
    WHERE  id_ano = V_ID_ANO
      AND  id_funcionario = V_ID_FUNCIONARIO;
  END IF;
  
  -- Actualizar horas sindicales (tipos > 500)
  IF TO_NUMBER(V_ID_TIPO_AUSENCIA) > C_TIPO_AUSENCIA_SINDICAL THEN
    UPDATE HORA_SINDICAL
    SET    TOTAL_UTILIZADAS = TOTAL_UTILIZADAS + V_TOTAL_HORAS
    WHERE  id_ano = V_ID_ANO
      AND  id_MES = i_id_mes
      AND  id_funcionario = V_ID_FUNCIONARIO
      AND  ID_TIPO_AUSENCIA = V_ID_TIPO_AUSENCIA
      AND  ROWNUM < 2;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 7: REGISTRAR EN HISTÓRICO
  --------------------------------------------------------------------------------
  
  INSERT INTO historico_operaciones
  VALUES (i_id_operacion,
          i_id_ausencia,
          i_id_estado_ausencia,
          V_ID_ANO,
          V_ID_FUNCIONARIO,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
          TO_CHAR(SYSDATE, 'HH:MI'),
          'SOLICITUD USUARIO',
          V_ID_FUNCIONARIO,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
  
  --------------------------------------------------------------------------------
  -- FASE 8: OBTENER DESCRIPCIÓN TIPO AUSENCIA
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT DESC_TIPO_AUSENCIA
    INTO   i_DESC_TIPO_AUSENCIA
    FROM   tr_tipo_ausencia
    WHERE  id_tipo_ausencia = V_ID_TIPO_AUSENCIA;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_DESC_TIPO_AUSENCIA := '';
  END;
  
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
            WHERE  id_funcionario = TO_CHAR(V_ID_FUNCIONARIO)
            UNION
            SELECT '' AS peticion,
                   '' AS nombre_peticion,
                   login || '@aytosalamanca.es' AS js,
                   '' AS ja
            FROM   apliweb_usuario
            WHERE  LPAD(id_funcionario, 6, '0') = LPAD(NVL(i_id_delegado_js, i_id_js), 6, '0')
            UNION
            SELECT '' AS peticion,
                   '' AS nombre_peticion,
                   '' AS js,
                   login || '@aytosalamanca.es' AS ja
            FROM   apliweb_usuario
            WHERE  LPAD(id_funcionario, 6, '0') = LPAD(NVL(i_id_delegado_ja, i_id_ja), 6, '0'));
            
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END;
  
  --------------------------------------------------------------------------------
  -- FASE 10: ENVIAR CORREOS SEGÚN ESTADO
  --------------------------------------------------------------------------------
  
  -- Preparar mensaje base
  BEGIN
    SELECT CABECERA || ' ' ||
           SOLICITADO || ' ' ||
           i_nombre_peticion || ' ' ||
           TIPO_PERMISO || ' ' ||
           i_desc_tipo_ausencia || ' ' ||
           FECHA_INICIO || ' ' ||
           TO_CHAR(V_FECHA_INICIO, 'DD/MM/YYYY') || ' ' ||
           DECODE(SUBSTR(V_ID_TIPO_AUSENCIA, 1, 1), '5',
                  FECHA_FIN || ' ' || TO_CHAR(V_FECHA_FIN, 'DD/MM/YYYY'), '') || ' ' ||
           HORA_INICIO || ' ' || V_HORA_INICIO || ' ' ||
           HORA_FIN || ' ' || V_HORA_FIN || ' ' ||
           CABECERA_FI || ' ' ||
           DECODE(i_id_estado_ausencia,
                  '10', 'Pendiente de Firma',
                  '20', 'Pendiente de Jefe Sección',
                  '21', 'Pendiente de Jefe Área',
                  '22', 'Pendiente de RRHH',
                  'Solicitado') || ' ' ||
           CABECERA_FIN_2
    INTO   i_desc_mensaje
    FROM   FORMATO_CORREO
    WHERE  DECODE(SUBSTR(V_ID_TIPO_AUSENCIA, 1, 1), '5', '500', '222') = ID_TIPO_PERMISO;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_desc_mensaje := 'Solicitud de ausencia: ' || i_DESC_TIPO_AUSENCIA;
  END;
  
  I_message := i_desc_mensaje;
  
  -- Enviar según estado
  CASE i_id_estado_ausencia
    
    -- Estado 10: Solicitado - notificar a JS
    WHEN C_ESTADO_SOLICITADO THEN
      i_sender := correo_v_funcionario;
      i_recipient := NVL(correo_js, 'permisos.rrhh@aytosalamanca.es');
      I_ccrecipient := '';
      i_subject := 'Solicitud de Ausencia pendiente de firma';
      
    -- Estado 20: Pde JS - notificar a JS
    WHEN C_ESTADO_PDE_JS THEN
      i_sender := correo_v_funcionario;
      i_recipient := NVL(correo_js, 'permisos.rrhh@aytosalamanca.es');
      I_ccrecipient := '';
      i_subject := 'Ausencia pendiente firma Jefe Sección';
      
    -- Estado 21: Pde JA - notificar a JA
    WHEN C_ESTADO_PDE_JA THEN
      i_sender := correo_v_funcionario;
      i_recipient := NVL(correo_ja, 'permisos.rrhh@aytosalamanca.es');
      I_ccrecipient := correo_js;
      i_subject := 'Ausencia pendiente firma Jefe Área';
      
    -- Estado 22: Pde RRHH - notificar a RRHH
    WHEN C_ESTADO_PDE_RRHH THEN
      i_sender := correo_v_funcionario;
      i_recipient := 'permisos.rrhh@aytosalamanca.es';
      I_ccrecipient := correo_js || ';' || correo_ja;
      i_subject := 'Ausencia pendiente visto bueno RRHH';
      
    ELSE
      i_sender := correo_v_funcionario;
      i_recipient := 'permisos.rrhh@aytosalamanca.es';
      I_ccrecipient := '';
      i_subject := 'Nueva solicitud de Ausencia';
      
  END CASE;
  
  envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
  
  msgBasico := 'Ausencia solicitada correctamente. ID: ' || i_id_ausencia || ' - Estado: ' ||
               DECODE(i_id_estado_ausencia, '10', 'Solicitado', '20', 'Pde JS', '21', 'Pde JA', '22', 'Pde RRHH', i_id_estado_ausencia);
  todo_ok_basico := 0;
  
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en inserta_ausencias: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en inserta_ausencias: ' || SQLERRM;
    
END INSERTA_AUSENCIAS;
/
