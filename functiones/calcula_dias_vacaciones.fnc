/**
 * ==============================================================================
 * Funcion: CALCULA_DIAS_VACACIONES
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Calcula el numero de dias laborales de vacaciones dentro de un periodo
 *   especifico, ajustando las fechas del permiso para que queden dentro
 *   del rango permitido.
 *
 * PARAMETROS:
 *   @param D_FECHA_INICIO (DATE) - Fecha inicio del permiso de vacaciones
 *   @param D_FECHA_FIN (DATE) - Fecha fin del permiso de vacaciones
 *   @param V_TIPO_DIA (VARCHAR2) - Tipo de dia. NOTA: Este parametro se mantiene
 *                                   por compatibilidad con llamadas existentes pero
 *                                   no se utiliza actualmente. La funcion siempre
 *                                   calcula dias laborales ('L').
 *   @param D_INICIO (DATE) - Fecha inicio del periodo permitido
 *   @param D_FIN (DATE) - Fecha fin del periodo permitido
 *
 * RETORNO:
 *   @return NUMBER - Numero de dias laborales de vacaciones dentro del
 *                    periodo permitido.
 *
 * LOGICA:
 *   1. Ajustar fecha inicio: usa D_INICIO si D_FECHA_INICIO es anterior
 *   2. Ajustar fecha fin: usa D_FIN si D_FECHA_FIN es posterior
 *   3. Calcular dias laborales en el rango ajustado usando CALCULA_DIAS
 *
 * EJEMPLO:
 *   Periodo permitido: 01-ENE-2025 a 31-DIC-2025
 *   Permiso solicitado: 20-DIC-2024 a 05-ENE-2025
 *   Rango calculado: 01-ENE-2025 a 05-ENE-2025 (3 dias laborales aprox)
 *
 * DEPENDENCIAS:
 *   - Funcion CALCULA_DIAS: Calculo de dias laborales
 *
 * CONSIDERACIONES:
 *   - Siempre calcula dias laborales ('L'), ignora V_TIPO_DIA
 *   - Si el permiso esta completamente fuera del periodo, retorna 0
 *
 * MEJORAS v2.0:
 *   - Uso de funciones GREATEST/LEAST para simplificar ajuste de fechas
 *   - Documentacion completa
 *   - Codigo mas compacto y legible
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.CALCULA_DIAS_VACACIONES(
    D_FECHA_INICIO IN DATE,
    D_FECHA_FIN    IN DATE,
    V_TIPO_DIA     IN VARCHAR2,
    D_INICIO       IN DATE,
    D_FIN          IN DATE
) RETURN NUMBER IS
    -- Constante para tipo de calculo
    C_TIPO_LABORAL CONSTANT VARCHAR2(1) := 'L';
    
    -- Variables ajustadas
    v_fecha_inicio_ajustada DATE;
    v_fecha_fin_ajustada    DATE;
    v_result                NUMBER;
    
BEGIN
    -- Ajustar fecha inicio al maximo entre la fecha del permiso y el inicio del periodo
    v_fecha_inicio_ajustada := GREATEST(D_FECHA_INICIO, D_INICIO);
    
    -- Ajustar fecha fin al minimo entre la fecha del permiso y el fin del periodo
    v_fecha_fin_ajustada := LEAST(D_FECHA_FIN, D_FIN);
    
    -- Calcular dias laborales en el rango ajustado
    v_result := CALCULA_DIAS(v_fecha_inicio_ajustada, v_fecha_fin_ajustada, C_TIPO_LABORAL);
    
    RETURN v_result;
END CALCULA_DIAS_VACACIONES;
/

