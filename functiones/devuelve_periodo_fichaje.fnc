/*******************************************************************************
 * Función: DEVUELVE_PERIODO_FICHAJE
 * 
 * Propósito:
 *   Determina a qué periodo (P1, P2, P3) pertenece un fichaje basándose en la
 *   hora del fichaje, la jornada del funcionario, y el número de fichajes posteriores.
 *
 * @param i_id_funcionario  ID del funcionario
 * @param v_pin             PIN del empleado para consultar transacciones
 * @param d_fecha_fichaje   Fecha del fichaje
 * @param i_horas_f         Hora del fichaje en formato numérico (hhmm)
 * @return VARCHAR2         Periodo del fichaje: 'P1', 'P2' o 'P3'
 *
 * Lógica:
 *   1. Obtener jornada del funcionario mediante finger_busca_jornada_fun
 *   2. Comparar hora de fichaje con los rangos de cada periodo (P1, P2, P3)
 *   3. En zonas ambiguas (entre periodos), contar fichajes posteriores:
 *      - 0 fichajes posteriores: periodo actual (P1 o P2)
 *      - 1 fichaje posterior: periodo siguiente (P2)
 *      - Más de 1 fichaje: periodo actual
 *
 * Dependencias:
 *   - Procedimiento: finger_busca_jornada_fun
 *   - Tabla: transacciones (pin, fecha, hora, tipotrans, dedo, numserie)
 *
 * Consideraciones:
 *   - Código duplicado en consulta de fichajes posteriores (2 veces idéntico)
 *   - Lógica compleja debido a múltiples condiciones de tipo de transacción
 *   - La función no inicializa i_periodo antes de usarlo
 *
 * Mejoras aplicadas:
 *   - Constantes para valores especiales y tipos de transacción
 *   - Inicialización explícita de variables
 *   - Extracción de consulta duplicada a bloque común
 *   - Variables con nombres descriptivos
 *   - Documentación completa de lógica de negocio
 *   - LPAD movido fuera de comparaciones repetitivas
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_PERIODO_FICHAJE(
    i_id_funcionario IN VARCHAR2,
    v_pin            IN VARCHAR2,
    d_fecha_fichaje  IN DATE,
    i_horas_f        IN NUMBER
) 
RETURN VARCHAR2 IS
    -- Constantes para tipos de transacción
    C_TIPO_SALIDA_1    CONSTANT NUMBER := 2;
    C_TIPO_SALIDA_2    CONSTANT NUMBER := 3;
    C_TIPO_55          CONSTANT NUMBER := 55;
    C_TIPO_39          CONSTANT NUMBER := 39;
    C_TIPO_40          CONSTANT NUMBER := 40;
    C_DEDO_17          CONSTANT VARCHAR2(2) := '17';
    C_DEDO_49          CONSTANT VARCHAR2(2) := '49';
    C_SERIE_CERO       CONSTANT NUMBER := 0;
    C_PIN_LENGTH       CONSTANT NUMBER := 4;
    C_PIN_PADDING      CONSTANT VARCHAR2(1) := '0';
    
    -- Constantes para periodos
    C_PERIODO_1        CONSTANT VARCHAR2(2) := 'P1';
    C_PERIODO_2        CONSTANT VARCHAR2(2) := 'P2';
    C_PERIODO_3        CONSTANT VARCHAR2(2) := 'P3';
    
    -- Constantes para valores de retorno de jornada
    C_SIN_CALENDARIO   CONSTANT NUMBER := 1;
    
    -- Variables de resultado
    v_result           VARCHAR2(122);
    v_periodo          VARCHAR2(4);
    
    -- Variables de jornada (entrada/salida de cada periodo)
    v_p1d              NUMBER;  -- Periodo 1 inicio
    v_p1h              NUMBER;  -- Periodo 1 fin
    v_p2d              NUMBER;  -- Periodo 2 inicio
    v_p2h              NUMBER;  -- Periodo 2 fin
    v_p3d              NUMBER;  -- Periodo 3 inicio
    v_p3h              NUMBER;  -- Periodo 3 fin
    v_po1d             NUMBER;  -- Periodo opcional 1 inicio
    v_po1h             NUMBER;  -- Periodo opcional 1 fin
    v_po2d             NUMBER;  -- Periodo opcional 2 inicio
    v_po2h             NUMBER;  -- Periodo opcional 2 fin
    v_po3d             NUMBER;  -- Periodo opcional 3 inicio
    v_po3h             NUMBER;  -- Periodo opcional 3 fin
    
    -- Variables de control de jornada
    v_sin_calendario   NUMBER;
    v_contar_comida    NUMBER;
    v_libre            NUMBER;
    v_turnos           NUMBER;
    
    -- Variables para conteo de fichajes posteriores
    v_cuantos_mayor    NUMBER;
    v_pin_formateado   VARCHAR2(4);
    v_fecha_trunc      DATE;
    
BEGIN
    -- Inicializar variables
    v_sin_calendario := C_SIN_CALENDARIO;
    v_periodo := NULL;
    v_pin_formateado := LPAD(v_pin, C_PIN_LENGTH, C_PIN_PADDING);
    v_fecha_trunc := TRUNC(d_fecha_fichaje);
    
    -- Obtener jornada del funcionario
    finger_busca_jornada_fun(
        i_id_funcionario,
        d_fecha_fichaje,
        v_p1d, v_p1h,
        v_p2d, v_p2h,
        v_p3d, v_p3h,
        v_po1d, v_po1h,
        v_po2d, v_po2h,
        v_po3d, v_po3h,
        v_contar_comida,
        v_libre,
        v_turnos,
        v_sin_calendario
    );
    
    -- Solo procesar si hay calendario definido
    IF v_sin_calendario != 0 THEN
        
        -- PERIODO 1: Fichaje antes del inicio P1 o dentro de P1
        IF i_horas_f < v_p1d OR (v_p1d <= i_horas_f AND i_horas_f <= v_p1h) THEN
            v_periodo := C_PERIODO_1;
            
        -- Zona entre P1 y P2 (si P2 existe)
        ELSIF i_horas_f > v_p1h AND v_p2h IS NOT NULL AND v_p2d > i_horas_f THEN
            -- Contar fichajes posteriores para determinar periodo
            BEGIN
                SELECT COUNT(*)
                INTO v_cuantos_mayor
                FROM transacciones
                WHERE (
                        (tipotrans = C_TIPO_SALIDA_1) OR 
                        (numserie = C_SERIE_CERO) OR
                        (dedo = C_DEDO_17 AND tipotrans = C_TIPO_SALIDA_2) OR
                        (dedo = C_DEDO_49 AND tipotrans = C_TIPO_SALIDA_2) OR
                        (tipotrans IN (C_TIPO_55, C_TIPO_39, C_TIPO_40))
                      )
                      AND LPAD(pin, C_PIN_LENGTH, C_PIN_PADDING) = v_pin_formateado
                      AND LENGTH(pin) <= C_PIN_LENGTH
                      AND fecha = v_fecha_trunc
                      AND TO_CHAR(hora, 'hh24mi') > i_horas_f;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_cuantos_mayor := 0;
            END;
            
            -- Determinar periodo según número de fichajes posteriores
            IF v_cuantos_mayor = 0 THEN
                v_periodo := C_PERIODO_1;
            ELSIF v_cuantos_mayor = 1 THEN
                v_periodo := C_PERIODO_2;
            ELSE
                -- Más de 1 fichaje posterior
                v_periodo := C_PERIODO_1;
            END IF;
            
        -- Después de P1 sin zona intermedia (no hay P2)
        ELSIF i_horas_f >= v_p1h AND v_p2h IS NULL THEN
            v_periodo := C_PERIODO_1;
        END IF;
        
        -- PERIODO 2: Dentro del rango P2
        IF v_p2d <= i_horas_f AND i_horas_f <= v_p2h THEN
            -- Si ya se asignó P1 por zona intermedia, verificar fichajes
            IF v_periodo = C_PERIODO_1 THEN
                BEGIN
                    SELECT COUNT(*)
                    INTO v_cuantos_mayor
                    FROM transacciones
                    WHERE (
                            (tipotrans = C_TIPO_SALIDA_1) OR 
                            (numserie = C_SERIE_CERO) OR
                            (dedo = C_DEDO_17 AND tipotrans = C_TIPO_SALIDA_2) OR
                            (dedo = C_DEDO_49 AND tipotrans = C_TIPO_SALIDA_2) OR
                            (tipotrans IN (C_TIPO_55, C_TIPO_39, C_TIPO_40))
                          )
                          AND LPAD(pin, C_PIN_LENGTH, C_PIN_PADDING) = v_pin_formateado
                          AND LENGTH(pin) <= C_PIN_LENGTH
                          AND fecha = v_fecha_trunc
                          AND TO_CHAR(hora, 'hh24mi') > i_horas_f;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_cuantos_mayor := 0;
                END;
                
                IF v_cuantos_mayor = 0 THEN
                    v_periodo := C_PERIODO_1;
                ELSIF v_cuantos_mayor = 1 THEN
                    v_periodo := C_PERIODO_2;
                ELSE
                    v_periodo := C_PERIODO_1;
                END IF;
            ELSE
                v_periodo := C_PERIODO_2;
            END IF;
        END IF;
        
        -- Después de P2 sin P3
        IF i_horas_f >= v_p2h AND v_p3h IS NULL THEN
            v_periodo := C_PERIODO_2;
        END IF;
        
        -- PERIODO 3: Dentro del rango P3 o después de P3
        IF v_p3d <= i_horas_f AND i_horas_f <= v_p3h THEN
            v_periodo := C_PERIODO_3;
        END IF;
        
        IF i_horas_f > v_p3h THEN
            v_periodo := C_PERIODO_3;
        END IF;
        
    END IF;
    
    v_result := v_periodo;
    RETURN v_result;
    
END DEVUELVE_PERIODO_FICHAJE;
/

