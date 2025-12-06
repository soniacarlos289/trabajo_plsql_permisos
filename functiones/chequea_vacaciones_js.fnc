/**
 * ==============================================================================
 * Funcion: CHEQUEA_VACACIONES_JS
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Verifica si un jefe de servicio (JS) tiene actualmente un permiso o baja
 *   activo. Util para determinar si el JS puede firmar/autorizar solicitudes
 *   o si debe derivarse a su delegado.
 *
 * PARAMETROS:
 *   @param V_ID_JS (VARCHAR2) - Identificador del jefe de servicio
 *
 * RETORNO:
 *   @return VARCHAR2 - Estado del JS:
 *                      '1' = JS tiene permiso/baja activo (no disponible)
 *                      '0' = JS disponible (sin permiso ni baja)
 *
 * LOGICA:
 *   1. Verifica si el JS tiene un permiso activo para la fecha actual
 *   2. Si no hay permiso, verifica si tiene baja activa
 *   3. Retorna 1 si esta ausente, 0 si esta disponible
 *
 * ANIOS CONSIDERADOS:
 *   La funcion verifica permisos de los anios 2010-2014.
 *   NOTA: Esta lista deberia actualizarse o usar un rango dinamico.
 *
 * ESTADOS EXCLUIDOS:
 *   - 30, 31, 32: Rechazados
 *   - 40: Cancelados
 *
 * DEPENDENCIAS:
 *   - Tabla PERMISO: Permisos de funcionarios
 *   - Tabla BAJAS_ILT: Bajas por incapacidad
 *
 * CONSIDERACIONES:
 *   - Usa SYSDATE para fecha actual
 *   - Los anios hardcodeados limitan la funcionalidad
 *   - Se sugiere usar: id_ano >= EXTRACT(YEAR FROM SYSDATE) - 1
 *
 * MEJORAS v2.0:
 *   - Documentacion completa
 *   - Variables con nombres descriptivos
 *   - Codigo simplificado
 *   - Nota sobre limitacion de anios
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_VACACIONES_JS(
    V_ID_JS IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_DISPONIBLE     CONSTANT NUMBER := 0;
    C_NO_DISPONIBLE  CONSTANT NUMBER := 1;
    
    -- Variables de trabajo
    v_funcionario_id NUMBER := 0;
    v_resultado      NUMBER;
    
BEGIN
    -- Inicializar
    v_funcionario_id := 0;
    
    -- 1. Verificar permiso activo
    BEGIN
        SELECT DISTINCT id_funcionario
          INTO v_funcionario_id
          FROM permiso
         WHERE TRUNC(SYSDATE) BETWEEN fecha_inicio AND fecha_fin
           AND id_funcionario = V_ID_JS
           AND id_ano IN (2010, 2011, 2012, 2013, 2014)
           AND (anulado = 'NO' OR anulado IS NULL)
           AND id_estado NOT IN ('30', '31', '32', '40');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_funcionario_id := 0;
    END;
    
    -- 2. Si no hay permiso, verificar baja activa
    IF v_funcionario_id = 0 THEN
        BEGIN
            SELECT DISTINCT id_funcionario
              INTO v_funcionario_id
              FROM bajas_ilt
             WHERE id_funcionario = V_ID_JS
               AND TRUNC(SYSDATE) BETWEEN fecha_inicio AND fecha_fin
               AND (anulada = 'NO' OR anulada IS NULL);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_funcionario_id := 0;
        END;
    END IF;
    
    -- 3. Determinar resultado
    IF v_funcionario_id <> 0 THEN
        v_resultado := C_NO_DISPONIBLE;
    ELSE
        v_resultado := C_DISPONIBLE;
    END IF;
    
    RETURN TO_CHAR(v_resultado);
END CHEQUEA_VACACIONES_JS;
/
