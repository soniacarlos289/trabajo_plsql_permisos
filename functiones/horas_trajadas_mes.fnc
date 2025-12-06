/*******************************************************************************
 * Función: HORAS_TRAJADAS_MES
 * 
 * Propósito:
 *   Calcula el total de horas trabajadas por un funcionario en un mes específico
 *   o en todo un año. Maneja diferentes tipos de funcionarios (personal regular
 *   y bomberos) con lógicas de cálculo específicas para cada uno.
 *
 * @param i_ID_FUNCIONARIO     ID del funcionario a consultar
 * @param ID_TIPO_FUNCIONARIO  Tipo de funcionario (23=Bombero, otros=Regular)
 * @param i_MES                Mes a consultar (1-12) o 13 para todo el año
 * @param i_id_Anno            Año a consultar
 * @return VARCHAR2            Horas trabajadas en formato HH:MM
 *
 * Ejemplos de uso:
 *   -- Obtener horas trabajadas de un funcionario regular en enero 2025
 *   SELECT HORAS_TRAJADAS_MES('12345', 21, 1, 2025) FROM DUAL;
 *
 *   -- Obtener horas trabajadas de un bombero en todo el año 2025
 *   SELECT HORAS_TRAJADAS_MES('67890', 23, 13, 2025) FROM DUAL;
 *
 * Lógica:
 *   1. Si es funcionario regular (tipo <> 23):
 *      - Suma horas_fichadas de FICHAJE_FUNCIONARIO
 *      - Filtra por fecha de entrada en el rango especificado
 *      - Solo incluye personal activo (sin fecha_fin_contrato o futura)
 *   2. Si es bombero (tipo = 23):
 *      - Calcula minutos trabajados de BOMBEROS_GUARDIAS_PLANI
 *      - Excluye períodos con permisos aprobados (estado 80)
 *      - Convierte días a minutos (hasta-desde) * 24 * 60
 *   3. Convierte el total de minutos a formato HH:MM usando devuelve_min_fto_hora
 *
 * Dependencias:
 *   - Tabla: FICHAJE_FUNCIONARIO
 *   - Tabla: personal_new
 *   - Tabla: BOMBEROS_GUARDIAS_PLANI
 *   - Tabla: permiso
 *   - Función: devuelve_min_fto_hora (convierte minutos a formato HH:MM)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa con ejemplos
 *   - Eliminación de TO_DATE(TO_CHAR()) innecesarios, uso de TRUNC
 *   - Uso de INNER JOIN explícito en lugar de sintaxis antigua con comas
 *   - Constantes nombradas para valores mágicos (tipo bombero, mes anual, estado)
 *   - Inicialización explícita de variables
 *   - CASE en lugar de DECODE para mejor legibilidad
 *   - NVL para manejar casos sin datos
 *   - Eliminación de variables no utilizadas (i_resultado)
 *   - Comentarios explicativos en cada sección
 *
 * Notas:
 *   - El mes 13 es un valor especial que indica "todo el año"
 *   - Para bomberos, se excluyen períodos con permisos aprobados
 *   - Los funcionarios con fecha_fin_contrato pasada no se incluyen
 *
 * Historial:
 *   - Original: Sin documentación, JOIN implícito, conversiones ineficientes
 *   - 2025-12: Optimización y documentación completa
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.HORAS_TRAJADAS_MES(
    i_ID_FUNCIONARIO     IN VARCHAR2,
    ID_TIPO_FUNCIONARIO  IN NUMBER,
    i_MES                IN NUMBER,
    i_id_Anno            IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes
    C_TIPO_BOMBERO    CONSTANT NUMBER := 23;
    C_MES_ANUAL       CONSTANT NUMBER := 13;  -- Indica todo el año
    C_ESTADO_APROBADO CONSTANT NUMBER := 80;
    C_HORAS_DIA       CONSTANT NUMBER := 24;
    C_MINUTOS_HORA    CONSTANT NUMBER := 60;
    
    -- Variables
    v_total_minutos   NUMBER := 0;
    v_fecha_inicio    DATE;
    v_fecha_fin       DATE;
    v_resultado       VARCHAR2(100);
    
BEGIN
    -- Calcular rango de fechas para el año especificado
    v_fecha_inicio := TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY');
    v_fecha_fin    := TO_DATE('01/01/' || (i_id_Anno + 1), 'DD/MM/YYYY');
    
    -- Calcular horas trabajadas según tipo de funcionario
    IF ID_TIPO_FUNCIONARIO <> C_TIPO_BOMBERO THEN
        -- Funcionario regular: sumar horas fichadas
        BEGIN
            SELECT NVL(SUM(horas_fichadas), 0)
            INTO v_total_minutos
            FROM FICHAJE_FUNCIONARIO fc
            INNER JOIN personal_new f 
                ON fc.id_funcionario = f.id_funcionario
            WHERE TRUNC(fc.fecha_fichaje_entrada) BETWEEN v_fecha_inicio 
                                                      AND v_fecha_fin - 1
              AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = TO_CHAR(i_MES, 'FM00') 
                   OR i_MES = C_MES_ANUAL)
              AND fc.id_funcionario = i_ID_FUNCIONARIO
              AND (f.fecha_fin_contrato IS NULL 
                   OR f.fecha_fin_contrato > SYSDATE);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_total_minutos := 0;
        END;
    ELSE
        -- Bombero: calcular minutos de guardias, excluyendo permisos
        BEGIN
            SELECT NVL(SUM(
                       CASE 
                           WHEN p.id_tipo_permiso IS NULL THEN
                               -- Sin permiso: calcular minutos trabajados
                               (b.hasta - b.desde) * C_HORAS_DIA * C_MINUTOS_HORA
                           ELSE
                               -- Con permiso aprobado: no contar
                               0
                       END
                   ), 0)
            INTO v_total_minutos
            FROM BOMBEROS_GUARDIAS_PLANI b
            LEFT JOIN permiso p 
                ON b.funcionario = p.id_funcionario
               AND b.hasta BETWEEN p.fecha_inicio - 1 AND p.fecha_fin + 1
               AND p.id_estado = C_ESTADO_APROBADO
            WHERE b.hasta BETWEEN v_fecha_inicio AND v_fecha_fin - 1
              AND (TO_CHAR(b.hasta, 'MM') = TO_CHAR(i_MES, 'FM00') 
                   OR i_MES = C_MES_ANUAL)
              AND b.funcionario = i_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_total_minutos := 0;
        END;
    END IF;
    
    -- Convertir minutos totales a formato HH:MM
    v_resultado := devuelve_min_fto_hora(v_total_minutos);
    
    RETURN v_resultado;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, retornar 00:00
        RETURN '00:00';
END HORAS_TRAJADAS_MES;
/

