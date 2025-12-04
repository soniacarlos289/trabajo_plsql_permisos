--------------------------------------------------------------------------------
-- PROCEDURE: PERMISOS_NEW
--------------------------------------------------------------------------------
-- Propósito: Crear nueva solicitud de permiso con validaciones completas
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Procedimiento principal para la creación de permisos de empleados.
--   Realiza validaciones exhaustivas según tipo de permiso, funcionario y
--   reglas de negocio (vacaciones, compensatorios, turnos, etc.)
--
-- Parámetros:
--   V_ID_ANO              - Año del permiso
--   V_ID_FUNCIONARIO      - ID del empleado
--   V_ID_TIPO_FUNCIONARIO - Tipo de funcionario (IN OUT)
--   V_ID_TIPO_PERMISO     - Código de tipo de permiso
--   V_ID_ESTADO_PERMISO   - Estado inicial del permiso
--   V_ID_TIPO_DIAS        - Tipo de días (L=Laborables, N=Naturales)
--   V_FECHA_INICIO        - Fecha inicio del permiso
--   V_FECHA_FIN           - Fecha fin del permiso (IN OUT)
--   V_HORA_INICIO         - Hora inicio (IN OUT, formato HH24:MI)
--   V_HORA_FIN            - Hora fin (IN OUT, formato HH24:MI)
--   V_ID_GRADO            - Grado del permiso
--   V_DPROVINCIA          - Provincia para permisos de desplazamiento
--   V_JUSTIFICACION       - Requiere justificación (SI/NO)
--   v_T1, v_T2, v_T3      - Turnos (bomberos)
--   V_UNICO               - Permiso único (actualiza contador, IN OUT)
--   V_IP                  - IP origen de la solicitud
--   msgsalida             - Mensaje resultado (OUT)
--   todook                - Estado operación: 0=OK, 1=Error (OUT)
--   v_enlace_fichero      - ID fichero justificante (OUT)
--
-- Validaciones realizadas:
--   1. Validación básica (fechas, solapamientos, reglas generales)
--   2. Validación de vacaciones según tipo de funcionario
--   3. Validación de compensatorios y bolsas de horas
--   4. Validación de turnos para bomberos
--   5. Validación de límites de días laborables
--   6. Actualización de contadores para permisos únicos
--
-- Excepciones:
--   - Permisos 11100, 11300: Solo tramitables por RRHH
--   - Vacaciones: Límite 22 días laborables
--   - Compensatorios: Verificación de saldo disponible
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0: Constantes, documentación, 
--                         variables optimizadas, manejo de errores mejorado
--   04/03/2025 - CHM - Mejora validación justificación
--   11/10/2022 - CHM - Control turnos bomberos
--   25/01/2017 - CHM - Control de turnos
--   01/03/2013 - Añadido control permisos RRHH
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH.PERMISOS_NEW(
  V_ID_ANO              IN NUMBER,
  V_ID_FUNCIONARIO      IN NUMBER,
  V_ID_TIPO_FUNCIONARIO IN OUT VARCHAR2,
  V_ID_TIPO_PERMISO     IN VARCHAR2,
  V_ID_ESTADO_PERMISO   IN VARCHAR2,
  V_ID_TIPO_DIAS        IN VARCHAR2,
  V_FECHA_INICIO        IN DATE,
  V_FECHA_FIN           IN OUT DATE,
  V_HORA_INICIO         IN OUT VARCHAR2,
  V_HORA_FIN            IN OUT VARCHAR2,
  V_ID_GRADO            IN VARCHAR2,
  V_DPROVINCIA          IN VARCHAR2,
  V_JUSTIFICACION       IN VARCHAR2,
  v_T1                  IN VARCHAR2,
  v_T2                  IN VARCHAR2,
  v_T3                  IN VARCHAR2,
  V_UNICO               IN OUT VARCHAR2,
  V_IP                  IN VARCHAR2,
  msgsalida             OUT VARCHAR2,
  todook                OUT VARCHAR2,
  v_enlace_fichero      OUT VARCHAR2
) IS
  
  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT VARCHAR2(1) := '0';
  C_ERROR CONSTANT VARCHAR2(1) := '1';
  
  -- Tipos de permiso especiales (solo RRHH)
  C_PERMISO_BAJA_ENFERMEDAD_1 CONSTANT VARCHAR2(5) := '11100';
  C_PERMISO_BAJA_ENFERMEDAD_2 CONSTANT VARCHAR2(5) := '11300';
  
  -- Tipos de permiso con validaciones específicas
  C_PERMISO_VACACIONES CONSTANT VARCHAR2(5) := '01000';
  C_PERMISO_VACACIONES_2 CONSTANT VARCHAR2(5) := '02000';
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  C_PERMISO_CONCILIACION CONSTANT VARCHAR2(5) := '40000';
  C_PERMISO_VACACIONES_EXTRA CONSTANT VARCHAR2(5) := '02015';
  
  -- Tipos de funcionario
  C_TIPO_FUNC_BOMBERO CONSTANT NUMBER := 23;
  C_TIPO_FUNC_ESPECIAL CONSTANT NUMBER := 21;
  C_TIPO_FUNC_ID_ESPECIAL CONSTANT NUMBER := 961388; -- ID funcionario con tipo 10
  
  -- Límites
  C_MAX_DIAS_VACACIONES_LAB CONSTANT NUMBER := 22; -- Días laborables máximos
  C_LONGITUD_HORA CONSTANT NUMBER := 5; -- HH24:MI
  
  -- Valores por defecto
  C_JUSTIF_NO CONSTANT VARCHAR2(2) := 'NO';
  C_JUSTIF_SI CONSTANT VARCHAR2(2) := 'SI';
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES (OPTIMIZADAS)
  --------------------------------------------------------------------------------
  
  -- Variables de control
  i_ficha NUMBER(1) := 0;
  i_todo_ok_B NUMBER(1);
  i_t1 NUMBER(1) := 0;
  
  -- Variables de cálculo
  v_num_dias NUMBER(5, 2);
  v_num_dias_tiene_per NUMBER(5, 2);
  i_num_dias_laborables NUMBER(3);
  v_total_horas NUMBER(5, 2);
  
  -- Variables de tipo/estado
  v_id_tipo_dias_per VARCHAR2(1);
  v_id_tipo_dias_ent VARCHAR2(1);
  v_justificacion2 VARCHAR2(2);
  
  -- Variables de identificación
  v_codpers VARCHAR2(5);
  i_codpers VARCHAR2(5);
  
  -- Variables de texto
  msgBasico VARCHAR2(500);
  V_GUARDIAS VARCHAR2(1000) := '';


BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  -- Estado inicial: error hasta que se complete correctamente
  todook := C_ERROR;
  v_id_tipo_dias_ent := V_ID_TIPO_DIAS;
  
  -- Normalizar horas a formato HH24:MI (primeros 5 caracteres)
  V_HORA_INICIO := SUBSTR(V_HORA_INICIO, 1, C_LONGITUD_HORA);
  V_HORA_FIN := SUBSTR(V_HORA_FIN, 1, C_LONGITUD_HORA);
  
  -- Inicializar justificación por defecto
  v_justificacion2 := C_JUSTIF_NO;
  
  --------------------------------------------------------------------------------
  -- FASE 2: DETERMINAR REQUERIMIENTO DE JUSTIFICACIÓN
  -- Actualización: 04/03/2025 - CHM
  --------------------------------------------------------------------------------
  
  IF V_JUSTIFICACION = C_JUSTIF_NO OR V_JUSTIFICACION IS NULL OR V_JUSTIFICACION = '--' THEN
    -- Consultar si el tipo de permiso requiere justificación
    BEGIN
      SELECT DECODE(JUSTIFICACION, C_JUSTIF_SI, C_JUSTIF_NO, JUSTIFICACION)
        INTO v_justificacion2
        FROM tr_tipo_permiso tr
       WHERE tr.id_ano = V_ID_ANO
         AND tr.id_tipo_permiso = V_ID_TIPO_PERMISO
         AND ROWNUM < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_justificacion2 := C_JUSTIF_NO;
    END;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: VALIDACIONES DE NEGOCIO ESPECÍFICAS
  --------------------------------------------------------------------------------
  
  -- Validación 1: Funcionario especial con tipo 10
  IF V_ID_FUNCIONARIO = C_TIPO_FUNC_ID_ESPECIAL THEN
    V_ID_TIPO_FUNCIONARIO := 10;
  END IF;
  
  -- Validación 2: Permisos solo tramitables por RRHH
  -- Añadido: 01/03/2013 - Descuento por baja enfermedad justificada
  IF V_ID_TIPO_PERMISO IN (C_PERMISO_BAJA_ENFERMEDAD_1, C_PERMISO_BAJA_ENFERMEDAD_2) THEN
    todook := C_ERROR;
    msgsalida := 'Este permiso es procesado solamente por RRHH. Perdón por las molestias.';
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: PROCESAMIENTO DE TURNOS (BOMBEROS)
  -- Actualización: 25/01/2017 - CHM - Control de turnos
  -- Actualización: 11/10/2022 - CHM - Ajuste fecha fin según turno
  --------------------------------------------------------------------------------
  
  -- Contar número de turnos seleccionados
  i_t1 := 0;
  
  IF v_T1 = '1' THEN
    i_t1 := i_t1 + 1;
    -- Para bomberos (excepto vacaciones), fecha fin = fecha inicio
    IF V_ID_TIPO_PERMISO <> C_PERMISO_VACACIONES AND V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNC_BOMBERO THEN
      V_FECHA_FIN := V_FECHA_INICIO;
    END IF;
  END IF;
  
  IF v_T2 = '1' THEN
    i_t1 := i_t1 + 1;
    -- Para bomberos (excepto vacaciones), fecha fin = fecha inicio + 1 día
    IF V_ID_TIPO_PERMISO <> C_PERMISO_VACACIONES AND V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNC_BOMBERO THEN
      V_FECHA_FIN := V_FECHA_INICIO + 1; -- Añadido 15/11/2022
    END IF;
  END IF;
  
  IF v_T3 = '1' THEN
    i_t1 := i_t1 + 1;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: VALIDACIÓN BÁSICA
  -- Comprobación de fechas, solapamientos y reglas generales
  --------------------------------------------------------------------------------
  
  Chequeo_Basico_NEW(
    V_ID_ANO,
    V_ID_FUNCIONARIO,
    V_ID_TIPO_FUNCIONARIO,
    V_ID_TIPO_PERMISO,
    v_id_tipo_dias_ent,
    V_FECHA_INICIO,
    V_FECHA_FIN,
    V_HORA_INICIO,
    V_HORA_FIN,
    V_UNICO,
    V_DPROVINCIA,
    V_ID_GRADO,
    i_t1,
    v_num_dias,
    v_id_tipo_dias_per,
    v_num_dias_tiene_per,
    i_todo_ok_B,
    msgBasico,
    0,
    0
  );
  
  -- Si hay errores en validación básica, terminar
  IF i_todo_ok_B = 1 THEN
    msgsalida := msgBasico;
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: VALIDACIÓN DE VACACIONES (FUNCIONARIOS GENERALES)
  --------------------------------------------------------------------------------
  
  IF (V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES OR
      V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES_2 OR
      SUBSTR(V_ID_TIPO_PERMISO, 1, 3) = '030' OR
      V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO OR
      V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES_EXTRA) 
     AND V_ID_TIPO_FUNCIONARIO <> C_TIPO_FUNC_BOMBERO THEN
    
    chequeo_vacaciones_new(
      v_id_ano,
      v_id_funcionario,
      v_id_tipo_funcionario,
      v_id_tipo_permiso,
      v_id_tipo_dias_ent,
      v_fecha_inicio,
      v_fecha_fin,
      v_num_dias,
      i_todo_ok_B,
      msgBasico,
      0 -- Comprobar reglas
    );
    
    -- Si hay errores en validación de vacaciones, terminar
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgBasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 7: VALIDACIÓN DE VACACIONES BOMBEROS
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES AND V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNC_BOMBERO THEN
    Chequeo_VACACIONES_BOMBEROS(
      v_id_ano,
      v_id_funcionario,
      v_id_tipo_funcionario,
      v_id_tipo_permiso,
      v_id_tipo_dias_ent,
      v_fecha_inicio,
      v_fecha_fin,
      v_num_dias,
      V_GUARDIAS,
      i_todo_ok_B,
      msgBasico,
      1 -- Comprobar reglas
    );
    
    -- Si hay errores, terminar
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgBasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 8: VALIDACIÓN DE BOLSA DE CONCILIACIÓN
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_CONCILIACION THEN
    chequeo_bolsa_concilia(
      v_id_ano,
      v_id_funcionario,
      v_fecha_inicio,
      v_fecha_fin,
      v_hora_inicio,
      v_hora_fin,
      v_total_horas,
      i_todo_ok_B,
      msgBasico
    );
    
    -- Si no hay saldo suficiente, terminar
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgBasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 9: VALIDACIÓN DE COMPENSATORIO
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO THEN
    chequeo_compensatorio(
      v_id_ano,
      v_id_funcionario,
      v_fecha_inicio,
      v_fecha_fin,
      v_hora_inicio,
      v_hora_fin,
      v_total_horas,
      i_todo_ok_B,
      msgBasico
    );
    
    -- Si no hay saldo suficiente, terminar
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgBasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 10: ACTUALIZACIÓN DE CONTADORES (PERMISOS ÚNICOS)
  -- Validación especial para vacaciones: máximo 22 días laborables
  --------------------------------------------------------------------------------
  
  IF V_UNICO = C_JUSTIF_SI AND V_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO THEN
    
    -- Validación especial: límite de 22 días laborables para vacaciones
    -- Añadido: 11/06/2020
    IF V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES 
       AND V_ID_TIPO_FUNCIONARIO NOT IN (C_TIPO_FUNC_BOMBERO, C_TIPO_FUNC_ESPECIAL) THEN
      
      -- Calcular días laborables efectivos
      i_num_dias_laborables := calcula_laborales_vaca(
        V_FECHA_INICIO,
        V_FECHA_FIN,
        V_ID_TIPO_DIAS_PER,
        V_ID_FUNCIONARIO,
        V_ID_ANO
      );
      
      -- Validar límite
      IF i_num_dias_laborables > C_MAX_DIAS_VACACIONES_LAB THEN
        msgsalida := 'Las vacaciones superan el límite de ' || C_MAX_DIAS_VACACIONES_LAB || ' días laborables.';
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
    
    -- Actualizar contador del permiso único
    ACTUALIZAR_UNICO_NEW(
      V_ID_ANO,
      V_ID_FUNCIONARIO,
      V_ID_TIPO_FUNCIONARIO,
      V_ID_TIPO_PERMISO,
      v_id_tipo_dias_ent,
      V_ID_TIPO_DIAS_PER,
      V_FECHA_INICIO,
      V_FECHA_FIN,
      V_NUM_DIAS,
      v_num_dias_tiene_per,
      i_todo_ok_B,
      msgBasico,
      0,
      i_num_dias_laborables
    );
    
    -- Si hay errores en actualización, terminar
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgBasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 11: INSERCIÓN DEL PERMISO Y ENVÍO DE NOTIFICACIONES
  --------------------------------------------------------------------------------
  
  inserta_permiso_new(
    v_id_ano,
    v_id_funcionario,
    v_id_tipo_funcionario,
    v_id_tipo_permiso,
    v_id_tipo_dias_ent,
    v_fecha_inicio,
    v_fecha_fin,
    v_hora_inicio,
    v_hora_fin,
    v_unico,
    v_dprovincia,
    v_id_GRADO,
    v_justificacion2,
    v_num_dias,
    v_total_horas,
    v_T1,
    v_T2,
    v_T3,
    V_GUARDIAS,
    i_todo_ok_B,
    msgBasico,
    v_enlace_fichero
  );
  
  -- Si hay errores en inserción, terminar
  IF i_todo_ok_B = 1 THEN
    msgsalida := msgBasico;
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 12: VERIFICAR SI EL FUNCIONARIO TIENE FICHAJE ACTIVO
  -- Fecha: 22/10/2006
  -- Modificación: 24/03/2010 - Uso de LPAD para comparación
  --------------------------------------------------------------------------------
  
  i_ficha := 1;
  BEGIN
    SELECT DISTINCT codpers
      INTO i_codpers
      FROM personal_new p, presenci pr, apliweb_usuario u
     WHERE p.id_funcionario = V_ID_FUNCIONARIO
       AND LPAD(TO_CHAR(p.id_funcionario), 6, '0') = LPAD(u.id_funcionario, 6, '0')
       AND u.id_fichaje IS NOT NULL
       AND u.id_fichaje = pr.codpers
       AND codinci <> 999
       AND ROWNUM < 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_ficha := 0;
  END;
  
  v_codpers := i_codpers;
  
  --------------------------------------------------------------------------------
  -- FASE 13: FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  COMMIT;
  msgsalida := 'La solicitud de permiso ha sido enviada para su firma.';
  todook := C_OK;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo robusto de excepciones no controladas
    todook := C_ERROR;
    msgsalida := 'Error inesperado al crear permiso: ' || SQLERRM || 
                 ' | Funcionario: ' || V_ID_FUNCIONARIO ||
                 ' | Tipo permiso: ' || V_ID_TIPO_PERMISO;
    ROLLBACK;
    
END PERMISOS_NEW;
/

