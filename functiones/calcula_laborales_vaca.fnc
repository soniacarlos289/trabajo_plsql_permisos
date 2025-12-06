/**
 * ==============================================================================
 * Funcion: CALCULA_LABORALES_VACA
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Calcula el total de dias laborales de vacaciones de un funcionario,
 *   sumando los dias del periodo solicitado mas los dias de permisos
 *   de vacaciones ya concedidos en el anio.
 *
 * PARAMETROS:
 *   @param D_FECHA_INICIO (DATE) - Fecha inicio del periodo a calcular
 *   @param D_FECHA_FIN (DATE) - Fecha fin del periodo a calcular
 *   @param V_TIPO_DIA (VARCHAR2) - Tipo de dia (no utilizado actualmente)
 *   @param V_ID_FUNCIONARIO (NUMBER) - Identificador del funcionario
 *   @param V_ID_ANO (NUMBER) - Anio del ejercicio de vacaciones
 *
 * RETORNO:
 *   @return NUMBER - Total de dias laborales de vacaciones:
 *                    dias_periodo + dias_permisos_existentes
 *                    Maximo 22 dias para mes completo.
 *
 * LOGICA:
 *   1. Obtener dias de permisos de vacaciones (01000) ya concedidos
 *      - Convierte dias naturales a laborales (resta fines de semana)
 *      - Excluye permisos anulados y en estados de rechazo
 *   2. Calcular dias laborales del periodo solicitado
 *   3. Sumar ambos valores
 *   4. Aplicar regla de mes completo: maximo 22 dias
 *
 * REGLAS DE NEGOCIO:
 *   - Permiso tipo 01000 = Vacaciones
 *   - Estados excluidos: 30,31,32 (rechazados) y 40,41 (cancelados)
 *   - Conversion N->L: dias - (dias/7)*2 (descuenta fines de semana)
 *   - Mes completo = 22 dias laborales maximo
 *
 * DEPENDENCIAS:
 *   - Tabla PERMISO: Registro de permisos de funcionarios
 *   - Funcion CALCULA_DIAS: Calculo de dias laborales
 *
 * CONSIDERACIONES:
 *   - La logica de mes completo asume calendario estandar de 22 dias
 *   - La conversion N->L es aproximada (no considera festivos)
 *
 * MEJORAS v2.0:
 *   - Uso de constantes para codigos y estados
 *   - Simplificacion de condiciones de mes completo
 *   - Documentacion de reglas de negocio
 *   - Codigo mas legible
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.CALCULA_LABORALES_VACA(
    D_FECHA_INICIO   IN DATE,
    D_FECHA_FIN      IN DATE,
    V_TIPO_DIA       IN VARCHAR2,
    V_ID_FUNCIONARIO IN NUMBER,
    V_ID_ANO         IN NUMBER
) RETURN NUMBER IS
    -- Constantes
    C_TIPO_VACACIONES    CONSTANT VARCHAR2(5) := '01000';
    C_TIPO_DIA_NATURAL   CONSTANT VARCHAR2(1) := 'N';
    C_ANULADO_NO         CONSTANT VARCHAR2(2) := 'NO';
    C_MAX_DIAS_MES       CONSTANT NUMBER := 22;
    C_DIAS_LABORAL_23    CONSTANT NUMBER := 23;
    C_TIPO_LABORAL       CONSTANT VARCHAR2(1) := 'L';
    
    -- Variables de trabajo
    v_dias_permisos_va   NUMBER := 0;
    v_dias_periodo       NUMBER;
    v_result             NUMBER;
    
BEGIN
    -- Obtener suma de dias de permisos de vacaciones existentes
    BEGIN
        SELECT NVL(SUM(
            CASE 
                WHEN id_tipo_dias = C_TIPO_DIA_NATURAL THEN 
                    num_dias - TRUNC(num_dias / 7) * 2
                ELSE 
                    num_dias 
            END
        ), 0)
          INTO v_dias_permisos_va
          FROM permiso
         WHERE id_funcionario = V_ID_FUNCIONARIO
           AND id_tipo_permiso = C_TIPO_VACACIONES
           AND id_ano = V_ID_ANO
           AND (anulado = C_ANULADO_NO OR anulado IS NULL)
           AND id_estado NOT IN ('30', '31', '32', '40', '41');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_dias_permisos_va := 0;
    END;
    
    -- Calcular dias laborales del periodo solicitado
    v_dias_periodo := CALCULA_DIAS(D_FECHA_INICIO, D_FECHA_FIN, C_TIPO_LABORAL);
    
    -- Sumar dias
    v_result := v_dias_periodo + v_dias_permisos_va;
    
    -- Regla de mes completo: si no hay permisos previos y son 23 dias, ajustar a 22
    IF v_dias_permisos_va = 0 AND v_dias_periodo = C_DIAS_LABORAL_23 THEN
        v_result := C_MAX_DIAS_MES;
    END IF;
    
    -- Limitar a maximo de dias de mes completo
    IF v_result > C_MAX_DIAS_MES THEN
        v_result := C_MAX_DIAS_MES;
    END IF;
    
    RETURN v_result;
END CALCULA_LABORALES_VACA;
/

