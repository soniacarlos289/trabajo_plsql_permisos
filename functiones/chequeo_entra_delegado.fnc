/**
 * ==============================================================================
 * Funcion: CHEQUEO_ENTRA_DELEGADO
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Determina si un delegado de jefe de servicio debe asumir las funciones
 *   de firma debido a que alguno de los JS que representa esta ausente
 *   (permiso o baja activa).
 *
 * PARAMETROS:
 *   @param V_ID_JS_DELEGADO (VARCHAR2) - Identificador del delegado
 *
 * RETORNO:
 *   @return VARCHAR2 - ID del funcionario ausente que debe cubrir:
 *                      - ID del JS ausente si encontro alguno
 *                      - NULL/0 si no hay JS ausentes
 *                      - Casos especiales hardcodeados para funcionarios
 *
 * LOGICA:
 *   1. Obtiene lista de JS para los que este delegado puede firmar
 *   2. Para cada JS, verifica si tiene permiso/baja activo
 *   3. Retorna el ID del primer JS ausente encontrado
 *   4. Aplica excepciones especiales para casos particulares
 *
 * ANIOS CONSIDERADOS:
 *   La funcion verifica permisos de los anios 2014-2017.
 *   NOTA: Esta lista deberia actualizarse o usar un rango dinamico.
 *
 * CASOS ESPECIALES (hardcoded):
 *   - Funcionario 101286: Siempre se considera
 *   - Delegado 101292: Siempre retorna 101121
 *
 * DEPENDENCIAS:
 *   - Tabla FUNCIONARIO_FIRMA: Relacion JS-Delegado
 *   - Tabla PERMISO: Permisos de funcionarios
 *   - Tabla BAJAS_ILT: Bajas por incapacidad
 *
 * ESTADOS EXCLUIDOS:
 *   - 30, 31, 32: Rechazados
 *   - 40, 41: Cancelados
 *
 * MEJORAS v2.0:
 *   - Documentacion completa
 *   - Variables con nombres descriptivos
 *   - Estructura de codigo mas clara
 *   - Nota sobre casos especiales hardcodeados
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEO_ENTRA_DELEGADO(
    V_ID_JS_DELEGADO IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes de casos especiales
    C_FUNCIONARIO_ESPECIAL_1 CONSTANT VARCHAR2(6) := '101286';
    C_DELEGADO_ESPECIAL      CONSTANT VARCHAR2(6) := '101292';
    C_RETORNO_ESPECIAL       CONSTANT VARCHAR2(6) := '101121';
    
    -- Variables de trabajo
    v_id_js           VARCHAR2(6);
    v_funcionario_id  NUMBER := 0;
    v_resultado       NUMBER := 0;
    
    -- Cursor para obtener los JS que tiene asignados el delegado
    CURSOR c_jefes_servicio(p_id_delegado VARCHAR2) IS
        SELECT DISTINCT id_js
          FROM funcionario_firma
         WHERE id_delegado_js = p_id_delegado
           AND id_js <> p_id_delegado;
    
BEGIN
    -- Inicializar
    v_id_js := '0';
    v_funcionario_id := 0;
    
    -- Iterar sobre los JS asignados al delegado
    OPEN c_jefes_servicio(V_ID_JS_DELEGADO);
    LOOP
        FETCH c_jefes_servicio INTO v_id_js;
        EXIT WHEN c_jefes_servicio%NOTFOUND;
        
        -- Verificar si este JS tiene permiso activo
        BEGIN
            SELECT DISTINCT id_funcionario
              INTO v_funcionario_id
              FROM permiso
             WHERE TRUNC(SYSDATE) BETWEEN fecha_inicio AND fecha_fin
               AND id_funcionario = v_id_js
               AND id_ano IN (2014, 2015, 2016, 2017)
               AND (anulado = 'NO' OR anulado IS NULL)
               AND id_estado NOT IN ('30', '31', '32', '40', '41');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_funcionario_id := 0;
        END;
        
        -- Si no hay permiso, verificar baja activa
        IF v_funcionario_id = 0 THEN
            BEGIN
                SELECT DISTINCT id_funcionario
                  INTO v_funcionario_id
                  FROM bajas_ilt
                 WHERE id_funcionario = v_id_js
                   AND TRUNC(SYSDATE) BETWEEN fecha_inicio AND fecha_fin
                   AND (anulada = 'NO' OR anulada IS NULL);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_funcionario_id := 0;
            END;
        END IF;
        
        -- Si encontramos un JS ausente, guardamos su ID
        IF v_funcionario_id <> 0 THEN
            v_resultado := v_funcionario_id;
        END IF;
    END LOOP;
    CLOSE c_jefes_servicio;
    
    -- Casos especiales hardcodeados
    -- NOTA: Estos casos deberian moverse a una tabla de configuracion
    IF v_id_js = C_FUNCIONARIO_ESPECIAL_1 THEN
        v_funcionario_id := TO_NUMBER(C_FUNCIONARIO_ESPECIAL_1);
    END IF;
    
    IF V_ID_JS_DELEGADO = C_DELEGADO_ESPECIAL THEN
        v_resultado := TO_NUMBER(C_RETORNO_ESPECIAL);
    END IF;
    
    RETURN TO_CHAR(v_resultado);
END CHEQUEO_ENTRA_DELEGADO;
/
