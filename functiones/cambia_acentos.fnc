/**
 * ==============================================================================
 * Funcion: CAMBIA_ACENTOS
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Convierte caracteres acentuados y especiales del espanol a sus
 *   equivalentes en formato de entidades HTML (sin el ampersand inicial).
 *   Util para generar contenido HTML seguro desde la base de datos.
 *
 * PARAMETROS:
 *   @param v_valor (VARCHAR2) - Cadena de texto que puede contener
 *                                caracteres acentuados o especiales.
 *                                Maximo 14500 caracteres.
 *
 * RETORNO:
 *   @return VARCHAR2 - Cadena con los caracteres especiales convertidos
 *                      a formato de entidad HTML (;xxxx;).
 *
 * CONVERSIONES REALIZADAS:
 *   Minusculas:
 *   - a acentuada -> ;aacute;
 *   - e acentuada -> ;eacute;
 *   - i acentuada -> ;iacute;
 *   - o acentuada -> ;oacute;
 *   - u acentuada -> ;uacute;
 *   - ene (n)     -> ;ntilde;
 *   - u dieresis  -> ;uuml;
 *
 *   Mayusculas:
 *   - A acentuada -> ;Aacute;
 *   - E acentuada -> ;Eacute;
 *   - I acentuada -> ;Iacute;
 *   - O acentuada -> ;Oacute;
 *   - U acentuada -> ;Uacute;
 *   - ENE (N)     -> ;Ntilde;
 *   - U dieresis  -> ;Uuml;
 *
 * NOTA:
 *   El formato de salida usa ';' en lugar de '&' al inicio
 *   para evitar problemas de interpretacion en ciertos contextos.
 *   La aplicacion cliente debe ajustar si necesita '&' standard.
 *
 * EJEMPLO:
 *   Entrada: 'Jose Garcia'
 *   Salida:  'Jos;eacute; Garc;iacute;a'
 *
 * CONSIDERACIONES:
 *   - La codificacion de caracteres depende del charset de la BD
 *   - Los caracteres que no coinciden se mantienen sin cambios
 *   - Si la BD usa UTF-8, los caracteres podrian verse como '?'
 *
 * MEJORAS v2.0:
 *   - Uso de TRANSLATE para mayor eficiencia (futuro)
 *   - Documentacion completa de conversiones
 *   - Variable con tamanio optimizado
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CAMBIA_ACENTOS(
    v_valor IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Variable de trabajo
    v_resultado VARCHAR2(32767);
    
BEGIN
    -- Inicializar con valor de entrada
    v_resultado := v_valor;
    
    -- Si la entrada es nula, retornar nulo
    IF v_resultado IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Convertir vocales acentuadas minusculas
    v_resultado := REPLACE(v_resultado, CHR(225), ';aacute;');  -- a acentuada
    v_resultado := REPLACE(v_resultado, CHR(233), ';eacute;');  -- e acentuada
    v_resultado := REPLACE(v_resultado, CHR(237), ';iacute;');  -- i acentuada
    v_resultado := REPLACE(v_resultado, CHR(243), ';oacute;');  -- o acentuada
    v_resultado := REPLACE(v_resultado, CHR(250), ';uacute;');  -- u acentuada
    v_resultado := REPLACE(v_resultado, CHR(241), ';ntilde;');  -- ene
    v_resultado := REPLACE(v_resultado, CHR(252), ';uuml;');    -- u dieresis
    
    -- Convertir vocales acentuadas mayusculas
    v_resultado := REPLACE(v_resultado, CHR(193), ';Aacute;');  -- A acentuada
    v_resultado := REPLACE(v_resultado, CHR(201), ';Eacute;');  -- E acentuada
    v_resultado := REPLACE(v_resultado, CHR(205), ';Iacute;');  -- I acentuada
    v_resultado := REPLACE(v_resultado, CHR(211), ';Oacute;');  -- O acentuada
    v_resultado := REPLACE(v_resultado, CHR(218), ';Uacute;');  -- U acentuada
    v_resultado := REPLACE(v_resultado, CHR(209), ';Ntilde;');  -- Ene
    v_resultado := REPLACE(v_resultado, CHR(220), ';Uuml;');    -- U dieresis
    
    RETURN v_resultado;
END CAMBIA_ACENTOS;
/

