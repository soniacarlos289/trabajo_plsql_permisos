-- =====================================================
-- Ejemplo de Integración con Procedimientos Existentes
-- Sistema de Lotes + Procedimientos de Negocio
-- =====================================================

/*
  Este archivo muestra cómo integrar el sistema de procesamiento
  por lotes con los procedimientos existentes del sistema RRHH.
  
  Los procedimientos principales que pueden beneficiarse son:
  - permisos_new.prc
  - ausencias_new.prc  
  - mete_fichaje_finger_new.prc
  - inserta_permiso_new.prc
  - etc.
*/

-- =====================================================
-- EJEMPLO 1: Procesamiento Masivo de Permisos
-- =====================================================

-- Paso 1: Crear lote para permisos masivos
DECLARE
  v_resultado VARCHAR2(4000);
  v_id_lote NUMBER;
BEGIN
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion       => 'CREAR',
    p_tipo_proceso => 'PERMISOS',
    p_descripcion  => 'Permisos vacaciones Navidad 2025',
    p_id_usuario   => 'ADMIN_RRHH',
    p_prioridad    => 3  -- Alta prioridad
  );
  
  -- Extraer ID del lote del JSON
  v_id_lote := TO_NUMBER(
    REGEXP_SUBSTR(v_resultado, '"id_lote": ([0-9]+)', 1, 1, NULL, 1)
  );
  
  DBMS_OUTPUT.PUT_LINE('Lote creado: ' || v_id_lote);
END;
/

-- Paso 2: Cargar datos desde una tabla temporal o CSV importado
INSERT INTO LOTES_PROCESAMIENTO (
  id_registro,
  id_lote,
  tipo_registro,
  estado,
  prioridad,
  datos_registro
)
SELECT
  SEQ_LOTES_PROCESAMIENTO.NEXTVAL,
  1,  -- ID del lote creado en paso 1
  'PERMISO_VACACIONES',
  'PENDIENTE',
  5,
  -- Construir JSON con los parámetros que necesita permisos_new
  '{"id_funcionario": "' || id_funcionario || '",' ||
  ' "fecha_inicio": "' || TO_CHAR(fecha_inicio, 'DD/MM/YYYY') || '",' ||
  ' "fecha_fin": "' || TO_CHAR(fecha_fin, 'DD/MM/YYYY') || '",' ||
  ' "id_tipo_permiso": "' || id_tipo_permiso || '",' ||
  ' "observaciones": "' || observaciones || '",' ||
  ' "id_usuario": "ADMIN_RRHH"}'
FROM tabla_permisos_importados
WHERE estado_importacion = 'PENDIENTE'
  AND validado = 'S';

-- Actualizar total en control
UPDATE LOTES_CONTROL
SET registros_total = (
  SELECT COUNT(*) FROM LOTES_PROCESAMIENTO WHERE id_lote = 1
)
WHERE id_lote = 1;

COMMIT;

-- =====================================================
-- EJEMPLO 2: Wrapper para llamar a permisos_new desde el lote
-- =====================================================

CREATE OR REPLACE PROCEDURE PROCESA_PERMISO_DESDE_LOTE (
  p_datos_json      IN CLOB,
  p_resultado       OUT VARCHAR2,
  p_mensaje         OUT VARCHAR2
) IS
  
  v_id_funcionario  VARCHAR2(50);
  v_fecha_inicio    VARCHAR2(20);
  v_fecha_fin       VARCHAR2(20);
  v_id_tipo_permiso VARCHAR2(10);
  v_observaciones   VARCHAR2(500);
  v_id_usuario      VARCHAR2(50);
  
  -- Variables para llamar al procedimiento real
  v_msg_salida      VARCHAR2(4000);
  v_todo_ok         VARCHAR2(1);
  
BEGIN
  
  -- Parsear JSON (método simple, en producción usar JSON_VALUE)
  v_id_funcionario  := REGEXP_SUBSTR(p_datos_json, '"id_funcionario": "([^"]+)"', 1, 1, NULL, 1);
  v_fecha_inicio    := REGEXP_SUBSTR(p_datos_json, '"fecha_inicio": "([^"]+)"', 1, 1, NULL, 1);
  v_fecha_fin       := REGEXP_SUBSTR(p_datos_json, '"fecha_fin": "([^"]+)"', 1, 1, NULL, 1);
  v_id_tipo_permiso := REGEXP_SUBSTR(p_datos_json, '"id_tipo_permiso": "([^"]+)"', 1, 1, NULL, 1);
  v_observaciones   := REGEXP_SUBSTR(p_datos_json, '"observaciones": "([^"]+)"', 1, 1, NULL, 1);
  v_id_usuario      := REGEXP_SUBSTR(p_datos_json, '"id_usuario": "([^"]+)"', 1, 1, NULL, 1);
  
  -- Llamar al procedimiento real de negocio
  PERMISOS_NEW(
    V_ID_FUNCIONARIO  => v_id_funcionario,
    V_FECHA_INICIO    => v_fecha_inicio,
    V_FECHA_FIN       => v_fecha_fin,
    V_ID_TIPO_PERMISO => v_id_tipo_permiso,
    V_OBSERVACIONES   => v_observaciones,
    V_ID_USUARIO      => v_id_usuario,
    MSGSALIDA         => v_msg_salida,
    V_TODO_OK         => v_todo_ok
  );
  
  IF v_todo_ok = '0' THEN
    p_resultado := 'OK';
    p_mensaje := 'Permiso procesado correctamente';
  ELSE
    p_resultado := 'ERROR';
    p_mensaje := v_msg_salida;
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    p_resultado := 'ERROR';
    p_mensaje := 'Error al procesar permiso: ' || SQLERRM;
