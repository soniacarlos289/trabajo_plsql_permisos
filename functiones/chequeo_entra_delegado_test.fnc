/*******************************************************************************
 * Función: CHEQUEO_ENTRA_DELEGADO_TEST
 * 
 * Propósito:
 *   Retorna una lista separada por comas de todos los jefes de servicio que
 *   están ausentes (con permisos o bajas activas) en la fecha actual.
 *   Variante "test" que incluye verificación de bajas por enfermedad.
 *
 * @param V_ID_JS_DELEGADO  ID del jefe de servicio delegado
 * @return VARCHAR2         Lista de IDs separados por comas de JSs ausentes
 *
 * Lógica:
 *   1. Busca todos los jefes de servicio que tienen al delegado como tal
 *   2. Para cada JS, verifica permisos activos en fecha actual
 *   3. Si no tiene permisos, verifica bajas por enfermedad
 *   4. Construye cadena de IDs separados por comas
 *   5. Incluye caso especial hardcodeado (ID 101286)
 *
 * Dependencias:
 *   - Tabla: funcionario_firma
 *   - Tabla: permiso
 *   - Tabla: bajas_ilt
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para estados y valores
 *   - FOR LOOP en lugar de cursor manual
 *   - TRUNC para comparaciones de fecha
 *   - ROWNUM para optimizar búsquedas
 *   - Variables inicializadas explícitamente
 *   - Eliminación de código comentado
 *   - Documentación completa
 *
 * Nota: Esta función usa años hardcodeados (2014-2017), considerar
 *       actualizar a rango dinámico. El caso especial 101286 debería
 *       moverse a tabla de configuración.
 *
 * Historial:
 *   - 09/01/2010: Añadido filtro id_js<>V_JS_DELEGADO
 *   - 05/04/2010: Añadido chequeo de bajas por enfermedad
 *   - 16/01/2017: Comentado caso especial 101292
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.CHEQUEO_ENTRA_DELEGADO_TEST(
    V_ID_JS_DELEGADO IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_ESTADO_EXCLUIDO_1 CONSTANT VARCHAR2(2) := '30';
    C_ESTADO_EXCLUIDO_2 CONSTANT VARCHAR2(2) := '31';
    C_ESTADO_EXCLUIDO_3 CONSTANT VARCHAR2(2) := '32';
    C_ESTADO_EXCLUIDO_4 CONSTANT VARCHAR2(2) := '40';
    C_ANULADO_NO        CONSTANT VARCHAR2(2) := 'NO';
    C_SEPARADOR         CONSTANT VARCHAR2(1) := ',';
    C_ID_ESPECIAL       CONSTANT NUMBER := 101286;
    
    -- Variables
    v_resultado         VARCHAR2(556) := NULL;
    v_id_js             VARCHAR2(6);
    v_js_ausente        NUMBER;
    v_fecha_hoy         DATE;
    
    -- Cursor para obtener jefes de servicio con el delegado especificado
    CURSOR cur_jefes_servicio(p_js_delegado VARCHAR2) IS
        SELECT DISTINCT id_js
        FROM funcionario_firma
        WHERE id_delegado_js = p_js_delegado
          AND id_js <> p_js_delegado;
          
BEGIN
    -- Inicializar fecha truncada
    v_fecha_hoy := TRUNC(SYSDATE);
    
    -- Recorrer todos los jefes de servicio
    FOR rec_js IN cur_jefes_servicio(V_ID_JS_DELEGADO) LOOP
        v_id_js := rec_js.id_js;
        v_js_ausente := 0;
        
        -- Verificar permisos activos
        BEGIN
            SELECT id_funcionario
            INTO v_js_ausente
            FROM permiso
            WHERE id_funcionario = v_id_js
              AND v_fecha_hoy BETWEEN fecha_inicio AND fecha_fin
              AND id_ano IN (2014, 2015, 2016, 2017)
              AND (anulado = C_ANULADO_NO OR anulado IS NULL)
              AND id_estado NOT IN (C_ESTADO_EXCLUIDO_1, C_ESTADO_EXCLUIDO_2, 
                                    C_ESTADO_EXCLUIDO_3, C_ESTADO_EXCLUIDO_4)
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_js_ausente := 0;
        END;
        
        -- Si no tiene permisos, verificar bajas por enfermedad
        IF v_js_ausente = 0 THEN
            BEGIN
                SELECT id_funcionario
                INTO v_js_ausente
                FROM bajas_ilt
                WHERE id_funcionario = v_id_js
                  AND v_fecha_hoy BETWEEN fecha_inicio AND fecha_fin
                  AND (anulada = C_ANULADO_NO OR anulada IS NULL)
                  AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_js_ausente := 0;
            END;
        END IF;
        
        -- Si está ausente, añadir a la lista
        IF v_js_ausente <> 0 THEN
            IF v_resultado IS NULL THEN
                v_resultado := TO_CHAR(v_js_ausente);
            ELSE
                v_resultado := TO_CHAR(v_js_ausente) || C_SEPARADOR || v_resultado;
            END IF;
        END IF;
    END LOOP;
    
    -- Caso especial hardcodeado (TODO: mover a tabla de configuración)
    IF v_id_js = C_ID_ESPECIAL THEN
        v_js_ausente := C_ID_ESPECIAL;
    END IF;
    
    RETURN v_resultado;
    
END CHEQUEO_ENTRA_DELEGADO_TEST;
/

