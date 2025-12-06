CREATE OR REPLACE PROCEDURE RRHH."PROCESA_LOTES_ITERACIONES" (
  p_tipo_proceso        IN VARCHAR2,  -- Tipo de proceso a ejecutar (permisos, ausencias, fichajes, etc.)
  p_id_lote             IN NUMBER,    -- ID del lote a procesar
  p_tamaño_lote         IN NUMBER DEFAULT 100,  -- Número de registros por iteración
  p_max_iteraciones     IN NUMBER DEFAULT 1000, -- Máximo de iteraciones permitidas
  p_modo_ejecucion      IN VARCHAR2 DEFAULT 'NORMAL', -- NORMAL, DEBUG, VALIDACION
  p_id_usuario          IN VARCHAR2,  -- Usuario que ejecuta el proceso
  p_resultado           OUT VARCHAR2, -- Resultado del proceso (OK, ERROR, WARNING)
  p_mensaje_salida      OUT VARCHAR2, -- Mensaje detallado del resultado
  p_registros_procesados OUT NUMBER,  -- Total de registros procesados
  p_registros_error     OUT NUMBER    -- Total de registros con error
) IS
  
  -- Variables de control de iteraciones
  v_iteracion_actual    NUMBER := 0;
  v_offset              NUMBER := 0;
  v_registros_restantes NUMBER := 0;
  v_registros_lote      NUMBER := 0;
  
  -- Variables de resultados
  v_registros_ok        NUMBER := 0;
  v_registros_skip      NUMBER := 0;
  v_error_count         NUMBER := 0;
  
  -- Variables de estado
  v_estado_lote         VARCHAR2(20);
  v_fecha_inicio        TIMESTAMP := SYSTIMESTAMP;
  v_fecha_fin           TIMESTAMP;
  v_tiempo_estimado     NUMBER := 0;
  
  -- Variables de log
  v_log_mensaje         VARCHAR2(4000);
  v_log_detalle         CLOB;
  
  -- Cursor para procesar registros según tipo
  CURSOR c_registros_lote IS
    SELECT id_registro, tipo_registro, estado, prioridad, datos_registro
    FROM lotes_procesamiento
    WHERE id_lote = p_id_lote
      AND estado IN ('PENDIENTE', 'REINTENTO')
      AND rownum <= p_tamaño_lote
    ORDER BY prioridad DESC, id_registro ASC
    FOR UPDATE SKIP LOCKED;
  
  TYPE t_registros IS TABLE OF c_registros_lote%ROWTYPE;
  v_registros t_registros;
  
  -- Excepciones personalizadas
  e_max_iteraciones EXCEPTION;
  e_lote_no_existe EXCEPTION;
  e_tipo_invalido EXCEPTION;
  
