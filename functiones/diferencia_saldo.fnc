/*******************************************************************************
 * Función: DIFERENCIA_SALDO
 * 
 * Propósito:
 *   Calcula la diferencia de saldo de horas entre dos tablas (temp_persfich_proceso
 *   y persfich) para un funcionario en un periodo específico, considerando el
 *   rango de fechas del último año.
 *
 * @param v_id_funcionario  ID del funcionario
 * @param periodo           Mes del periodo (formato mm)
 * @param id_ano            Año del periodo (formato yyyy)
 * @return VARCHAR2         Diferencia de saldo en minutos (puede ser negativo)
 *
 * Lógica:
 *   1. Suma horas computables de temp_persfich_proceso (tabla temporal)
 *   2. Resta horas computables de persfich (tabla permanente)
 *   3. Filtra por funcionario, periodo y fechas del último año
 *   4. Retorna diferencia en minutos
 *
 * Dependencias:
 *   - Tabla: temp_persfich_proceso (npersonal, fecha, hcomputablef)
 *   - Tabla: persfich (npersonal, fecha, hcomputablef)
 *   - Tabla: webperiodo (ano, mes, inicio, fin)
 *
 * Consideraciones:
 *   - Valores por defecto: 50000 y 40000 cuando no hay datos
 *   - TO_DATE innecesario sobre SYSDATE que ya es DATE
 *   - Rango de fechas hardcodeado (365 días)
 *   - NVL con valores muy altos podría ocultar errores de datos
 *
 * Mejoras aplicadas:
 *   - Constantes para valores por defecto y días
 *   - Eliminación de TO_DATE innecesario sobre SYSDATE
 *   - TRUNC para comparaciones de fechas
 *   - Variables con nombres descriptivos
 *   - Documentación completa
 *   - Simplificación de lógica de suma/resta
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DIFERENCIA_SALDO(
    v_id_funcionario IN VARCHAR2,
    periodo          IN VARCHAR2,
    id_ano           IN VARCHAR2
) 
RETURN VARCHAR2 IS
    -- Constantes
    C_DIAS_RANGO          CONSTANT NUMBER := 365;
    C_DEFAULT_TEMP        CONSTANT NUMBER := 50000;
    C_DEFAULT_PERSFICH    CONSTANT NUMBER := 40000;
    C_ERROR_NO_DATA       CONSTANT NUMBER := -500000;
    C_MINUTOS_POR_HORA    CONSTANT NUMBER := 60;
    
    -- Variables
    v_result              NUMBER;
    v_diferencia_saldo    NUMBER;
    v_fecha_desde         DATE;
    v_fecha_hasta         DATE;
    
BEGIN
    -- Calcular rango de fechas (último año hasta ayer)
    v_fecha_desde := TRUNC(SYSDATE) - C_DIAS_RANGO;
    v_fecha_hasta := TRUNC(SYSDATE) - 1;
    
    BEGIN
        SELECT SUM(campo9)
        INTO v_diferencia_saldo
        FROM (
            -- Suma de horas de tabla temporal
            SELECT NVL(SUM(TO_CHAR(b.hcomputablef, 'hh24') * C_MINUTOS_POR_HORA + 
                           TO_CHAR(b.hcomputablef, 'mi')), C_DEFAULT_TEMP) AS campo9
            FROM temp_persfich_proceso b
            INNER JOIN webperiodo c ON b.fecha BETWEEN c.inicio AND c.fin
            WHERE b.npersonal = v_id_funcionario
              AND b.fecha BETWEEN v_fecha_desde AND v_fecha_hasta
              AND c.ano = id_ano
              AND c.mes = periodo
            
            UNION
            
            -- Resta de horas de tabla permanente (multiplicado por -1)
            SELECT (NVL(SUM(TO_CHAR(b.hcomputablef, 'hh24') * C_MINUTOS_POR_HORA + 
                            TO_CHAR(b.hcomputablef, 'mi')), C_DEFAULT_PERSFICH)) * -1 AS campo9
            FROM persfich b
            INNER JOIN webperiodo c ON b.fecha BETWEEN c.inicio AND c.fin
            WHERE b.npersonal = v_id_funcionario
              AND b.fecha BETWEEN v_fecha_desde AND v_fecha_hasta
              AND c.ano = id_ano
              AND c.mes = periodo
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_diferencia_saldo := C_ERROR_NO_DATA;
    END;
    
    v_result := v_diferencia_saldo;
    RETURN v_result;
    
END DIFERENCIA_SALDO;
/

