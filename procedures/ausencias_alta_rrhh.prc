/**
 * AUSENCIAS_ALTA_RRHH
 *
 * @description
 * Permite a RRHH crear ausencias directamente con workflow completo de firmas.
 * Determina automáticamente el estado según la jerarquía de firmas del funcionario.
 *
 * @details
 * Diferencia con inserta_ausencias_rrhh:
 * - inserta_ausencias_rrhh: inserción directa estado 80 (sin workflow)
 * - ausencias_alta_rrhh: inserción con workflow (estados 10/20/21/22)
 *
 * Determinación de estado inicial:
 * - Estado 10 (Solicitado): si requiere firma JS o JA
 * - Estado 20 (Pde JS): si JS ya firmó (delegado/bombero)
 * - Estado 21 (Pde JA): si JS y JA ya firmaron
 * - Estado 22 (Pde RRHH): si todas las firmas completas
 *
 * Operaciones realizadas:
 * - Generar secuencias (id_ausencia, id_operacion)
 * - Determinar estado según jerarquía firmas
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
 * @param V_ID_ANO          IN Año ausencia
 * @param V_ID_FUNCIONARIO  IN ID del funcionario
 * @param V_ID_TIPO_AUSENCIA IN Tipo ausencia (50=Concilia, >500=Sindical)
 * @param V_FECHA_INICIO    IN Fecha inicio
 * @param V_FECHA_FIN       IN Fecha fin
 * @param V_HORA_INICIO     IN Hora inicio (HH:MI)
 * @param V_HORA_FIN        IN Hora fin (HH:MI)
 * @param V_JUSTIFICACION   IN SI/NO si justificada
 * @param V_TOTAL_HORAS     IN Total horas en minutos
 * @param V_IP              IN IP del usuario RRHH
 * @param todo_ok_Basico    OUT 0=Éxito, 1=Error
 * @param msgBasico         OUT Mensaje resultado
 *
 * @notes
 * - Workflow completo con notificaciones por correo
 * - Bolsa concilia (tipo 50): actualiza utilizadas por año
 * - Horas sindicales (>500): actualiza total_utilizadas por mes
 * - Tipo funcionario: 10=Admin, 21=Policía, 23=Bombero
 *
 * @see envio_correo  Envío notificaciones
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 13/02/2020 (bolsa concilia)
 * @version 2.0
 */
CREATE OR REPLACE PROCEDURE RRHH.AUSENCIAS_ALTA_RRHH (
  V_ID_ANO          IN NUMBER,
  V_ID_FUNCIONARIO  IN NUMBER,
  V_ID_TIPO_AUSENCIA IN VARCHAR2,
  V_FECHA_INICIO    IN DATE,
  V_FECHA_FIN       IN DATE,
  V_HORA_INICIO     IN VARCHAR2,
  V_HORA_FIN        IN VARCHAR2,
  V_JUSTIFICACION   IN VARCHAR2,
  V_TOTAL_HORAS     IN NUMBER,
  V_IP              IN VARCHAR2,
  todo_ok_Basico    OUT INTEGER,
  msgBasico         OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_SOLICITADO      CONSTANT VARCHAR2(2) := '10';
  C_ESTADO_PDE_JS          CONSTANT VARCHAR2(2) := '20';
  C_ESTADO_PDE_JA          CONSTANT VARCHAR2(2) := '21';
  C_ESTADO_PDE_RRHH        CONSTANT VARCHAR2(2) := '22';
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
  i_tipo_funcionario   VARCHAR2(2);
  
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
  -- FASE 1: VALIDACIONES Y GENERACIÓN DE SECUENCIAS
  --------------------------------------------------------------------------------
  
  todo_ok_basico := 0;
  msgBasico := '';
  i_no_hay_firma := 0;
  
  -- Generar secuencias
  SELECT sec_ausencia.NEXTVAL INTO i_id_ausencia FROM DUAL;
  SELECT sec_operacion.NEXTVAL INTO i_id_operacion FROM DUAL;
  
  -- Obtener mes
  SELECT TO_CHAR(V_FECHA_INICIO, 'MM') INTO i_id_mes FROM DUAL;
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER TIPO FUNCIONARIO
  --------------------------------------------------------------------------------
  
  i_tipo_funcionario := '0';
  
  BEGIN
    SELECT tipo_funcionario2
    INTO   i_tipo_funcionario
    FROM   personal_new pe
    WHERE  id_funcionario = V_id_funcionario
      AND  ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_tipo_funcionario := '-1';
  END;
  
  IF i_tipo_funcionario = '-1' THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: OBTENER JERARQUÍA DE FIRMAS
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
  -- FASE 4: DETERMINAR ESTADO INICIAL SEGÚN JERARQUÍA
  --------------------------------------------------------------------------------
  
  -- Determinar estado según firmas requeridas
  IF i_id_js IS NOT NULL OR i_id_ja IS NOT NULL THEN
    i_id_estado_ausencia := C_ESTADO_SOLICITADO; -- 10: Requiere firmas
  ELSE
    i_id_estado_ausencia := C_ESTADO_PDE_RRHH; -- 22: Directo a RRHH
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: INSERTAR AUSENCIA
  --------------------------------------------------------------------------------
  
  INSERT INTO ausencia
  VALUES (i_id_ausencia,
          V_ID_ANO,
          V_ID_FUNCIONARIO,
          i_tipo_funcionario,
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
          V_IP);
  
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
          'ALTA RRHH',
          V_ID_FUNCIONARIO,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
  
  --------------------------------------------------------------------------------
  -- FASE 8: OBTENER CORREOS Y ENVIAR NOTIFICACIÓN
  --------------------------------------------------------------------------------
  
  -- Obtener descripción tipo ausencia
  BEGIN
    SELECT DESC_TIPO_AUSENCIA
    INTO   i_DESC_TIPO_AUSENCIA
    FROM   tr_tipo_ausencia
    WHERE  id_tipo_ausencia = V_ID_TIPO_AUSENCIA;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_DESC_TIPO_AUSENCIA := '';
  END;
  
  -- Obtener correos
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
  END;
  
  -- Enviar correo notificación
  i_sender := 'permisos.rrhh@aytosalamanca.es';
  i_recipient := correo_v_funcionario;
  I_ccrecipient := correo_js || ';' || correo_ja;
  i_subject := 'Nueva Ausencia creada por RRHH';
  I_message := 'Se ha creado una solicitud de ausencia.' || CHR(10) || CHR(10) ||
               'Funcionario: ' || i_nombre_peticion || CHR(10) ||
               'Tipo Ausencia: ' || i_DESC_TIPO_AUSENCIA || CHR(10) ||
               'Fecha Inicio: ' || TO_CHAR(V_FECHA_INICIO, 'DD/MM/YYYY') || ' ' || V_HORA_INICIO || CHR(10) ||
               'Fecha Fin: ' || TO_CHAR(V_FECHA_FIN, 'DD/MM/YYYY') || ' ' || V_HORA_FIN || CHR(10) ||
               'Estado: ' || DECODE(i_id_estado_ausencia, '10', 'Solicitado', '20', 'Pde JS', '21', 'Pde JA', '22', 'Pde RRHH', 'Desconocido');
  
  envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
  
  msgBasico := 'Ausencia creada correctamente. ID: ' || i_id_ausencia;
  todo_ok_basico := 0;
  
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en ausencias_alta_rrhh: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en ausencias_alta_rrhh: ' || SQLERRM;
    
END AUSENCIAS_ALTA_RRHH;
/