BEGIN
  
  -- Inicializar variables de salida
  p_resultado := 'OK';
  p_mensaje_salida := '';
  p_registros_procesados := 0;
  p_registros_error := 0;
  
  -- Log inicio de proceso
  v_log_mensaje := 'Iniciando proceso de lotes - Tipo: ' || p_tipo_proceso || 
                   ', Lote: ' || p_id_lote || 
                   ', Usuario: ' || p_id_usuario ||
                   ', Tamaño lote: ' || p_tamaño_lote;
  
  -- Validar que el lote existe
  BEGIN
    SELECT estado, COUNT(*) 
    INTO v_estado_lote, v_registros_restantes
    FROM lotes_procesamiento
    WHERE id_lote = p_id_lote
    GROUP BY estado;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE e_lote_no_existe;
  END;
  
  -- Validar tipo de proceso
  IF p_tipo_proceso NOT IN ('PERMISOS', 'AUSENCIAS', 'FICHAJES', 'NOMINAS', 'CURSOS') THEN
    RAISE e_tipo_invalido;
  END IF;
  
  -- Actualizar estado del lote a EN_PROCESO
  UPDATE lotes_control
  SET estado = 'EN_PROCESO',
      fecha_inicio_proceso = SYSTIMESTAMP,
      id_usuario_proceso = p_id_usuario
  WHERE id_lote = p_id_lote;
  
  -- Bucle principal de iteraciones
  WHILE v_registros_restantes > 0 AND v_iteracion_actual < p_max_iteraciones LOOP
    
    v_iteracion_actual := v_iteracion_actual + 1;
    
    -- Log de iteración
    IF p_modo_ejecucion = 'DEBUG' THEN
      DBMS_OUTPUT.PUT_LINE('Iteración ' || v_iteracion_actual || 
                          ' - Procesando hasta ' || p_tamaño_lote || ' registros...');
    END IF;
    
    -- Obtener registros del lote actual
    BEGIN
      OPEN c_registros_lote;
      FETCH c_registros_lote BULK COLLECT INTO v_registros LIMIT p_tamaño_lote;
      v_registros_lote := v_registros.COUNT;
      CLOSE c_registros_lote;
      
      -- Si no hay más registros, salir del bucle
      IF v_registros_lote = 0 THEN
        EXIT;
      END IF;
      
      -- Procesar cada registro del lote
      FOR i IN 1..v_registros.COUNT LOOP
        
        BEGIN
          -- Marcar registro como en proceso
          UPDATE lotes_procesamiento
          SET estado = 'PROCESANDO',
              iteracion_actual = v_iteracion_actual,
              fecha_inicio_proceso = SYSTIMESTAMP
          WHERE id_registro = v_registros(i).id_registro;
          
          -- Procesar según tipo
          CASE p_tipo_proceso
            WHEN 'PERMISOS' THEN
              -- Llamar al procedimiento de permisos
              NULL; -- Aquí iría la llamada real: permisos_new(params...);
              
            WHEN 'AUSENCIAS' THEN
              -- Llamar al procedimiento de ausencias
              NULL; -- Aquí iría la llamada real: ausencias_new(params...);
              
            WHEN 'FICHAJES' THEN
              -- Llamar al procedimiento de fichajes
              NULL; -- Aquí iría la llamada real: mete_fichaje_finger_new(params...);
              
            WHEN 'NOMINAS' THEN
              -- Llamar al procedimiento de nóminas
              NULL; -- Procesamiento de nóminas
              
            WHEN 'CURSOS' THEN
              -- Llamar al procedimiento de cursos
              NULL; -- Procesamiento de cursos
              
            ELSE
              -- Tipo no reconocido (ya validado antes, pero por seguridad)
              RAISE e_tipo_invalido;
          END CASE;
          
          -- Marcar registro como procesado OK
          UPDATE lotes_procesamiento
          SET estado = 'COMPLETADO',
              fecha_fin_proceso = SYSTIMESTAMP,
              resultado = 'OK',
              mensaje_resultado = 'Procesado correctamente en iteración ' || v_iteracion_actual
          WHERE id_registro = v_registros(i).id_registro;
          
          v_registros_ok := v_registros_ok + 1;
          p_registros_procesados := p_registros_procesados + 1;
          
        EXCEPTION
          WHEN OTHERS THEN
            -- Registrar error y continuar con siguiente registro
            v_error_count := v_error_count + 1;
            p_registros_error := p_registros_error + 1;
            
            UPDATE lotes_procesamiento
            SET estado = 'ERROR',
                fecha_fin_proceso = SYSTIMESTAMP,
                resultado = 'ERROR',
                mensaje_resultado = 'Error en iteración ' || v_iteracion_actual || ': ' || SQLERRM,
                reintentos = NVL(reintentos, 0) + 1
            WHERE id_registro = v_registros(i).id_registro;
            
            -- Log del error
            IF p_modo_ejecucion IN ('DEBUG', 'VALIDACION') THEN
              DBMS_OUTPUT.PUT_LINE('Error en registro ' || v_registros(i).id_registro || 
                                  ': ' || SQLERRM);
            END IF;
        END;
        
      END LOOP;
      
      -- Commit después de cada lote para no perder trabajo
      COMMIT;
      
      -- Calcular registros restantes
      SELECT COUNT(*)
      INTO v_registros_restantes
      FROM lotes_procesamiento
      WHERE id_lote = p_id_lote
        AND estado IN ('PENDIENTE', 'REINTENTO');
      
      -- Actualizar progreso del lote
      UPDATE lotes_control
      SET registros_procesados = p_registros_procesados,
          registros_error = p_registros_error,
          iteracion_actual = v_iteracion_actual,
          ultima_actualizacion = SYSTIMESTAMP
      WHERE id_lote = p_id_lote;
      
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        v_log_mensaje := 'Error en iteración ' || v_iteracion_actual || ': ' || SQLERRM;
        
        -- Actualizar estado del lote
        UPDATE lotes_control
        SET estado = 'ERROR',
            mensaje_error = v_log_mensaje,
            fecha_fin_proceso = SYSTIMESTAMP
        WHERE id_lote = p_id_lote;
        
        COMMIT;
        
        p_resultado := 'ERROR';
        p_mensaje_salida := v_log_mensaje;
        RETURN;
    END;
    
  END LOOP;
  
  -- Verificar si se alcanzó el máximo de iteraciones
  IF v_iteracion_actual >= p_max_iteraciones THEN
    RAISE e_max_iteraciones;
  END IF;
  
  -- Finalizar proceso
  v_fecha_fin := SYSTIMESTAMP;
  
  -- Determinar resultado final
  IF p_registros_error = 0 THEN
    p_resultado := 'OK';
    v_estado_lote := 'COMPLETADO';
  ELSIF p_registros_error < p_registros_procesados THEN
    p_resultado := 'WARNING';
    v_estado_lote := 'COMPLETADO_CON_ERRORES';
  ELSE
    p_resultado := 'ERROR';
    v_estado_lote := 'ERROR';
  END IF;
  
  -- Actualizar estado final del lote
  UPDATE lotes_control
  SET estado = v_estado_lote,
      fecha_fin_proceso = v_fecha_fin,
      registros_procesados = p_registros_procesados,
      registros_error = p_registros_error,
      registros_ok = v_registros_ok,
      total_iteraciones = v_iteracion_actual,
      tiempo_proceso = EXTRACT(SECOND FROM (v_fecha_fin - v_fecha_inicio))
  WHERE id_lote = p_id_lote;
  
  COMMIT;
  
  -- Construir mensaje de salida
  p_mensaje_salida := 'Proceso completado. ' ||
                      'Total registros: ' || p_registros_procesados ||
                      ', Exitosos: ' || v_registros_ok ||
                      ', Errores: ' || p_registros_error ||
                      ', Iteraciones: ' || v_iteracion_actual ||
                      ', Tiempo: ' || ROUND(EXTRACT(SECOND FROM (v_fecha_fin - v_fecha_inicio)), 2) || 's';
  
