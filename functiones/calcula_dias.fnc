/**
 * ==============================================================================
 * Funcion: CALCULA_DIAS
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Calcula el numero de dias entre dos fechas, pudiendo contar solo
 *   dias laborales o todos los dias naturales del rango, segun el
 *   tipo de calculo solicitado.
 *
 * PARAMETROS:
 *   @param D_FECHA_INICIO (DATE) - Fecha de inicio del rango (inclusive)
 *   @param D_FECHA_FIN (DATE) - Fecha de fin del rango (inclusive)
 *   @param V_CADENA (VARCHAR2) - Tipo de calculo:
 *                                'L' = Solo dias Laborales
 *                                'N' = Dias Naturales (todos los dias)
 *
 * RETORNO:
 *   @return NUMBER - Numero de dias calculados:
 *                    - Para tipo 'L': count-1 (minimo 1 si count > 0)
 *                    - Para tipo 'N': count total de dias
 *                    - 0 si el resultado seria negativo
 *
 * LOGICA:
 *   - Tipo 'L' (Laborales):
 *     1. Cuenta dias en calendario_laboral donde laboral='SI'
 *     2. Resta 1 al resultado (convencion de conteo de permisos)
 *     3. Si el resultado es 0 (1 dia laboral), retorna 1
 *   - Tipo 'N' (Naturales):
 *     1. Cuenta todos los dias en el calendario_laboral
 *     2. Retorna el conteo directo
 *
 * DEPENDENCIAS:
 *   - Tabla rrhh.CALENDARIO_LABORAL: Calendario con marcador de laboralidad
 *
 * CONSIDERACIONES:
 *   - El ajuste de -1 en dias laborales sigue la convencion del sistema
 *     donde un permiso de 1 dia laboral se cuenta como 1, no 2
 *   - Si V_CADENA no es 'L' ni 'N', no se realiza calculo (Result=NULL)
 *
 * MEJORAS v2.0:
 *   - Uso de constantes para tipos de calculo
 *   - Manejo explicito de valor minimo
 *   - Estructura CASE para mejor legibilidad
 *   - Documentacion completa
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.CALCULA_DIAS(
    D_FECHA_INICIO IN DATE,
    D_FECHA_FIN    IN DATE,
    V_CADENA       IN VARCHAR2
) RETURN NUMBER IS
    -- Constantes
    C_TIPO_LABORAL  CONSTANT VARCHAR2(1) := 'L';
    C_TIPO_NATURAL  CONSTANT VARCHAR2(1) := 'N';
    C_ES_LABORAL    CONSTANT VARCHAR2(2) := 'SI';
    C_MIN_DIAS      CONSTANT NUMBER := 1;
    
    -- Variable de resultado
    v_result NUMBER;
    
BEGIN
    IF V_CADENA = C_TIPO_LABORAL THEN
        -- Contar dias laborales
        SELECT COUNT(*) - 1
          INTO v_result
          FROM rrhh.calendario_laboral
         WHERE id_dia BETWEEN D_FECHA_INICIO AND D_FECHA_FIN
           AND laboral = C_ES_LABORAL;
        
        -- Asegurar minimo de 1 dia si hay al menos un dia laboral
        IF v_result = 0 THEN
            v_result := C_MIN_DIAS;
        END IF;
        
    ELSIF V_CADENA = C_TIPO_NATURAL THEN
        -- Contar todos los dias
        SELECT COUNT(*)
          INTO v_result
          FROM rrhh.calendario_laboral
         WHERE id_dia BETWEEN D_FECHA_INICIO AND D_FECHA_FIN;
    END IF;
    
    -- Asegurar que no se retornen valores negativos
    IF v_result < 0 THEN
        v_result := 0;
    END IF;
    
    RETURN v_result;
END CALCULA_DIAS;
/

