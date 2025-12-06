/*******************************************************************************
 * Función: FINGER_JORNADA_SOLAPA
 * 
 * Propósito:
 *   Verifica si existe solapamiento de jornadas para un funcionario específico
 *   en el rango de fechas proporcionado. Retorna el número de funcionarios
 *   distintos con jornadas solapadas (0 o 1).
 *
 * @param V_FECHA_INICIO  Fecha de inicio del período a verificar
 * @param V_FECHA_FIN     Fecha de fin del período (puede ser NULL, usa fecha actual)
 * @param V_ID_FUNCIONARIO ID del funcionario a verificar
 * 
 * @return NUMBER  1 si hay solapamiento, 0 si no hay solapamiento
 *
 * Lógica:
 *   1. Busca jornadas existentes del funcionario
 *   2. Verifica si las fechas del nuevo período se solapan con jornadas existentes
 *   3. Considera dos casos de solapamiento:
 *      - La fecha de inicio está dentro de una jornada existente
 *      - La fecha de fin está dentro de una jornada existente
 *   4. Si fecha_fin es NULL, usa la fecha actual truncada
 *
 * Dependencias:
 *   - Tabla: fichaje_funcionario_jornada (id_funcionario, fecha_inicio, fecha_fin)
 *
 * Mejoras aplicadas:
 *   - Eliminación de conversión redundante TO_DATE(TO_CHAR(SYSDATE))
 *   - Uso de TRUNC(SYSDATE) para obtener fecha sin hora
 *   - Constantes nombradas para valores por defecto
 *   - Variables inicializadas explícitamente
 *   - Documentación completa JavaDoc
 *   - Variables con nombres descriptivos
 *   - Eliminación de bloque BEGIN/END innecesario
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.FINGER_JORNADA_SOLAPA(
    V_FECHA_INICIO IN DATE,
    V_FECHA_FIN IN DATE,
    V_ID_FUNCIONARIO IN VARCHAR2
) RETURN NUMBER IS
    -- Constantes
    C_NO_SOLAPAMIENTO CONSTANT NUMBER := 0;
    
    -- Variables
    v_contador NUMBER := 0;
    v_fecha_fin_efectiva DATE;
    
BEGIN
    -- Calcular fecha fin efectiva (si es NULL, usar fecha actual sin hora)
    v_fecha_fin_efectiva := NVL(V_FECHA_FIN, TRUNC(SYSDATE));
    
    -- Verificar si existe solapamiento de jornadas
    BEGIN
        SELECT COUNT(DISTINCT id_funcionario)
        INTO v_contador
        FROM fichaje_funcionario_jornada
        WHERE id_funcionario = V_ID_FUNCIONARIO
            AND (
                (V_FECHA_INICIO BETWEEN FECHA_INICIO AND FECHA_FIN) OR
                (v_fecha_fin_efectiva BETWEEN FECHA_INICIO AND FECHA_FIN)
            );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_contador := C_NO_SOLAPAMIENTO;
    END;
    
    RETURN v_contador;
    
END FINGER_JORNADA_SOLAPA;
/

