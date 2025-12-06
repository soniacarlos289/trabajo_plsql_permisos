/**
 * ==============================================================================
 * Funcion: CHEQUEA_SOLAPAMIENTOS
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Verifica si un nuevo permiso/ausencia solapa con permisos o ausencias
 *   existentes del funcionario. Detecta conflictos temporales antes de
 *   permitir la creacion de nuevos registros.
 *
 * PARAMETROS:
 *   @param V_ID_ANO (NUMBER) - Anio del ejercicio
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del funcionario
 *   @param V_ID_TIPO_PERMISO (VARCHAR2) - Tipo de permiso a crear
 *   @param V_FECHA_INICIO (DATE) - Fecha inicio del nuevo permiso
 *   @param v_FECHA_FIN (DATE) - Fecha fin del nuevo permiso (puede ser NULL)
 *   @param V_HORA_INICIO (VARCHAR2) - Hora inicio (formato HH24:MI)
 *   @param V_HORA_FIN (VARCHAR2) - Hora fin (formato HH24:MI)
 *
 * RETORNO:
 *   @return VARCHAR2 - Resultado de la validacion:
 *                      '0' = Sin solapamientos (OK para crear)
 *                      'Existe un permiso entre esas fechas'
 *                      'Existe una ausencia entre esas fechas'
 *                      'Existe una baja entre esas fechas' (deshabilitado)
 *
 * LOGICA:
 *   1. Verifica solapamiento con permisos existentes (por fechas)
 *   2. Para permiso 15000: verifica tambien por horas
 *   3. Verifica solapamiento con ausencias
 *   4. Retorna mensaje descriptivo si hay conflicto
 *
 * TIPO PERMISO 15000:
 *   - Requiere validacion adicional por horas
 *   - Puede solapar fechas pero no horas con otros permisos
 *
 * ESTADOS EXCLUIDOS:
 *   - 30, 31, 32: Rechazados
 *   - 40, 41: Cancelados
 *
 * NOTA:
 *   La validacion de bajas esta comentada porque ya se incluyen
 *   como permisos en el sistema.
 *
 * MEJORAS v2.0:
 *   - Constantes para tipo de permiso especial
 *   - Simplificacion de IF/ELSE anidados
 *   - Documentacion de logica de negocio
 *   - Codigo mas legible
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_SOLAPAMIENTOS(
    V_ID_ANO          IN NUMBER,
    V_ID_FUNCIONARIO  IN VARCHAR2,
    V_ID_TIPO_PERMISO IN VARCHAR2,
    V_FECHA_INICIO    IN DATE,
    v_FECHA_FIN       IN DATE,
    V_HORA_INICIO     VARCHAR2,
    V_HORA_FIN        VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_TIPO_PERMISO_HORAS CONSTANT VARCHAR2(5) := '15000';
    C_RESULTADO_OK       CONSTANT VARCHAR2(1) := '0';
    C_MSG_PERMISO        CONSTANT VARCHAR2(50) := 'Existe un permiso entre esas fechas';
    C_MSG_AUSENCIA       CONSTANT VARCHAR2(50) := 'Existe una ausencia entre esas fechas';
    C_MSG_BAJA           CONSTANT VARCHAR2(50) := 'Existe una baja entre esas fechas';
    
    -- Variables de conteo
    v_count_permisos     NUMBER := 0;
    v_count_permisos_h   NUMBER := 0;
    v_count_ausencias    NUMBER := 0;
    v_count_bajas        NUMBER := 0;
    
    -- Variables de fechas con hora
    v_fecha_hora_inicio  DATE;
    v_fecha_hora_fin     DATE;
    
    -- Resultado
    v_resultado          VARCHAR2(256);
    
BEGIN
    -- Inicializar resultado
    v_resultado := C_RESULTADO_OK;
    
    -- Solo procesar si hay fecha fin
    IF v_FECHA_FIN IS NOT NULL THEN
        -- Construir fechas con hora
        v_fecha_hora_inicio := TO_DATE(TO_CHAR(V_FECHA_INICIO, 'DD/MM/YYYY') || V_HORA_INICIO,
                                       'DD/MM/YYYY HH24:MI');
        v_fecha_hora_fin := TO_DATE(TO_CHAR(v_FECHA_FIN, 'DD/MM/YYYY') || V_HORA_FIN,
                                    'DD/MM/YYYY HH24:MI');
        
        -- 1. Verificar solapamiento con permisos (por fechas)
        BEGIN
            SELECT COUNT(*)
              INTO v_count_permisos
              FROM permiso
             WHERE ((fecha_inicio BETWEEN TRUNC(V_FECHA_INICIO) AND TRUNC(v_FECHA_FIN))
                    OR (fecha_fin BETWEEN TRUNC(V_FECHA_INICIO) AND TRUNC(v_FECHA_FIN)))
               AND id_funcionario = V_ID_FUNCIONARIO
               AND id_ano = V_ID_ANO
               AND (anulado = 'NO' OR anulado IS NULL)
               AND id_estado NOT IN ('30', '31', '32', '40', '41')
               AND id_tipo_permiso <> C_TIPO_PERMISO_HORAS;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_count_permisos := 0;
        END;
        
        -- 2. Para permiso 15000: verificar tambien por horas
        IF V_ID_TIPO_PERMISO = C_TIPO_PERMISO_HORAS AND v_count_permisos > 0 THEN
            BEGIN
                SELECT COUNT(*)
                  INTO v_count_permisos_h
                  FROM permiso
                 WHERE ((TO_DATE(TO_CHAR(fecha_inicio, 'DD/MM/YYYY') || hora_inicio,
                                'DD/MM/YYYY HH24:MI') BETWEEN v_fecha_hora_inicio AND v_fecha_hora_fin)
                        OR (TO_DATE(TO_CHAR(fecha_fin, 'DD/MM/YYYY') || hora_fin,
                                   'DD/MM/YYYY HH24:MI') BETWEEN v_fecha_hora_inicio AND v_fecha_hora_fin))
                   AND id_funcionario = V_ID_FUNCIONARIO
                   AND id_ano = V_ID_ANO
                   AND (anulado = 'NO' OR anulado IS NULL)
                   AND id_estado NOT IN ('30', '31', '32', '40', '41');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_count_permisos_h := 0;
            END;
        END IF;
        
        -- 3. Verificar solapamiento con ausencias
        BEGIN
            SELECT COUNT(*)
              INTO v_count_ausencias
              FROM ausencia
             WHERE ((fecha_inicio BETWEEN v_fecha_hora_inicio AND v_fecha_hora_fin)
                    OR (fecha_fin BETWEEN v_fecha_hora_inicio AND v_fecha_hora_fin))
               AND id_funcionario = V_ID_FUNCIONARIO
               AND id_ano = V_ID_ANO
               AND (anulado = 'NO' OR anulado IS NULL)
               AND id_estado NOT IN ('30', '31', '32', '40', '41');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_count_ausencias := 0;
        END;
        
        -- Nota: La validacion de bajas esta deshabilitada
        -- porque ya se incluyen como permisos en el sistema
        
    END IF;  -- IF v_FECHA_FIN IS NOT NULL
    
    -- Determinar resultado final
    IF (v_count_permisos <> 0 AND V_ID_TIPO_PERMISO <> C_TIPO_PERMISO_HORAS) OR
       (v_count_permisos_h <> 0 AND V_ID_TIPO_PERMISO = C_TIPO_PERMISO_HORAS) THEN
        v_resultado := C_MSG_PERMISO;
    ELSIF v_count_ausencias <> 0 THEN
        v_resultado := C_MSG_AUSENCIA;
    ELSIF v_count_bajas <> 0 THEN
        v_resultado := C_MSG_BAJA;
    ELSE
        v_resultado := C_RESULTADO_OK;
    END IF;
    
    RETURN v_resultado;
END CHEQUEA_SOLAPAMIENTOS;
/
