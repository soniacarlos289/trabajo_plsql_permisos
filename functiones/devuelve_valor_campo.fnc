/*******************************************************************************
 * Función: DEVUELVE_VALOR_CAMPO
 * 
 * Propósito:
 *   Extrae el valor de un campo específico de una cadena formateada con
 *   delimitador punto y coma (;). Formato esperado: "CAMPO1valor1;CAMPO2valor2;"
 *
 * @param v_cadena  Cadena con campos delimitados por ';'
 * @param v_campo   Nombre del campo a buscar (incluir con formato como aparece)
 * @return VARCHAR2 Valor del campo extraído, o cadena vacía si no se encuentra
 *
 * Lógica:
 *   1. Buscar la posición del nombre del campo
 *   2. El valor comienza después del nombre del campo
 *   3. El valor termina en el siguiente ';'
 *   4. Extraer substring entre inicio y fin
 *
 * Ejemplo:
 *   Entrada: 'FI01/01/2025;FF31/01/2025;'
 *   Campo: 'FI'
 *   Salida: '01/01/2025'
 *
 * Dependencias:
 *   Ninguna
 *
 * Consideraciones:
 *   - Si el campo no existe, retorna cadena vacía
 *   - El formato de campo debe coincidir exactamente con el parámetro v_campo
 *   - Función similar a devuelve_valor_campo_agenda pero con delimitador diferente
 *
 * Mejoras aplicadas:
 *   - Constantes para el delimitador
 *   - Variables con nombres descriptivos
 *   - Documentación completa con ejemplo
 *   - Manejo explícito del caso cuando no se encuentra el campo
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_VALOR_CAMPO
  (v_cadena IN VARCHAR2, v_campo IN VARCHAR2) 
RETURN VARCHAR2 IS
    -- Constantes
    C_DELIMITADOR      CONSTANT VARCHAR2(1) := ';';
    C_CADENA_VACIA     CONSTANT VARCHAR2(1) := '';
    
    -- Variables
    v_result           VARCHAR2(122);
    v_pos_inicio       NUMBER;
    v_pos_fin          NUMBER;
    
BEGIN
    -- Buscar la posición donde comienza el valor (después del nombre del campo)
    v_pos_inicio := INSTR(v_cadena, v_campo, 1, 1) + LENGTH(v_campo);
    
    -- Buscar la posición del siguiente delimitador
    v_pos_fin := INSTR(v_cadena, C_DELIMITADOR, v_pos_inicio, 1);
    
    -- Extraer el valor si se encontró
    IF v_pos_fin - v_pos_inicio > 0 THEN
        v_result := SUBSTR(v_cadena, v_pos_inicio, v_pos_fin - v_pos_inicio);
    ELSE
        v_result := C_CADENA_VACIA;
    END IF;
    
    RETURN v_result;
    
END DEVUELVE_VALOR_CAMPO;
/

