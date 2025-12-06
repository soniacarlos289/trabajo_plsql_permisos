/*******************************************************************************
 * Función: NUMERO_VACACIONES_BOMBERO
 * 
 * Propósito:
 *   Cuenta el número de guardias de bombero dentro de un rango de fechas
 *   y retorna una cadena con el detalle de las guardias.
 *
 * @param D_FECHA_INICIO  Fecha inicial del período a consultar
 * @param D_FECHA_FIN     Fecha final del período a consultar
 * @param D_FUNCIONARIO   ID del funcionario bombero
 * @param V_numero        OUT: Número total de guardias encontradas
 * @return VARCHAR2       Cadena con listado de guardias ('Guardia: XXX -- ')
 *
 * Lógica:
 *   1. Busca guardias planificadas entre fechas indicadas
 *   2. Solo considera guardias posteriores a 2017001
 *   3. Concatena descripción de cada guardia
 *   4. Retorna contador en parámetro OUT
 *
 * Dependencias:
 *   - Tabla: bomberos_guardias_plani
 *
 * Consideraciones:
 *   - Fecha hardcodeada: 2017001 (considerar parametrizar)
 *   - Comparación de fechas con hora fija (08:00)
 *   - Cursor manual (considerar FOR LOOP)
 *
 * Mejoras aplicadas:
 *   - FOR LOOP en lugar de cursor manual
 *   - Constante para año de inicio
 *   - Variables inicializadas explícitamente
 *   - Uso de TRUNC() en lugar de TO_DATE(TO_CHAR())
 *   - Documentación JavaDoc completa
 *   - Simplificación de concatenación
 *
 * Historial:
 *   - 2025-12-06: Optimización y documentación (Grupo 7)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.NUMERO_VACACIONES_BOMBERO(
    D_FECHA_INICIO IN DATE,
    D_FECHA_FIN    IN DATE,
    D_FUNCIONARIO  IN VARCHAR2,
    V_numero       OUT NUMBER
) RETURN VARCHAR2 IS

    -- Constante para filtro de año
    C_ANO_INICIO   CONSTANT NUMBER := 2017001;
    C_HORA_INICIO  CONSTANT NUMBER := 8;  -- Hora de inicio de guardia (08:00)
    
    -- Variables
    Result          VARCHAR2(1256) := '';
    i_contador      NUMBER := 0;

BEGIN

    -- Buscar guardias en el rango de fechas usando FOR LOOP
    FOR rec IN (
        SELECT 'Guardia: ' || GUARDIA || ' -- ' AS guardia_desc
        FROM bomberos_guardias_plani
        WHERE desde BETWEEN TRUNC(D_FECHA_INICIO) + NUMTODSINTERVAL(C_HORA_INICIO, 'HOUR')
                        AND TRUNC(D_FECHA_FIN) + NUMTODSINTERVAL(C_HORA_INICIO, 'HOUR')
          AND SUBSTR(guardia, 1, 7) > C_ANO_INICIO
          AND funcionario = D_FUNCIONARIO
        ORDER BY guardia
    ) LOOP
        -- Concatenar guardias
        Result := Result || rec.guardia_desc;
        i_contador := i_contador + 1;
    END LOOP;
    
    -- Retornar contador en parámetro OUT
    V_numero := i_contador;
    
    RETURN Result;

END NUMERO_VACACIONES_BOMBERO;
/

