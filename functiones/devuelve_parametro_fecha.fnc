/*******************************************************************************
 * Función: DEVUELVE_PARAMETRO_FECHA
 * 
 * Propósito:
 *   Genera un rango de fechas en formato cadena basado en el tipo de filtro y
 *   el parámetro proporcionado. Soporta búsquedas por año, periodo, o valor manual.
 *
 * @param i_filtro_2        Tipo de filtro ('A'=Año, 'P'=Periodo, 'M'=Manual)
 * @param i_filtro_2_para   Parámetro del filtro (año, mmyyyy, 'DA', 'MA', 'PA', o valor manual)
 * @return VARCHAR2         Cadena con formato 'FI{fecha_inicio};FF{fecha_fin};' o el valor manual
 *
 * Lógica:
 *   1. Si tipo='A': Obtiene primer y último día del año desde calendario_laboral
 *   2. Si tipo='P': 
 *      - Si parámetro es mmyyyy: Obtiene fechas desde webperiodo
 *      - Si 'DA': Ayer
 *      - Si 'MA': Mes anterior desde calendario_laboral
 *      - Si 'PA': Periodo anterior desde webperiodo
 *   3. Si tipo='M': Retorna el parámetro tal cual (modo manual)
 *
 * Dependencias:
 *   - Tabla: calendario_laboral (id_dia, id_ano)
 *   - Tabla: webperiodo (mes, ano, inicio, fin)
 *
 * Consideraciones:
 *   - Conversiones TRUNC innecesarias removidas en comparaciones de fechas
 *   - DECODE reemplazado por CASE para mejor legibilidad
 *   - Queries combinadas para reducir accesos a BD
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para valores especiales
 *   - Combinación de MIN/MAX en una sola consulta
 *   - Simplificación de TRUNC() innecesarios
 *   - CASE en lugar de DECODE anidado
 *   - Inicialización explícita de variables
 *   - Documentación completa
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_PARAMETRO_FECHA
  (i_filtro_2 IN VARCHAR2, i_filtro_2_para IN VARCHAR2) 
RETURN VARCHAR2 IS
    -- Constantes
    C_FILTRO_ANO       CONSTANT VARCHAR2(1) := 'A';
    C_FILTRO_PERIODO   CONSTANT VARCHAR2(1) := 'P';
    C_FILTRO_MANUAL    CONSTANT VARCHAR2(1) := 'M';
    C_DIA_ANTERIOR     CONSTANT VARCHAR2(2) := 'DA';
    C_MES_ANTERIOR     CONSTANT VARCHAR2(2) := 'MA';
    C_PERIODO_ANTERIOR CONSTANT VARCHAR2(2) := 'PA';
    C_PREFIJO_INICIO   CONSTANT VARCHAR2(2) := 'FI';
    C_PREFIJO_FIN      CONSTANT VARCHAR2(2) := 'FF';
    C_SEPARADOR        CONSTANT VARCHAR2(1) := ';';
    C_ERROR_DEFAULT    CONSTANT VARCHAR2(1) := '0';
    
    -- Variables
    v_result        VARCHAR2(122);
    v_fecha_inicio  DATE;
    v_fecha_fin     DATE;
    v_mes_anterior  DATE;
    
BEGIN
    -- Filtro por AÑO: obtener primer y último día del año
    IF i_filtro_2 = C_FILTRO_ANO THEN
        BEGIN
            SELECT MIN(id_dia), MAX(id_dia)
            INTO v_fecha_inicio, v_fecha_fin
            FROM calendario_laboral
            WHERE id_ano = i_filtro_2_para;
            
            v_result := C_PREFIJO_INICIO || TO_CHAR(v_fecha_inicio, 'dd/mm/yyyy') || 
                        C_SEPARADOR || C_PREFIJO_FIN || TO_CHAR(v_fecha_fin, 'dd/mm/yyyy') || C_SEPARADOR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_result := C_ERROR_DEFAULT;
        END;
        
        RETURN v_result;
    END IF;
    
    -- Filtro por PERIODO
    IF i_filtro_2 = C_FILTRO_PERIODO THEN
        -- Caso especial: Día anterior
        IF i_filtro_2_para = C_DIA_ANTERIOR THEN
            v_fecha_inicio := TRUNC(SYSDATE) - 1;
            v_fecha_fin    := TRUNC(SYSDATE) - 1;
            
        -- Caso especial: Mes anterior
        ELSIF i_filtro_2_para = C_MES_ANTERIOR THEN
            v_mes_anterior := ADD_MONTHS(TRUNC(SYSDATE), -1);
            
            BEGIN
                SELECT MIN(id_dia), MAX(id_dia)
                INTO v_fecha_inicio, v_fecha_fin
                FROM calendario_laboral
                WHERE TRUNC(id_dia, 'MM') = TRUNC(v_mes_anterior, 'MM');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RETURN C_ERROR_DEFAULT;
            END;
            
        -- Caso especial: Periodo anterior
        ELSIF i_filtro_2_para = C_PERIODO_ANTERIOR THEN
            BEGIN
                SELECT inicio, fin
                INTO v_fecha_inicio, v_fecha_fin
                FROM webperiodo
                WHERE ano || mes = (
                    SELECT CASE 
                               WHEN TO_NUMBER(mes) - 1 = 0 
                               THEN TO_CHAR(TO_NUMBER(ano) - 1) || '12'
                               ELSE ano || LPAD(TO_NUMBER(mes) - 1, 2, '0')
                           END
                    FROM webperiodo
                    WHERE SYSDATE BETWEEN inicio AND fin
                );
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RETURN C_ERROR_DEFAULT;
            END;
            
        -- Caso normal: Periodo específico (formato mmyyyy)
        ELSE
            BEGIN
                SELECT inicio, fin
                INTO v_fecha_inicio, v_fecha_fin
                FROM webperiodo
                WHERE mes || ano = i_filtro_2_para;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RETURN C_ERROR_DEFAULT;
            END;
        END IF;
        
        v_result := C_PREFIJO_INICIO || TO_CHAR(v_fecha_inicio, 'dd/mm/yyyy') || 
                    C_SEPARADOR || C_PREFIJO_FIN || TO_CHAR(v_fecha_fin, 'dd/mm/yyyy') || C_SEPARADOR;
        RETURN v_result;
    END IF;
    
    -- Filtro MANUAL: retornar el parámetro tal cual
    IF i_filtro_2 = C_FILTRO_MANUAL THEN
        RETURN i_filtro_2_para;
    END IF;
    
    -- Si no coincide ningún filtro, retornar NULL
    RETURN NULL;
    
END DEVUELVE_PARAMETRO_FECHA;
/

