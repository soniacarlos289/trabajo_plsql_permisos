/*******************************************************************************
 * Función: DEVUELVE_PERIODO
 * 
 * Propósito:
 *   Obtiene el periodo (mes+año) en formato mmyyyy para una fecha dada o actual.
 *   Si la entrada es formato mmyyyy y no es '000000', se retorna tal cual.
 *
 * @param v_cadena  Fecha en formato 'dd/mm/yyyy', periodo 'mmyyyy', o '000000' para actual
 * @return VARCHAR2 Periodo en formato 'mmyyyy' (ejemplo: '012025' para enero 2025)
 *
 * Lógica:
 *   1. Si longitud=6: usar SYSDATE (excepto si es '000000')
 *   2. Si longitud!=6: convertir cadena a fecha
 *   3. Buscar periodo en webperiodo que contenga la fecha
 *   4. Si no se encuentra: buscar periodo actual
 *   5. Si entrada es periodo válido (6 caracteres y != '000000'): retornar entrada
 *
 * Dependencias:
 *   - Tabla: webperiodo (mes, ano, inicio, fin)
 *
 * Consideraciones:
 *   - Valor por defecto '012019' usado como indicador de "no encontrado"
 *   - Conversión TO_DATE(TO_CHAR(...)) eliminada con TRUNC
 *   - Si el periodo ya viene formateado, se retorna sin consultar BD
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para valores especiales
 *   - TRUNC() en lugar de TO_DATE(TO_CHAR())
 *   - Eliminación de conversiones redundantes
 *   - Documentación completa
 *   - Variables con nombres descriptivos
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_PERIODO
  (v_cadena IN VARCHAR2) 
RETURN VARCHAR2 IS
    -- Constantes
    C_LONGITUD_PERIODO   CONSTANT NUMBER := 6;
    C_PERIODO_CERO       CONSTANT VARCHAR2(6) := '000000';
    C_PERIODO_DEFAULT    CONSTANT VARCHAR2(6) := '012019';
    
    -- Variables
    v_result       VARCHAR2(122);
    v_mes_ano      VARCHAR2(15);
    v_fecha        DATE;

BEGIN
    -- Determinar la fecha a usar
    IF LENGTH(v_cadena) = C_LONGITUD_PERIODO THEN
        v_fecha := TRUNC(SYSDATE);
    ELSE
        v_fecha := TO_DATE(v_cadena, 'dd/mm/yyyy');
    END IF;
    
    -- Buscar el periodo que contiene la fecha
    BEGIN
        SELECT mes || ano
        INTO v_mes_ano
        FROM webperiodo
        WHERE TRUNC(v_fecha) BETWEEN inicio AND fin;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_mes_ano := C_PERIODO_DEFAULT;
    END;
    
    -- Si no se encontró el periodo, buscar el periodo actual
    IF v_mes_ano = C_PERIODO_DEFAULT THEN
        SELECT mes || ano
        INTO v_mes_ano
        FROM webperiodo
        WHERE TRUNC(SYSDATE) BETWEEN inicio AND fin;
    END IF;
    
    v_result := v_mes_ano;
    
    -- Si la entrada es un periodo válido (6 chars y no '000000'), retornarlo
    IF v_cadena != C_PERIODO_CERO AND LENGTH(v_cadena) = C_LONGITUD_PERIODO THEN
        v_result := v_cadena;
    END IF;
    
    RETURN v_result;
    
END DEVUELVE_PERIODO;
/

