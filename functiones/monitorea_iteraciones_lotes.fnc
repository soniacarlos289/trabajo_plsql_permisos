CREATE OR REPLACE FUNCTION RRHH."MONITOREA_ITERACIONES_LOTES" (
  p_id_lote             IN NUMBER,
  p_formato_salida      IN VARCHAR2 DEFAULT 'JSON'  -- JSON, TEXT, HTML
) RETURN VARCHAR2 IS
  
  v_output              VARCHAR2(32767);
  v_estado_lote         VARCHAR2(50);
  v_tipo_proceso        VARCHAR2(50);
  v_total_registros     NUMBER;
  v_procesados          NUMBER;
  v_errores             NUMBER;
  v_progreso            NUMBER;
  v_tiempo_total        NUMBER;
  v_tiempo_promedio     NUMBER;
  v_iteraciones_count   NUMBER;
  
  CURSOR c_iteraciones IS
    SELECT 
      iteracion_numero,
      registros_procesados,
      registros_exitosos,
      registros_error,
      tiempo_ejecucion,
      TO_CHAR(fecha_inicio, 'DD/MM/YYYY HH24:MI:SS') as fecha_inicio_fmt,
      TO_CHAR(fecha_fin, 'DD/MM/YYYY HH24:MI:SS') as fecha_fin_fmt,
      mensaje
    FROM LOTES_LOG_ITERACIONES
    WHERE id_lote = p_id_lote
    ORDER BY iteracion_numero;
  
  e_lote_no_existe      EXCEPTION;
  
