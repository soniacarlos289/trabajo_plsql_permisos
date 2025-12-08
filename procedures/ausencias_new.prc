/**
 * AUSENCIAS_NEW
 *
 * @description
 * Procedimiento principal para que empleados soliciten ausencias.
 * Valida tipo funcionario, formateo de horas, solapamientos, bolsa disponible
 * y delega la inserción real a inserta_ausencias.
 *
 * @details
 * Operaciones principales:
 * - Obtener y validar tipo de funcionario
 * - Normalizar fechas y horas (formato HH:MI con ceros a la izquierda)
 * - Calcular total de horas
 * - Chequear solapamientos con ausencias/permisos existentes
 * - Validar bolsa concilia (tipo 50) - horas disponibles
 * - Validar horas sindicales (tipos > 500) con chequeo_hsindical
 * - Llamar a inserta_ausencias para registro y workflow
 *
 * Validaciones especiales:
 * - Tipo 998 (incidencia fichaje): NO valida solapamientos
 * - Tipo 50 (concilia): valida horas disponibles en bolsa_concilia
 * - Tipos > 500 (sindicales): valida con chequeo_hsindical
 * - Bomberos (tipo 23): permite solapamientos en mismo día
 *
 * @param V_ID_ANO               IN OUT Año ausencia (default año actual si 0)
 * @param V_ID_FUNCIONARIO       IN ID del funcionario solicitante
 * @param V_ID_TIPO_FUNCIONARIO2 OUT Tipo funcionario (10=Admin, 21=Policía, 23=Bombero)
 * @param V_ID_TIPO_AUSENCIA     IN Código tipo ausencia (50=Concilia, >500=Sindical, 998=Incidencia)
 * @param V_ID_ESTADO_AUSENCIA   IN Estado inicial (no usado - se asigna en inserta_ausencias)
 * @param V_FECHA_INICIO         IN Fecha inicio ausencia
 * @param V_FECHA_FIN            IN OUT Fecha fin (se ajusta a fecha_inicio si igual)
 * @param V_HORA_INICIO          IN OUT Hora inicio (normalizado a HH:MI)
 * @param V_HORA_FIN             IN OUT Hora fin (normalizado a HH:MI)
 * @param V_JUSTIFICACION        IN SI/NO si está justificada
 * @param V_IP                   IN IP del usuario solicitante
 * @param msgsalida              OUT Mensaje resultado
 * @param todook                 OUT '0'=Éxito, '1'=Error
 *
 * @notes
 * - Bomberos: permitido solapamiento en mismo día (tipo 23)
 * - Fecha fin debe ser >= fecha inicio
 * - Normalización horas: completa con ceros (ej: 8:0 → 08:00)
 * - Total horas en minutos
 *
 * @see inserta_ausencias        Procedimiento que ejecuta la inserción real
 * @see chequea_solapamientos    Función que valida solapamientos
 * @see chequeo_hsindical        Validación horas sindicales
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 15/03/2021 (incidencia fichaje tipo 998)
 * @version 3.0
 */
CREATE OR REPLACE PROCEDURE RRHH.AUSENCIAS_NEW (
  V_ID_ANO               IN OUT NUMBER,
  V_ID_FUNCIONARIO       IN NUMBER,
  V_ID_TIPO_FUNCIONARIO2 OUT VARCHAR2,
  V_ID_TIPO_AUSENCIA     IN VARCHAR2,
  V_ID_ESTADO_AUSENCIA   IN VARCHAR2,
  V_FECHA_INICIO         IN DATE,
  V_FECHA_FIN            IN OUT DATE,
  V_HORA_INICIO          IN OUT VARCHAR2,
  V_HORA_FIN             IN OUT VARCHAR2,
  V_JUSTIFICACION        IN VARCHAR2,
  V_IP                   IN VARCHAR2,
  msgsalida              OUT VARCHAR2,
  todook                 OUT VARCHAR2
) IS

  -- Constantes
  C_TIPO_FUNC_BOMBERO        CONSTANT VARCHAR2(2) := '23';
  C_TIPO_AUSENCIA_CONCILIA   CONSTANT VARCHAR2(3) := '50';
  C_TIPO_AUSENCIA_SINDICAL   CONSTANT NUMBER := 500;
  C_TIPO_INCIDENCIA_FICHAJE  CONSTANT VARCHAR2(3) := '998';
  
  -- Variables
  i_ficha                 NUMBER;
  v_num_dias              NUMBER;
  v_id_tipo_dias_per      VARCHAR2(1);
  v_codpers               VARCHAR2(5);
  i_total_horas           NUMBER;
  i_todo_ok_B             NUMBER;
  msgBasico               VARCHAR2(100);
  v_id_tipo_dias_ent      VARCHAR2(100);
  i_codpers               VARCHAR(5);
  i_id_funcionario        NUMBER;
  v_num_dias_tiene_per    NUMBER;
  i_formato_fecha_inicio  DATE;
  i_formato_fecha_fin     DATE;
  i_diferencia_TOTAL      DATE;
  i_total_dias            NUMBER;
  i_contador              NUMBER;
  i_operacion_solapamiento VARCHAR2(1024);
  i_horas_v               VARCHAR2(2);
  i_minutos_v             VARCHAR2(2);
  i_horas_quedan          NUMBER;
  V_ID_TIPO_FUNCIONARIO   VARCHAR2(2);

