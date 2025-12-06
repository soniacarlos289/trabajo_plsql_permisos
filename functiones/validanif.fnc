/*******************************************************************************
 * Función: VALIDANIF
 * 
 * Propósito:
 *   Genera el NIF (Número de Identificación Fiscal) completo añadiendo
 *   la letra de control correspondiente a un DNI numérico.
 *
 * @param DNI        Número de DNI (solo dígitos) o cadena no numérica
 * @return VARCHAR2  NIF completo (8 dígitos + letra) o '0' si no es número válido
 *
 * Lógica:
 *   1. Verifica si el parámetro es un número válido usando es_NUMERO()
 *   2. Calcula el resto de dividir DNI entre 23
 *   3. Obtiene la letra correspondiente de la cadena de letras válidas
 *   4. Formatea el resultado con ceros a la izquierda (8 dígitos) + letra
 *
 * Dependencias:
 *   - Función: es_NUMERO (verifica si una cadena es numérica)
 *
 * Notas:
 *   - La cadena de letras sigue el algoritmo oficial del DNI español
 *   - El resultado siempre tiene 9 caracteres (8 dígitos + 1 letra)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa con ejemplos
 *   - Constante para la cadena de letras válidas
 *   - Variables con nombres más descriptivos
 *   - Comentarios explicativos
 *
 * Ejemplos:
 *   SELECT RRHH.VALIDANIF('12345678') FROM DUAL;  -- Retorna '12345678Z'
 *   SELECT RRHH.VALIDANIF('1234567') FROM DUAL;   -- Retorna '01234567L'
 *   SELECT RRHH.VALIDANIF('ABC') FROM DUAL;       -- Retorna '0' (no numérico)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - documentación completa
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.VALIDANIF(
    DNI IN VARCHAR2
) RETURN VARCHAR2 AS

    -- Constante con las 23 letras válidas del algoritmo DNI
    C_LETRAS_VALIDAS CONSTANT CHAR(23) := 'TRWAGMYFPDXBNJZSQVHLCKE';
    
    -- Variables
    v_letra_correcta CHAR;
    v_resto          INTEGER;
    v_nif            VARCHAR2(10);

BEGIN
    -- Verificar si el parámetro es un número válido
    IF es_NUMERO(DNI) = 0 THEN
        -- Calcular resto de división entre 23
        v_resto := DNI MOD 23;
        
        -- Obtener letra correspondiente al resto (posición resto+1)
        v_letra_correcta := SUBSTR(C_LETRAS_VALIDAS, v_resto + 1, 1);
        
        -- Formatear NIF: 8 dígitos con ceros a la izquierda + letra
        v_nif := LPAD(DNI, 8, '0') || v_letra_correcta;
        
        RETURN v_nif;
    ELSE
        -- No es un número válido
        RETURN '0';
    END IF;

END VALIDANIF;
/

