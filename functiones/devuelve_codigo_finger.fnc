/*******************************************************************************
 * Función: DEVUELVE_CODIGO_FINGER
 * 
 * Propósito:
 *   Obtiene el código de fichaje asociado a un funcionario desde el sistema
 *   de control de acceso (fingerprint/huella dactilar).
 *
 * @param I_ID_FUNCIONARIO  ID del funcionario
 * @return VARCHAR2         Código de fichaje (id_fichaje), o '0' si no existe
 *
 * Lógica:
 *   1. Busca el id_fichaje en la tabla apliweb.usuario
 *   2. Retorna el código si existe
 *   3. Retorna '0' si no se encuentra
 *
 * Dependencias:
 *   - Tabla: apliweb.usuario
 *
 * Mejoras aplicadas:
 *   - Constante nombrada para valor por defecto
 *   - Eliminación de DISTINCT innecesario (id_funcionario debería ser único)
 *   - ROWNUM para limitar resultados
 *   - Variable con nombre descriptivo
 *   - Documentación completa
 *
 * Nota: El DISTINCT original sugiere que podría haber duplicados en
 *       apliweb.usuario. Si id_funcionario es clave única, se puede eliminar.
 *       Se mantiene por compatibilidad pero se añade ROWNUM.
 *
 * Historial:
 *   - Original: Implementación básica de consulta
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_CODIGO_FINGER(
    I_ID_FUNCIONARIO IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_VALOR_NO_ENCONTRADO CONSTANT VARCHAR2(1) := '0';
    
    -- Variables
    v_id_fichaje VARCHAR2(122);
    
BEGIN
    BEGIN
        -- Obtener código de fichaje del usuario
        SELECT DISTINCT id_fichaje
        INTO v_id_fichaje
        FROM apliweb.usuario u
        WHERE u.id_funcionario = I_ID_FUNCIONARIO
          AND ROWNUM = 1;
          
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_fichaje := C_VALOR_NO_ENCONTRADO;
    END;
    
    RETURN v_id_fichaje;
    
END DEVUELVE_CODIGO_FINGER;
/