BEGIN

  --------------------------------------------------------------------------------
  -- FASE 1: OBTENER Y VALIDAR TIPO DE FUNCIONARIO
  --------------------------------------------------------------------------------
  
  v_id_tipo_funcionario := '0';
  
  BEGIN
    SELECT tipo_funcionario2
    INTO   v_id_tipo_funcionario
    FROM   personal_new
    WHERE  id_funcionario = V_id_funcionario
      AND  ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_id_tipo_funcionario := '-1';
  END;
  
  IF v_id_tipo_funcionario = '-1' THEN
    todook := '1';
    msgsalida := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  V_ID_TIPO_FUNCIONARIO2 := v_id_tipo_funcionario;
  
  --------------------------------------------------------------------------------
  -- FASE 2: NORMALIZAR FECHAS Y HORAS
  --------------------------------------------------------------------------------
  
  i_horas_quedan := 0;
  V_FECHA_FIN := V_FECHA_INICIO;
  
  -- Año por defecto: año actual
  IF V_ID_ANO = 0 THEN
    V_ID_ANO := TO_CHAR(SYSDATE, 'YYYY');
  END IF;
  
  -- Normalizar hora inicio (completar con ceros)
  IF LENGTH(V_HORA_INICIO) < 5 THEN
    i_horas_v := LPAD(SUBSTR(V_HORA_INICIO, 1, INSTR(V_HORA_INICIO, ':', 1) - 1), 2, '0');
    i_minutos_v := LPAD(SUBSTR(V_HORA_INICIO, INSTR(V_HORA_INICIO, ':', 1) + 1, 2), 2, '0');
    V_HORA_INICIO := i_horas_v || ':' || i_minutos_v;
  END IF;
  
  -- Normalizar hora fin (completar con ceros)
  IF LENGTH(V_HORA_FIN) < 5 THEN
    i_horas_v := LPAD(SUBSTR(V_HORA_FIN, 1, INSTR(V_HORA_FIN, ':', 1) - 1), 2, '0');
    i_minutos_v := LPAD(SUBSTR(V_HORA_FIN, INSTR(V_HORA_FIN, ':', 1) + 1, 2), 2, '0');
    V_HORA_FIN := i_horas_v || ':' || i_minutos_v;
  END IF;
  
  -- Formatear fechas completas
  i_formato_fecha_inicio := TO_DATE(TO_CHAR(V_FECHA_INICIO, 'DD/MM/YYYY') || V_HORA_INICIO, 'DD/MM/YYYY HH24:MI');
  i_formato_fecha_fin := TO_DATE(TO_CHAR(V_FECHA_FIN, 'DD/MM/YYYY') || V_HORA_FIN, 'DD/MM/YYYY HH24:MI');
  i_total_dias := TO_NUMBER(TO_DATE(i_formato_fecha_fin, 'DD/MM/YYYY') - TO_DATE(i_formato_fecha_inicio, 'DD/MM/YYYY')) + 1;
  
  -- Calcular total horas en minutos
  i_total_horas := i_total_dias *
    TO_NUMBER(TO_DATE('01/01/2000' || TO_CHAR(i_formato_fecha_fin, 'HH24:MI'), 'DD/MM/YYYY HH24:MI') -
              TO_DATE('01/01/2000' || TO_CHAR(i_formato_fecha_inicio, 'HH24:MI'), 'DD/MM/YYYY HH24:MI')) * 24 * 60;
  
  --------------------------------------------------------------------------------
  -- FASE 3: VALIDAR SOLAPAMIENTOS (excepto tipo 998 - incidencia fichaje)
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_AUSENCIA <> C_TIPO_INCIDENCIA_FICHAJE THEN
    
    i_operacion_solapamiento := chequea_solapamientos(
      v_id_ano,
      v_id_funcionario,
      v_id_tipo_ausencia,
      v_fecha_inicio,
      v_fecha_fin,
      v_hora_inicio,
      v_hora_fin
    );
    
    -- Bomberos: permitido solapamiento en mismo día
    IF LENGTH(i_operacion_solapamiento) > 1 AND v_id_tipo_funcionario <> C_TIPO_FUNC_BOMBERO THEN
      todook := '1';
      msgsalida := 'Operacion no realizada. ' || i_operacion_solapamiento;
      RETURN;
    END IF;
    
    -- Validar fecha fin >= fecha inicio
    IF i_total_horas <= 0 THEN
      todook := '1';
      msgsalida := 'Fecha de la Ausencia. Fin debe ser igual o mayor que la de Inicio.';
      ROLLBACK;
      RETURN;
    END IF;
    
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: VALIDAR BOLSA CONCILIA (tipo 50)
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT total - utilizadas
    INTO   i_horas_quedan
    FROM   BOLSA_CONCILIA
    WHERE  id_ano = V_ID_ANO
      AND  id_funcionario = V_ID_FUNCIONARIO;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_horas_quedan := 0;
  END;
  
  IF (i_horas_quedan <= 0 OR i_horas_quedan < i_total_horas) AND V_ID_TIPO_AUSENCIA = C_TIPO_AUSENCIA_CONCILIA THEN
    todook := '1';
    msgsalida := 'Operacion no realizada. Horas solicitadas mayor que disponible. Horas Disponibles ' || (i_horas_quedan / 60) || 'h.';
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: VALIDAR HORAS SINDICALES (tipos > 500, excepto 998)
  --------------------------------------------------------------------------------
  
  IF TO_NUMBER(V_ID_TIPO_AUSENCIA) > C_TIPO_AUSENCIA_SINDICAL AND V_ID_TIPO_AUSENCIA <> C_TIPO_INCIDENCIA_FICHAJE THEN
    
    CHEQUEO_HSINDICAL(
      V_ID_ANO,
      V_ID_FUNCIONARIO,
      v_id_tipo_funcionario,
      V_ID_TIPO_AUSENCIA,
      V_FECHA_INICIO,
      V_FECHA_FIN,
      V_HORA_INICIO,
      V_HORA_FIN,
      i_total_horas,
      i_todo_ok_B,
      msgbasico
    );
    
    IF i_todo_ok_B = 1 THEN
      todook := '1';
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
    
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: INSERTAR AUSENCIA Y ENVIAR CORREOS
  --------------------------------------------------------------------------------
  
  inserta_ausencias(
    V_ID_ANO,
    V_ID_FUNCIONARIO,
    v_id_tipo_funcionario,
    V_ID_TIPO_AUSENCIA,
    V_FECHA_INICIO,
    V_FECHA_FIN,
    V_HORA_INICIO,
    V_HORA_FIN,
    V_JUSTIFICACION,
    i_total_horas,
    i_todo_ok_B,
    msgbasico
  );
  
  IF i_todo_ok_B = 1 THEN
    todook := '1';
    msgsalida := msgbasico;
    ROLLBACK;
    RETURN;
  END IF;
  
  COMMIT;
  todook := '0';
  msgsalida := 'La solicitud de ausencia ha sido enviada para su firma.';
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en ausencias_new: ' || SQLERRM);
    ROLLBACK;
    todook := '1';
    msgsalida := 'Error en ausencias_new: ' || SQLERRM;
    
END AUSENCIAS_NEW;
/

