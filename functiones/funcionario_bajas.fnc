/*******************************************************************************
 * Función: FUNCIONARIO_BAJAS
 * 
 * Propósito:
 *   Cuenta el número de funcionarios distintos de una unidad específica que
 *   se encuentran de baja (tabla bajas_ilt) en una fecha determinada.
 *
 * @param V_FECHA_INICIO  Fecha a verificar
 * @param V_ID_UNIDAD     ID de la unidad organizativa (se busca con LIKE para incluir subunidades)
 * 
 * @return VARCHAR2  Número de funcionarios de baja en formato texto
 *
 * Lógica:
 *   1. Construye patrón de búsqueda de unidad con comodín (%)
 *   2. Busca funcionarios en bajas_ilt que:
 *      - Pertenecen a la unidad especificada (o subunidades)
 *      - La fecha de verificación está en el rango de la baja
 *      - La baja no está anulada
 *   3. Retorna el conteo de funcionarios distintos
 *
 * Dependencias:
 *   - Tabla: bajas_ilt (id_funcionario, fecha_inicio, fecha_fin, anulada)
 *   - Tabla: personal_rpt (id_funcionario, id_unidad)
 *
 * Consideraciones:
 *   - Uso de LIKE permite buscar unidades jerárquicas
 *   - Solo cuenta bajas activas (ANULADA='NO' o NULL)
 *   - Retorna número en formato texto para compatibilidad
 *
 * Mejoras aplicadas:
 *   - Eliminación de variables no utilizadas (i_error, i_personas_total, etc.)
 *   - Constantes nombradas para valores por defecto
 *   - Variables inicializadas explícitamente
 *   - Documentación completa JavaDoc
 *   - INNER JOIN explícito en lugar de subconsulta IN
 *   - Eliminación de código comentado
 *   - Variables con nombres descriptivos
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.FUNCIONARIO_BAJAS(
    V_FECHA_INICIO IN DATE,
    V_ID_UNIDAD IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_NO_BAJAS CONSTANT NUMBER := 0;
    C_WILDCARD CONSTANT VARCHAR2(1) := '%';
    
    -- Variables
    v_patron_unidad VARCHAR2(25);
    v_num_bajas NUMBER := C_NO_BAJAS;
    
BEGIN
    -- Construir patrón de búsqueda con comodín
    v_patron_unidad := V_ID_UNIDAD || C_WILDCARD;
    
    -- Contar funcionarios de baja en la fecha especificada
    BEGIN
        SELECT COUNT(DISTINCT b.id_funcionario)
        INTO v_num_bajas
        FROM bajas_ilt b
        INNER JOIN personal_rpt pr ON b.id_funcionario = pr.id_funcionario
        WHERE pr.id_unidad LIKE v_patron_unidad
            AND V_FECHA_INICIO BETWEEN b.FECHA_INICIO AND b.FECHA_FIN
            AND (b.ANULADA = 'NO' OR b.ANULADA IS NULL);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_num_bajas := C_NO_BAJAS;
    END;
    
    RETURN TO_CHAR(v_num_bajas);
    
END FUNCIONARIO_BAJAS;
/

