/*******************************************************************************
 * Función: FUNCIONARIO_VACACIONES_DETA_NU
 * 
 * Propósito:
 *   Cuenta el número de funcionarios distintos de una unidad específica que
 *   tienen permisos de vacaciones (estado 80) en una fecha determinada.
 *
 * @param V_FECHA_INICIO  Fecha a verificar
 * @param V_ID_UNIDAD     ID de la unidad organizativa (se busca con LIKE para incluir subunidades)
 * 
 * @return VARCHAR2  Número de funcionarios de vacaciones en formato texto
 *
 * Lógica:
 *   1. Construye patrón de búsqueda de unidad con comodín (%)
 *   2. Busca funcionarios en permisos que:
 *      - Pertenecen a la unidad especificada (o subunidades)
 *      - La fecha de verificación está en el rango del permiso
 *      - El permiso no está anulado
 *      - El permiso es de tipo vacaciones (estado 80)
 *   3. Retorna el conteo de funcionarios distintos
 *
 * Dependencias:
 *   - Tabla: rrhh.permiso (id_funcionario, fecha_inicio, fecha_fin, anulado, id_estado)
 *   - Tabla: personal_rpt (id_funcionario, id_unidad)
 *
 * Consideraciones:
 *   - Uso de LIKE permite buscar unidades jerárquicas
 *   - Solo cuenta permisos activos (ANULADO='NO' o NULL)
 *   - Estado 80 representa permisos de vacaciones
 *   - Retorna número en formato texto para compatibilidad
 *
 * Mejoras aplicadas:
 *   - Eliminación de variables no utilizadas (i_error, i_personas_total, v_dia_semana, etc.)
 *   - Constantes nombradas para valores especiales
 *   - Variables inicializadas explícitamente
 *   - Documentación completa JavaDoc
 *   - INNER JOIN explícito en lugar de subconsulta IN
 *   - Eliminación de código comentado
 *   - Variables con nombres descriptivos
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.FUNCIONARIO_VACACIONES_DETA_NU(
    V_FECHA_INICIO IN DATE,
    V_ID_UNIDAD IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_ESTADO_VACACIONES CONSTANT NUMBER := 80;
    C_NO_VACACIONES CONSTANT NUMBER := 0;
    C_WILDCARD CONSTANT VARCHAR2(1) := '%';
    
    -- Variables
    v_patron_unidad VARCHAR2(25);
    v_num_vacaciones NUMBER := C_NO_VACACIONES;
    
BEGIN
    -- Construir patrón de búsqueda con comodín
    v_patron_unidad := V_ID_UNIDAD || C_WILDCARD;
    
    -- Contar funcionarios de vacaciones en la fecha especificada
    BEGIN
        SELECT COUNT(DISTINCT p.id_funcionario)
        INTO v_num_vacaciones
        FROM rrhh.permiso p
        INNER JOIN personal_rpt pr ON p.id_funcionario = pr.id_funcionario
        WHERE pr.id_unidad LIKE v_patron_unidad
            AND V_FECHA_INICIO BETWEEN p.FECHA_INICIO AND p.FECHA_FIN
            AND (p.ANULADO = 'NO' OR p.ANULADO IS NULL)
            AND p.id_estado = C_ESTADO_VACACIONES;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_num_vacaciones := C_NO_VACACIONES;
    END;
    
    RETURN TO_CHAR(v_num_vacaciones);
    
END FUNCIONARIO_VACACIONES_DETA_NU;
/

