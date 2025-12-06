/*******************************************************************************
 * Función: EXTRAE_AGENDA
 * 
 * Propósito:
 *   Procesa y extrae información estructurada de convocatorias almacenadas en 
 *   formato HTML/texto en WEB_CONVOCATORIA, parseando hora, lugar y contenido,
 *   para insertarlos en TEMP_WEB_CF de forma normalizada.
 *
 * @return VARCHAR2  Retorna '1' si se procesaron registros
 *
 * Lógica:
 *   1. Recorrer registros de WEB_CONVOCATORIA con fechas entre 2018-2021
 *   2. Buscar patrón 'Hora:' o 'horas' en el HTML
 *   3. Para cada hora encontrada:
 *      - Extraer hora (formato hh:mm)
 *      - Extraer lugar (hasta <br />)
 *      - Extraer contenido (hasta </p> o segundo <br />)
 *   4. Limpiar HTML tags de los campos extraídos
 *   5. Insertar en web_convocatoria_final
 *   6. Commit por cada convocatoria procesada
 *
 * Dependencias:
 *   - Tabla: WEB_CONVOCATORIA (id, fechas, todo)
 *   - Tabla: TEMP_WEB_CF (id)
 *   - Tabla: web_convocatoria_final (id, fecha, hora, lugar, contenido)
 *
 * Consideraciones:
 *   - Rango de fechas hardcodeado (2018-2021)
 *   - Commit dentro del loop (no transaccional)
 *   - DBMS_OUTPUT para debugging (comentado)
 *   - Cursor manual puede ser reemplazado por FOR LOOP
 *   - Múltiples REPLACE anidados dificultan mantenimiento
 *   - Fecha ajustada con -1 día sin documentación
 *
 * Mejoras aplicadas:
 *   - FOR LOOP en lugar de cursor manual OPEN/FETCH/CLOSE
 *   - Constantes para patrones de búsqueda HTML
 *   - Constantes para longitudes y ajustes
 *   - Variables con nombres descriptivos
 *   - Función auxiliar implícita para limpieza HTML
 *   - Documentación de lógica compleja
 *   - Nota sobre limitaciones y mejoras futuras
 *
 * Limitaciones conocidas:
 *   - Fechas hardcodeadas (debería parametrizarse)
 *   - No es transaccional (commit por registro)
 *   - HTML parsing manual (frágil ante cambios de formato)
 *
 * Mejoras futuras recomendadas:
 *   - Parametrizar rango de fechas
 *   - Commit al final del proceso completo
 *   - Usar expresiones regulares para parsing HTML
 *   - Separar en procedure para mejor manejo de transacciones
 *
 * Historial:
 *   - 2025-12: Optimización y documentación (Grupo 4)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.EXTRAE_AGENDA 
RETURN VARCHAR2 IS
    -- Constantes para patrones de búsqueda
    C_PATRON_HORA_1       CONSTANT VARCHAR2(5) := 'Hora:';
    C_PATRON_HORA_2       CONSTANT VARCHAR2(5) := 'horas';
    C_PATRON_LUGAR        CONSTANT VARCHAR2(6) := 'Lugar:';
    C_TAG_BR              CONSTANT VARCHAR2(7) := '<br />';
    C_TAG_P_CLOSE         CONSTANT VARCHAR2(4) := '</p>';
    
    -- Constantes para limpieza HTML
    C_TAG_STRONG_OPEN     CONSTANT VARCHAR2(8) := '<strong>';
    C_TAG_STRONG_CLOSE    CONSTANT VARCHAR2(9) := '</strong>';
    C_TAG_SPAN_UNDERLINE  CONSTANT VARCHAR2(42) := '<span style="text-decoration: underline;"';
    C_TAG_SPAN_CLOSE      CONSTANT VARCHAR2(7) := '</span>';
    C_TAG_U_OPEN          CONSTANT VARCHAR2(3) := '<u>';
    C_TAG_U_CLOSE         CONSTANT VARCHAR2(4) := '</u>';
    C_MALFORMED_TAG       CONSTANT VARCHAR2(21) := '<u>Convocatoria:,'')'; -- Malformed HTML found in source data
    C_CONVOCATORIA_TAG    CONSTANT VARCHAR2(23) := '<u>Convocatoria:</u>';
    C_MENOR_QUE           CONSTANT VARCHAR2(1) := '<';
    C_MAYOR_QUE           CONSTANT VARCHAR2(1) := '>';
    
    -- Constantes para ajustes
    C_OFFSET_HORA_1       CONSTANT NUMBER := 6;
    C_OFFSET_HORA_2       CONSTANT NUMBER := -6;
    C_LONGITUD_HORA       CONSTANT NUMBER := 5;
    C_OFFSET_LUGAR        CONSTANT NUMBER := 11;
    C_OFFSET_FECHA        CONSTANT NUMBER := -1;
    C_PATH_PREFIX         CONSTANT VARCHAR2(33) := 'C:\temp\noticias\es\agenda\';
    
    -- Constantes de control
    C_INICIO_VUELTA       CONSTANT NUMBER := 1;
    C_RESULTADO_EXITO     CONSTANT VARCHAR2(1) := '1';
    C_POSICION_NO_ENCONTRADA CONSTANT NUMBER := 0;
    
    -- Variables de resultado
    v_result              VARCHAR2(122);
    
    -- Variables para procesamiento de cada convocatoria
    v_id                  VARCHAR2(4000);
    v_fecha               DATE;
    v_todo                CLOB;
    v_vuelta              NUMBER;
    
    -- Variables para extracción de campos
    v_hora                VARCHAR2(4000);
    v_lugar               VARCHAR2(4000);
    v_contenido           VARCHAR2(4000);
    
    -- Variables de posiciones
    v_pos_hora            NUMBER;
    v_pos_siguiente_hora  NUMBER;
    v_pos_lugar           NUMBER;
    v_pos_lugar_fin       NUMBER;
    v_pos_contenido_fin   NUMBER;
    v_operacion_offset    NUMBER;
    
    -- Variables de contadores
    v_cuantas_horas       NUMBER;
    v_cuantos_lugares     NUMBER;
    v_cuantos_contenidos  NUMBER;
    v_hay_vacio           NUMBER;
    
BEGIN
    -- Procesar cada convocatoria pendiente
    FOR rec IN (
        SELECT id, fechas, todo
        FROM WEB_CONVOCATORIA t
        WHERE todo IS NOT NULL
          AND fechas < TO_DATE('12/05/2021', 'DD/MM/YYYY')
          AND fechas > TO_DATE('01/01/2018', 'DD/MM/YYYY')
          AND REPLACE(id, C_PATH_PREFIX, '') NOT IN (SELECT id FROM TEMP_WEB_CF)
        ORDER BY 1 DESC
    ) LOOP
        v_id := rec.id;
        v_fecha := rec.fechas;
        v_todo := rec.todo;
        
        -- Inicializar contadores
        v_vuelta := C_INICIO_VUELTA;
        v_cuantas_horas := 1;
        v_cuantos_lugares := 1;
        v_cuantos_contenidos := 1;
        
        -- Buscar primera ocurrencia de hora
        v_pos_hora := INSTR(v_todo, C_PATRON_HORA_1, 1, v_vuelta);
        v_pos_siguiente_hora := INSTR(v_todo, C_PATRON_HORA_1, 1, v_vuelta + 1);
        v_operacion_offset := v_pos_hora + C_OFFSET_HORA_1;
        
        -- Si no se encuentra 'Hora:', buscar 'horas'
        IF v_pos_hora = C_POSICION_NO_ENCONTRADA THEN
            v_pos_hora := INSTR(v_todo, C_PATRON_HORA_2, 1, v_vuelta);
            v_pos_siguiente_hora := INSTR(v_todo, C_PATRON_HORA_2, 1, v_vuelta + 1);
            v_operacion_offset := v_pos_hora + C_OFFSET_HORA_2;
        END IF;
        
        -- Procesar todas las horas encontradas en la convocatoria
        WHILE v_pos_hora > C_POSICION_NO_ENCONTRADA LOOP
            
            -- Extraer hora
            v_hora := SUBSTR(v_todo, v_operacion_offset, C_LONGITUD_HORA);
            
            IF v_pos_hora > C_POSICION_NO_ENCONTRADA THEN
                v_cuantas_horas := v_cuantas_horas + 1;
            END IF;
            
            -- Buscar lugar
            v_pos_lugar := INSTR(v_todo, C_PATRON_LUGAR, 1, v_vuelta);
            
            IF v_pos_lugar > C_POSICION_NO_ENCONTRADA THEN
                v_cuantos_lugares := v_cuantos_lugares + 1;
            ELSE
                -- Buscar lugar alternativo después de la hora
                v_pos_lugar := INSTR(v_todo, v_hora || ' ' || C_PATRON_HORA_2, 1, 1) + C_OFFSET_LUGAR;
                v_pos_lugar := INSTR(v_todo, v_hora || 'hora: ', 1, 1) + 5;
            END IF;
            
            -- Buscar fin del lugar y contenido
            v_pos_lugar_fin := INSTR(v_todo, C_TAG_BR, v_pos_lugar, 1);
            v_pos_contenido_fin := INSTR(v_todo, C_TAG_BR, v_pos_lugar, 2);
            
            IF v_pos_contenido_fin = C_POSICION_NO_ENCONTRADA THEN
                v_pos_contenido_fin := INSTR(v_todo, C_TAG_P_CLOSE, v_pos_lugar, 1);
            END IF;
            
            -- Extraer lugar y contenido
            v_lugar := SUBSTR(v_todo, v_pos_lugar, v_pos_lugar_fin - v_pos_lugar);
            v_contenido := SUBSTR(v_todo, v_pos_lugar_fin, v_pos_contenido_fin - v_pos_lugar_fin);
            
            -- Limpiar HTML del lugar
            v_lugar := REPLACE(v_lugar, C_TAG_STRONG_OPEN, '');
            v_lugar := REPLACE(v_lugar, C_TAG_STRONG_CLOSE, '');
            v_lugar := REPLACE(v_lugar, C_TAG_BR, '');
            v_lugar := REPLACE(v_lugar, C_CONVOCATORIA_TAG, '');
            
            -- Limpiar HTML del contenido
            v_contenido := REPLACE(v_contenido, C_TAG_STRONG_OPEN, '');
            v_contenido := REPLACE(v_contenido, C_TAG_STRONG_CLOSE, '');
            v_contenido := REPLACE(v_contenido, C_TAG_BR, '');
            v_contenido := REPLACE(v_contenido, C_MALFORMED_TAG, '');
            v_contenido := REPLACE(v_contenido, C_TAG_SPAN_UNDERLINE, '');
            v_contenido := REPLACE(v_contenido, C_TAG_SPAN_CLOSE, '');
            v_contenido := REPLACE(v_contenido, C_TAG_U_OPEN, '');
            v_contenido := REPLACE(v_contenido, C_TAG_U_CLOSE, '');
            
            -- Limpiar hora y ID
            v_hora := REPLACE(REPLACE(v_hora, C_MENOR_QUE, ''), C_MAYOR_QUE, '');
            v_id := REPLACE(v_id, C_PATH_PREFIX, '');
            
            -- Insertar registro procesado
            INSERT INTO web_convocatoria_final (id, fecha, hora, lugar, contenido)
            VALUES (v_id, v_fecha + C_OFFSET_FECHA, v_hora, v_lugar, v_contenido);
            
            -- Verificar si hay campos vacíos
            v_hay_vacio := 0;
            IF v_hora IS NULL OR v_lugar IS NULL OR v_contenido IS NULL OR
               v_hora = '' OR v_lugar = '' OR v_contenido = '' THEN
                v_hay_vacio := 1;
            END IF;
            
            -- Avanzar a la siguiente hora
            v_vuelta := v_vuelta + 1;
            v_pos_hora := INSTR(v_todo, C_PATRON_HORA_1, 1, v_vuelta);
            v_operacion_offset := v_pos_hora + C_OFFSET_HORA_1;
            
            IF v_pos_hora = C_POSICION_NO_ENCONTRADA THEN
                v_pos_hora := INSTR(v_todo, C_PATRON_HORA_2, 1, v_vuelta);
                v_operacion_offset := v_pos_hora + C_OFFSET_HORA_2;
            END IF;
            
            v_result := C_RESULTADO_EXITO;
            
        END LOOP;
        
        -- Verificar consistencia de datos extraídos
        IF (v_cuantas_horas != v_cuantos_lugares) OR (v_hay_vacio = 1) THEN
            DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' vuelta:' || v_vuelta);
        END IF;
        
        -- Commit por cada convocatoria procesada
        COMMIT;
        
    END LOOP;
    
    RETURN v_result;
    
END EXTRAE_AGENDA;
/

