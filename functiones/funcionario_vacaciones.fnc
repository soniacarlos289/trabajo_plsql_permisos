/*******************************************************************************
 * Función: FUNCIONARIO_VACACIONES
 * 
 * Propósito:
 *   Retorna información sobre funcionarios de vacaciones en una unidad organizativa
 *   específica durante un rango de fechas. Devuelve una cadena formateada con el
 *   nombre de la unidad y estadísticas de funcionarios de vacaciones.
 *
 * @param V_FECHA_INICIO    Fecha de inicio del período a verificar
 * @param V_FECHA_FIN       Fecha de fin del período a verificar
 * @param V_ID_FUNCIONARIO  ID del funcionario para determinar su unidad
 * 
 * @return VARCHAR2  Cadena con formato "Nombre Unidad (X de un total de Y Func.)"
 *
 * Lógica:
 *   1. Obtiene la unidad del funcionario y su descripción
 *   2. Cuenta el total de funcionarios en la unidad
 *   3. Cuenta funcionarios de vacaciones (permisos estado 80) en el rango de fechas
 *   4. Formatea resultado con nombre de unidad y estadísticas
 *
 * Dependencias:
 *   - Tabla: rpt (id_unidad)
 *   - Tabla: personal_rpt (id_funcionario, id_unidad)
 *   - Tabla: unidad (id_unidad, desc_unidad, f_num_plazas, l_num_plazas)
 *   - Tabla: permiso (id_funcionario, fecha_inicio, fecha_fin, anulado, id_estado)
 *
 * Consideraciones:
 *   - Estado 80 representa permisos de vacaciones
 *   - Solo cuenta permisos no anulados (ANULADO='NO' o NULL)
 *   - Verifica solapamiento en ambos extremos del período
 *   - Solo considera unidades con plazas activas (F_NUM_PLAZAS > 0 OR L_NUM_PLAZAS > 0)
 *
 * Mejoras aplicadas:
 *   - Eliminación de variable no utilizada (i_error)
 *   - Constantes nombradas para estado de permiso y valores por defecto
 *   - INNER JOIN explícito en lugar de comas en FROM
 *   - Inicialización explícita de todas las variables
 *   - Documentación completa JavaDoc
 *   - Variables con nombres descriptivos
 *   - Estructura más legible con consultas optimizadas
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.FUNCIONARIO_VACACIONES(
    V_FECHA_INICIO IN DATE,
    V_FECHA_FIN IN DATE,
    V_ID_FUNCIONARIO IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_ESTADO_VACACIONES CONSTANT NUMBER := 80;
    C_CONTADOR_INICIAL CONSTANT NUMBER := 0;
    C_DESC_SIN_UNIDAD CONSTANT VARCHAR2(20) := 'Sin Unidad';
    
    -- Variables
    v_id_unidad VARCHAR2(25);
    v_desc_unidad VARCHAR2(256) := C_DESC_SIN_UNIDAD;
    v_total_funcionarios NUMBER := C_CONTADOR_INICIAL;
    v_funcionarios_vacaciones NUMBER := C_CONTADOR_INICIAL;
    v_resultado VARCHAR2(256);
    
BEGIN
    -- Obtener unidad del funcionario
    BEGIN
        SELECT DISTINCT r.id_unidad, INITCAP(u.desc_unidad)
        INTO v_id_unidad, v_desc_unidad
        FROM rpt r
        INNER JOIN personal_rpt pr ON r.id_unidad = pr.id_unidad
        INNER JOIN unidad u ON pr.id_unidad = u.id_Unidad
        WHERE pr.id_funcionario = V_ID_FUNCIONARIO
            AND (u.F_NUM_PLAZAS > 0 OR u.L_NUM_PLAZAS > 0);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_desc_unidad := C_DESC_SIN_UNIDAD;
            v_id_unidad := NULL;
    END;
    
    -- Si se encontró unidad, obtener estadísticas
    IF v_id_unidad IS NOT NULL THEN
        -- Contar total de funcionarios en la unidad
        BEGIN
            SELECT COUNT(DISTINCT id_funcionario)
            INTO v_total_funcionarios
            FROM personal_rpt
            WHERE id_unidad = v_id_unidad;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_total_funcionarios := C_CONTADOR_INICIAL;
        END;
        
        -- Contar funcionarios de vacaciones en el período
        BEGIN
            SELECT COUNT(DISTINCT p.id_funcionario)
            INTO v_funcionarios_vacaciones
            FROM permiso p
            INNER JOIN personal_rpt pr ON p.id_funcionario = pr.id_funcionario
            WHERE pr.id_unidad = v_id_unidad
                AND (p.ANULADO = 'NO' OR p.ANULADO IS NULL)
                AND p.id_estado = C_ESTADO_VACACIONES
                AND (
                    (p.fecha_inicio BETWEEN V_FECHA_INICIO AND V_FECHA_FIN) OR
                    (p.fecha_fin BETWEEN V_FECHA_INICIO AND V_FECHA_FIN)
                );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_funcionarios_vacaciones := C_CONTADOR_INICIAL;
        END;
    END IF;
    
    -- Formatear resultado
    v_resultado := v_desc_unidad || 
                   '  (' || v_funcionarios_vacaciones || 
                   ' de un total de ' || v_total_funcionarios || ' Func.)';
    
    RETURN v_resultado;
    
END FUNCIONARIO_VACACIONES;
/

