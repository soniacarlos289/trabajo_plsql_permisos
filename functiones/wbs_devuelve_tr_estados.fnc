/*******************************************************************************
 * Función: wbs_devuelve_tr_estados
 * 
 * Propósito:
 *   Devuelve catálogos y tipos de referencia (TR) para diferentes entidades
 *   del sistema: estados de permisos, tipos de permiso, ausencias, cursos,
 *   incidencias de fichaje, grados y tipos de días.
 *
 * @param opcion VARCHAR2  Código del catálogo a consultar (1-7)
 * @param anio   NUMBER    Año para filtrar tipos de permiso/ausencia
 * @return CLOB            JSON con elementos del catálogo solicitado
 *
 * Opciones:
 *   - '1': Estados de permisos/ausencias
 *   - '2': Tipos de permiso por año
 *   - '3': Tipos de ausencia
 *   - '4': Estados de solicitud de curso
 *   - '5': Tipos de motivo de incidencia de fichaje
 *   - '6': Grados de permisos
 *   - '7': Tipos de días
 *
 * Lógica:
 *   1. Según opción, consulta tabla TR correspondiente
 *   2. Normaliza caracteres especiales usando función cambia_acentos
 *   3. Construye JSON con todos los elementos del catálogo
 *   4. Retorna array JSON con los datos
 *
 * Dependencias:
 *   - Tabla: tr_estado_permiso (estados de permiso)
 *   - Tabla: tr_tipo_permiso (tipos de permiso por año)
 *   - Tabla: tr_tipo_ausencia (tipos de ausencia)
 *   - Tabla: tr_estado_sol_curso (estados solicitud curso)
 *   - Tabla: tr_tipo_incidiencia_fichaje (tipos incidencia)
 *   - Tabla: tr_grado (grados de permiso)
 *   - Tabla: tr_tipo_dias (tipos de días)
 *   - Función: cambia_acentos (normalización de caracteres)
 *
 * Mejoras aplicadas:
 *   - Conversión 7 cursores manuales → FOR LOOP
 *   - Uso de función cambia_acentos en lugar de TRANSLATE/REGEXP_REPLACE
 *   - Constantes nombradas para filtros y estados
 *   - Eliminación de variables no utilizadas
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   - Filtra ausencias anuladas (tr_anulado='NO')
 *   - Excluye ausencias con descripción '0 0' (datos de prueba)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Cursores a FOR LOOP, cambia_acentos
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_tr_estados(
    opcion IN VARCHAR2,
    anio   IN NUMBER
) RETURN CLOB IS
    -- Constantes
    C_ANULADO_NO          CONSTANT VARCHAR2(2) := 'NO';
    C_DESC_INVALIDA       CONSTANT VARCHAR2(3) := '0 0';
    
    -- Variables
    v_resultado           CLOB;
    v_datos               CLOB;
    v_contador            NUMBER := 0;
    
BEGIN
    v_datos := '';
    
    CASE opcion
        -- Opción 1: Estados de permisos/ausencias
        WHEN '1' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_estado_permiso' IS id_estado_permiso,
                        'estado_permiso' IS cambia_acentos(desc_estado_permiso)
                    ) AS datos_json,
                    id_estado_permiso
                FROM tr_estado_permiso
                ORDER BY id_estado_permiso
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"estados_permisos_ausencias": [' || v_datos || ']}';
        
        -- Opción 2: Tipos de permiso por año
        WHEN '2' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_tipo_permiso' IS id_tipo_permiso,
                        'desc_tipo_permiso' IS cambia_acentos(desc_tipo_permiso),
                        'anio' IS anio
                    ) AS datos_json,
                    id_tipo_permiso
                FROM tr_tipo_permiso
                WHERE id_ano = anio
                ORDER BY id_tipo_permiso
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"tipo_permisos_anio": [' || v_datos || ']}';
        
        -- Opción 3: Tipos de ausencia
        WHEN '3' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_tipo_ausencia' IS id_tipo_ausencia,
                        'desc_tipo_permiso' IS cambia_acentos(desc_tipo_ausencia),
                        'anio' IS anio
                    ) AS datos_json,
                    id_tipo_ausencia
                FROM tr_tipo_ausencia
                WHERE tr_anulado = C_ANULADO_NO
                  AND desc_tipo_ausencia <> C_DESC_INVALIDA
                ORDER BY id_tipo_ausencia
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"tipo_ausencias_anio": [' || v_datos || ']}';
        
        -- Opción 4: Estados de solicitud de curso
        WHEN '4' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_estado_sol_curso' IS id_estado_sol_curso,
                        'desc_estado_sol_curso' IS desc_estado_sol_curso
                    ) AS datos_json,
                    id_estado_sol_curso
                FROM tr_estado_sol_curso
                ORDER BY id_estado_sol_curso
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"estados_solicitudes_curso": [' || v_datos || ']}';
        
        -- Opción 5: Tipos de motivo de incidencia de fichaje
        WHEN '5' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_estado_motivo_fichaje' IS id_tipo_incidencia,
                        'desc_estado_motivo_fichaje' IS cambia_acentos(desc_tipo_incidencia)
                    ) AS datos_json,
                    id_tipo_incidencia
                FROM tr_tipo_incidiencia_fichaje
                ORDER BY id_tipo_incidencia
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"estados_incidencia_fichaje": [' || v_datos || ']}';
        
        -- Opción 6: Grados de permisos
        WHEN '6' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_estado_grado' IS id_grado,
                        'desc_estado_grado' IS cambia_acentos(desc_grado)
                    ) AS datos_json,
                    id_grado
                FROM tr_grado
                ORDER BY id_grado
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"estados_grado_permisos": [' || v_datos || ']}';
        
        -- Opción 7: Tipos de días
        WHEN '7' THEN
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_tipo_dias' IS id_tipo_dias,
                        'desc_tipo_dias' IS desc_tipo_dias
                    ) AS datos_json,
                    id_tipo_dias
                FROM tr_tipo_dias
                ORDER BY id_tipo_dias
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"tipo_dias_permisos": [' || v_datos || ']}';
        
        ELSE
            v_resultado := 'ERROR';
    END CASE;
    
    RETURN v_resultado;
    
END wbs_devuelve_tr_estados;
/

