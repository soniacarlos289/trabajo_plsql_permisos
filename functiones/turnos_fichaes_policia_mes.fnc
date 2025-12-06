/*******************************************************************************
 * Función: TURNOS_FICHAES_POLICIA_MES
 * 
 * Propósito:
 *   Calcula las horas trabajadas por un funcionario de policía en un mes
 *   específico, desglosadas por turno (mañana, tarde, noche) más el total.
 *
 * @param i_ID_FUNCIONARIO  ID del funcionario a consultar
 * @param i_MES             Número del mes (1-12), o 13 para todos los meses del año
 * @param i_id_Anno         Año a consultar
 * @return VARCHAR2         String con formato: "Total-> X. M->Y. T->Z. N->W"
 *                          donde X=total horas, Y=horas mañana, Z=horas tarde, W=horas noche
 *
 * Lógica:
 *   1. Calcula año siguiente para el rango de fechas
 *   2. Consulta horas fichadas para turno mañana (turno 0 o 1)
 *   3. Consulta horas fichadas para turno tarde (turno 2)
 *   4. Consulta horas fichadas para turno noche (turno 3)
 *   5. Consulta total de horas fichadas
 *   6. Concatena resultados en formato legible
 *
 * Dependencias:
 *   - Tabla: FICHAJE_FUNCIONARIO (id_funcionario, fecha_fichaje_entrada, horas_fichadas, turno)
 *   - Tabla: personal_new (id_funcionario)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa
 *   - Constantes para códigos de turno
 *   - TRUNC() en lugar de TO_DATE(TO_CHAR()) para comparación de fechas
 *   - Constante para mes "todos" (13)
 *   - INNER JOIN explícito en lugar de sintaxis con comas
 *   - Eliminación de encoding corrupto en comentarios
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - mejor rendimiento y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.TURNOS_FICHAES_POLICIA_MES(
    i_ID_FUNCIONARIO IN VARCHAR2,
    i_MES            IN NUMBER,
    i_id_Anno        IN NUMBER
) RETURN VARCHAR2 IS

    -- Constantes
    C_TURNO_MANANA CONSTANT NUMBER := 1;
    C_TURNO_TARDE  CONSTANT NUMBER := 2;
    C_TURNO_NOCHE  CONSTANT NUMBER := 3;
    C_MES_TODOS    CONSTANT NUMBER := 13;
    
    -- Variables de resultado
    v_resultado VARCHAR2(200);
    i_contador  VARCHAR2(30);
    i_prox_anno NUMBER;

BEGIN
    i_prox_anno := i_id_Anno + 1;
    v_resultado := '';
    
    -- Calcular horas de turno mañana (incluye turno 0 y 1)
    BEGIN
        SELECT CASE 
                WHEN TRUNC(SUM(horas_fichadas) / 60) IS NULL THEN ''
                ELSE '. M->' || TRUNC(SUM(horas_fichadas) / 60)
            END
        INTO i_contador
        FROM FICHAJE_FUNCIONARIO fc
        INNER JOIN personal_new f ON fc.id_funcionario = f.id_funcionario
        WHERE TRUNC(fc.fecha_fichaje_entrada, 'DD')
                BETWEEN TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY')
                    AND TO_DATE('01/01/' || i_prox_anno, 'DD/MM/YYYY')
            AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = i_MES OR C_MES_TODOS = i_MES)
            AND fc.turno IN (0, C_TURNO_MANANA)
            AND fc.id_funcionario = i_ID_FUNCIONARIO;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_contador := '';
    END;
    
    v_resultado := v_resultado || i_contador;
    
    -- Calcular horas de turno tarde
    BEGIN
        SELECT CASE 
                WHEN TRUNC(SUM(horas_fichadas) / 60) IS NULL THEN ''
                ELSE '. T->' || TRUNC(SUM(horas_fichadas) / 60)
            END
        INTO i_contador
        FROM FICHAJE_FUNCIONARIO fc
        INNER JOIN personal_new f ON fc.id_funcionario = f.id_funcionario
        WHERE TRUNC(fc.fecha_fichaje_entrada, 'DD')
                BETWEEN TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY')
                    AND TO_DATE('01/01/' || i_prox_anno, 'DD/MM/YYYY')
            AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = i_MES OR C_MES_TODOS = i_MES)
            AND fc.turno = C_TURNO_TARDE
            AND fc.id_funcionario = i_ID_FUNCIONARIO;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_contador := '';
    END;
    
    v_resultado := v_resultado || i_contador;
    
    -- Calcular horas de turno noche
    BEGIN
        SELECT CASE 
                WHEN TRUNC(SUM(horas_fichadas) / 60) IS NULL THEN ''
                ELSE '. N->' || TRUNC(SUM(horas_fichadas) / 60)
            END
        INTO i_contador
        FROM FICHAJE_FUNCIONARIO fc
        INNER JOIN personal_new f ON fc.id_funcionario = f.id_funcionario
        WHERE TRUNC(fc.fecha_fichaje_entrada, 'DD')
                BETWEEN TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY')
                    AND TO_DATE('01/01/' || i_prox_anno, 'DD/MM/YYYY')
            AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = i_MES OR C_MES_TODOS = i_MES)
            AND fc.turno = C_TURNO_NOCHE
            AND fc.id_funcionario = i_ID_FUNCIONARIO;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_contador := '';
    END;
    
    v_resultado := v_resultado || i_contador;
    
    -- Calcular total de horas
    BEGIN
        SELECT ' Total-> ' || NVL(TRUNC(SUM(horas_fichadas) / 60), 0)
        INTO i_contador
        FROM FICHAJE_FUNCIONARIO fc
        INNER JOIN personal_new f ON fc.id_funcionario = f.id_funcionario
        WHERE TRUNC(fc.fecha_fichaje_entrada, 'DD')
                BETWEEN TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY')
                    AND TO_DATE('01/01/' || i_prox_anno, 'DD/MM/YYYY')
            AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = i_MES OR C_MES_TODOS = i_MES)
            AND fc.id_funcionario = i_ID_FUNCIONARIO;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_contador := '';
    END;
    
    -- Formato: Total primero, luego desglose por turnos
    v_resultado := i_contador || v_resultado;
    
    RETURN v_resultado;

END TURNOS_FICHAES_POLICIA_MES;
/

