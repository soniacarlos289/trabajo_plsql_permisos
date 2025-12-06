/**
 * ==============================================================================
 * Funcion: CALCULA_ANT_POST
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Calcula el dia laboral mas cercano anterior o posterior a una fecha dada,
 *   consultando el calendario laboral del sistema. Util para determinar
 *   dias habiles en procesos de permisos y vacaciones.
 *
 * PARAMETROS:
 *   @param v_FECHA (DATE) - Fecha de referencia desde la cual se busca
 *   @param TIPO (VARCHAR2) - Tipo de busqueda:
 *                            'A' = Anterior (busca el dia laboral previo)
 *                            'P' = Posterior (busca el dia laboral siguiente)
 *
 * RETORNO:
 *   @return DATE - Fecha del dia laboral encontrado.
 *                  NULL si no existe dia laboral en el rango de 8 dias.
 *
 * LOGICA:
 *   - Para TIPO='A': Busca el MAX(id_dia) laboral en los 8 dias anteriores
 *   - Para TIPO='P': Busca el MIN(id_dia) laboral en los 8 dias posteriores
 *   - El rango de 8 dias cubre posibles festivos consecutivos (ej: Semana Santa)
 *
 * DEPENDENCIAS:
 *   - Tabla CALENDARIO_LABORAL: Contiene los dias del anio con indicador de
 *     si es laboral ('SI') o festivo ('NO')
 *
 * CONSIDERACIONES:
 *   - El rango de busqueda de 8 dias asume que no habra mas de 7 dias
 *     festivos consecutivos (incluidos fines de semana)
 *   - Si no hay dias laborales en el rango, retorna NULL
 *
 * MEJORAS v2.0:
 *   - Uso de constantes para valores magicos
 *   - Documentacion completa
 *   - Mejor formato y legibilidad del SQL
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.CALCULA_ANT_POST(
    v_FECHA IN DATE,
    TIPO    IN VARCHAR2
) RETURN DATE IS
    -- Constantes
    C_TIPO_ANTERIOR  CONSTANT VARCHAR2(1) := 'A';
    C_RANGO_BUSQUEDA CONSTANT NUMBER := 8;
    C_ES_LABORAL     CONSTANT VARCHAR2(2) := 'SI';
    
    -- Variable de resultado
    v_result DATE;
    
BEGIN
    IF TIPO = C_TIPO_ANTERIOR THEN
        -- Buscar el dia laboral anterior mas cercano (maximo en el rango)
        SELECT MAX(id_dia)
          INTO v_result
          FROM calendario_laboral
         WHERE id_dia BETWEEN v_FECHA - C_RANGO_BUSQUEDA AND v_FECHA - 1
           AND laboral = C_ES_LABORAL;
    ELSE
        -- Buscar el dia laboral posterior mas cercano (minimo en el rango)
        SELECT MIN(id_dia)
          INTO v_result
          FROM calendario_laboral
         WHERE id_dia BETWEEN v_FECHA + 1 AND v_FECHA + C_RANGO_BUSQUEDA
           AND laboral = C_ES_LABORAL;
    END IF;
    
    RETURN v_result;
END CALCULA_ANT_POST;
/

