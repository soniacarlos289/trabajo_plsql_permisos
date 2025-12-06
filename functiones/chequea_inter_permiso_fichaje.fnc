/**
 * ==============================================================================
 * Funcion: CHEQUEA_INTER_PERMISO_FICHAJE
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Obtiene informacion combinada de permisos/bajas y fichajes para un
 *   funcionario en una fecha especifica. Puede devolver la hora de fichaje
 *   en una posicion determinada o indicadores de patrones de fichaje.
 *
 * PARAMETROS:
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del funcionario
 *   @param v_DIA_CALENDARIO (DATE) - Fecha a consultar
 *   @param v_posicion (NUMBER) - Posicion del fichaje a obtener:
 *                                1-22: Fichaje en esa posicion del dia
 *                                23: Indica si hay dias con >2 fichajes en semana
 *                                33: Indica si hay dias con >4 fichajes en semana
 *
 * RETORNO:
 *   @return VARCHAR2 - Segun v_posicion:
 *                      - Posiciones 1-22: HTML con hora del fichaje (ej: "08:30")
 *                      - Posicion 23: 'A' si >2 fichajes/dia, 'B' si no
 *                      - Posicion 33: 'A' si >4 fichajes/dia, 'B' si no
 *
 * LOGICA:
 *   1. Busca permiso activo y obtiene el HTML de estado
 *   2. Si no hay permiso, busca baja activa
 *   3. Busca el fichaje en la posicion solicitada
 *   4. Combina HTML de estado con hora de fichaje
 *   5. Para posiciones 23/33: analiza patron de fichajes semanal
 *
 * DEPENDENCIAS:
 *   - Tabla PERMISO: Permisos de funcionarios
 *   - Tabla BAJAS_ILT: Bajas por incapacidad
 *   - Tabla FICHAJE_FUNCIONARIO_TRAN: Registro de fichajes
 *   - Tabla TR_TIPO_COLUMNA_CALENDARIO: Configuracion de colores
 *
 * CONSIDERACIONES:
 *   - La posicion 23 verifica si hay mas de 2 fichajes en algun dia
 *     de la semana anterior (puede indicar errores de fichaje)
 *   - La posicion 33 verifica si hay mas de 4 fichajes (turno partido)
 *   - El HTML combina color de estado + hora de fichaje
 *
 * MEJORAS v2.0:
 *   - Constantes para posiciones especiales
 *   - Documentacion de logica completa
 *   - Variables con nombres descriptivos
 *   - Codigo mas estructurado
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_INTER_PERMISO_FICHAJE(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA_CALENDARIO IN DATE,
    v_posicion       IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes de posiciones especiales
    C_POS_PATRON_2_FICHAJES CONSTANT NUMBER := 23;
    C_POS_PATRON_4_FICHAJES CONSTANT NUMBER := 33;
    C_LIMITE_FICHAJES_2     CONSTANT NUMBER := 2;
    C_LIMITE_FICHAJES_4     CONSTANT NUMBER := 4;
    C_DIAS_SEMANA           CONSTANT NUMBER := 7;
    
    -- Constantes HTML
    C_CELDA_BLANCA CONSTANT VARCHAR2(60) := '<td bgcolor=FFFFFF align="center"></td>';
    C_INDICADOR_OK CONSTANT VARCHAR2(1) := 'A';
    C_INDICADOR_NO CONSTANT VARCHAR2(1) := 'B';
    
    -- Constantes de permisos/bajas
    C_TIPO_BAJA     CONSTANT VARCHAR2(5) := '88888';
    C_ESTADO_BAJA   CONSTANT VARCHAR2(2) := '80';
    
    -- Variables de trabajo
    v_resultado         VARCHAR2(512);
    v_html_estado       VARCHAR2(512);
    v_hora_fichaje      VARCHAR2(5);
    v_encontrado_estado NUMBER := 0;
    v_contador_patron   NUMBER := 0;
    v_indicador_patron  VARCHAR2(1);
    
BEGIN
    -- Inicializar
    v_html_estado := C_CELDA_BLANCA;
    
    -- 1. Buscar permiso activo
    BEGIN
        SELECT tc.desc_tipo_columna
          INTO v_html_estado
          FROM permiso p, rrhh.tr_tipo_columna_calendario tc
         WHERE p.id_funcionario = V_ID_FUNCIONARIO
           AND p.id_tipo_permiso = tc.id_tipo_permiso
           AND p.id_estado = tc.id_tipo_estado
           AND v_DIA_CALENDARIO BETWEEN p.fecha_inicio AND NVL(p.fecha_fin, SYSDATE + 1)
           AND (p.anulado = 'NO' OR p.anulado IS NULL)
           AND p.id_estado NOT IN ('30', '31', '32', '40')
           AND ROWNUM < 2;
        
        v_encontrado_estado := 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_html_estado := C_CELDA_BLANCA;
            v_encontrado_estado := 0;
    END;
    
    -- 2. Si no hay permiso, buscar baja
    IF v_encontrado_estado = 0 THEN
        BEGIN
            SELECT DISTINCT tc.desc_tipo_columna
              INTO v_html_estado
              FROM bajas_ilt b, rrhh.tr_tipo_columna_calendario tc
             WHERE b.id_funcionario = V_ID_FUNCIONARIO
               AND C_TIPO_BAJA = tc.id_tipo_permiso
               AND C_ESTADO_BAJA = tc.id_tipo_estado
               AND v_DIA_CALENDARIO BETWEEN b.fecha_inicio AND b.fecha_fin
               AND (b.anulada = 'NO' OR b.anulada IS NULL)
               AND ROWNUM < 2;
            
            v_encontrado_estado := 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_html_estado := C_CELDA_BLANCA;
        END;
    END IF;
    
    -- 3. Obtener fichaje en posicion solicitada
    v_hora_fichaje := ' ';
    BEGIN
        SELECT TO_CHAR(fecha_fichaje, 'HH24:MI')
          INTO v_hora_fichaje
          FROM (
              SELECT id_funcionario, fecha_fichaje, ROWNUM AS fila
                FROM fichaje_funcionario_tran
               WHERE id_funcionario = V_ID_FUNCIONARIO
                 AND TRUNC(fecha_fichaje) = TRUNC(v_DIA_CALENDARIO)
               ORDER BY id_funcionario, fecha_fichaje
          )
         WHERE fila = v_posicion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_hora_fichaje := ' ';
    END;
    
    -- 4. Combinar HTML de estado con hora de fichaje
    v_resultado := REPLACE(v_html_estado, '</td>', '') || v_hora_fichaje || '</td>';
    
    -- 5. Posiciones especiales: analisis de patron semanal
    IF v_posicion = C_POS_PATRON_2_FICHAJES THEN
        -- Verificar si hay dias con mas de 2 fichajes en la semana anterior
        v_indicador_patron := C_INDICADOR_NO;
        BEGIN
            SELECT COUNT(*)
              INTO v_contador_patron
              FROM (
                  SELECT TRUNC(fecha_fichaje) AS dia, COUNT(*) AS num_fichajes
                    FROM fichaje_funcionario_tran
                   WHERE id_funcionario = V_ID_FUNCIONARIO
                     AND TRUNC(fecha_fichaje) BETWEEN TRUNC(v_DIA_CALENDARIO) - C_DIAS_SEMANA
                                                  AND TRUNC(v_DIA_CALENDARIO) - 1
                   GROUP BY TRUNC(fecha_fichaje)
                  HAVING COUNT(*) > C_LIMITE_FICHAJES_2
              );
            
            IF v_contador_patron > 0 THEN
                v_indicador_patron := C_INDICADOR_OK;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_indicador_patron := C_INDICADOR_NO;
            WHEN TOO_MANY_ROWS THEN
                v_indicador_patron := C_INDICADOR_OK;
        END;
        v_resultado := v_indicador_patron;
        
    ELSIF v_posicion = C_POS_PATRON_4_FICHAJES THEN
        -- Verificar si hay dias con mas de 4 fichajes en la semana anterior
        v_indicador_patron := C_INDICADOR_NO;
        BEGIN
            SELECT COUNT(*)
              INTO v_contador_patron
              FROM (
                  SELECT TRUNC(fecha_fichaje) AS dia, COUNT(*) AS num_fichajes
                    FROM fichaje_funcionario_tran
                   WHERE id_funcionario = V_ID_FUNCIONARIO
                     AND TRUNC(fecha_fichaje) BETWEEN TRUNC(v_DIA_CALENDARIO) - C_DIAS_SEMANA
                                                  AND TRUNC(v_DIA_CALENDARIO) - 1
                   GROUP BY TRUNC(fecha_fichaje)
                  HAVING COUNT(*) > C_LIMITE_FICHAJES_4
              );
            
            IF v_contador_patron > 0 THEN
                v_indicador_patron := C_INDICADOR_OK;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_indicador_patron := C_INDICADOR_NO;
            WHEN TOO_MANY_ROWS THEN
                v_indicador_patron := C_INDICADOR_OK;
        END;
        v_resultado := v_indicador_patron;
    END IF;
    
    RETURN v_resultado;
END CHEQUEA_INTER_PERMISO_FICHAJE;
/