END;
/

-- =====================================================
-- EJEMPLO 3: Versión mejorada de PROCESA_LOTES_ITERACIONES
--            conectada con procedimientos reales
-- =====================================================

/*
  Para conectar el sistema con procedimientos reales, modifica
  el CASE dentro de PROCESA_LOTES_ITERACIONES.prc:
  
  CASE p_tipo_proceso
    WHEN 'PERMISOS' THEN
      -- Parsear JSON y llamar a wrapper
      PROCESA_PERMISO_DESDE_LOTE(
        p_datos_json => v_registros(i).datos_registro,
        p_resultado  => v_resultado_proc,
        p_mensaje    => v_mensaje_proc
      );
      
      IF v_resultado_proc != 'OK' THEN
        RAISE e_error_procesamiento;
      END IF;
      
    WHEN 'AUSENCIAS' THEN
      -- Similar para ausencias
      PROCESA_AUSENCIA_DESDE_LOTE(...);
      
    WHEN 'FICHAJES' THEN
      -- Similar para fichajes
      PROCESA_FICHAJE_DESDE_LOTE(...);
      
    -- etc.
  END CASE;
*/

-- =====================================================
-- EJEMPLO 4: Monitoreo en tiempo real
-- =====================================================

-- Consultar progreso cada X segundos
SELECT 
  id_lote,
  tipo_proceso,
  estado_lote,
  registros_total,
  registros_procesados,
  registros_error,
  porcentaje_completado,
  iteracion_actual,
  TO_CHAR(fecha_inicio_proceso, 'HH24:MI:SS') as hora_inicio,
  ROUND((SYSTIMESTAMP - fecha_inicio_proceso) * 24 * 60, 1) as minutos_transcurridos
FROM V_LOTES_ESTADO
WHERE estado_lote = 'EN_PROCESO'
ORDER BY fecha_inicio_proceso DESC;

-- Ver detalle de iteraciones
SELECT 
  iteracion_numero,
  registros_procesados,
  registros_exitosos,
  registros_error,
  ROUND(tiempo_ejecucion, 2) as tiempo_seg,
  TO_CHAR(fecha_inicio, 'HH24:MI:SS') as hora
FROM LOTES_LOG_ITERACIONES
WHERE id_lote = 1
ORDER BY iteracion_numero DESC
FETCH FIRST 10 ROWS ONLY;

-- =====================================================
-- EJEMPLO 5: Job programado para procesar lotes nocturnos
-- =====================================================

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_PROCESA_LOTES_PENDIENTES',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '
DECLARE
  v_resultado           VARCHAR2(50);
  v_mensaje             VARCHAR2(4000);
  v_registros_proc      NUMBER;
  v_registros_error     NUMBER;
BEGIN
  -- Procesar todos los lotes en estado CREADO
  FOR lote IN (
    SELECT id_lote, tipo_proceso
    FROM LOTES_CONTROL
    WHERE estado = ''CREADO''
      AND fecha_creacion < SYSTIMESTAMP - INTERVAL ''1'' HOUR
    ORDER BY prioridad ASC, fecha_creacion ASC
  ) LOOP
    
    BEGIN
      PROCESA_LOTES_ITERACIONES(
        p_tipo_proceso         => lote.tipo_proceso,
        p_id_lote              => lote.id_lote,
        p_tamaño_lote          => 100,
        p_max_iteraciones      => 1000,
        p_modo_ejecucion       => ''NORMAL'',
        p_id_usuario           => ''SISTEMA_AUTO'',
        p_resultado            => v_resultado,
        p_mensaje_salida       => v_mensaje,
        p_registros_procesados => v_registros_proc,
        p_registros_error      => v_registros_error
      );
      
      DBMS_OUTPUT.PUT_LINE(''Lote '' || lote.id_lote || '': '' || v_resultado);
      
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(''Error en lote '' || lote.id_lote || '': '' || SQLERRM);
    END;
    
  END LOOP;
END;
    ',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',  -- 2 AM diario
    enabled         => FALSE  -- Activar manualmente después de pruebas
  );
END;
/

-- =====================================================
-- EJEMPLO 6: Procesamiento de lote con reintentos automáticos
-- =====================================================

