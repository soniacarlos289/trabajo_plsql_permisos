/**
 * ==============================================================================
 * Funcion: BASE64ENCODE
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Codifica un objeto BLOB (Binary Large Object) en formato Base64,
 *   retornando el resultado como un CLOB (Character Large Object).
 *   Util para transmitir datos binarios a traves de protocolos de texto.
 *
 * PARAMETROS:
 *   @param p_blob (BLOB) - Objeto binario a codificar. Puede contener
 *                          archivos, imagenes u otros datos binarios.
 *
 * RETORNO:
 *   @return CLOB - Cadena de caracteres con la representacion Base64
 *                  del BLOB de entrada. Retorna NULL si el BLOB esta vacio.
 *
 * LOGICA:
 *   1. Procesa el BLOB en chunks de 12000 bytes (multiplo de 3 requerido)
 *   2. Cada chunk se codifica usando UTL_ENCODE.base64_encode
 *   3. El resultado se convierte a VARCHAR2 y se concatena al CLOB
 *   4. El proceso se repite hasta procesar todo el BLOB
 *
 * CONSIDERACIONES DE RENDIMIENTO:
 *   - El tamanio del chunk (12000) esta optimizado para balance entre
 *     uso de memoria y numero de iteraciones
 *   - El limite maximo por chunk de Oracle es 24573 bytes
 *   - El chunk debe ser multiplo de 3 para codificacion Base64 correcta
 *
 * DEPENDENCIAS:
 *   - DBMS_LOB: Para manipulacion de objetos LOB
 *   - UTL_ENCODE: Para codificacion Base64
 *   - UTL_RAW: Para conversion a VARCHAR2
 *
 * CREDITOS:
 *   Basado en implementacion de Tim Hall (oracle-base.com)
 *
 * MEJORAS v2.0:
 *   - Manejo de BLOB nulo o vacio
 *   - Documentacion completa
 *   - Constantes nombradas para mejor legibilidad
 *
 * AUTOR: Tim Hall / Sistema RRHH
 * FECHA: 2011 / Actualizado 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.BASE64ENCODE(
    p_blob IN BLOB
) RETURN CLOB IS
    -- Constantes de configuracion
    -- El paso debe ser multiplo de 3 y no mayor a 24573
    C_CHUNK_SIZE CONSTANT PLS_INTEGER := 12000;
    
    -- Variables de trabajo
    l_clob       CLOB;
    l_blob_size  NUMBER;
    l_iterations NUMBER;
    
BEGIN
    -- Validar entrada
    IF p_blob IS NULL THEN
        RETURN NULL;
    END IF;
    
    l_blob_size := DBMS_LOB.getlength(p_blob);
    
    IF l_blob_size = 0 THEN
        RETURN NULL;
    END IF;
    
    -- Calcular numero de iteraciones necesarias
    l_iterations := TRUNC((l_blob_size - 1) / C_CHUNK_SIZE);
    
    -- Procesar BLOB en chunks
    FOR i IN 0 .. l_iterations LOOP
        l_clob := l_clob || UTL_RAW.cast_to_varchar2(
            UTL_ENCODE.base64_encode(
                DBMS_LOB.substr(p_blob, C_CHUNK_SIZE, i * C_CHUNK_SIZE + 1)
            )
        );
    END LOOP;
    
    RETURN l_clob;
END BASE64ENCODE;
/

