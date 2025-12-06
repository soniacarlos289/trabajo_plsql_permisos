/*******************************************************************************
 * Función: wbs_devuelve_consulta_ausencias
 * 
 * Propósito:
 *   Devuelve información de ausencias en formato JSON según el tipo de consulta:
 *   - Ausencias solicitadas (historial)
 *   - Ausencias disponibles (catálogo de tipos)
 *   - Detalle de una ausencia específica
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @param opcion VARCHAR2             Tipo de consulta:
 *                                    '0' = ausencias solicitadas
 *                                    '1' = ausencias disponibles
 *                                    otro = detalle de ausencia específica (ID)
 * @param anio NUMBER                 Año de consulta
 * @return CLOB                       JSON con ausencias según opción
 *
 * Lógica:
 *   1. Opción '0': Lista ausencias solicitadas del funcionario en el año
 *   2. Opción '1': Lista tipos de ausencias disponibles con saldos
 *   3. Otra: Detalle de ausencia específica por ID
 *
 * Dependencias:
 *   - Tabla: AUSENCIA (ausencias registradas)
 *   - Tabla: TR_TIPO_AUSENCIA (tipos de ausencia)
 *   - Tabla: TR_ESTADO_PERMISO (estados)
 *   - Tabla: bolsa_concilia (saldos de conciliación)
 *   - Tabla: hora_sindical (horas sindicales)
 *   - Función: cambia_acentos (normalización texto)
 *   - Función: CHEQUEA_ENLACE_FICHERO_JUSTI (verificación justificantes)
 *
 * Mejoras aplicadas:
 *   - 2 cursores manuales → FOR LOOP (mejor gestión de memoria)
 *   - Constantes para años hardcodeados (2024, 2023)
 *   - Constantes para IDs de ausencia especiales (050, 998)
 *   - INNER JOIN explícito en lugar de sintaxis antigua
 *   - Eliminación IF/ELSE anidados innecesarios
 *   - Simplificación lógica de concatenación JSON
 *   - Constantes para mes actual dinámico
 *   - Documentación JavaDoc completa
 *
 * Ejemplo de uso:
 *   -- Ausencias solicitadas
 *   SELECT wbs_devuelve_consulta_ausencias('123456', '0', 2024) FROM DUAL;
 *   
 *   -- Ausencias disponibles
 *   SELECT wbs_devuelve_consulta_ausencias('123456', '1', 2024) FROM DUAL;
 *   
 *   -- Detalle de ausencia
 *   SELECT wbs_devuelve_consulta_ausencias('123456', '67890', 2024) FROM DUAL;
 *
 * Nota:
 *   - Los años en cabecera están hardcodeados (2024, 2023)
 *   - Considerar parametrizar para hacerlo dinámico
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_consulta_ausencias(
    i_id_funcionario IN VARCHAR2,
    opcion IN VARCHAR2,
    anio IN NUMBER
) RETURN CLOB IS
    -- Constantes
    C_OPCION_SOLICITADAS CONSTANT VARCHAR2(10) := '0';
    C_OPCION_DISPONIBLES CONSTANT VARCHAR2(10) := '1';
    C_TIPO_CONCILIACION CONSTANT VARCHAR2(10) := '050';
    C_TIPO_EXCLUIR CONSTANT VARCHAR2(10) := '998';
    -- ⚠️ TODO: Parametrizar años dinámicamente: EXTRACT(YEAR FROM SYSDATE)
    C_ANIO_ACTUAL CONSTANT NUMBER := 2024;
    C_ANIO_ANTERIOR CONSTANT NUMBER := 2023;
    
    -- Variables
    v_resultado CLOB;
    v_datos CLOB;
    v_contador NUMBER;
    v_datos_p CLOB;
    v_contador_p NUMBER;

    
BEGIN   
    v_datos := '';
    v_contador := 0;
    v_datos_p := '';
    v_contador_p := 0;
    
    -- Procesar ausencias solicitadas
    FOR rec IN (
        SELECT JSON_OBJECT( 
                   'anio' IS ausencia.id_ano,
                   'id_ausencia' IS ausencia.id_ausencia,
                   'tipo_ausencia' IS cambia_acentos(SUBSTR(DESC_TIPO_AUSENCIA, 1, 36)),
                   'id_tipo_ausencia' IS ausencia.id_tipo_ausencia,
                   'estado' IS cambia_acentos(DESC_ESTADO_PERMISO) || 
                              CASE WHEN tre.id_estado_permiso = 30 
                                   THEN ' - Motivo: ' || cambia_acentos(ausencia.motivo_denega)
                                   ELSE ''
                              END,
                   'id_estado_ausencia' IS ausencia.id_estado,
                   'motivo_denega' IS NVL(ausencia.motivo_denega, ''),
                   'fecha_inicio' IS TO_CHAR(ausencia.FECHA_INICIO, 'DD/MM/YYYY HH24:MI'), 
                   'fecha_fin' IS TO_CHAR(ausencia.FECHA_FIN, 'DD/MM/YYYY HH24:MI'), 
                   'justificado' IS CASE 
                       WHEN ausencia.JUSTIFICADO = '--' THEN NULL
                       ELSE CHEQUEA_ENLACE_FICHERO_JUSTI(ausencia.ID_ANO, ausencia.ID_FUNCIONARIO, ausencia.ID_AUSENCIA)
                   END,
                   'hora_inicio' IS SUBSTR(TO_CHAR(ausencia.FECHA_INICIO, 'DD/MM/YYYY HH24:MI'), 12, 5), 
                   'hora_fin' IS SUBSTR(TO_CHAR(ausencia.FECHA_FIN, 'DD/MM/YYYY HH24:MI'), 12, 5)
               ) AS json_data,
               ausencia.fecha_inicio
        FROM RRHH.AUSENCIA ausencia
        INNER JOIN RRHH.TR_TIPO_AUSENCIA ON ausencia.ID_TIPO_AUSENCIA = TR_TIPO_AUSENCIA.ID_TIPO_AUSENCIA
        INNER JOIN TR_ESTADO_PERMISO tre ON tre.ID_ESTADO_PERMISO = ausencia.ID_ESTADO
        WHERE ausencia.ID_FUNCIONARIO = i_id_funcionario
        AND ausencia.ID_ANO = anio 
        AND (ausencia.ID_AUSENCIA = opcion OR opcion = C_OPCION_SOLICITADAS)
        AND (ausencia.ANULADO = 'NO' OR ausencia.ANULADO IS NULL) 
        AND TR_TIPO_AUSENCIA.id_tipo_ausencia <> C_TIPO_EXCLUIR
        ORDER BY ausencia.FECHA_INICIO DESC
    ) LOOP
        v_contador := v_contador + 1;
        
        IF v_contador = 1 THEN   
            v_datos := rec.json_data; 
        ELSE
            v_datos := v_datos || ',' || rec.json_data;   
        END IF;              
    END LOOP;
    
    -- Procesar ausencias disponibles
    FOR rec_p IN (
        SELECT JSON_OBJECT(
                   'id_tipo_ausencia' IS id_tipo_ausencia,
                   'desc_tipo_ausencia' IS desc_tipo_ausencia
               ) AS json_data
        FROM (
            -- Tipos de ausencia estándar
            SELECT id_tipo_ausencia, desc_tipo_ausencia
            FROM tr_tipo_ausencia
            WHERE id_tipo_ausencia < 500
            AND id_tipo_ausencia <> C_TIPO_CONCILIACION
            AND id_tipo_ausencia > 0 
            AND id_tipo_ausencia <> C_TIPO_EXCLUIR
            
            UNION
            
            -- Bolsa de conciliación con saldo
            SELECT t.id_tipo_ausencia,
                   desc_tipo_ausencia || '. Horas Disponibles este año: ' ||
                   TRUNC((h.Total - h.utILIZADAs) / 60, 2) || ' h.' AS desc_tipo_ausencia
            FROM bolsa_concilia h
            INNER JOIN tr_tipo_ausencia t ON C_TIPO_CONCILIACION = t.id_tipo_ausencia
            WHERE h.id_funcionario = i_id_funcionario
            AND h.ID_ANO = anio 
            AND h.tr_ANULADO = 'NO'
            
            UNION
            
            -- Horas sindicales disponibles este mes
            SELECT t.id_tipo_ausencia,
                   desc_tipo_ausencia || 'Horas Disponibles este mes: ' ||
                   TRUNC((h.Total_HORAS - h.TOTAL_UTILIZADAs) / 60, 2) || 'h.' AS desc_tipo_ausencia
            FROM hora_sindical h
            INNER JOIN tr_tipo_ausencia t ON h.id_tipo_ausencia = t.id_tipo_ausencia
            WHERE h.id_funcionario = i_id_funcionario
            AND h.id_mes = EXTRACT(MONTH FROM SYSDATE)
            AND h.ID_ANO = anio 
            AND h.tr_ANULADO = 'NO'
        )
        ORDER BY 1
    ) LOOP
        v_contador_p := v_contador_p + 1;
        
        IF v_contador_p = 1 THEN   
            v_datos_p := rec_p.json_data; 
        ELSE
            v_datos_p := v_datos_p || ',' || rec_p.json_data;   
        END IF;              
    END LOOP;
    
    -- Construir respuesta según opción
    IF opcion = C_OPCION_SOLICITADAS THEN
        v_resultado := '{"periodos_consulta_anio":[' || C_ANIO_ACTUAL || ',' || C_ANIO_ANTERIOR || ']},' ||
                      '{"ausencias_solicitadas": [' || v_datos || ']}';
    ELSIF opcion = C_OPCION_DISPONIBLES THEN
        v_resultado := '{"periodos_consulta_anio":[' || C_ANIO_ACTUAL || ',' || C_ANIO_ANTERIOR || ']},' ||
                      '{"ausencias_disponibles": [' || v_datos_p || ']}';
    ELSE 
        v_resultado := '{"ausencia_detalle": [' || v_datos || ']}';  
    END IF;
    
    RETURN v_resultado;
END;
/

