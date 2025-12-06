/*******************************************************************************
 * Función: HORAS_FICHAES_POLICIA_MES
 * 
 * Propósito:
 *   Calcula el total de horas fichadas por un funcionario de policía en un mes
 *   específico de un año. Retorna el resultado formateado como HH:MM.
 *
 * @param i_ID_FUNCIONARIO  ID del funcionario a consultar
 * @param i_MES             Número de mes (1-12), o 13 para todo el año
 * @param i_id_Anno         Año a consultar
 * 
 * @return VARCHAR2  Total de horas en formato HH:MM (ej: "175:30")
 *
 * Lógica:
 *   1. Calcula el año siguiente para definir rango de fechas
 *   2. Busca fichajes del funcionario en el año especificado
 *   3. Filtra por mes específico (o todo el año si i_mes=13)
 *   4. Suma las horas fichadas totales
 *   5. Convierte minutos totales a formato HH:MM usando devuelve_min_fto_hora
 *
 * Dependencias:
 *   - Tabla: FICHAJE_FUNCIONARIO (id_funcionario, fecha_fichaje_entrada, horas_fichadas)
 *   - Tabla: personal_new (id_funcionario)
 *   - Función: devuelve_min_fto_hora (convierte minutos a formato HH:MM)
 *
 * Consideraciones:
 *   - horas_fichadas se asume en minutos
 *   - Valor 13 en i_mes representa "todo el año"
 *   - El rango de fechas incluye todo el año desde 01/01 hasta 01/01 del año siguiente
 *   - Si no hay datos, retorna "0:00"
 *
 * Mejoras aplicadas:
 *   - Eliminación de conversión redundante TO_DATE(TO_CHAR(fecha))
 *   - Uso de TRUNC para comparaciones de fecha sin hora
 *   - Constantes nombradas para valores especiales
 *   - INNER JOIN explícito en lugar de comas en FROM
 *   - Variables inicializadas explícitamente
 *   - Documentación completa JavaDoc
 *   - Variables con nombres descriptivos
 *   - Uso de TO_DATE directo con año concatenado
 *
 * Historial:
 *   - 2025-12: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.HORAS_FICHAES_POLICIA_MES(
    i_ID_FUNCIONARIO IN VARCHAR2,
    i_MES IN NUMBER,
    i_id_Anno IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes
    C_MES_TODO_ANNO CONSTANT NUMBER := 13;
    C_MINUTOS_INICIAL CONSTANT NUMBER := 0;
    
    -- Variables
    v_anno_siguiente NUMBER;
    v_total_minutos NUMBER := C_MINUTOS_INICIAL;
    v_fecha_inicio DATE;
    v_fecha_fin DATE;
    v_resultado VARCHAR2(100);
    
BEGIN
    -- Calcular año siguiente para rango de fechas
    v_anno_siguiente := i_id_Anno + 1;
    
    -- Construir fechas de inicio y fin del rango
    v_fecha_inicio := TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY');
    v_fecha_fin := TO_DATE('01/01/' || v_anno_siguiente, 'DD/MM/YYYY');
    
    -- Sumar horas fichadas del funcionario en el período
    BEGIN
        SELECT SUM(fc.horas_fichadas)
        INTO v_total_minutos
        FROM FICHAJE_FUNCIONARIO fc
        INNER JOIN personal_new f ON fc.id_funcionario = f.id_funcionario
        WHERE TRUNC(fc.fecha_fichaje_entrada) BETWEEN v_fecha_inicio AND v_fecha_fin
            AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = TO_CHAR(i_MES, 'FM00')
                 OR i_MES = C_MES_TODO_ANNO)
            AND fc.id_funcionario = i_ID_FUNCIONARIO;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_total_minutos := C_MINUTOS_INICIAL;
    END;
    
    -- Convertir minutos a formato HH:MM
    v_resultado := devuelve_min_fto_hora(v_total_minutos);
    
    RETURN v_resultado;
    
END HORAS_FICHAES_POLICIA_MES;
/

