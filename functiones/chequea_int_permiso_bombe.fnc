/**
 * ==============================================================================
 * Funcion: CHEQUEA_INT_PERMISO_BOMBE
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Genera el HTML de estado de permisos para el calendario de bomberos,
 *   mostrando el estado de cada tramo horario de guardia. Considera los
 *   cambios de turno implementados el 21/05/2022.
 *
 * PARAMETROS:
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del bombero
 *   @param v_DIA_CALENDARIO (DATE) - Fecha a consultar
 *   @param TRAMO1 (NUMBER) - Solicitar info del tramo 1 (1=Si)
 *   @param TRAMO2 (NUMBER) - Solicitar info del tramo 2 (1=Si)
 *   @param TRAMO3 (NUMBER) - Solicitar info del tramo 3 (1=Si)
 *
 * RETORNO:
 *   @return VARCHAR2 - Segun combinacion de parametros:
 *                      - Si un solo tramo=1: HTML de celda con color de estado
 *                      - Si TRAMO1=TRAMO2=TRAMO3=1: Numero de ordenacion (0,1,2)
 *                      - HTML especial amarillo si dotacion = '#BA' (baja)
 *
 * TRAMOS HORARIOS:
 *   Antes del 21/05/2022:
 *     - TRAMO 1: 14:00-22:00
 *     - TRAMO 2: 22:00-06:00
 *     - TRAMO 3: 06:00-14:00
 *   
 *   Desde el 21/05/2022:
 *     - TRAMO 1: 08:00-16:00
 *     - TRAMO 2: 16:00-24:00
 *     - TRAMO 3: 00:00-08:00
 *
 * COLORES DE ESTADO:
 *   - FFFFFF (blanco): No trabaja / sin guardia
 *   - E6E6E6 (gris): Trabaja / con guardia
 *   - CCCC33 (amarillo): Baja (#BA)
 *   - Otros: Segun tipo de permiso (tr_tipo_columna_calendario)
 *
 * ORDENACION (cuando los 3 tramos = 1):
 *   - 0: Trabaja sin permiso
 *   - 1: Con permiso activo
 *   - 2: No trabaja (sin guardia)
 *
 * DEPENDENCIAS:
 *   - Tabla BOMBEROS_GUARDIAS_PLANI: Planificacion de guardias
 *   - Tabla PERMISO: Permisos de funcionarios
 *   - Tabla TR_TIPO_COLUMNA_CALENDARIO: Configuracion de colores
 *
 * MEJORAS v2.0:
 *   - Constantes para fechas de cambio de turno
 *   - Constantes para colores y estados
 *   - Simplificacion de DECODE con CASE
 *   - Documentacion completa de tramos
 *   - Codigo mas legible
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_INT_PERMISO_BOMBE(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA_CALENDARIO IN DATE,
    TRAMO1           IN NUMBER,
    TRAMO2           IN NUMBER,
    TRAMO3           IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes de configuracion
    C_FECHA_CAMBIO_TURNO CONSTANT DATE := TO_DATE('21/05/2022', 'DD/MM/YYYY');
    C_ANO_MIN_GUARDIA    CONSTANT NUMBER := 2018;
    C_ANO_MIN_PERMISO    CONSTANT NUMBER := 2018;
    C_DOTACION_BAJA      CONSTANT VARCHAR2(3) := '#BA';
    
    -- Constantes de hora segun sistema
    C_HORA_INICIO_ANTIGUO CONSTANT VARCHAR2(5) := '14:00';
    C_HORA_INICIO_NUEVO   CONSTANT VARCHAR2(5) := '08:00';
    
    -- Constantes HTML
    C_CELDA_BLANCA   CONSTANT VARCHAR2(50) := '<td bgcolor=FFFFFF> </td>';
    C_CELDA_GRIS     CONSTANT VARCHAR2(50) := '<td bgcolor=E6E6E6> </td>';
    C_CELDA_AMARILLA CONSTANT VARCHAR2(50) := '<td bgcolor=CCCC33></td>';
    
    -- Variables de trabajo
    v_resultado       VARCHAR2(512);
    v_html_tramo1     VARCHAR2(512);
    v_html_tramo2     VARCHAR2(512);
    v_html_tramo3     VARCHAR2(512);
    v_id_func_guardia VARCHAR2(512);
    v_es_dotacion_ba  NUMBER := 0;
    v_tiene_guardia   NUMBER := 0;
    v_tiene_permiso   NUMBER := 0;
    v_ordenacion      NUMBER := 2;  -- Default: no trabaja
    v_hora_inicio     VARCHAR2(5);
    
BEGIN
    -- Determinar hora de inicio segun fecha
    IF v_DIA_CALENDARIO < C_FECHA_CAMBIO_TURNO THEN
        v_hora_inicio := C_HORA_INICIO_ANTIGUO;
    ELSE
        v_hora_inicio := C_HORA_INICIO_NUEVO;
    END IF;
    
    -- Verificar si tiene guardia programada
    BEGIN
        SELECT funcionario,
               CASE WHEN dotacion = C_DOTACION_BAJA THEN 1 ELSE 0 END
          INTO v_id_func_guardia, v_es_dotacion_ba
          FROM bomberos_guardias_plani
         WHERE TO_DATE(TO_CHAR(v_DIA_CALENDARIO, 'DD/MM/YYYY') || ' ' || v_hora_inicio,
                       'DD/MM/YYYY HH24:MI') = desde
           AND funcionario = V_ID_FUNCIONARIO
           AND SUBSTR(guardia, 1, 4) > C_ANO_MIN_GUARDIA;
        
        v_tiene_guardia := 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_func_guardia := NULL;
            v_es_dotacion_ba := 0;
            v_tiene_guardia := 0;
    END;
    
    -- Inicializar celdas segun estado de guardia
    IF v_id_func_guardia IS NULL THEN
        -- Sin guardia: celdas blancas
        v_html_tramo1 := C_CELDA_BLANCA;
        v_html_tramo2 := C_CELDA_BLANCA;
        v_html_tramo3 := C_CELDA_BLANCA;
        v_ordenacion := 2;  -- No trabaja
    ELSE
        -- Con guardia: celdas grises (trabajando)
        v_html_tramo1 := C_CELDA_GRIS;
        v_html_tramo2 := C_CELDA_GRIS;
        v_html_tramo3 := C_CELDA_GRIS;
        v_ordenacion := 0;  -- Trabaja
        
        -- Buscar permiso activo
        BEGIN
            SELECT 
                CASE p.id_tipo_permiso
                    WHEN '11000' THEN CASE WHEN tu1_14_22 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02030' THEN CASE WHEN tu1_14_22 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02031' THEN CASE WHEN tu1_14_22 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02000' THEN CASE WHEN tu1_14_22 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '01015' THEN CASE WHEN tu1_14_22 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02015' THEN CASE WHEN tu1_14_22 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    ELSE tc.desc_tipo_columna
                END,
                CASE p.id_tipo_permiso
                    WHEN '11000' THEN CASE WHEN tu2_22_06 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02030' THEN CASE WHEN tu2_22_06 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02031' THEN CASE WHEN tu2_22_06 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02000' THEN CASE WHEN tu2_22_06 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '01015' THEN CASE WHEN tu2_22_06 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02015' THEN CASE WHEN tu2_22_06 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    ELSE tc.desc_tipo_columna
                END,
                CASE p.id_tipo_permiso
                    WHEN '11000' THEN CASE WHEN tu3_04_14 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02030' THEN CASE WHEN tu3_04_14 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02031' THEN CASE WHEN tu3_04_14 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02000' THEN CASE WHEN tu3_04_14 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '01015' THEN CASE WHEN tu3_04_14 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    WHEN '02015' THEN CASE WHEN tu3_04_14 = 1 THEN tc.desc_tipo_columna ELSE '' END
                    ELSE tc.desc_tipo_columna
                END
              INTO v_html_tramo1, v_html_tramo2, v_html_tramo3
              FROM permiso p, rrhh.tr_tipo_columna_calendario tc
             WHERE p.id_funcionario = V_ID_FUNCIONARIO
               AND p.id_tipo_permiso = tc.id_tipo_permiso
               AND p.id_ano > C_ANO_MIN_PERMISO
               AND p.id_estado = tc.id_tipo_estado
               AND v_DIA_CALENDARIO BETWEEN p.fecha_inicio AND NVL(p.fecha_fin, SYSDATE + 1)
               AND (p.anulado = 'NO' OR p.anulado IS NULL)
               AND p.id_estado NOT IN ('30', '31', '32', '40')
               AND ROWNUM < 2;
            
            v_tiene_permiso := 1;
            v_ordenacion := 1;  -- Con permiso
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tiene_permiso := 0;
        END;
    END IF;
    
    -- Corregir celdas vacias a gris
    IF v_html_tramo1 IS NULL OR v_html_tramo1 = '' THEN
        v_html_tramo1 := C_CELDA_GRIS;
    END IF;
    IF v_html_tramo2 IS NULL OR v_html_tramo2 = '' THEN
        v_html_tramo2 := C_CELDA_GRIS;
    END IF;
    IF v_html_tramo3 IS NULL OR v_html_tramo3 = '' THEN
        v_html_tramo3 := C_CELDA_GRIS;
    END IF;
    
    -- Seleccionar resultado segun tramos solicitados
    IF TRAMO1 = 1 AND TRAMO2 = 1 AND TRAMO3 = 1 THEN
        -- Modo ordenacion: retornar numero
        v_resultado := TO_CHAR(v_ordenacion);
    ELSIF TRAMO1 = 1 THEN
        v_resultado := v_html_tramo1;
    ELSIF TRAMO2 = 1 THEN
        v_resultado := v_html_tramo2;
    ELSIF TRAMO3 = 1 THEN
        v_resultado := v_html_tramo3;
    END IF;
    
    -- Override si esta de baja (#BA)
    IF v_es_dotacion_ba = 1 THEN
        v_resultado := C_CELDA_AMARILLA;
    END IF;
    
    RETURN v_resultado;
END CHEQUEA_INT_PERMISO_BOMBE;
/
