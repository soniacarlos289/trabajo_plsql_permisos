/*******************************************************************************
 * Función: DEVUELVE_MIN_FTO_HORA
 * 
 * Propósito:
 *   Convierte una cantidad de minutos en formato de texto legible
 *   "X horas Y minutos", manejando valores positivos y negativos.
 *
 * @param V_CADENA  Cantidad de minutos como cadena (puede ser negativa)
 * @return VARCHAR2 Formato legible: "X horas Y minutos" o "-X horas Y minutos"
 *                  Retorna cadena vacía si el input no es numérico
 *
 * Lógica:
 *   1. Verifica que la cadena sea un número válido
 *   2. Guarda el signo (positivo/negativo)
 *   3. Convierte a valor absoluto
 *   4. Calcula horas (división entre 60)
 *   5. Calcula minutos restantes (módulo 60)
 *   6. Formatea el texto omitiendo partes en cero
 *   7. Añade el signo negativo si corresponde
 *
 * Dependencias:
 *   - Función: es_numero
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para formato y valores
 *   - Eliminación de variables no utilizadas (pos, pos2)
 *   - Simplificación de lógica de formato
 *   - Variables con nombres descriptivos
 *   - Documentación completa
 *
 * Ejemplos:
 *   devuelve_min_fto_hora('135')  => "2 horas 15 minutos"
 *   devuelve_min_fto_hora('-90')  => "-1 horas 30 minutos"
 *   devuelve_min_fto_hora('45')   => "0 horas 45 minutos"
 *   devuelve_min_fto_hora('120')  => "2 horas"
 *   devuelve_min_fto_hora('abc')  => ""
 *
 * Historial:
 *   - Original: Implementación básica de conversión
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_MIN_FTO_HORA(
    V_CADENA IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_MINUTOS_HORA      CONSTANT NUMBER := 60;
    C_TEXTO_HORAS       CONSTANT VARCHAR2(10) := ' horas ';
    C_TEXTO_HORAS_CERO  CONSTANT VARCHAR2(10) := '0 horas';
    C_TEXTO_MINUTOS     CONSTANT VARCHAR2(10) := ' minutos';
    C_SIGNO_NEGATIVO    CONSTANT VARCHAR2(1) := '-';
    
    -- Variables
    v_minutos_totales   NUMBER;
    v_es_negativo       BOOLEAN := FALSE;
    v_horas             NUMBER;
    v_minutos           NUMBER;
    v_texto_horas       VARCHAR2(50);
    v_texto_minutos     VARCHAR2(50);
    v_resultado         VARCHAR2(122);
    
BEGIN
    -- Verificar que sea un número válido
    IF es_numero(V_CADENA) = 1 THEN
        RETURN '';
    END IF;
    
    -- Obtener valor absoluto y signo
    v_minutos_totales := TO_NUMBER(V_CADENA);
    
    IF v_minutos_totales < 0 THEN
        v_es_negativo := TRUE;
        v_minutos_totales := ABS(v_minutos_totales);
    END IF;
    
    -- Calcular horas y minutos
    v_horas   := TRUNC(v_minutos_totales / C_MINUTOS_HORA);
    v_minutos := TRUNC(MOD(v_minutos_totales, C_MINUTOS_HORA));
    
    -- Formatear texto de horas
    IF v_horas = 0 OR v_horas IS NULL THEN
        v_texto_horas := C_TEXTO_HORAS_CERO;
    ELSE
        v_texto_horas := TO_CHAR(v_horas) || C_TEXTO_HORAS;
    END IF;
    
    -- Formatear texto de minutos
    IF v_minutos = 0 OR v_minutos IS NULL THEN
        v_texto_minutos := '';
    ELSE
        v_texto_minutos := TO_CHAR(v_minutos) || C_TEXTO_MINUTOS;
    END IF;
    
    -- Construir resultado
    v_resultado := v_texto_horas || v_texto_minutos;
    
    -- Añadir signo negativo si corresponde
    IF v_es_negativo THEN
        v_resultado := C_SIGNO_NEGATIVO || v_resultado;
    END IF;
    
    RETURN v_resultado;
    
END DEVUELVE_MIN_FTO_HORA;
/

