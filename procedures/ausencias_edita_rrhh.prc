/**
 * AUSENCIAS_EDITA_RRHH
 *
 * @description
 * Permite a RRHH editar ausencias existentes, actualizar fechas/horas,
 * sincronizar con finger y ajustar bolsas (concilia/sindical).
 *
 * @details
 * Permite modificar:
 * - Fechas y horas de inicio/fin
 * - Tipo de ausencia
 * - Total de horas
 * - Justificación
 *
 * Operaciones realizadas:
 * - Validar existencia y permisos
 * - Calcular diferencia horas (nueva - original)
 * - Actualizar ausencia con nuevos datos
 * - Sincronizar finger (anular anterior, insertar nuevo)
 * - Ajustar bolsa_concilia (tipo 50) según diferencia
 * - Ajustar hora_sindical (>500) según diferencia
 * - Enviar correo notificación
 * - Registrar en histórico
 *
 * Finger sincronización:
 * - Si usuario ficha: anula registro anterior y crea nuevo
 * - Formato horas: HH:MI (ej: 08:30)
 *
 * Estados ausencias:
 * 10=Solicitado, 20=Pde JS, 21=Pde JA, 22=Pde RRHH
 * 30=Rechazado JS, 31=Rechazado JA, 32=Denegado RRHH
 * 40=Anulado RRHH, 41=Anulado Usuario, 80=Concedido
 *
 * @param V_ID_AUSENCIA      IN ID de la ausencia a editar
 * @param V_ID_ANO           IN Año ausencia
 * @param V_ID_FUNCIONARIO   IN ID del funcionario
 * @param V_ID_TIPO_AUSENCIA IN Nuevo tipo ausencia
 * @param V_FECHA_INICIO     IN Nueva fecha inicio
 * @param V_FECHA_FIN        IN Nueva fecha fin
 * @param V_HORA_INICIO      IN Nueva hora inicio (HH:MI)
 * @param V_HORA_FIN         IN Nueva hora fin (HH:MI)
 * @param V_JUSTIFICACION    IN SI/NO si justificada
 * @param V_TOTAL_HORAS      IN Nuevo total horas en minutos
 * @param V_IP               IN IP del usuario RRHH
 * @param todo_ok_Basico     OUT 0=Éxito, 1=Error
 * @param msgBasico          OUT Mensaje resultado
 *
 * @notes
 * - Ajuste bolsas: diferencia = nuevo_total - total_original
 * - Finger: anula+inserta solo si usuario ficha (codpers)
 * - Tipo funcionario: 10=Admin, 21=Policía, 23=Bombero
 * - Mes calculado de fecha_inicio original (para hora_sindical)
 *
 * @see anula_fichaje_finger_15000  Anulación en finger
 * @see mete_fichaje_finger_new     Inserción en finger
 * @see envio_correo                Envío notificación
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 13/02/2020 (bolsa concilia)
 * @version 2.0
 */
CREATE OR REPLACE PROCEDURE RRHH.AUSENCIAS_EDITA_RRHH (
  V_ID_AUSENCIA      IN NUMBER,
  V_ID_ANO           IN NUMBER,
  V_ID_FUNCIONARIO   IN NUMBER,
  V_ID_TIPO_AUSENCIA IN VARCHAR2,
  V_FECHA_INICIO     IN DATE,
  V_FECHA_FIN        IN DATE,
  V_HORA_INICIO      IN VARCHAR2,
  V_HORA_FIN         IN VARCHAR2,
  V_JUSTIFICACION    IN VARCHAR2,
  V_TOTAL_HORAS      IN NUMBER,
  V_IP               IN VARCHAR2,
  todo_ok_Basico     OUT INTEGER,
  msgBasico          OUT VARCHAR2
) IS

  -- Constantes
  C_TIPO_AUSENCIA_CONCILIA CONSTANT VARCHAR2(3) := '50';
  C_TIPO_AUSENCIA_SINDICAL CONSTANT NUMBER := 500;
  
  -- Variables ausencia original
  i_total_horas_original   NUMBER;
  i_fecha_inicio_original  DATE;
  i_fecha_fin_original     DATE;
  i_hora_inicio_original   VARCHAR2(5);
  i_hora_fin_original      VARCHAR2(5);
  i_id_tipo_ausencia_orig  VARCHAR2(3);
  i_id_estado              VARCHAR2(2);
  i_id_mes                 VARCHAR2(2);
  i_tipo_funcionario       VARCHAR2(2);
  i_DESC_TIPO_AUSENCIA     VARCHAR2(100);
  
  -- Variables cálculo
  i_diferencia_horas       NUMBER;
  v_total_horas_mete       VARCHAR2(12);
  
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
  i_id_js              VARCHAR2(6);
  i_id_ja              VARCHAR2(6);

