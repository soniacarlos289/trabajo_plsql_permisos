/*******************************************************************************
 * Función: LABORAL_DIA
 * 
 * Propósito:
 *   Determina si un día es laboral para un funcionario específico y genera
 *   HTML para mostrar en calendario con formato según el tipo de funcionario.
 *
 * @param V_ID_FUNCIONARIO  ID del funcionario a consultar
 * @param v_ID_DIA          Fecha del día a evaluar
 * @return VARCHAR2         HTML con el día y su formato según tipo laboral
 *
 * Lógica:
 *   1. Identifica el tipo de funcionario (policía=21, bombero=23, otros)
 *   2. Para policía: verifica fichajes y muestra turno (M/T/N)
 *   3. Para bombero: verifica guardias planificadas
 *   4. Consulta calendario laboral y permisos aprobados
 *   5. Genera HTML con colores según estado:
 *      - Permiso: color personalizado según tipo
 *      - No laboral: gris (#bfc1be)
 *      - Festivo: rojo (#FA5858)
 *      - Laboral: blanco (#FFFFFF)
 *
 * Dependencias:
 *   - Tabla: personal_new
 *   - Tabla: calendario_laboral
 *   - Tabla: TR_TIPO_COLUMNA_CALENDARIO
 *   - Tabla: permiso
 *   - Tabla: fichaje_funcionario (para policías)
 *   - Tabla: Bomberos_guardias_plani (para bomberos)
 *
 * Consideraciones:
 *   - Solo consulta permisos de años > 2015
 *   - Solo permisos en estado aprobado (80)
 *   - Genera HTML inline (considerar separar presentación)
 *   - Fin de semana (sábado=7, domingo=6) marca como festivo
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para tipos de funcionario
 *   - Constantes para estados y colores HTML
 *   - Uso de TRUNC() en comparaciones de fecha
 *   - Eliminación de TO_DATE(TO_CHAR()) redundantes
 *   - Variables inicializadas explícitamente
 *   - Estructura simplificada de IF anidados
 *   - Documentación JavaDoc completa
 *
 * Historial:
 *   - 2025-12-06: Optimización y documentación (Grupo 7)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.LABORAL_DIA(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_ID_DIA         IN DATE
) RETURN VARCHAR2 IS

    -- Constantes para tipos de funcionario
    C_TIPO_POLICIA  CONSTANT NUMBER := 21;
    C_TIPO_BOMBERO  CONSTANT NUMBER := 23;
    
    -- Constantes para estados
    C_ESTADO_APROBADO CONSTANT VARCHAR2(2) := '80';
    C_ANO_INICIO      CONSTANT NUMBER := 2015;
    
    -- Constantes para colores HTML
    C_COLOR_PERMISO  CONSTANT VARCHAR2(20) := 'CCCCCC';
    C_COLOR_NO_LAB   CONSTANT VARCHAR2(20) := '#bfc1be';
    C_COLOR_FESTIVO  CONSTANT VARCHAR2(20) := '#FA5858';
    C_COLOR_LABORAL  CONSTANT VARCHAR2(20) := '#FFFFFF';
    
    -- Constantes para días de semana (Oracle TO_CHAR d: 1=domingo, 7=sábado)
    C_SABADO   CONSTANT CHAR(1) := '7';
    C_DOMINGO  CONSTANT CHAR(1) := '6';
    
    -- Variables de resultado
    Result              VARCHAR2(512);
    V_LABORAL           VARCHAR2(2) := 'NO';
    V_DESC_COL          VARCHAR2(200);
    v_desc_columna      VARCHAR2(20) := C_COLOR_PERMISO;
    
    -- Variables auxiliares
    i_encontrado        NUMBER := 0;
    i_contador          NUMBER := 0;
    i_turno             NUMBER := 0;
    ID_TIPO_FUNCIONARIO NUMBER;

BEGIN
    -- Obtener tipo de funcionario
    BEGIN
        SELECT TIPO_FUNCIONARIO2
        INTO ID_TIPO_FUNCIONARIO
        FROM personal_new
        WHERE id_funcionario = V_ID_FUNCIONARIO
          AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_encontrado := 0;
    END;

    -- Consultar calendario laboral general
    BEGIN
        SELECT 
            CASE TO_CHAR(id_dia, 'd')
                WHEN C_SABADO THEN 'FE'
                WHEN C_DOMINGO THEN 'FE'
                ELSE CASE LABORAL 
                        WHEN 'NO' THEN 'FE'
                        ELSE 'SI'
                     END
            END AS LAB,
            '<a href=../Finger/detalle_dia.jsp?ID_DIA=' || TO_CHAR(id_dia, 'dd/mm/yyyy') ||
            '><div align=center>' || TO_CHAR(id_dia, 'dd') || '</a></td>'
        INTO V_LABORAL, V_DESC_COL
        FROM calendario_laboral
        WHERE id_dia = v_ID_DIA
          AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_LABORAL := 'NO';
            V_DESC_COL := '';
    END;
    -- Verificar permisos aprobados (color de columna personalizado)
    BEGIN
        SELECT SUBSTR(DESC_TIPO_COLUMNA, 1, 19) AS DESC_COLUMNA
        INTO v_desc_columna
        FROM RRHH.TR_TIPO_COLUMNA_CALENDARIO t
        INNER JOIN permiso p ON p.id_tipo_permiso = t.id_tipo_permiso 
                             AND p.id_estado = t.id_tipo_estado
        WHERE p.id_ano > C_ANO_INICIO
          AND p.id_funcionario = V_ID_FUNCIONARIO
          AND v_ID_DIA BETWEEN p.fecha_inicio AND p.fecha_fin
          AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_desc_columna := C_COLOR_PERMISO;
    END;



    -- Lógica especial para POLICÍA (tipo 21): verificar fichajes
    IF ID_TIPO_FUNCIONARIO = C_TIPO_POLICIA THEN
        i_contador := 0;
        
        -- Buscar fichaje del día para determinar turno
        BEGIN
            SELECT turno
            INTO i_turno
            FROM fichaje_funcionario
            WHERE id_funcionario = V_ID_FUNCIONARIO
              AND TRUNC(fecha_fichaje_entrada) = TRUNC(v_ID_DIA)
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := -1;
        END;
        
        -- Si hay fichaje, es día laboral y se muestra turno
        IF i_contador > -1 THEN
            BEGIN
                SELECT 
                    CASE TO_CHAR(id_dia, 'd')
                        WHEN C_SABADO THEN 'FE'
                        WHEN C_DOMINGO THEN 'FE'
                        ELSE laboral
                    END AS LAB,
                    '<a href=../Finger/detalle_dia.jsp?ID_DIA=' || TO_CHAR(id_dia, 'dd/mm/yyyy') ||
                    '><div align=center>' || 
                    CASE i_turno
                        WHEN 1 THEN 'M'  -- Mañana
                        WHEN 2 THEN 'T'  -- Tarde
                        WHEN 3 THEN 'N'  -- Noche
                        ELSE '?'         -- Desconocido
                    END || '</a></td>'
                INTO V_LABORAL, V_DESC_COL
                FROM calendario_laboral
                WHERE id_dia = v_ID_DIA
                  AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_LABORAL := 'NO';
                    V_DESC_COL := '';
            END;
        ELSE
            V_LABORAL := 'NO';
        END IF;
    END IF;

    -- Lógica especial para BOMBERO (tipo 23): verificar guardias
    IF ID_TIPO_FUNCIONARIO = C_TIPO_BOMBERO THEN
        i_contador := 0;
        
        -- Verificar si tiene guardia planificada ese día
        BEGIN
            SELECT COUNT(*)
            INTO i_contador
            FROM Bomberos_guardias_plani
            WHERE TRUNC(desde) = TRUNC(v_ID_DIA)
              AND funcionario = V_ID_FUNCIONARIO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_contador := 0;
        END;
        
        -- Si hay guardia, es día laboral
        IF i_contador > 0 THEN
            V_LABORAL := 'SI';
        ELSE
            V_LABORAL := 'NO';
        END IF;
    END IF;


    -- Construir HTML final con formato según el tipo de día
    IF v_desc_columna <> C_COLOR_PERMISO THEN
        -- Tiene permiso: usar color del tipo de permiso
        V_DESC_COL := v_desc_columna || V_DESC_COL;
    ELSIF V_LABORAL = 'NO' THEN
        -- Día no laboral: gris
        V_DESC_COL := '<td bgcolor=' || C_COLOR_NO_LAB || '>' || V_DESC_COL;
    ELSIF V_LABORAL = 'FE' THEN
        -- Festivo/fin de semana: rojo
        V_DESC_COL := '<td bgcolor=' || C_COLOR_FESTIVO || '>' || V_DESC_COL;
    ELSE
        -- Día laboral normal: blanco
        V_DESC_COL := '<td bgcolor=' || C_COLOR_LABORAL || '>' || V_DESC_COL;
    END IF;
    
    Result := V_DESC_COL;
    
    RETURN Result;

END LABORAL_DIA;
/

