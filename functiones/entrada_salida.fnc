/*******************************************************************************
 * Función: ENTRADA_SALIDA
 * 
 * Propósito:
 *   Determina si el próximo fichaje de un empleado debe ser de entrada o salida,
 *   basándose en el número de transacciones registradas hoy. Usa MOD para 
 *   alternar: impar=Entrada, par=Salida.
 *
 * @param vpin      PIN del empleado
 * @return VARCHAR2 'Entrada' si el siguiente fichaje es entrada, 'Salida' si es salida
 *
 * Lógica:
 *   1. Contar transacciones válidas del empleado hoy
 *   2. Si el conteo es impar: próximo fichaje es "Entrada"
 *   3. Si el conteo es par: próximo fichaje es "Salida"
 *   4. Filtrar transacciones con numserie!=0 y pin!='0000'
 *
 * Dependencias:
 *   - Tabla: transacciones (pin, fecha, numserie)
 *
 * Consideraciones:
 *   - Asume que el primer fichaje del día es entrada
 *   - Filtra transacciones inválidas (numserie=0, pin='0000')
 *   - TRUNC removido de fecha ya que TO_DATE ya trunca la hora
 *
 * Mejoras aplicadas:
 *   - Constantes para valores de filtro
 *   - Constantes para resultado
 *   - TRUNC en SYSDATE para garantizar fecha sin hora
 *   - Variables con nombres descriptivos
 *   - Documentación completa
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.ENTRADA_SALIDA(
    vpin VARCHAR2
) 
RETURN VARCHAR2 IS
    -- Constantes
    C_PIN_INVALIDO     CONSTANT VARCHAR2(4) := '0000';
    C_SERIE_INVALIDA   CONSTANT NUMBER := 0;
    C_RESULTADO_ENTRADA CONSTANT VARCHAR2(7) := 'Entrada';
    C_RESULTADO_SALIDA  CONSTANT VARCHAR2(6) := 'Salida';
    C_MOD_DIVISOR      CONSTANT NUMBER := 2;
    C_MOD_IMPAR        CONSTANT NUMBER := 1;
    
    -- Variables
    v_result           VARCHAR2(1024);
    v_fecha_hoy        DATE;
    
BEGIN
    -- Obtener fecha actual truncada (sin hora)
    v_fecha_hoy := TRUNC(SYSDATE);
    
    -- Determinar si siguiente fichaje es entrada o salida
    SELECT CASE MOD(COUNT(*), C_MOD_DIVISOR)
               WHEN C_MOD_IMPAR THEN C_RESULTADO_ENTRADA
               ELSE C_RESULTADO_SALIDA
           END
    INTO v_result
    FROM transacciones t
    WHERE t.pin = vpin
      AND t.fecha = v_fecha_hoy
      AND t.numserie != C_SERIE_INVALIDA
      AND t.pin != C_PIN_INVALIDO;
    
    RETURN v_result;
    
END ENTRADA_SALIDA;
/

