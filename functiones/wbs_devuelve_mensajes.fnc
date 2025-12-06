/*******************************************************************************
 * Función: wbs_devuelve_mensajes
 * 
 * Propósito:
 *   Devuelve un JSON con las últimas notificaciones/mensajes de un funcionario,
 *   limitado a las 4 más recientes.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @return CLOB                      JSON con array de notificaciones
 *
 * Lógica:
 *   1. Recupera mensajes del funcionario ordenados por fecha descendente
 *   2. Limpia caracteres especiales y normaliza acentos usando función cambia_acentos
 *   3. Retorna máximo 4 notificaciones más recientes
 *
 * Dependencias:
 *   - Tabla: funcionario_mensaje (notificaciones del funcionario)
 *   - Función: cambia_acentos (normalización de caracteres especiales)
 *
 * Mejoras aplicadas:
 *   - Conversión cursor manual → FOR LOOP
 *   - Constante para límite de mensajes
 *   - Uso de función cambia_acentos en lugar de TRANSLATE/REGEXP_REPLACE
 *   - Eliminación de variables no utilizadas
 *   - Inicialización explícita de variables
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   - Limita resultados a 4 mensajes más recientes
 *   - Los mensajes se ordenan por fecha descendente (más recientes primero)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Cursor a FOR LOOP, constantes
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_mensajes(
    i_id_funcionario IN VARCHAR2
) RETURN CLOB IS
    -- Constantes
    C_MAX_MENSAJES        CONSTANT NUMBER := 4;
    
    -- Variables
    v_resultado           CLOB;
    v_datos               CLOB;
    v_contador            NUMBER := 0;
    
BEGIN
    v_datos := '';
    
    -- Itera sobre los mensajes del funcionario, ordenados por fecha descendente
    FOR rec IN (
        SELECT DISTINCT
            JSON_OBJECT(
                'notificacion' IS cambia_acentos(mensaje)
            ) AS datos_json,
            fecha_mensaje
        FROM funcionario_mensaje
        WHERE id_funcionario = i_id_funcionario
        ORDER BY fecha_mensaje DESC
    ) LOOP
        v_contador := v_contador + 1;
        
        -- Limita a las 4 notificaciones más recientes
        IF v_contador = 1 THEN
            v_datos := rec.datos_json;
        ELSIF v_contador <= C_MAX_MENSAJES THEN
            v_datos := v_datos || ',' || rec.datos_json;
        END IF;
    END LOOP;
    
    v_resultado := '"notificaciones": [' || v_datos || ']';
    RETURN v_resultado;
    
END wbs_devuelve_mensajes;
/

