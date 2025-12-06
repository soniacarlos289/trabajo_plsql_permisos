/*******************************************************************************
 * Función: TURNOS_TRABAJOS_MES
 * 
 * Propósito:
 *   Calcula las horas trabajadas por un funcionario en un mes, con lógica
 *   diferenciada para bomberos (tipo 23) vs otros tipos de funcionario.
 *
 * @param i_ID_FUNCIONARIO      ID del funcionario a consultar
 * @param ID_TIPO_FUNCIONARIO   Tipo de funcionario (23=bombero, otro=personal regular)
 * @param i_MES                 Número del mes (1-12), o 13 para todos los meses
 * @param i_id_Anno             Año a consultar
 * @return VARCHAR2             String con formato: "Total-> X. M->Y. T->Z. N->W"
 *
 * Lógica:
 *   1. Si NO es bombero (tipo!=23):
 *      - Calcula horas por turno (mañana, tarde, noche) más total
 *      - Solo considera funcionarios activos (sin fecha_fin_contrato o futura)
 *   2. Si es bombero (tipo=23):
 *      - Calcula horas de guardias planificadas
 *      - Resta permisos aprobados (estado=80) en esas fechas
 *
 * Dependencias:
 *   - Tabla: FICHAJE_FUNCIONARIO (id_funcionario, fecha_fichaje_entrada, horas_fichadas, turno)
 *   - Tabla: personal_new (id_funcionario, fecha_fin_contrato)
 *   - Tabla: BOMBEROS_GUARDIAS_PLANI (funcionario, desde, hasta)
 *   - Tabla: permiso (id_funcionario, fecha_inicio, fecha_fin, id_tipo_permiso, id_estado)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa
 *   - Constantes para códigos de turno y tipo bombero
 *   - TRUNC() en lugar de TO_DATE(TO_CHAR()) para fechas
 *   - INNER JOIN y LEFT JOIN explícitos en lugar de sintaxis antigua
 *   - CASE en lugar de DECODE para mejor legibilidad
 *   - Eliminación de encoding corrupto
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - mejor rendimiento y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.TURNOS_TRABAJOS_MES(
    i_ID_FUNCIONARIO      IN VARCHAR2,
    ID_TIPO_FUNCIONARIO   IN NUMBER,
    i_MES                 IN NUMBER,
    i_id_Anno             IN NUMBER
) RETURN VARCHAR2 IS

    -- Constantes
    C_TURNO_MANANA    CONSTANT NUMBER := 1;
    C_TURNO_TARDE     CONSTANT NUMBER := 2;
    C_TURNO_NOCHE     CONSTANT NUMBER := 3;
    C_TIPO_BOMBERO    CONSTANT NUMBER := 23;
    C_MES_TODOS       CONSTANT NUMBER := 13;
    C_ESTADO_APROBADO CONSTANT NUMBER := 80;
    
    -- Variables de resultado
    v_resultado VARCHAR2(200);
    i_contador  VARCHAR2(130);
    i_prox_anno NUMBER;

BEGIN
    i_prox_anno := i_id_Anno + 1;
    v_resultado := '';
    
    -- Lógica diferenciada según tipo de funcionario
    IF ID_TIPO_FUNCIONARIO <> C_TIPO_BOMBERO THEN
        -- Personal regular (NO bomberos): calcular horas fichadas por turno
        
        -- Turno mañana (incluye turno 0 y 1)
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
                AND (f.fecha_fin_contrato IS NULL OR f.fecha_fin_contrato > SYSDATE)
                AND fc.id_funcionario = i_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := '';
        END;
        
        v_resultado := v_resultado || i_contador;
        
        -- Turno tarde
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
                AND (f.fecha_fin_contrato IS NULL OR f.fecha_fin_contrato > SYSDATE)
                AND fc.id_funcionario = i_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := '';
        END;
        
        v_resultado := v_resultado || i_contador;
        
        -- Turno noche
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
                AND (f.fecha_fin_contrato IS NULL OR f.fecha_fin_contrato > SYSDATE)
                AND fc.id_funcionario = i_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := '';
        END;
        
        v_resultado := v_resultado || i_contador;
        
        -- Total horas para personal regular
        BEGIN
            SELECT ' Total-> ' || NVL(TRUNC(SUM(horas_fichadas) / 60), 0)
            INTO i_contador
            FROM FICHAJE_FUNCIONARIO fc
            INNER JOIN personal_new f ON fc.id_funcionario = f.id_funcionario
            WHERE TRUNC(fc.fecha_fichaje_entrada, 'DD')
                    BETWEEN TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY')
                        AND TO_DATE('01/01/' || i_prox_anno, 'DD/MM/YYYY')
                AND (TO_CHAR(fc.fecha_fichaje_entrada, 'MM') = i_MES OR C_MES_TODOS = i_MES)
                AND (f.fecha_fin_contrato IS NULL OR f.fecha_fin_contrato > SYSDATE)
                AND fc.id_funcionario = i_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := '';
        END;
        
    ELSE
        -- Bomberos: calcular horas de guardias planificadas menos permisos
        BEGIN
            SELECT 'Total-> ' || SUM(
                    CASE 
                        WHEN p.id_tipo_permiso IS NULL THEN ((hasta - desde) * 24)
                        ELSE 0
                    END
                )
            INTO i_contador
            FROM BOMBEROS_GUARDIAS_PLANI b
            LEFT JOIN permiso p ON b.funcionario = p.id_funcionario
                AND hasta BETWEEN p.fecha_inicio - 1 AND p.fecha_fin + 1
                AND p.id_estado = C_ESTADO_APROBADO
            WHERE hasta BETWEEN TO_DATE('01/01/' || i_id_Anno, 'DD/MM/YYYY')
                            AND TO_DATE('01/01/' || i_prox_anno, 'DD/MM/YYYY')
                AND (TO_CHAR(hasta, 'MM') = i_MES OR C_MES_TODOS = i_MES)
                AND funcionario = i_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := '0';
        END;
    END IF;
    
    -- Formato: Total primero, luego desglose (si aplica)
    v_resultado := i_contador || v_resultado;
    
    RETURN v_resultado;

END TURNOS_TRABAJOS_MES;
/

