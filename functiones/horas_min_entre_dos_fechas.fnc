/*******************************************************************************
 * Función: HORAS_MIN_ENTRE_DOS_FECHAS
 * 
 * Propósito:
 *   Calcula la diferencia de tiempo entre dos fechas (fecha1 - fecha2) y retorna
 *   el resultado en horas o minutos según la opción especificada.
 *   NOTA: Se espera que fecha1 sea mayor que fecha2 (fecha1 es la más reciente).
 *
 * @param fecha1  Fecha/hora mayor (más reciente)
 * @param fecha2  Fecha/hora menor (más antigua)
 * @param opcion  'H' para retornar horas, cualquier otro valor para minutos
 * @return NUMBER Diferencia en horas o minutos según opción
 *
 * Ejemplos de uso:
 *   -- Obtener horas de diferencia
 *   SELECT HORAS_MIN_ENTRE_DOS_FECHAS(
 *     TO_DATE('15/12/2023 14:30', 'DD/MM/YYYY HH24:MI'),
 *     TO_DATE('15/12/2023 10:15', 'DD/MM/YYYY HH24:MI'),
 *     'H'
 *   ) FROM DUAL; --> Retorna 4 horas
 *
 *   -- Obtener minutos de diferencia
 *   SELECT HORAS_MIN_ENTRE_DOS_FECHAS(
 *     TO_DATE('15/12/2023 14:30', 'DD/MM/YYYY HH24:MI'),
 *     TO_DATE('15/12/2023 10:15', 'DD/MM/YYYY HH24:MI'),
 *     'M'
 *   ) FROM DUAL; --> Retorna 15 minutos
 *
 * Lógica:
 *   1. Extrae horas y minutos de ambas fechas
 *   2. Si minutos de fecha2 > minutos de fecha1, ajusta "prestando" una hora
 *   3. Calcula diferencia de horas y minutos
 *   4. Retorna resultado según opción especificada
 *
 * Dependencias:
 *   - Ninguna (función standalone)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa con ejemplos
 *   - Constantes nombradas para opciones de retorno
 *   - Inicialización explícita de todas las variables
 *   - Uso de EXTRACT en lugar de TO_NUMBER(TO_CHAR())
 *   - Comentarios explicativos en la lógica de ajuste
 *   - ELSIF para mejor legibilidad
 *
 * Historial:
 *   - Original: Sin documentación, conversiones ineficientes
 *   - 2025-12: Optimización y documentación completa
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.HORAS_MIN_ENTRE_DOS_FECHAS(
    fecha1  IN DATE,
    fecha2  IN DATE,
    opcion  IN VARCHAR2
) RETURN NUMBER IS
    -- Constantes para tipo de retorno
    C_OPCION_HORAS    CONSTANT VARCHAR2(1) := 'H';
    C_MINUTOS_POR_HORA CONSTANT NUMBER := 60;
    
    -- Variables para almacenar el resultado
    v_resultado_horas   NUMBER := 0;
    v_resultado_minutos NUMBER := 0;
    
    -- Variables para extraer componentes de tiempo
    v_horas_fecha1   NUMBER;
    v_horas_fecha2   NUMBER;
    v_minutos_fecha1 NUMBER;
    v_minutos_fecha2 NUMBER;
    
BEGIN
    -- Extraer horas y minutos de ambas fechas usando EXTRACT
    -- (más eficiente que TO_NUMBER(TO_CHAR()))
    v_horas_fecha1   := EXTRACT(HOUR FROM CAST(fecha1 AS TIMESTAMP));
    v_horas_fecha2   := EXTRACT(HOUR FROM CAST(fecha2 AS TIMESTAMP));
    v_minutos_fecha1 := EXTRACT(MINUTE FROM CAST(fecha1 AS TIMESTAMP));
    v_minutos_fecha2 := EXTRACT(MINUTE FROM CAST(fecha2 AS TIMESTAMP));
    
    -- Calcular diferencia de tiempo
    -- Si los minutos de fecha2 son mayores, necesitamos "pedir prestado" una hora
    IF v_minutos_fecha2 > v_minutos_fecha1 THEN
        -- Ajuste: convertir una hora de fecha1 en minutos
        v_horas_fecha2 := v_horas_fecha2 + 1;
        v_resultado_minutos := C_MINUTOS_POR_HORA - v_minutos_fecha2 + v_minutos_fecha1;
        v_resultado_horas := v_horas_fecha1 - v_horas_fecha2;
    ELSE
        -- Sin ajuste necesario
        v_resultado_minutos := v_minutos_fecha1 - v_minutos_fecha2;
        v_resultado_horas := v_horas_fecha1 - v_horas_fecha2;
    END IF;
    
    -- Retornar según la opción especificada
    IF UPPER(opcion) = C_OPCION_HORAS THEN
        RETURN v_resultado_horas;
    ELSE
        RETURN v_resultado_minutos;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, retornar 0
        RETURN 0;
END HORAS_MIN_ENTRE_DOS_FECHAS;
/

