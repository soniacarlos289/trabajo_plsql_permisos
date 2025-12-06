CREATE OR REPLACE FUNCTION RRHH."GESTIONA_RUTA_LOTES" (
  p_accion              IN VARCHAR2,  -- CREAR, DUPLICAR, CONSULTAR, CANCELAR
  p_id_lote_origen      IN NUMBER DEFAULT NULL,  -- ID del lote origen (para duplicar)
  p_tipo_proceso        IN VARCHAR2 DEFAULT NULL, -- Tipo de proceso
  p_descripcion         IN VARCHAR2 DEFAULT NULL, -- Descripción del lote
  p_id_usuario          IN VARCHAR2, -- Usuario que ejecuta
  p_prioridad           IN NUMBER DEFAULT 5      -- Prioridad (1=Alta, 5=Normal, 10=Baja)
) RETURN VARCHAR2 IS
  
  v_id_lote_nuevo       NUMBER;
  v_resultado           VARCHAR2(4000);
  v_json_output         VARCHAR2(4000);
  v_count_registros     NUMBER := 0;
  v_estado_origen       VARCHAR2(20);
  
  -- Excepciones
  e_accion_invalida     EXCEPTION;
  e_lote_no_existe      EXCEPTION;
  e_tipo_invalido       EXCEPTION;
  
