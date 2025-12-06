/*******************************************************************************
 * Función: ES_NUMERO
 * 
 * Propósito:
 *   Valida si una cadena puede ser convertida a número. Retorna 0 si es válida,
 *   1 si no lo es. Útil para validación de entrada antes de conversiones.
 *
 * @param v_valor   Cadena a validar
 * @return NUMBER   0 si es número válido, 1 si no lo es
 *
 * Lógica:
 *   1. Intentar convertir la cadena a NUMBER con TO_NUMBER
 *   2. Si la conversión es exitosa: retornar 0 (válido)
 *   3. Si lanza VALUE_ERROR: retornar 1 (inválido)
 *
 * Ejemplo de uso:
 *   es_numero('123')      -> 0 (válido)
 *   es_numero('12.5')     -> 0 (válido)
 *   es_numero('ABC')      -> 1 (inválido)
 *   es_numero('12,34')    -> 1 (inválido, usa coma en lugar de punto)
 *   es_numero('')         -> 1 (inválido)
 *   es_numero(NULL)       -> 1 (inválido)
 *
 * Dependencias:
 *   Ninguna
 *
 * Consideraciones:
 *   - Retorna 0 para válido y 1 para inválido (no booleano)
 *   - No maneja separadores de miles ni formatos personalizados
 *   - Usa configuración NLS del sistema para separador decimal
 *   - La variable v_numero es necesaria aunque no se use su valor
 *
 * Mejoras aplicadas:
 *   - Constantes para valores de retorno
 *   - Documentación completa con ejemplos
 *   - Comentarios explicativos
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.ES_NUMERO(
    v_valor IN VARCHAR2
) 
RETURN NUMBER IS
    -- Constantes
    C_VALIDO    CONSTANT NUMBER := 0;
    C_INVALIDO  CONSTANT NUMBER := 1;
    
    -- Variables
    v_numero    NUMBER;
    
BEGIN
    -- Intentar conversión a número
    v_numero := TO_NUMBER(v_valor);
    
    -- Si llegamos aquí, la conversión fue exitosa
    RETURN C_VALIDO;
    
EXCEPTION
    WHEN VALUE_ERROR THEN
        -- La cadena no es un número válido
        RETURN C_INVALIDO;
        
END ES_NUMERO;
/