DECLARE
  v_resultado           VARCHAR2(50);
  v_mensaje             VARCHAR2(4000);
  v_registros_proc      NUMBER;
  v_registros_error     NUMBER;
  v_max_reintentos      NUMBER := 3;
  v_intento             NUMBER := 1;
BEGIN
  
  WHILE v_intento <= v_max_reintentos LOOP
    
    DBMS_OUTPUT.PUT_LINE('Intento ' || v_intento || ' de ' || v_max_reintentos);
    
    PROCESA_LOTES_ITERACIONES(
      p_tipo_proceso         => 'PERMISOS',
      p_id_lote              => 1,
      p_tamaño_lote          => 50,
      p_max_iteraciones      => 500,
      p_modo_ejecucion       => 'NORMAL',
      p_id_usuario           => 'ADMIN',
      p_resultado            => v_resultado,
      p_mensaje_salida       => v_mensaje,
      p_registros_procesados => v_registros_proc,
      p_registros_error      => v_registros_error
    );
    
    IF v_resultado = 'OK' THEN
      DBMS_OUTPUT.PUT_LINE('Procesamiento exitoso!');
      EXIT;
    ELSIF v_registros_error > 0 AND v_intento < v_max_reintentos THEN
      -- Marcar errores para reintento
      UPDATE LOTES_PROCESAMIENTO
      SET estado = 'REINTENTO'
      WHERE id_lote = 1
        AND estado = 'ERROR'
        AND reintentos < 3;
      COMMIT;
      
      -- Esperar antes del siguiente intento
      DBMS_LOCK.SLEEP(5);  -- 5 segundos
    END IF;
    
    v_intento := v_intento + 1;
    
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Resultado final: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_mensaje);
  
END;
/

-- =====================================================
-- EJEMPLO 7: Consulta de registros con error para análisis
-- =====================================================

SELECT 
  lp.id_registro,
  lp.tipo_registro,
  lp.estado,
  lp.mensaje_resultado,
  lp.reintentos,
  lp.datos_registro,
  TO_CHAR(lp.fecha_fin_proceso, 'DD/MM/YYYY HH24:MI:SS') as fecha_error
FROM LOTES_PROCESAMIENTO lp
WHERE lp.id_lote = 1
  AND lp.estado = 'ERROR'
ORDER BY lp.fecha_fin_proceso DESC;

-- Extraer parámetros específicos que fallaron
SELECT 
  lp.id_registro,
  REGEXP_SUBSTR(lp.datos_registro, '"id_funcionario": "([^"]+)"', 1, 1, NULL, 1) as funcionario,
  REGEXP_SUBSTR(lp.datos_registro, '"fecha_inicio": "([^"]+)"', 1, 1, NULL, 1) as fecha_inicio,
  lp.mensaje_resultado,
  lp.reintentos
FROM LOTES_PROCESAMIENTO lp
WHERE lp.id_lote = 1
  AND lp.estado = 'ERROR'
ORDER BY lp.reintentos DESC, lp.id_registro;

-- =====================================================
-- EJEMPLO 8: Limpieza de lotes antiguos completados
-- =====================================================

-- Archivar en tabla histórica (opcional, crear primero)
-- CREATE TABLE LOTES_CONTROL_HISTORICO AS SELECT * FROM LOTES_CONTROL WHERE 1=0;

-- Eliminar lotes completados de hace más de 90 días
DELETE FROM LOTES_LOG_ITERACIONES
WHERE id_lote IN (
  SELECT id_lote 
  FROM LOTES_CONTROL 
  WHERE estado IN ('COMPLETADO', 'CANCELADO')
    AND fecha_fin_proceso < SYSDATE - 90
);

DELETE FROM LOTES_PROCESAMIENTO
WHERE id_lote IN (
  SELECT id_lote 
  FROM LOTES_CONTROL 
  WHERE estado IN ('COMPLETADO', 'CANCELADO')
    AND fecha_fin_proceso < SYSDATE - 90
);

DELETE FROM LOTES_CONTROL
WHERE estado IN ('COMPLETADO', 'CANCELADO')
  AND fecha_fin_proceso < SYSDATE - 90;

COMMIT;

DBMS_OUTPUT.PUT_LINE('Limpieza completada');

-- =====================================================
-- FIN DE EJEMPLOS DE INTEGRACIÓN
-- =====================================================

/*
  NOTAS FINALES:
  
  1. Para usar en producción, implementar los wrappers específicos
     para cada tipo de proceso (PERMISOS, AUSENCIAS, etc.)
     
  2. Modificar el CASE en procesa_lotes_iteraciones.prc para 
     llamar a los wrappers correspondientes
     
  3. Ajustar el tamaño de lote según el tipo de operación:
     - Operaciones simples: 200-500 registros/lote
     - Operaciones complejas: 50-100 registros/lote
     
  4. Configurar jobs programados para procesamiento nocturno
  
  5. Implementar notificaciones por email para errores críticos
  
  6. Monitorear rendimiento y ajustar índices si es necesario
*/
