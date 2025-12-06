/*******************************************************************************
 * Función: wbs_devuelve_saldo_horario
 * 
 * Propósito:
 *   Devuelve información del saldo horario de un funcionario, incluyendo
 *   fichajes del día actual, fichajes históricos y permisos del período.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @param opcion           VARCHAR2  Tipo de consulta (r=resumen, d=detallado)
 * @param anio             VARCHAR2  Año a consultar
 * @param v_mes            VARCHAR2  Mes a consultar
 * @return VARCHAR2                  JSON con saldo y fichajes
 *
 * Opciones:
 *   - 'r': Resumen del saldo horario + fichajes del día actual
 *   - 'd': Detallado con períodos, fichajes del día, fichajes período y permisos
 *
 * Lógica:
 *   1. Calcula saldo horario del mes/año especificado
 *   2. Obtiene fichajes del día actual desde tabla fichaje_diarios
 *   3. Si opción 'd':
 *      - Lista períodos disponibles para consulta
 *      - Muestra fichajes del período con jornada vs horas fichadas
 *      - Lista permisos activos en el período
 *   4. Utiliza función devuelve_periodo para obtener período actual
 *
 * Dependencias:
 *   - Tabla: fichaje_funcionario_resu_dia (resumen diario)
 *   - Tabla: webperiodo (períodos mensuales)
 *   - Tabla: fichaje_diarios (fichajes del día actual)
 *   - Tabla: resumen_saldo (detalle de fichajes)
 *   - Tabla: calendario_laboral (días laborables)
 *   - Tabla: calendario_fichaje (permisos registrados)
 *   - Función: devuelve_periodo (obtiene período MMAAAA)
 *   - Función: devuelve_min_fto_hora (formato horas y minutos)
 *
 * Mejoras aplicadas:
 *   - Conversión 3 cursores manuales → FOR LOOP
 *   - Constantes nombradas para mensajes
 *   - CASE en lugar de DECODE para mes
 *   - Eliminación de TO_DATE(TO_CHAR()) redundante
 *   - TRUNC para comparaciones de fechas
 *   - Inicialización explícita de variables
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   - El cursor comentado C_fichajes_dia antiguo usa tabla transacciones
 *   - Versión actual usa tabla fichaje_diarios (más simple)
 *   - Formato período: MMAAAA (ej: 122025 = diciembre 2025)
 *
 * Historial:
 *   - 24/04/2025: Cambio de transacciones → fichaje_diarios
 *   - 06/12/2025: Optimización Grupo 10 - Cursores a FOR LOOP, CASE
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_saldo_horario(
    i_id_funcionario IN VARCHAR2,
    opcion           IN VARCHAR2,
    anio             IN VARCHAR2,
    v_mes            IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_MSG_SALDO_CERO      CONSTANT VARCHAR2(30) := '{"saldo_horario":"0 horas "}';
    C_LONGITUD_PERIODO_5  CONSTANT NUMBER := 5;
    C_LONGITUD_PERIODO_6  CONSTANT NUMBER := 6;
    
    -- Variables
    v_resultado           VARCHAR2(12000);
    v_saldo_horario_r     VARCHAR2(1232);
    v_saldo_horario_d     VARCHAR2(1232);
    v_datos               VARCHAR2(12000);
    v_contador            NUMBER := 0;
    v_datos_periodos      VARCHAR2(12000);
    v_contador_periodos   NUMBER := 0;
    v_id_periodo          VARCHAR2(12000);
    v_id_mes              VARCHAR2(12000);
    v_id_anio             VARCHAR2(12000);
    
BEGIN
    v_saldo_horario_r := '';
    v_saldo_horario_d := '';
    v_datos := '';
    v_datos_periodos := '';
    
    -- Calcula saldo horario del mes/año
    BEGIN
        SELECT
            REPLACE(REPLACE(JSON_OBJECT('saldo_horario' IS devuelve_min_fto_hora(NVL(SUM(horas_saldo - horas_hacer), 0))), '{', ''), '}', ''),
            REPLACE(REPLACE(JSON_OBJECT('saldo_horario' IS devuelve_min_fto_hora(NVL(SUM(horas_saldo - horas_hacer), 0))), '{', ''), '}', '')
        INTO v_saldo_horario_r, v_saldo_horario_d
        FROM fichaje_funcionario_resu_dia t
        INNER JOIN webperiodo ow ON LPAD(v_mes, 2, '0') || anio = ow.mes || ow.ano
        WHERE t.id_funcionario = i_id_funcionario
          AND t.id_dia BETWEEN ow.inicio AND ow.fin
          AND TRUNC(t.id_dia) < TRUNC(SYSDATE);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_saldo_horario_r := C_MSG_SALDO_CERO;
        WHEN OTHERS THEN
            v_saldo_horario_r := C_MSG_SALDO_CERO;
    END;
    
    -- Obtiene fichajes del día actual
    FOR rec IN (
        SELECT DISTINCT
            JSON_OBJECT('hora' IS hora) AS datos_json,
            TO_DATE('31/12/1899' || hora, 'DD/MM/YYYY HH24:MI') AS hora_orden
        FROM fichaje_diarios
        WHERE id_funcionario = i_id_funcionario
        ORDER BY hora_orden
    ) LOOP
        v_contador := v_contador + 1;
        
        IF v_contador = 1 THEN
            v_datos := rec.datos_json;
        ELSE
            v_datos := v_datos || ',' || rec.datos_json;
        END IF;
    END LOOP;
    
    -- Procesa según opción
    CASE opcion
        -- Opción 'r': Resumen
        WHEN 'r' THEN
            v_resultado := v_saldo_horario_r || ',' || '"fichajes": [' || v_datos || ']';
        
        -- Opción 'd': Detallado
        WHEN 'd' THEN
            -- Lista períodos disponibles
            FOR rec_periodo IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id' IS ano || mes,
                        'anio' IS ano,
                        'mes' IS mes,
                        'Desde' IS TO_CHAR(inicio, 'DD/MM/YYYY'),
                        'Hasta' IS TO_CHAR(fin, 'DD/MM/YYYY'),
                        'opcion_menu' IS RPAD(
                            CASE mes
                                WHEN 1 THEN 'ENERO'
                                WHEN 2 THEN 'FEBRERO'
                                WHEN 3 THEN 'MARZO'
                                WHEN 4 THEN 'ABRIL'
                                WHEN 5 THEN 'MAYO'
                                WHEN 6 THEN 'JUNIO'
                                WHEN 7 THEN 'JULIO'
                                WHEN 8 THEN 'AGOSTO'
                                WHEN 9 THEN 'SEPTIEMBRE'
                                WHEN 10 THEN 'OCTUBRE'
                                WHEN 11 THEN 'NOVIEMBRE'
                                WHEN 12 THEN 'DICIEMBRE'
                            END, 13, ' ') || ' Desde:' || TO_CHAR(inicio, 'DD-MON-YYYY') || ' a ' || TO_CHAR(fin, 'DD-MON-YYYY')
                    ) AS datos_json,
                    ano || mes AS periodo
                FROM webperiodo
                WHERE ano = anio
                ORDER BY mes
            ) LOOP
                v_contador_periodos := v_contador_periodos + 1;
                
                IF v_contador_periodos = 1 THEN
                    v_datos_periodos := '{"periodos_consulta":[' || rec_periodo.datos_json;
                ELSE
                    v_datos_periodos := v_datos_periodos || ',' || rec_periodo.datos_json;
                END IF;
            END LOOP;
            
            v_datos_periodos := v_datos_periodos || '],';
            v_datos_periodos := v_datos_periodos || '"periodo_seleccionado":[ {"anio":' || anio || ',"mes":"' || v_mes || '"}],';
            
            -- Obtiene período actual
            v_id_periodo := devuelve_periodo(TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
            
            IF LENGTH(v_id_periodo) = C_LONGITUD_PERIODO_5 THEN
                v_id_mes := SUBSTR(v_id_periodo, 1, 1);
                v_id_anio := SUBSTR(v_id_periodo, 2, 4);
                v_datos_periodos := v_datos_periodos || '"periodo_actual":[ {"anio":' || v_id_anio || ',"mes":"' || v_id_mes || '"}],';
            ELSIF LENGTH(v_id_periodo) = C_LONGITUD_PERIODO_6 THEN
                v_id_mes := SUBSTR(v_id_periodo, 1, 2);
                v_id_anio := SUBSTR(v_id_periodo, 3, 4);
                v_datos_periodos := v_datos_periodos || '"periodo_actual":[ {"anio":' || v_id_anio || ',"mes":"' || v_id_mes || '"}],';
            END IF;
            
            v_resultado := v_datos_periodos || v_saldo_horario_d || ',' || '"fichajes": [' || v_datos || ']';
            
            -- Obtiene fichajes del período
            v_datos := '';
            v_contador := 0;
            
            FOR rec_fichajes IN (
                SELECT DISTINCT
                    TO_CHAR(r.fecha_fichaje_entrada, 'HH24:MI') AS entrada,
                    JSON_OBJECT(
                        'fecha' IS TO_CHAR(r.id_dia, 'DD/MM/YYYY'),
                        'entrada' IS TO_CHAR(r.fecha_fichaje_entrada, 'HH24:MI'),
                        'salida' IS TO_CHAR(r.fecha_fichaje_salida, 'HH24:MI'),
                        'saldo_dia' IS 'Jornada: ' || 
                            CASE 
                                WHEN TRUNC(r.hh) = 0 THEN '                                  '
                                ELSE devuelve_min_fto_hora(r.hh)
                            END || 
                            '--Fichadas: ' || devuelve_min_fto_hora(r.hr)
                    ) AS datos_json,
                    r.id_dia
                FROM resumen_saldo r
                INNER JOIN personal_new p ON r.id_funcionario = p.id_funcionario
                WHERE p.id_funcionario = i_id_funcionario
                  AND r.periodo = LPAD(v_mes, 2, '0') || anio
                  AND TRUNC(r.id_dia) < TRUNC(SYSDATE)
                  AND r.hr > 0
                ORDER BY r.id_dia, entrada
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec_fichajes.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec_fichajes.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := v_resultado || ',' || '"fichajes_periodo": [' || v_datos || ']';
            
            -- Obtiene permisos del período
            v_contador := 0;
            v_datos := '';
            
            FOR rec_permisos IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_tipo_permiso' IS tr.id_tipo_permiso,
                        'permiso' IS tr.desc_tipo_permiso,
                        'fecha' IS TO_CHAR(ca.id_dia, 'DD/MM/YYYY'),
                        'estado' IS tp.desc_estado_permiso,
                        'id_estado_permiso' IS tp.id_estado_permiso
                    ) AS datos_json,
                    ca.id_dia
                FROM calendario_laboral ca
                INNER JOIN webperiodo w ON w.mes || w.ano = LPAD(v_mes, 2, '0') || anio
                INNER JOIN calendario_fichaje cf ON ca.id_dia BETWEEN cf.fecha_inicio AND NVL(cf.fecha_fin, SYSDATE)
                INNER JOIN tr_tipo_permiso tr ON tr.id_tipo_permiso = cf.id_tipo_permiso
                                              AND tr.id_ano = w.ano
                INNER JOIN tr_estado_permiso tp ON tp.id_estado_permiso = cf.id_tipo_estado
                WHERE cf.id_funcionario = i_id_funcionario
                  AND ca.id_dia BETWEEN w.inicio AND w.fin
                ORDER BY ca.id_dia ASC
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec_permisos.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec_permisos.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := v_resultado || ',' || '"permisos_en_periodo": [' || v_datos || ']}';
    END CASE;
    
    RETURN v_resultado;
    
END wbs_devuelve_saldo_horario;
/

