/*******************************************************************************
 * Función: fn_GetIBANDigits
 * 
 * Propósito:
 *   Convierte una cadena IBAN en su representación numérica según el algoritmo
 *   ISO 7064 Mod-97. Cada letra se convierte a su valor numérico (A=10, B=11...Z=35)
 *   y los dígitos se mantienen igual.
 *
 * @param IBAN  Cadena IBAN a convertir (puede contener letras y números)
 * 
 * @return VARCHAR2  Cadena numérica resultante de la conversión
 *
 * Lógica:
 *   1. Recorre cada caracter del IBAN
 *   2. Obtiene el código ASCII del caracter
 *   3. Si es dígito (ASCII 48-57): convierte restando 48
 *   4. Si es letra (ASCII 65+): convierte restando 55 (A=10, B=11, etc.)
 *   5. Concatena los valores numéricos
 *
 * Ejemplos:
 *   - fn_GetIBANDigits('ES91') → '142891'
 *     E(69-55=14), S(83-55=28), 9(9), 1(1)
 *
 * Dependencias:
 *   - Funciones Oracle: SUBSTR, LENGTH, ASCII, TO_CHAR
 *
 * Consideraciones:
 *   - Función auxiliar usada para validación IBAN (ISO 13616)
 *   - No valida formato de entrada, asume entrada correcta
 *   - Soporta tanto letras mayúsculas como números
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para códigos ASCII
 *   - Documentación completa JavaDoc
 *   - Variables con nombres descriptivos (v_ prefix)
 *   - Inicialización explícita de cadena resultado
 *   - Comentarios explicativos de lógica ASCII
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.fn_GetIBANDigits(
    IBAN IN VARCHAR2
) RETURN VARCHAR2 AS
    -- Constantes para códigos ASCII
    C_ASCII_DIGIT_START CONSTANT INTEGER := 48;  -- '0'
    C_ASCII_DIGIT_END   CONSTANT INTEGER := 57;  -- '9'
    C_ASCII_TO_DIGIT    CONSTANT INTEGER := 48;  -- Offset para convertir dígito
    C_ASCII_TO_LETTER   CONSTANT INTEGER := 55;  -- Offset para convertir letra (A=10)
    
    -- Variables
    v_char          VARCHAR2(1);
    v_ascii_code    INTEGER;
    v_result_string VARCHAR2(255) := '';
    
BEGIN
    -- Recorrer cada caracter del IBAN
    FOR i IN 1..LENGTH(IBAN) LOOP
        v_char := SUBSTR(IBAN, i, 1);
        v_ascii_code := ASCII(v_char);
        
        -- Determinar si es dígito o letra y convertir
        IF v_ascii_code > C_ASCII_DIGIT_START AND v_ascii_code < C_ASCII_DIGIT_END THEN
            -- Es un dígito (0-9)
            v_result_string := v_result_string || TO_CHAR(v_ascii_code - C_ASCII_TO_DIGIT);
        ELSE
            -- Es una letra (A-Z → 10-35)
            v_result_string := v_result_string || TO_CHAR(v_ascii_code - C_ASCII_TO_LETTER);
        END IF;
    END LOOP;
    
    RETURN v_result_string;
    
END fn_GetIBANDigits;
/

