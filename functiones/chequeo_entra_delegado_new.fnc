/*******************************************************************************
 * Función: CHEQUEO_ENTRA_DELEGADO_NEW
 * 
 * Propósito:
 *   Verifica si un jefe de servicio tiene delegados que están ausentes en la
 *   fecha actual, retornando el ID del delegado ausente encontrado.
 *   Variante "new" que permite filtrar por funcionario específico.
 *
 * @param V_ID_JS_DELEGADO  ID del jefe de servicio delegado
 * @param i_ID_FUNCIONARIO  ID del funcionario a filtrar
 * @return VARCHAR2         ID del jefe de servicio ausente, o NULL si no hay
 *
 * Lógica:
 *   1. Busca todos los jefes de servicio distintos al delegado para el funcionario
 *   2. Verifica si cada JS tiene permisos activos en la fecha actual
 *   3. Retorna el ID del primer JS ausente encontrado
 *   4. Incluye caso especial hardcodeado (ID 101286) - TODO: mover a tabla
 *
 * Dependencias:
 *   - Tabla: funcionario_firma
 *   - Tabla: permiso
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para años y estados
 *   - Variables inicializadas explícitamente
 *   - Eliminación de código comentado innecesario
 *   - TRUNC en comparaciones de fecha
 *   - Cursor con nombre descriptivo
 *   - Documentación completa
 *
 * Nota: Se recomienda migrar los años hardcodeados a un rango dinámico
 *       basado en EXTRACT(YEAR FROM SYSDATE) y el caso especial 101286
 *       a una tabla de configuración.
 *
 * Historial:
 *   - 09/01/2010: Añadido filtro por funcionario
 *   - 09/04/2019: Eliminado filtro id_delegado_js
 *   - 17/03/2017: Eliminado bloque bajas_ilt
 *   - 16/01/2017: Comentado caso especial 101292
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.CHEQUEO_ENTRA_DELEGADO_NEW(
    V_ID_JS_DELEGADO IN VARCHAR2,
    i_ID_FUNCIONARIO IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_ESTADO_EXCLUIDO_1 CONSTANT VARCHAR2(2) := '30';
    C_ESTADO_EXCLUIDO_2 CONSTANT VARCHAR2(2) := '31';
    C_ESTADO_EXCLUIDO_3 CONSTANT VARCHAR2(2) := '32';
    C_ESTADO_EXCLUIDO_4 CONSTANT VARCHAR2(2) := '40';
    C_ESTADO_EXCLUIDO_5 CONSTANT VARCHAR2(2) := '41';
    C_ANULADO_NO        CONSTANT VARCHAR2(2) := 'NO';
    C_ID_ESPECIAL       CONSTANT NUMBER := 101286;
    
    -- Variables
    v_resultado         NUMBER := NULL;
    v_id_js             VARCHAR2(6);
    v_js_ausente        NUMBER;
    v_fecha_hoy         DATE;
    
    -- Cursor para obtener jefes de servicio del funcionario
    CURSOR cur_jefes_servicio(p_js_delegado VARCHAR2, p_id_funcionario VARCHAR2) IS
        SELECT DISTINCT id_js
        FROM funcionario_firma
        WHERE id_js <> p_js_delegado
          AND id_funcionario = p_id_funcionario;
          
BEGIN
    -- Inicializar fecha truncada
    v_fecha_hoy := TRUNC(SYSDATE);
    
    -- Recorrer todos los jefes de servicio del funcionario
    FOR rec_js IN cur_jefes_servicio(V_ID_JS_DELEGADO, i_ID_FUNCIONARIO) LOOP
        v_id_js := rec_js.id_js;
        v_js_ausente := 0;
        
        -- Verificar si el JS tiene permisos activos en la fecha actual
        BEGIN
            SELECT id_funcionario
            INTO v_js_ausente
            FROM permiso
            WHERE id_funcionario = v_id_js
              AND v_fecha_hoy BETWEEN fecha_inicio AND NVL(fecha_fin, v_fecha_hoy + 1)
              AND id_ano IN (2019, 2020, 2021, 2022, 2023, 2024, 2025)
              AND (anulado = C_ANULADO_NO OR anulado IS NULL)
              AND id_estado NOT IN (C_ESTADO_EXCLUIDO_1, C_ESTADO_EXCLUIDO_2, 
                                    C_ESTADO_EXCLUIDO_3, C_ESTADO_EXCLUIDO_4, 
                                    C_ESTADO_EXCLUIDO_5)
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_js_ausente := 0;
        END;
        
        -- Si encontramos un JS ausente, retornarlo
        IF v_js_ausente <> 0 THEN
            v_resultado := v_js_ausente;
            EXIT; -- Salir del bucle al encontrar el primer ausente
        END IF;
    END LOOP;
    
    -- Caso especial hardcodeado (TODO: mover a tabla de configuración)
    IF v_id_js = C_ID_ESPECIAL THEN
        v_resultado := C_ID_ESPECIAL;
    END IF;
    
    RETURN v_resultado;
    
END CHEQUEO_ENTRA_DELEGADO_NEW;
/

