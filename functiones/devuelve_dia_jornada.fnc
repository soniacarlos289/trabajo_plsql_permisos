/*******************************************************************************
 * Función: DEVUELVE_DIA_JORNADA
 * 
 * Propósito:
 *   Extrae el valor correspondiente al día de la semana de una cadena de
 *   jornada semanal, ajustando según el contexto de ejecución (web o PL/SQL).
 *
 * @param V_CADENA  Cadena de 7 caracteres representando la jornada semanal
 *                  Formato: "LMMJVSD" donde cada posición es:
 *                  0 = día no laborable, número = horas de trabajo
 *                  Ejemplo: "8880000" = 8h Lu-Mi, 0h Ju-Do
 * @param ID_DIA    Fecha para la cual se extrae el valor
 * @return NUMBER   Valor extraído de la cadena (0 u horas de jornada)
 *
 * Lógica:
 *   1. Detecta el contexto de ejecución (web vs PL/SQL) usando día de referencia
 *   2. Obtiene el día de la semana de ID_DIA
 *   3. Ajusta el índice según el contexto (web empieza en domingo=1, PL/SQL en lunes=2)
 *   4. Extrae el carácter correspondiente de V_CADENA
 *   5. Retorna el valor numérico
 *
 * Dependencias:
 *   - Función: es_numero
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para fecha de referencia y ajustes
 *   - Eliminación de SELECT FROM DUAL innecesarios
 *   - Variables con nombres descriptivos
 *   - Simplificación de lógica de ajuste de día
 *   - Comentarios explicativos del formato de cadena
 *   - Documentación completa
 *
 * Nota sobre el ajuste de día:
 *   - En web (NLS_TERRITORY='AMERICA'): Domingo=1, Lunes=2, ..., Sábado=7
 *   - En PL/SQL (NLS_TERRITORY='SPAIN'): Lunes=1, Martes=2, ..., Domingo=7
 *   La fecha de referencia 07/01/2019 es un lunes, usada para detectar contexto
 *
 * Historial:
 *   - Original: Implementación con SELECT FROM DUAL
 *   - 2025: Optimización eliminando DUALs y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_DIA_JORNADA(
    V_CADENA VARCHAR2,
    ID_DIA   DATE
) RETURN NUMBER IS
    -- Constantes
    C_FECHA_REFERENCIA CONSTANT DATE   := TO_DATE('07/01/2019', 'DD/MM/YYYY'); -- Lunes
    C_DIA_LUNES_WEB    CONSTANT NUMBER := 2;  -- Lunes en web (territorio AMERICA)
    C_DIA_DOMINGO      CONSTANT NUMBER := 7;  -- Domingo ajustado
    C_AJUSTE_WEB       CONSTANT NUMBER := -1; -- Ajuste para formato web
    C_AJUSTE_PLSQL     CONSTANT NUMBER := 0;  -- Sin ajuste para PL/SQL
    
    -- Variables
    v_dia_referencia   NUMBER;
    v_dia_semana       NUMBER;
    v_ajuste           NUMBER;
    v_posicion         NUMBER;
    v_valor_dia        VARCHAR2(1);
    v_resultado        NUMBER;
    
BEGIN
    -- Detectar contexto de ejecución usando fecha de referencia (lunes)
    v_dia_referencia := TO_NUMBER(TO_CHAR(C_FECHA_REFERENCIA, 'D'));
    
    -- Determinar ajuste según contexto
    -- Si da 2, se ejecuta desde web (formato americano, domingo=1)
    -- Si da 1, se ejecuta desde PL/SQL (formato español, lunes=1)
    IF v_dia_referencia = C_DIA_LUNES_WEB THEN
        v_ajuste := C_AJUSTE_WEB;
    ELSE
        v_ajuste := C_AJUSTE_PLSQL;
    END IF;
    
    -- Obtener día de la semana de la fecha objetivo
    v_dia_semana := TO_NUMBER(TO_CHAR(ID_DIA, 'D'));
    
    -- Calcular posición en la cadena (1-7)
    v_posicion := v_dia_semana + v_ajuste;
    
    -- Ajustar si resulta 0 (domingo en formato web)
    IF v_posicion = 0 THEN
        v_posicion := C_DIA_DOMINGO;
    END IF;
    
    -- Extraer el carácter de la posición correspondiente
    v_valor_dia := SUBSTR(V_CADENA, v_posicion, 1);
    
    -- Convertir a número si es válido, sino retornar 0
    IF es_numero(v_valor_dia) = 1 THEN
        v_resultado := 0;
    ELSE
        v_resultado := TO_NUMBER(v_valor_dia);
    END IF;
    
    RETURN v_resultado;
    
END DEVUELVE_DIA_JORNADA;
/

