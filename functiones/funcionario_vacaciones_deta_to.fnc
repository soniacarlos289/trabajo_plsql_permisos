/*******************************************************************************
 * Función: FUNCIONARIO_VACACIONES_DETA_TO
 * 
 * Propósito:
 *   Cuenta el número total de funcionarios distintos en una unidad organizativa
 *   específica. Esta función es complementaria a FUNCIONARIO_VACACIONES_DETA_NU
 *   para calcular el total de funcionarios de la unidad.
 *
 * @param V_FECHA_INICIO  Fecha (parámetro no utilizado, mantenido por compatibilidad)
 * @param V_ID_UNIDAD     ID de la unidad organizativa (se busca con LIKE para incluir subunidades)
 * 
 * @return VARCHAR2  Número total de funcionarios en formato texto
 *
 * Lógica:
 *   1. Construye patrón de búsqueda de unidad con comodín (%)
 *   2. Cuenta todos los funcionarios distintos de la unidad
 *   3. Retorna el conteo en formato texto
 *
 * Dependencias:
 *   - Tabla: personal_rpt (id_funcionario, id_unidad)
 *
 * Consideraciones:
 *   - Uso de LIKE permite buscar unidades jerárquicas
 *   - El parámetro V_FECHA_INICIO no se utiliza actualmente
 *   - Retorna número en formato texto para compatibilidad
 *   - Función complementaria para calcular porcentajes de vacaciones
 *
 * Mejoras aplicadas:
 *   - Eliminación de variables no utilizadas (i_error, i_personas_vacaciones, i_Desc_unidad, etc.)
 *   - Constantes nombradas para valores por defecto
 *   - Variables inicializadas explícitamente
 *   - Documentación completa JavaDoc
 *   - Eliminación de código comentado
 *   - Variables con nombres descriptivos
 *   - Nota sobre parámetro no utilizado
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.FUNCIONARIO_VACACIONES_DETA_TO(
    V_FECHA_INICIO IN DATE,
    V_ID_UNIDAD IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_NO_FUNCIONARIOS CONSTANT NUMBER := 0;
    C_WILDCARD CONSTANT VARCHAR2(1) := '%';
    
    -- Variables
    v_patron_unidad VARCHAR2(25);
    v_total_funcionarios NUMBER := C_NO_FUNCIONARIOS;
    
BEGIN
    -- Construir patrón de búsqueda con comodín
    v_patron_unidad := V_ID_UNIDAD || C_WILDCARD;
    
    -- Contar total de funcionarios en la unidad
    BEGIN
        SELECT COUNT(DISTINCT id_funcionario)
        INTO v_total_funcionarios
        FROM personal_rpt
        WHERE id_unidad LIKE v_patron_unidad;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_total_funcionarios := C_NO_FUNCIONARIOS;
    END;
    
    RETURN TO_CHAR(v_total_funcionarios);
    
END FUNCIONARIO_VACACIONES_DETA_TO;
/

