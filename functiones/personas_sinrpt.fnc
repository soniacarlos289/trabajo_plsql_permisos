/*******************************************************************************
 * Función: PERSONAS_SINRPT
 * 
 * Propósito:
 *   Devuelve un resumen de empleados sin RPT que tienen permisos/vacaciones 
 *   en un rango de fechas dado, basándose en la estructura de firma del funcionario.
 *
 * @param V_FECHA_INICIO         Fecha inicial del rango a consultar
 * @param V_FECHA_FIN            Fecha final del rango a consultar
 * @param V_ID_FUNCIONARIO_FIRMA ID del funcionario firmante (puede ser JS, delegado o JA)
 * @return VARCHAR2              Mensaje con el formato: "No incluida en la RPT (X de un total de Y Func.)"
 *
 * Lógica:
 *   1. Identifica funcionarios relacionados con el firmante (JS, delegado_js o JA)
 *   2. Excluye aquellos que SÍ están en personal_rpt bajo la misma unidad
 *   3. Para cada funcionario sin RPT, verifica si tiene permisos aprobados (estado=80)
 *      que se solapen con el rango de fechas dado
 *   4. Retorna un resumen contando cuántos tienen permisos del total sin RPT
 *
 * Dependencias:
 *   - Tabla: rrhh.funcionario_firma (id_js, id_delegado_js, id_ja)
 *   - Tabla: personal_rpt (id_funcionario, id_unidad)
 *   - Tabla: permiso (id_funcionario, fecha_inicio, fecha_fin, id_estado, anulado)
 *
 * Mejoras aplicadas:
 *   - Cursor manual → FOR LOOP para mejor gestión de memoria
 *   - Constante C_ESTADO_APROBADO para el valor mágico 80
 *   - Uso de CASE en lugar de IF para concatenación
 *   - SELECT EXISTS en lugar de COUNT DISTINCT con ROWNUM para mejor rendimiento
 *   - Eliminación de código comentado
 *   - Variables descriptivas (v_contador_primero en lugar de i_no_hay_datos)
 *   - Documentación JavaDoc completa
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - mejor rendimiento y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.PERSONAS_SINRPT(
    V_FECHA_INICIO         IN DATE,
    V_FECHA_FIN            IN DATE,
    V_ID_FUNCIONARIO_FIRMA IN VARCHAR2
) RETURN VARCHAR2 IS

    -- Constantes
    C_ESTADO_APROBADO    CONSTANT NUMBER := 80;
    C_DESC_UNIDAD        CONSTANT VARCHAR2(512) := 'No incluida en la RPT';
    
    -- Variables de resultado
    v_resultado           VARCHAR2(4000);
    v_lista_funcionario   VARCHAR2(4000);
    
    -- Contadores
    i_personas_vacaciones NUMBER := 0;
    i_personas_total      NUMBER := 0;
    i_temp                NUMBER;
    v_contador_primero    BOOLEAN := TRUE;
    
    -- Cursor: Funcionarios relacionados con el firmante pero NO en RPT
    CURSOR c_funcionarios_sin_rpt IS
        SELECT id_funcionario
        FROM rrhh.funcionario_firma
        WHERE (id_js = V_ID_FUNCIONARIO_FIRMA 
            OR id_delegado_js = V_ID_FUNCIONARIO_FIRMA 
            OR id_ja = V_ID_FUNCIONARIO_FIRMA)
        MINUS
        SELECT id_funcionario
        FROM personal_rpt
        WHERE id_unidad LIKE (
            SELECT id_unidad || '%'
            FROM personal_rpt
            WHERE id_funcionario = V_ID_FUNCIONARIO_FIRMA
        );

BEGIN
    v_lista_funcionario := '';
    
    -- Recorrer funcionarios sin RPT
    FOR rec IN c_funcionarios_sin_rpt LOOP
        -- Construir lista de funcionarios (por si se necesita en el futuro)
        v_lista_funcionario := v_lista_funcionario || 
            CASE WHEN v_contador_primero THEN '''' ELSE ',''' END || 
            rec.id_funcionario || '''';
        v_contador_primero := FALSE;
        
        i_personas_total := i_personas_total + 1;
        
        -- Verificar si tiene permisos aprobados en el rango de fechas
        BEGIN
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM permiso p
                WHERE p.id_funcionario = rec.id_funcionario
                    AND (
                        (fecha_inicio BETWEEN V_FECHA_INICIO AND V_FECHA_FIN)
                        OR (fecha_fin BETWEEN V_FECHA_INICIO AND V_FECHA_FIN)
                        OR (fecha_inicio <= V_FECHA_INICIO AND fecha_fin >= V_FECHA_FIN)
                    )
                    AND (anulado = 'NO' OR anulado IS NULL)
                    AND id_estado = C_ESTADO_APROBADO
                    AND ROWNUM = 1
            ) THEN 1 ELSE 0 END
            INTO i_temp
            FROM DUAL;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_temp := 0;
        END;
        
        i_personas_vacaciones := i_personas_vacaciones + i_temp;
    END LOOP;
    
    -- Construir mensaje de resultado
    v_resultado := C_DESC_UNIDAD || '  (' || i_personas_vacaciones ||
                   ' de un total de ' || i_personas_total || ' Func.)';
    
    RETURN v_resultado;

END PERSONAS_SINRPT;
/

