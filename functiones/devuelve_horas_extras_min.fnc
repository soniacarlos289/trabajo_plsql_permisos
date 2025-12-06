/*******************************************************************************
 * Función: DEVUELVE_HORAS_EXTRAS_MIN
 * 
 * Propósito:
 *   Calcula el total de minutos trabajados entre dos horas, aplicando un
 *   factor multiplicador según el tipo de hora extra.
 *
 * @param V_HORA_INICIO     Hora de inicio en formato 'HH24:MI'
 * @param V_HORA_FIN        Hora de fin en formato 'HH24:MI'
 * @param v_id_tipo_horas   ID del tipo de hora (normal, extra, festivo, etc.)
 * @return VARCHAR2         Total de minutos con factor aplicado
 *
 * Lógica:
 *   1. Extrae horas y minutos de las cadenas de entrada
 *   2. Calcula la diferencia de tiempo
 *   3. Obtiene el factor multiplicador de la tabla TR_TIPO_HORA
 *   4. Aplica el factor a los minutos totales
 *   5. Retorna el resultado en minutos
 *
 * Dependencias:
 *   - Tabla: TR_TIPO_HORA
 *
 * Mejoras aplicadas:
 *   - Constantes para posiciones y longitudes de subcadenas
 *   - Constante para minutos por hora
 *   - Inicialización explícita de variables
 *   - Documentación completa del cálculo
 *   - Manejo explícito de hora fin menor que hora inicio
 *
 * Ejemplo:
 *   devuelve_horas_extras_min('08:30', '10:45', 1)
 *   Con factor=1.5: (2h 15min) * 1.5 = 135 min * 1.5 = 202.5 min
 *
 * Nota: Esta función NO maneja el caso de que la hora de fin sea del día
 *       siguiente. Asume que ambas horas son del mismo día.
 *
 * Historial:
 *   - Original: Implementación básica de cálculo
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_HORAS_EXTRAS_MIN(
    V_HORA_INICIO    IN VARCHAR2,
    V_HORA_FIN       IN VARCHAR2,
    v_id_tipo_horas  IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes
    C_POS_HORA      CONSTANT NUMBER := 1;
    C_LEN_HORA      CONSTANT NUMBER := 2;
    C_POS_MINUTO    CONSTANT NUMBER := 4;
    C_LEN_MINUTO    CONSTANT NUMBER := 2;
    C_MINUTOS_HORA  CONSTANT NUMBER := 60;
    C_FACTOR_DEFAULT CONSTANT NUMBER := 1;
    
    -- Variables
    v_hora_inicio       NUMBER;
    v_hora_fin          NUMBER;
    v_minuto_inicio     NUMBER;
    v_minuto_fin        NUMBER;
    v_factor            NUMBER;
    v_minutos_diferencia NUMBER;
    v_horas_diferencia  NUMBER;
    v_minutos_totales   NUMBER;
    
BEGIN
    -- Extraer horas y minutos de las cadenas
    v_hora_inicio   := TO_NUMBER(SUBSTR(V_HORA_INICIO, C_POS_HORA, C_LEN_HORA));
    v_hora_fin      := TO_NUMBER(SUBSTR(V_HORA_FIN, C_POS_HORA, C_LEN_HORA));
    v_minuto_inicio := TO_NUMBER(SUBSTR(V_HORA_INICIO, C_POS_MINUTO, C_LEN_MINUTO));
    v_minuto_fin    := TO_NUMBER(SUBSTR(V_HORA_FIN, C_POS_MINUTO, C_LEN_MINUTO));
    
    -- Calcular diferencia de tiempo
    -- Si minuto_fin < minuto_inicio, pedir prestada una hora
    IF v_minuto_inicio > v_minuto_fin THEN
        v_minutos_diferencia := (v_minuto_fin + C_MINUTOS_HORA) - v_minuto_inicio;
        v_horas_diferencia   := v_hora_fin - v_hora_inicio - 1;
    ELSE
        v_minutos_diferencia := v_minuto_fin - v_minuto_inicio;
        v_horas_diferencia   := v_hora_fin - v_hora_inicio;
    END IF;
    
    -- Obtener factor multiplicador del tipo de hora
    BEGIN
        SELECT factor
        INTO v_factor
        FROM TR_TIPO_HORA
        WHERE id_tipo_horas = v_id_tipo_horas;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_factor := C_FACTOR_DEFAULT;
    END;
    
    -- Calcular total de minutos con factor aplicado
    v_minutos_totales := (v_horas_diferencia * C_MINUTOS_HORA + v_minutos_diferencia) * v_factor;
    
    RETURN TO_CHAR(v_minutos_totales);
    
END DEVUELVE_HORAS_EXTRAS_MIN;
/