BEGIN

  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR AUSENCIA Y OBTENER DATOS ORIGINALES
  --------------------------------------------------------------------------------
  
  todo_ok_basico := 0;
  msgBasico := '';
  
  BEGIN
    SELECT total_horas,
           fecha_inicio,
           fecha_fin,
           TO_CHAR(fecha_inicio, 'HH24:MI') AS hora_inicio,
           TO_CHAR(fecha_fin, 'HH24:MI') AS hora_fin,
           id_tipo_ausencia,
           id_estado,
           TO_CHAR(fecha_inicio, 'MM') AS mes
    INTO   i_total_horas_original,
           i_fecha_inicio_original,
           i_fecha_fin_original,
           i_hora_inicio_original,
           i_hora_fin_original,
           i_id_tipo_ausencia_orig,
           i_id_estado,
           i_id_mes
    FROM   ausencia
    WHERE  id_ausencia = V_ID_AUSENCIA
      AND  id_funcionario = V_ID_FUNCIONARIO;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      todo_ok_basico := 1;
      msgBasico := 'Operacion no realizada. Ausencia no encontrada.';
      RETURN;
  END;
  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER TIPO FUNCIONARIO
  --------------------------------------------------------------------------------
  
  i_tipo_funcionario := '0';
  
  BEGIN
    SELECT tipo_funcionario2
    INTO   i_tipo_funcionario
    FROM   personal_new pe
    WHERE  id_funcionario = V_ID_FUNCIONARIO
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
  -- FASE 3: CALCULAR DIFERENCIA DE HORAS
  --------------------------------------------------------------------------------
  
  i_diferencia_horas := V_TOTAL_HORAS - i_total_horas_original;
  
  --------------------------------------------------------------------------------
  -- FASE 4: ACTUALIZAR AUSENCIA
  --------------------------------------------------------------------------------
  
  UPDATE ausencia
  SET    id_tipo_ausencia = V_ID_TIPO_AUSENCIA,
         fecha_inicio = V_FECHA_INICIO,
         fecha_fin = V_FECHA_FIN,
         hora_inicio = V_HORA_INICIO,
         hora_fin = V_HORA_FIN,
         justificado = V_JUSTIFICACION,
         total_horas = V_TOTAL_HORAS,
         fecha_modi = SYSDATE,
         ip = V_IP
  WHERE  id_ausencia = V_ID_AUSENCIA
    AND  id_funcionario = V_ID_FUNCIONARIO;
  
  IF SQL%ROWCOUNT = 0 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Error al actualizar ausencia.';
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: SINCRONIZAR FINGER (anular anterior + insertar nuevo)
  --------------------------------------------------------------------------------
  
  i_ficha := 1;
  
  BEGIN
    SELECT DISTINCT codpers
    INTO   i_codpers
    FROM   personal_new p,
           presenci pr,
           apliweb_usuario u
    WHERE  p.id_funcionario = V_ID_FUNCIONARIO
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
    
    -- Anular registro anterior en finger
    ANULA_FICHAJE_FINGER_15000(
      V_ID_ANO,
      V_ID_FUNCIONARIO,
      i_fecha_inicio_original,
      i_hora_inicio_original,
      i_hora_fin_original,
      i_codpers,
      0,
      '00000',
      todo_ok_basico,
      msgbasico
    );
    
    -- Insertar nuevo registro en finger
    v_total_horas_mete := LPAD(TRUNC(V_TOTAL_HORAS / 60), 2, '0') || ':' || LPAD(MOD(V_TOTAL_HORAS, 60), 2, '0');
    
    mete_fichaje_finger_new(
      V_ID_ANO,
      V_ID_FUNCIONARIO,
      V_FECHA_INICIO,
      V_HORA_INICIO,
      V_HORA_FIN,
      i_codpers,
      v_total_horas_mete,
      '00000',
      todo_ok_basico,
      msgbasico
    );
    
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: AJUSTAR BOLSAS SEGÚN DIFERENCIA
  --------------------------------------------------------------------------------
  
  -- Ajustar bolsa concilia (tipo 50)
  IF V_ID_TIPO_AUSENCIA = C_TIPO_AUSENCIA_CONCILIA THEN
    UPDATE BOLSA_CONCILIA
    SET    utilizadas = utilizadas + i_diferencia_horas,
           pendientes_justificar = pendientes_justificar + i_diferencia_horas
    WHERE  id_ano = V_ID_ANO
      AND  id_funcionario = V_ID_FUNCIONARIO;
  END IF;
  
  -- Ajustar horas sindicales (tipos > 500)
  IF TO_NUMBER(V_ID_TIPO_AUSENCIA) > C_TIPO_AUSENCIA_SINDICAL THEN
    UPDATE HORA_SINDICAL
    SET    TOTAL_UTILIZADAS = TOTAL_UTILIZADAS + i_diferencia_horas
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
  VALUES (sec_operacion.NEXTVAL,
          V_ID_AUSENCIA,
          i_id_estado,
          V_ID_ANO,
          V_ID_FUNCIONARIO,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
          TO_CHAR(SYSDATE, 'HH:MI'),
          'EDICION RRHH',
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
  
  -- Obtener jerarquía firmas
  BEGIN
    SELECT id_js, id_ja
    INTO   i_id_js, i_id_ja
    FROM   funcionario_firma
    WHERE  id_funcionario = V_ID_FUNCIONARIO;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_js := '';
      i_id_ja := '';
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
  i_subject := 'Ausencia modificada por RRHH';
  I_message := 'Su ausencia ha sido modificada por RRHH.' || CHR(10) || CHR(10) ||
               'Funcionario: ' || i_nombre_peticion || CHR(10) ||
               'Tipo Ausencia: ' || i_DESC_TIPO_AUSENCIA || CHR(10) ||
               'Nueva Fecha Inicio: ' || TO_CHAR(V_FECHA_INICIO, 'DD/MM/YYYY') || ' ' || V_HORA_INICIO || CHR(10) ||
               'Nueva Fecha Fin: ' || TO_CHAR(V_FECHA_FIN, 'DD/MM/YYYY') || ' ' || V_HORA_FIN || CHR(10) ||
               'Diferencia horas: ' || DECODE(SIGN(i_diferencia_horas), 1, '+', '') || (i_diferencia_horas / 60) || 'h';
  
  envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
  
  msgBasico := 'Ausencia editada correctamente. ID: ' || V_ID_AUSENCIA;
  todo_ok_basico := 0;
  
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en ausencias_edita_rrhh: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en ausencias_edita_rrhh: ' || SQLERRM;
    
END AUSENCIAS_EDITA_RRHH;
/
