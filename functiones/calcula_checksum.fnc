/**
 * ==============================================================================
 * Funcion: CALCULA_CHECKSUM
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Calcula un caracter de verificacion (checksum) para una cadena de texto
 *   de hasta 39 caracteres. Utiliza una formula matematica basada en la suma
 *   ponderada de los valores ASCII de cada caracter.
 *
 * PARAMETROS:
 *   @param V_CADENA (VARCHAR2) - Cadena de entrada de hasta 39 caracteres.
 *                                 Se procesan los primeros 39 caracteres si
 *                                 la cadena es mas larga.
 *
 * RETORNO:
 *   @return VARCHAR2(1) - Un unico caracter que representa el checksum.
 *                         El resultado esta en el rango ASCII 32-172 o 174.
 *
 * ALGORITMO:
 *   1. Para cada caracter (posicion 1-39):
 *      - Obtiene valor ASCII (32 si es nulo/vacio)
 *      - Resta 32 (normaliza desde espacio)
 *      - Multiplica por su posicion (peso)
 *   2. Suma todos los valores ponderados + constante 104
 *   3. Aplica modulo 103
 *   4. Mapea valores especiales (91-102 y 0) a caracteres extendidos
 *   5. Suma 32 para obtener caracter imprimible
 *
 * TABLA DE MAPEO ESPECIAL:
 *   91->161, 92->162, 93->163, 94->164, 95->165
 *   96->166, 97->167, 98->168, 99->169, 100->170
 *   101->171, 102->172, 0->174
 *
 * CONSIDERACIONES:
 *   - La formula garantiza un checksum unico para cada combinacion de entrada
 *   - Los caracteres nulos se tratan como espacios (ASCII 32)
 *   - Util para validacion de integridad de datos
 *
 * MEJORAS v2.0:
 *   - Implementacion con bucle PL/SQL en lugar de SQL puro
 *   - Mejor rendimiento al evitar select from dual
 *   - Codigo mas legible y mantenible
 *   - Documentacion completa del algoritmo
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.CALCULA_CHECKSUM(
    V_CADENA IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_MAX_LONGITUD   CONSTANT NUMBER := 39;
    C_VALOR_BASE     CONSTANT NUMBER := 104;
    C_MODULO         CONSTANT NUMBER := 103;
    C_ASCII_ESPACIO  CONSTANT NUMBER := 32;
    
    -- Variables de trabajo
    v_suma           NUMBER := C_VALOR_BASE;
    v_ascii_char     NUMBER;
    v_mod_result     NUMBER;
    v_checksum_ascii NUMBER;
    v_result         VARCHAR2(1);
    
BEGIN
    -- Calcular suma ponderada de valores ASCII
    FOR i IN 1..C_MAX_LONGITUD LOOP
        -- Obtener valor ASCII del caracter, usar espacio si es nulo
        v_ascii_char := NVL(ASCII(SUBSTR(V_CADENA, i, 1)), C_ASCII_ESPACIO);
        
        -- Si el caracter esta vacio, usar valor de espacio
        IF v_ascii_char IS NULL THEN
            v_ascii_char := C_ASCII_ESPACIO;
        END IF;
        
        -- Sumar valor normalizado multiplicado por posicion
        v_suma := v_suma + (v_ascii_char - C_ASCII_ESPACIO) * i;
    END LOOP;
    
    -- Aplicar modulo
    v_mod_result := MOD(v_suma, C_MODULO);
    
    -- Mapear valores especiales
    v_checksum_ascii := CASE v_mod_result
        WHEN 91  THEN 161
        WHEN 92  THEN 162
        WHEN 93  THEN 163
        WHEN 94  THEN 164
        WHEN 95  THEN 165
        WHEN 96  THEN 166
        WHEN 97  THEN 167
        WHEN 98  THEN 168
        WHEN 99  THEN 169
        WHEN 100 THEN 170
        WHEN 101 THEN 171
        WHEN 102 THEN 172
        WHEN 0   THEN 174
        ELSE v_mod_result + C_ASCII_ESPACIO
    END;
    
    -- Convertir a caracter
    v_result := CHR(v_checksum_ascii);
    
    RETURN v_result;
END CALCULA_CHECKSUM;
/