EXCEPTION
  WHEN e_lote_no_existe THEN
    ROLLBACK;
    p_resultado := 'ERROR';
    p_mensaje_salida := 'Error: El lote ' || p_id_lote || ' no existe';
    
  WHEN e_tipo_invalido THEN
    ROLLBACK;
    p_resultado := 'ERROR';
    p_mensaje_salida := 'Error: Tipo de proceso inválido: ' || p_tipo_proceso;
    
  WHEN e_max_iteraciones THEN
    ROLLBACK;
    p_resultado := 'ERROR';
    p_mensaje_salida := 'Error: Se alcanzó el máximo de iteraciones (' || p_max_iteraciones || 
                        '). Procesados: ' || p_registros_procesados ||
                        ', Pendientes: ' || v_registros_restantes;
    
    UPDATE lotes_control
    SET estado = 'MAX_ITERACIONES',
        mensaje_error = p_mensaje_salida,
        fecha_fin_proceso = SYSTIMESTAMP
    WHERE id_lote = p_id_lote;
    COMMIT;
    
  WHEN OTHERS THEN
    ROLLBACK;
    p_resultado := 'ERROR';
    p_mensaje_salida := 'Error inesperado: ' || SQLERRM || ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    
    -- Intentar actualizar estado del lote
    BEGIN
      UPDATE lotes_control
      SET estado = 'ERROR',
          mensaje_error = p_mensaje_salida,
          fecha_fin_proceso = SYSTIMESTAMP
      WHERE id_lote = p_id_lote;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL; -- Si falla la actualización, al menos reportamos el error
    END;
    
END PROCESA_LOTES_ITERACIONES;
/
