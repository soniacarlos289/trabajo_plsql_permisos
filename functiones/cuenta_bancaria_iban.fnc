/*******************************************************************************
 * Función: CUENTA_BANCARIA_IBAN
 * 
 * Propósito:
 *   Genera el código IBAN español (ES) completo a partir de un número de
 *   cuenta bancaria tradicional de 20 dígitos (CCC).
 *
 * @param numCuenta  Número de cuenta bancaria (20 dígitos: 4+4+2+10)
 *                   Formato: BBBBSSSSCCNNNNNNNNNN
 *                   B=Banco, S=Sucursal, C=DC, N=Número de cuenta
 * @return VARCHAR2  IBAN completo (24 caracteres) formato: ESDDBBBBSSSSCCNNNNNNNNNN
 *                   Retorna cadena vacía si numCuenta es NULL
 *
 * Lógica:
 *   1. Verifica si el número de cuenta es NULL
 *   2. Calcula dígito de control según algoritmo mod-97 (ISO 7064)
 *   3. Concatena código país (ES) + dígito control + número de cuenta
 *   4. El cálculo usa: cuenta + '142800' (1=A, 4=D, 2=B, 8=H, 0=espacio en base 36)
 *      donde 'ES' = 1428 en base 36
 *   5. DC = 98 - (número_extendido MOD 97)
 *
 * Dependencias:
 *   - Ninguna (función standalone)
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para país y sufijo de conversión
 *   - Variable para dígito de control con nombre descriptivo
 *   - Uso de || en lugar de CONCAT para mejor legibilidad
 *   - Formato de DC con padding izquierdo (00-99)
 *   - Documentación completa del algoritmo
 *
 * Ejemplo:
 *   cuenta_bancaria_iban('12345678901234567890')
 *   => 'ES7712345678901234567890'
 *
 * Nota: Esta función NO valida que el número de cuenta sea válido.
 *       Solo calcula el IBAN basándose en el input proporcionado.
 *
 * Historial:
 *   - Original: Implementación del cálculo IBAN
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.CUENTA_BANCARIA_IBAN(
    numCuenta VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_CODIGO_PAIS    CONSTANT VARCHAR2(2)  := 'ES';
    C_SUFIJO_CONV    CONSTANT VARCHAR2(6)  := '142800'; -- ES00 en base 36
    C_MODULO         CONSTANT NUMBER       := 97;
    C_BASE_CALCULO   CONSTANT NUMBER       := 98;
    
    -- Variables
    v_iban              VARCHAR2(24);
    v_numero_extendido  NUMBER;
    v_digito_control    VARCHAR2(2);
    
BEGIN
    -- Verificar si el número de cuenta es NULL
    IF numCuenta IS NULL THEN
        RETURN '';
    END IF;
    
    -- Calcular dígito de control según algoritmo mod-97
    -- Paso 1: Concatenar cuenta + código país en base 36 (ES00 = 142800)
    v_numero_extendido := TO_NUMBER(numCuenta || C_SUFIJO_CONV);
    
    -- Paso 2: Calcular DC = 98 - (número MOD 97)
    v_digito_control := TO_CHAR(C_BASE_CALCULO - MOD(v_numero_extendido, C_MODULO), '00');
    
    -- Paso 3: Construir IBAN completo
    v_iban := C_CODIGO_PAIS || v_digito_control || numCuenta;
    
    RETURN v_iban;
    
END CUENTA_BANCARIA_IBAN;
/

