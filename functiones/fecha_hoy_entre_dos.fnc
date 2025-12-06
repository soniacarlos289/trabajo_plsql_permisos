/*******************************************************************************
 * Función: FECHA_HOY_ENTRE_DOS
 * 
 * Propósito:
 *   Verifica si la fecha actual (hoy) está dentro de un rango de fechas dado.
 *   Retorna 1 si está dentro del rango, 0 si no lo está.
 *
 * @param fecha_1   Fecha inicio del rango
 * @param fecha_2   Fecha fin del rango
 * @return VARCHAR2 '1' si hoy está en el rango, '0' si no lo está
 *
 * Lógica:
 *   1. Comparar SYSDATE truncado contra el rango [fecha_1, fecha_2]
 *   2. Si está dentro: retornar 1
 *   3. Si está fuera: retornar 0
 *
 * Ejemplo:
 *   fecha_hoy_entre_dos('01/01/2025', '31/12/2025') -> '1' (si estamos en 2025)
 *   fecha_hoy_entre_dos('01/01/2024', '31/12/2024') -> '0' (si estamos en 2025)
 *
 * Dependencias:
 *   Ninguna
 *
 * Consideraciones:
 *   - SELECT FROM DUAL innecesario, puede hacerse con lógica PL/SQL directa
 *   - Retorna VARCHAR2 en lugar de NUMBER (inconsistente)
 *   - Inicialización redundante de i_cuenta
 *
 * Mejoras aplicadas:
 *   - Eliminación de SELECT FROM DUAL
 *   - Constantes para valores de retorno
 *   - TRUNC para comparación de fechas sin hora
 *   - Lógica directa con IF en lugar de SELECT/EXCEPTION
 *   - Documentación completa
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.FECHA_HOY_ENTRE_DOS(
    fecha_1 DATE,
    fecha_2 DATE
) 
RETURN VARCHAR2 IS
    -- Constantes
    C_EN_RANGO     CONSTANT VARCHAR2(1) := '1';
    C_FUERA_RANGO  CONSTANT VARCHAR2(1) := '0';
    
    -- Variables
    v_resultado    VARCHAR2(1);
    v_hoy          DATE;
    
BEGIN
    -- Obtener fecha actual sin hora
    v_hoy := TRUNC(SYSDATE);
    
    -- Verificar si está en el rango
    IF v_hoy BETWEEN fecha_1 AND fecha_2 THEN
        v_resultado := C_EN_RANGO;
    ELSE
        v_resultado := C_FUERA_RANGO;
    END IF;
    
    RETURN v_resultado;
    
END FECHA_HOY_ENTRE_DOS;
/

