/*******************************************************************************
 * Función: wbs_devuelve_datos_operacion
 * 
 * Propósito:
 *   Construye un JSON con el resultado y observaciones de una operación.
 *   Utilizada para devolver respuestas estándar en operaciones WBS.
 *
 * @param v_resultado VARCHAR2      Código de resultado de la operación
 * @param v_observaciones VARCHAR2  Observaciones o mensaje descriptivo
 * @return VARCHAR2                 JSON con formato: "operacion": [{"resultado":"...","observaciones":"..."}]
 *
 * Lógica:
 *   1. Construye JSON con JSON_OBJECT
 *   2. Retorna formato estándar de operación
 *   3. Manejo de errores con mensaje default
 *
 * Dependencias:
 *   Ninguna (función de utilidad)
 *
 * Mejoras aplicadas:
 *   - Eliminación SELECT FROM DUAL innecesario
 *   - Constante para mensaje de error
 *   - Cálculo directo de JSON en lugar de consulta
 *   - Simplificación de manejo de excepciones
 *   - Documentación JavaDoc completa
 *
 * Ejemplo de uso:
 *   -- Operación exitosa
 *   SELECT wbs_devuelve_datos_operacion('OK', 'Registro actualizado') FROM DUAL;
 *   -- Retorna: "operacion": [{"resultado":"OK","observaciones":"Registro actualizado"}]
 *
 *   -- Operación fallida
 *   SELECT wbs_devuelve_datos_operacion('ERROR', 'Usuario no encontrado') FROM DUAL;
 *   -- Retorna: "operacion": [{"resultado":"ERROR","observaciones":"Usuario no encontrado"}]
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_datos_operacion(
    v_resultado IN VARCHAR2,
    v_observaciones IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constante para mensaje de error
    C_MENSAJE_ERROR CONSTANT VARCHAR2(30) := 'Operacion incorrecta';
    
    -- Variables
    v_json VARCHAR2(4000);
    
BEGIN
    BEGIN
        -- Construir JSON directamente sin SELECT FROM DUAL
        v_json := '"operacion": [' ||
                  JSON_OBJECT(
                      'resultado' IS v_resultado,
                      'observaciones' IS v_observaciones
                  ) || ']';
    EXCEPTION
        WHEN OTHERS THEN
            v_json := C_MENSAJE_ERROR;
    END;
    
    RETURN v_json;
END;
/