BEGIN
  
  -- Validar acción
  IF p_accion NOT IN ('CREAR', 'DUPLICAR', 'CONSULTAR', 'CANCELAR') THEN
    RAISE e_accion_invalida;
  END IF;
  
  CASE p_accion
    
    -- Crear nuevo lote vacío
    WHEN 'CREAR' THEN
      
      -- Validar tipo de proceso
      IF p_tipo_proceso IS NULL OR p_tipo_proceso NOT IN ('PERMISOS', 'AUSENCIAS', 'FICHAJES', 'NOMINAS', 'CURSOS') THEN
        RAISE e_tipo_invalido;
      END IF;
      
      -- Obtener siguiente ID de lote usando secuencia
      SELECT SEQ_LOTES_CONTROL.NEXTVAL
      INTO v_id_lote_nuevo
      FROM DUAL;
      
      -- Crear registro de control del lote
      INSERT INTO lotes_control (
        id_lote,
        tipo_proceso,
        descripcion,
        estado,
        prioridad,
        fecha_creacion,
        id_usuario_creacion,
        registros_total,
        registros_procesados,
        registros_error,
        iteracion_actual
      ) VALUES (
        v_id_lote_nuevo,
        p_tipo_proceso,
        NVL(p_descripcion, 'Lote ' || p_tipo_proceso || ' - ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')),
        'CREADO',
        p_prioridad,
        SYSTIMESTAMP,
        p_id_usuario,
        0,
        0,
        0,
        0
      );
      
      COMMIT;
      
      -- Construir respuesta JSON
      v_json_output := '{"resultado": "OK", ' ||
                       '"id_lote": ' || v_id_lote_nuevo || ', ' ||
                       '"tipo_proceso": "' || p_tipo_proceso || '", ' ||
                       '"estado": "CREADO", ' ||
                       '"mensaje": "Lote creado exitosamente"}';
      
      RETURN v_json_output;
      
    -- Duplicar lote existente
    WHEN 'DUPLICAR' THEN
      
      -- Validar que existe el lote origen
      IF p_id_lote_origen IS NULL THEN
        RAISE e_lote_no_existe;
      END IF;
      
      BEGIN
        SELECT COUNT(*)
        INTO v_count_registros
        FROM lotes_procesamiento
        WHERE id_lote = p_id_lote_origen;
        
        IF v_count_registros = 0 THEN
          RAISE e_lote_no_existe;
        END IF;
        
        SELECT estado
        INTO v_estado_origen
        FROM lotes_control
        WHERE id_lote = p_id_lote_origen;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE e_lote_no_existe;
      END;
      
      -- Obtener siguiente ID de lote usando secuencia
      SELECT SEQ_LOTES_CONTROL.NEXTVAL
      INTO v_id_lote_nuevo
      FROM DUAL;
      
      -- Crear nuevo lote control basado en el origen
      INSERT INTO lotes_control (
        id_lote,
        tipo_proceso,
        descripcion,
        estado,
        prioridad,
        fecha_creacion,
        id_usuario_creacion,
        registros_total,
        registros_procesados,
        registros_error,
        iteracion_actual,
        id_lote_origen
      )
      SELECT
        v_id_lote_nuevo,
        tipo_proceso,
        'DUPLICADO DE ' || descripcion,
        'CREADO',
        p_prioridad,
        SYSTIMESTAMP,
        p_id_usuario,
        registros_total,
        0,  -- Reiniciar procesados
        0,  -- Reiniciar errores
        0,  -- Reiniciar iteraciones
        p_id_lote_origen
      FROM lotes_control
      WHERE id_lote = p_id_lote_origen;
      
      -- Duplicar registros del lote
      INSERT INTO lotes_procesamiento (
        id_registro,
        id_lote,
        tipo_registro,
        estado,
        prioridad,
        datos_registro,
        fecha_creacion,
        iteracion_actual,
        reintentos
      )
      SELECT
        SEQ_LOTES_PROCESAMIENTO.NEXTVAL,  -- Nuevo ID
        v_id_lote_nuevo,                   -- Nuevo lote
        tipo_registro,
        'PENDIENTE',                       -- Resetear estado
        prioridad,
        datos_registro,
        SYSTIMESTAMP,
        0,                                 -- Resetear iteración
        0                                  -- Resetear reintentos
      FROM lotes_procesamiento
      WHERE id_lote = p_id_lote_origen;
      
      v_count_registros := SQL%ROWCOUNT;
      
      -- Actualizar total de registros en control
      UPDATE lotes_control
      SET registros_total = v_count_registros
      WHERE id_lote = v_id_lote_nuevo;
      
      COMMIT;
      
      -- Construir respuesta JSON
      v_json_output := '{"resultado": "OK", ' ||
                       '"id_lote_nuevo": ' || v_id_lote_nuevo || ', ' ||
                       '"id_lote_origen": ' || p_id_lote_origen || ', ' ||
                       '"registros_duplicados": ' || v_count_registros || ', ' ||
                       '"estado": "CREADO", ' ||
                       '"mensaje": "Lote duplicado exitosamente con ' || v_count_registros || ' registros"}';
      
      RETURN v_json_output;
      
    -- Consultar estado del lote
    WHEN 'CONSULTAR' THEN
      
      IF p_id_lote_origen IS NULL THEN
        RAISE e_lote_no_existe;
      END IF;
      
      -- Obtener información del lote
      SELECT
        '{"resultado": "OK", ' ||
        '"id_lote": ' || id_lote || ', ' ||
        '"tipo_proceso": "' || tipo_proceso || '", ' ||
        '"descripcion": "' || REPLACE(descripcion, '"', '\"') || '", ' ||
        '"estado": "' || estado || '", ' ||
        '"prioridad": ' || prioridad || ', ' ||
        '"registros_total": ' || registros_total || ', ' ||
        '"registros_procesados": ' || NVL(registros_procesados, 0) || ', ' ||
        '"registros_error": ' || NVL(registros_error, 0) || ', ' ||
        '"registros_ok": ' || NVL(registros_ok, 0) || ', ' ||
        '"iteracion_actual": ' || NVL(iteracion_actual, 0) || ', ' ||
        '"total_iteraciones": ' || NVL(total_iteraciones, 0) || ', ' ||
        '"fecha_creacion": "' || TO_CHAR(fecha_creacion, 'DD/MM/YYYY HH24:MI:SS') || '", ' ||
        '"usuario_creacion": "' || id_usuario_creacion || '", ' ||
        CASE 
          WHEN fecha_inicio_proceso IS NOT NULL THEN
            '"fecha_inicio_proceso": "' || TO_CHAR(fecha_inicio_proceso, 'DD/MM/YYYY HH24:MI:SS') || '", '
          ELSE ''
        END ||
        CASE 
          WHEN fecha_fin_proceso IS NOT NULL THEN
            '"fecha_fin_proceso": "' || TO_CHAR(fecha_fin_proceso, 'DD/MM/YYYY HH24:MI:SS') || '", ' ||
            '"tiempo_proceso": ' || NVL(tiempo_proceso, 0) || ', '
          ELSE ''
        END ||
        '"mensaje": "Consulta exitosa"}'
      INTO v_json_output
      FROM lotes_control
      WHERE id_lote = p_id_lote_origen;
      
      RETURN v_json_output;
      
    -- Cancelar lote
    WHEN 'CANCELAR' THEN
      
      IF p_id_lote_origen IS NULL THEN
        RAISE e_lote_no_existe;
      END IF;
      
      -- Verificar que el lote existe
      SELECT COUNT(*)
      INTO v_count_registros
      FROM lotes_control
      WHERE id_lote = p_id_lote_origen;
      
      IF v_count_registros = 0 THEN
        RAISE e_lote_no_existe;
      END IF;
      
      -- Cancelar registros pendientes
      UPDATE lotes_procesamiento
      SET estado = 'CANCELADO',
          fecha_fin_proceso = SYSTIMESTAMP,
          mensaje_resultado = 'Cancelado por usuario: ' || p_id_usuario
      WHERE id_lote = p_id_lote_origen
        AND estado IN ('PENDIENTE', 'REINTENTO', 'PROCESANDO');
      
      v_count_registros := SQL%ROWCOUNT;
      
      -- Actualizar estado del lote
      UPDATE lotes_control
      SET estado = 'CANCELADO',
          fecha_fin_proceso = SYSTIMESTAMP,
          mensaje_error = 'Cancelado por usuario: ' || p_id_usuario
      WHERE id_lote = p_id_lote_origen;
      
      COMMIT;
      
      -- Construir respuesta JSON
      v_json_output := '{"resultado": "OK", ' ||
                       '"id_lote": ' || p_id_lote_origen || ', ' ||
                       '"registros_cancelados": ' || v_count_registros || ', ' ||
                       '"estado": "CANCELADO", ' ||
                       '"mensaje": "Lote cancelado exitosamente"}';
      
      RETURN v_json_output;
      
  END CASE;
  
EXCEPTION
  WHEN e_accion_invalida THEN
    ROLLBACK;
    RETURN '{"resultado": "ERROR", "mensaje": "Acción inválida: ' || p_accion || 
           '. Acciones válidas: CREAR, DUPLICAR, CONSULTAR, CANCELAR"}';
           
  WHEN e_lote_no_existe THEN
    ROLLBACK;
    RETURN '{"resultado": "ERROR", "mensaje": "El lote ' || 
           NVL(TO_CHAR(p_id_lote_origen), 'NULL') || ' no existe"}';
           
  WHEN e_tipo_invalido THEN
    ROLLBACK;
    RETURN '{"resultado": "ERROR", "mensaje": "Tipo de proceso inválido: ' || 
           NVL(p_tipo_proceso, 'NULL') || 
           '. Tipos válidos: PERMISOS, AUSENCIAS, FICHAJES, NOMINAS, CURSOS"}';
           
  WHEN OTHERS THEN
    ROLLBACK;
    RETURN '{"resultado": "ERROR", "mensaje": "Error inesperado: ' || 
           REPLACE(SQLERRM, '"', '\"') || '"}';
           
END GESTIONA_RUTA_LOTES;
/
