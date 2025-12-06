/*******************************************************************************
 * Función: DEVUELVE_LUNES_AGUA
 * 
 * Propósito:
 *   Obtiene la fecha del festivo local "Lunes de Aguas" para un año dado.
 *   El Lunes de Aguas es un festivo local de la ciudad de Salamanca que se
 *   celebra el lunes siguiente al lunes de Pascua.
 *
 * @param V_ANO     Año para el cual se busca el festivo (formato: YYYY)
 * @return DATE     Fecha del Lunes de Aguas, o NULL si no existe
 *
 * Lógica:
 *   1. Busca en calendario_laboral la fecha que contiene 'Agua' en observacion
 *   2. Retorna la fecha encontrada
 *   3. Retorna NULL si no existe para ese año
 *
 * Dependencias:
 *   - Tabla: calendario_laboral
 *
 * Mejoras aplicadas:
 *   - Constante nombrada para patrón de búsqueda
 *   - Variable con nombre descriptivo
 *   - Retorno NULL en lugar de cadena vacía
 *   - ROWNUM para limitar búsqueda
 *   - Documentación completa del festivo
 *
 * Nota sobre el festivo:
 *   - El Lunes de Aguas es una fiesta local de Salamanca
 *   - Se celebra el lunes siguiente al domingo de Cuasimodo (octava de Pascua)
 *   - Es festivo móvil que depende del cálculo de la Pascua
 *
 * Ejemplo:
 *   devuelve_lunes_agua('2025') => 28-ABR-2025
 *
 * Historial:
 *   - Original: Implementación básica de consulta
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_LUNES_AGUA(
    V_ANO IN VARCHAR2
) RETURN DATE IS
    -- Constantes
    C_PATRON_AGUA CONSTANT VARCHAR2(10) := '%Agua%';
    
    -- Variables
    v_fecha_festivo DATE;
    
BEGIN
    BEGIN
        -- Buscar fecha del Lunes de Aguas en el calendario laboral
        SELECT id_dia
        INTO v_fecha_festivo
        FROM calendario_laboral
        WHERE id_ano = V_ANO
          AND observacion LIKE C_PATRON_AGUA
          AND ROWNUM = 1;
          
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_fecha_festivo := NULL;
    END;
    
    RETURN v_fecha_festivo;
    
END DEVUELVE_LUNES_AGUA;
/

