/**
 * ==============================================================================
 * Funcion: CHEQUEA_CHECKIBAN
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Valida el digito de control de un numero IBAN (International Bank Account
 *   Number) siguiendo el estandar ISO 13616. Utiliza el algoritmo de modulo 97
 *   para verificar la integridad del numero de cuenta.
 *
 * PARAMETROS:
 *   @param pIBAN (VARCHAR2) - Numero IBAN completo a validar.
 *                             Formato: CCDDXXXXXX... donde CC=Pais, DD=Digitos control
 *                             Ejemplo: 'ES9121000418450200051332'
 *
 * RETORNO:
 *   @return INTEGER - Resultado de la validacion:
 *                     1 = IBAN valido
 *                     0 = IBAN invalido
 *
 * ALGORITMO ISO 13616:
 *   1. Reorganizar IBAN: mover los 4 primeros caracteres al final
 *   2. Convertir letras a numeros (A=10, B=11, ..., Z=35)
 *   3. Calcular modulo 97 del numero resultante
 *   4. Si el resultado es 1, el IBAN es valido
 *
 * EJEMPLO:
 *   IBAN: ES9121000418450200051332
 *   Paso 1: 21000418450200051332ES91
 *   Paso 2: 21000418450200051332142891 (ES=14,28)
 *   Paso 3: MOD(21000418450200051332142891, 97) = 1
 *   Resultado: 1 (valido)
 *
 * DEPENDENCIAS:
 *   - Funcion fn_GetIBANDigits: Convierte letras a sus valores numericos
 *
 * CONSIDERACIONES DE RENDIMIENTO:
 *   - Procesa en chunks de 5 digitos para evitar overflow numerico
 *   - El algoritmo de modulo acumulativo evita manejar numeros muy grandes
 *
 * MEJORAS v2.0:
 *   - Constantes nombradas para valores magicos
 *   - Documentacion completa del algoritmo ISO
 *   - Variables con nombres descriptivos
 *   - Codigo mas legible con indentacion consistente
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_CheckIBAN(
    pIBAN IN VARCHAR2
) RETURN INTEGER IS
    -- Constantes
    C_MODULO_97      CONSTANT NUMBER := 97;
    C_CHUNK_SIZE     CONSTANT INTEGER := 5;
    C_RESULTADO_OK   CONSTANT NUMBER := 1;
    C_PREFIJO_LENGTH CONSTANT NUMBER := 4;
    
    -- Variables de trabajo
    v_iban_reordenado VARCHAR2(256);
    v_iban_numerico   VARCHAR2(256);
    v_modulo          NUMBER;
    v_chunk           VARCHAR2(8);
    v_posicion        INTEGER := 1;
    v_resultado       INTEGER;
    
BEGIN
    -- Paso 1: Reorganizar IBAN (mover primeros 4 caracteres al final)
    v_iban_reordenado := SUBSTR(pIBAN, C_PREFIJO_LENGTH + 1) || 
                         SUBSTR(pIBAN, 1, C_PREFIJO_LENGTH);
    
    -- Paso 2: Convertir letras a numeros
    v_iban_numerico := fn_GetIBANDigits(v_iban_reordenado);
    
    -- Paso 3: Calcular modulo 97 en chunks para evitar overflow
    LOOP
        v_chunk := SUBSTR(v_iban_numerico, v_posicion, C_CHUNK_SIZE);
        EXIT WHEN v_chunk IS NULL;
        
        IF v_modulo IS NULL THEN
            -- Primer chunk: calcular modulo directamente
            v_modulo := MOD(TO_NUMBER(v_chunk), C_MODULO_97);
        ELSE
            -- Chunks siguientes: concatenar resto anterior con chunk actual
            v_modulo := MOD(TO_NUMBER(TO_CHAR(v_modulo) || v_chunk), C_MODULO_97);
        END IF;
        
        v_posicion := v_posicion + C_CHUNK_SIZE;
    END LOOP;
    
    -- Paso 4: Verificar resultado (IBAN valido si modulo = 1)
    IF v_modulo = C_RESULTADO_OK THEN
        v_resultado := 1;
    ELSE
        v_resultado := 0;
    END IF;
    
    RETURN v_resultado;
END CHEQUEA_CheckIBAN;
/

