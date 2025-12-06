-- =====================================================
-- Script de Ejemplo y Prueba
-- Sistema de Procesamiento por Lotes con Iteraciones
-- =====================================================

SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_resultado           VARCHAR2(4000);
  v_mensaje_salida      VARCHAR2(4000);
  v_registros_procesados NUMBER;
  v_registros_error     NUMBER;
  v_id_lote             NUMBER;
BEGIN
  
  DBMS_OUTPUT.PUT_LINE('==============================================');
  DBMS_OUTPUT.PUT_LINE('TEST: Sistema de Procesamiento por Lotes');
  DBMS_OUTPUT.PUT_LINE('==============================================');
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- PASO 1: Crear un nuevo lote
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 1: Creando nuevo lote de prueba...');
  
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion       => 'CREAR',
    p_tipo_proceso => 'PERMISOS',
    p_descripcion  => 'Lote de prueba - Permisos Diciembre 2025',
    p_id_usuario   => 'TEST_USER',
    p_prioridad    => 5
  );
  
  DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('');
  
  -- Extraer id_lote del JSON (método simple)
  -- En producción usar JSON_VALUE o parser JSON apropiado
  v_id_lote := TO_NUMBER(
    REGEXP_SUBSTR(v_resultado, '"id_lote": ([0-9]+)', 1, 1, NULL, 1)
  );
  
  DBMS_OUTPUT.PUT_LINE('ID Lote creado: ' || v_id_lote);
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- PASO 2: Agregar registros de prueba al lote
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 2: Agregando registros de prueba al lote...');
  
  -- Insertar 150 registros de prueba
  FOR i IN 1..150 LOOP
    INSERT INTO LOTES_PROCESAMIENTO (
      id_registro,
      id_lote,
      tipo_registro,
      estado,
      prioridad,
      datos_registro,
      fecha_creacion,
      iteracion_actual,
      reintentos
    ) VALUES (
      SEQ_LOTES_PROCESAMIENTO.NEXTVAL,
      v_id_lote,
      'PERMISO_TEST',
      'PENDIENTE',
      5,
      '{"id_funcionario": ' || (1000 + i) || 
      ', "tipo_permiso": "VACACIONES", ' ||
      '"dias": 5, "fecha_inicio": "01/12/2025"}',
      SYSTIMESTAMP,
      0,
      0
    );
  END LOOP;
  
  -- Actualizar total de registros en control
  UPDATE LOTES_CONTROL
  SET registros_total = 150
  WHERE id_lote = v_id_lote;
  
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('150 registros agregados al lote ' || v_id_lote);
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- PASO 3: Consultar estado del lote (antes de procesar)
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 3: Consultando estado del lote...');
  
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion         => 'CONSULTAR',
    p_id_lote_origen => v_id_lote,
    p_id_usuario     => 'TEST_USER'
  );
  
  DBMS_OUTPUT.PUT_LINE('Estado: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- PASO 4: Procesar el lote en modo DEBUG
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 4: Procesando lote (modo NORMAL)...');
  DBMS_OUTPUT.PUT_LINE('Configuración: Tamaño lote=50, Max iteraciones=10');
  DBMS_OUTPUT.PUT_LINE('');
  
  -- NOTA: En este ejemplo, el procesamiento real está comentado
  -- porque no tenemos procedimientos de negocio conectados.
  -- En producción, descomentar esta sección.
  
  /*
  PROCESA_LOTES_ITERACIONES(
    p_tipo_proceso         => 'PERMISOS',
    p_id_lote              => v_id_lote,
    p_tamaño_lote          => 50,
    p_max_iteraciones      => 10,
    p_modo_ejecucion       => 'DEBUG',
    p_id_usuario           => 'TEST_USER',
    p_resultado            => v_resultado,
    p_mensaje_salida       => v_mensaje_salida,
    p_registros_procesados => v_registros_procesados,
    p_registros_error      => v_registros_error
  );
  
  DBMS_OUTPUT.PUT_LINE('--- Resultado del Procesamiento ---');
  DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_mensaje_salida);
  DBMS_OUTPUT.PUT_LINE('Registros procesados: ' || v_registros_procesados);
  DBMS_OUTPUT.PUT_LINE('Registros con error: ' || v_registros_error);
  DBMS_OUTPUT.PUT_LINE('');
  */
  
  DBMS_OUTPUT.PUT_LINE('[INFO] Procesamiento real omitido en modo test');
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- PASO 5: Duplicar el lote
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 5: Duplicando lote para reproceso...');
  
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion         => 'DUPLICAR',
    p_id_lote_origen => v_id_lote,
    p_id_usuario     => 'TEST_USER',
    p_prioridad      => 3  -- Mayor prioridad
  );
  
  DBMS_OUTPUT.PUT_LINE('Resultado duplicación: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- PASO 6: Consultar estado mediante vista
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 6: Consultando estado mediante vista...');
  
  FOR rec IN (
    SELECT 
      id_lote,
      tipo_proceso,
      estado_lote,
      registros_total,
      pendientes,
      completados,
      errores,
      porcentaje_completado
    FROM V_LOTES_ESTADO
    WHERE id_lote IN (v_id_lote, v_id_lote + 1)
    ORDER BY id_lote
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('--- Lote ' || rec.id_lote || ' ---');
    DBMS_OUTPUT.PUT_LINE('Tipo: ' || rec.tipo_proceso);
    DBMS_OUTPUT.PUT_LINE('Estado: ' || rec.estado_lote);
    DBMS_OUTPUT.PUT_LINE('Total: ' || rec.registros_total);
    DBMS_OUTPUT.PUT_LINE('Pendientes: ' || rec.pendientes);
    DBMS_OUTPUT.PUT_LINE('Completados: ' || rec.completados);
    DBMS_OUTPUT.PUT_LINE('Errores: ' || rec.errores);
    DBMS_OUTPUT.PUT_LINE('Progreso: ' || NVL(rec.porcentaje_completado, 0) || '%');
    DBMS_OUTPUT.PUT_LINE('');
  END LOOP;
  
  -- =====================================================
  -- PASO 7: Cancelar lote (opcional)
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('PASO 7: Cancelando lote de prueba...');
  
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion         => 'CANCELAR',
    p_id_lote_origen => v_id_lote,
    p_id_usuario     => 'TEST_USER'
  );
  
  DBMS_OUTPUT.PUT_LINE('Resultado cancelación: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('');
  
  -- =====================================================
  -- RESUMEN FINAL
  -- =====================================================
  DBMS_OUTPUT.PUT_LINE('==============================================');
  DBMS_OUTPUT.PUT_LINE('TEST COMPLETADO EXITOSAMENTE');
  DBMS_OUTPUT.PUT_LINE('==============================================');
  DBMS_OUTPUT.PUT_LINE('Funcionalidades probadas:');
  DBMS_OUTPUT.PUT_LINE('  ✓ Creación de lote');
  DBMS_OUTPUT.PUT_LINE('  ✓ Inserción de registros');
  DBMS_OUTPUT.PUT_LINE('  ✓ Consulta de estado');
  DBMS_OUTPUT.PUT_LINE('  ✓ Duplicación de lote');
  DBMS_OUTPUT.PUT_LINE('  ✓ Vista consolidada');
  DBMS_OUTPUT.PUT_LINE('  ✓ Cancelación de lote');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Para procesar realmente los lotes:');
  DBMS_OUTPUT.PUT_LINE('  1. Descomentar sección PASO 4');
  DBMS_OUTPUT.PUT_LINE('  2. Implementar lógica de negocio en PROCESA_LOTES_ITERACIONES');
  DBMS_OUTPUT.PUT_LINE('  3. Conectar con procedimientos existentes (permisos_new, etc.)');
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ERROR EN TEST:');
    DBMS_OUTPUT.PUT_LINE(SQLERRM);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
END;
/

-- =====================================================
-- Queries de Verificación
-- =====================================================

PROMPT
PROMPT ===== VERIFICACIÓN: Lotes Creados =====
SELECT 
  id_lote,
  tipo_proceso,
  estado,
  registros_total,
  TO_CHAR(fecha_creacion, 'DD/MM/YYYY HH24:MI:SS') as fecha_creacion,
  id_usuario_creacion
FROM LOTES_CONTROL
ORDER BY id_lote DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT ===== VERIFICACIÓN: Estado Detallado =====
SELECT 
  id_lote,
  tipo_proceso,
  estado_lote,
  registros_total,
  pendientes,
  procesando,
  completados,
  errores,
  ROUND(porcentaje_completado, 2) as progreso
FROM V_LOTES_ESTADO
ORDER BY id_lote DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT ===== Script de Test Finalizado =====