BEGIN
  
  -- Obtener información del lote
  BEGIN
    SELECT 
      estado,
      tipo_proceso,
      registros_total,
      NVL(registros_procesados, 0),
      NVL(registros_error, 0),
      NVL(tiempo_proceso, 0)
    INTO 
      v_estado_lote,
      v_tipo_proceso,
      v_total_registros,
      v_procesados,
      v_errores,
      v_tiempo_total
    FROM LOTES_CONTROL
    WHERE id_lote = p_id_lote;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE e_lote_no_existe;
  END;
  
  -- Calcular progreso
  IF v_total_registros > 0 THEN
    v_progreso := ROUND((v_procesados / v_total_registros) * 100, 2);
  ELSE
    v_progreso := 0;
  END IF;
  
  -- Contar iteraciones
  SELECT COUNT(*)
  INTO v_iteraciones_count
  FROM LOTES_LOG_ITERACIONES
  WHERE id_lote = p_id_lote;
  
  -- Calcular tiempo promedio por iteración
  IF v_iteraciones_count > 0 THEN
    SELECT AVG(tiempo_ejecucion)
    INTO v_tiempo_promedio
    FROM LOTES_LOG_ITERACIONES
    WHERE id_lote = p_id_lote;
  ELSE
    v_tiempo_promedio := 0;
  END IF;
  
  -- Generar salida según formato
  CASE p_formato_salida
    
    WHEN 'JSON' THEN
      -- Formato JSON
      v_output := '{' ||
        '"id_lote": ' || p_id_lote || ',' ||
        '"tipo_proceso": "' || v_tipo_proceso || '",' ||
        '"estado": "' || v_estado_lote || '",' ||
        '"registros_total": ' || v_total_registros || ',' ||
        '"registros_procesados": ' || v_procesados || ',' ||
        '"registros_error": ' || v_errores || ',' ||
        '"progreso_porcentaje": ' || v_progreso || ',' ||
        '"tiempo_total_segundos": ' || v_tiempo_total || ',' ||
        '"total_iteraciones": ' || v_iteraciones_count || ',' ||
        '"tiempo_promedio_iteracion": ' || ROUND(v_tiempo_promedio, 2) || ',' ||
        '"iteraciones": [';
      
      -- Agregar cada iteración
      FOR rec IN c_iteraciones LOOP
        IF rec.iteracion_numero > 1 THEN
          v_output := v_output || ',';
        END IF;
        
        v_output := v_output || '{' ||
          '"iteracion": ' || rec.iteracion_numero || ',' ||
          '"procesados": ' || rec.registros_procesados || ',' ||
          '"exitosos": ' || rec.registros_exitosos || ',' ||
          '"errores": ' || rec.registros_error || ',' ||
          '"tiempo_segundos": ' || NVL(rec.tiempo_ejecucion, 0) || ',' ||
          '"fecha_inicio": "' || rec.fecha_inicio_fmt || '",' ||
          '"fecha_fin": "' || rec.fecha_fin_fmt || '",' ||
          '"mensaje": "' || REPLACE(NVL(rec.mensaje, ''), '"', '\"') || '"' ||
          '}';
      END LOOP;
      
      v_output := v_output || ']' || '}';
    
    WHEN 'TEXT' THEN
      -- Formato texto plano
      v_output := '========================================' || CHR(10) ||
                  'MONITOREO DE LOTE: ' || p_id_lote || CHR(10) ||
                  '========================================' || CHR(10) ||
                  'Tipo Proceso: ' || v_tipo_proceso || CHR(10) ||
                  'Estado: ' || v_estado_lote || CHR(10) ||
                  'Progreso: ' || v_progreso || '%' || CHR(10) ||
                  'Total Registros: ' || v_total_registros || CHR(10) ||
                  'Procesados: ' || v_procesados || CHR(10) ||
                  'Errores: ' || v_errores || CHR(10) ||
                  'Tiempo Total: ' || v_tiempo_total || 's' || CHR(10) ||
                  'Total Iteraciones: ' || v_iteraciones_count || CHR(10) ||
                  'Tiempo Promedio/Iteración: ' || ROUND(v_tiempo_promedio, 2) || 's' || CHR(10) ||
                  CHR(10) ||
                  'DETALLE DE ITERACIONES:' || CHR(10) ||
                  '========================================' || CHR(10);
      
      FOR rec IN c_iteraciones LOOP
        v_output := v_output ||
          'Iteración #' || rec.iteracion_numero || CHR(10) ||
          '  Procesados: ' || rec.registros_procesados || CHR(10) ||
          '  Exitosos: ' || rec.registros_exitosos || CHR(10) ||
          '  Errores: ' || rec.registros_error || CHR(10) ||
          '  Tiempo: ' || NVL(rec.tiempo_ejecucion, 0) || 's' || CHR(10) ||
          '  Inicio: ' || rec.fecha_inicio_fmt || CHR(10) ||
          '  Fin: ' || rec.fecha_fin_fmt || CHR(10) ||
          '  Mensaje: ' || NVL(rec.mensaje, 'N/A') || CHR(10) ||
          '----------------------------------------' || CHR(10);
      END LOOP;
    
    WHEN 'HTML' THEN
      -- Formato HTML (básico)
      v_output := '<div class="lote-monitor">' ||
        '<h2>Monitoreo de Lote ' || p_id_lote || '</h2>' ||
        '<table border="1" cellpadding="5">' ||
        '<tr><th>Campo</th><th>Valor</th></tr>' ||
        '<tr><td>Tipo Proceso</td><td>' || v_tipo_proceso || '</td></tr>' ||
        '<tr><td>Estado</td><td>' || v_estado_lote || '</td></tr>' ||
        '<tr><td>Progreso</td><td>' || v_progreso || '%</td></tr>' ||
        '<tr><td>Total Registros</td><td>' || v_total_registros || '</td></tr>' ||
        '<tr><td>Procesados</td><td>' || v_procesados || '</td></tr>' ||
        '<tr><td>Errores</td><td>' || v_errores || '</td></tr>' ||
        '<tr><td>Tiempo Total</td><td>' || v_tiempo_total || 's</td></tr>' ||
        '<tr><td>Total Iteraciones</td><td>' || v_iteraciones_count || '</td></tr>' ||
        '</table>' ||
        '<h3>Detalle de Iteraciones</h3>' ||
        '<table border="1" cellpadding="5">' ||
        '<tr>' ||
        '<th>Iteración</th>' ||
        '<th>Procesados</th>' ||
        '<th>Exitosos</th>' ||
        '<th>Errores</th>' ||
        '<th>Tiempo (s)</th>' ||
        '<th>Fecha Inicio</th>' ||
        '</tr>';
      
      FOR rec IN c_iteraciones LOOP
        v_output := v_output ||
          '<tr>' ||
          '<td>' || rec.iteracion_numero || '</td>' ||
          '<td>' || rec.registros_procesados || '</td>' ||
          '<td>' || rec.registros_exitosos || '</td>' ||
          '<td>' || rec.registros_error || '</td>' ||
          '<td>' || NVL(rec.tiempo_ejecucion, 0) || '</td>' ||
          '<td>' || rec.fecha_inicio_fmt || '</td>' ||
          '</tr>';
      END LOOP;
      
      v_output := v_output || '</table></div>';
    
    ELSE
      -- Formato no válido, usar JSON por defecto
      v_output := '{"error": "Formato no válido. Use: JSON, TEXT o HTML"}';
  END CASE;
  
  RETURN v_output;
  
EXCEPTION
  WHEN e_lote_no_existe THEN
    RETURN '{"error": "El lote ' || p_id_lote || ' no existe"}';
    
  WHEN OTHERS THEN
    RETURN '{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}';
    
END MONITOREA_ITERACIONES_LOTES;
/
