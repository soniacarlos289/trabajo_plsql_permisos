/*******************************************************************************
 * Función: TEST_ENCRIPTA
 * 
 * Propósito:
 *   Verifica si el paquete DBMS_CRYPTO está disponible y funcionando correctamente
 *   en la base de datos. Se usa como función de diagnóstico.
 *
 * @param v_valor  Parámetro no utilizado (mantenido por compatibilidad de firma)
 * @return NUMBER  0 si DBMS_CRYPTO funciona correctamente, 1 si hay un error
 *
 * Lógica:
 *   1. Intenta ejecutar una operación de hash SHA-1 con una clave fija
 *   2. Si la operación es exitosa, retorna 0 (éxito)
 *   3. Si hay un VALUE_ERROR, retorna 1 (error)
 *
 * Dependencias:
 *   - Package: SYS.DBMS_CRYPTO (Oracle encryption/hashing package)
 *   - Package: UTL_RAW (conversión de datos)
 *
 * Notas:
 *   - Esta función es solo para testing/diagnóstico
 *   - No se recomienda usar en producción
 *   - La clave hardcodeada es solo para pruebas
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa
 *   - Constante para la clave de prueba
 *   - Constante para valores de retorno
 *   - Comentarios explicativos
 *
 * Ejemplos:
 *   SELECT RRHH.TEST_ENCRIPTA('test') FROM DUAL;  -- Verifica DBMS_CRYPTO
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - documentación y constantes
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.TEST_ENCRIPTA(
    v_valor IN VARCHAR2
) RETURN NUMBER IS

    -- Constantes
    C_TEST_KEY     CONSTANT VARCHAR2(50) := '|X7GY2M43XKF3AZP176T';
    C_SUCCESS      CONSTANT NUMBER := 0;
    C_ERROR        CONSTANT NUMBER := 1;
    
    -- Variables
    v_hash_result  NUMBER;

BEGIN
    -- Intentar ejecutar hash SHA-1 para verificar disponibilidad de DBMS_CRYPTO
    v_hash_result := SYS.DBMS_CRYPTO.hash(
        src => UTL_RAW.CAST_TO_RAW(C_TEST_KEY),
        typ => SYS.DBMS_CRYPTO.hash_sh1
    );
    
    -- Si llega aquí, DBMS_CRYPTO funciona correctamente
    RETURN C_SUCCESS;
    
EXCEPTION
    WHEN VALUE_ERROR THEN
        -- Error en el procesamiento: DBMS_CRYPTO no disponible o configurado incorrectamente
        RETURN C_ERROR;
        
END TEST_ENCRIPTA;
/

