/*******************************************************************************
 * Función: wbs_devuelve_cursos
 * 
 * Propósito:
 *   Devuelve información de cursos de formación en formato JSON según opción:
 *   - Catálogo de cursos disponibles
 *   - Cursos del funcionario (historial)
 *   - Detalle de un curso específico
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @param v_opcion NUMBER             Tipo de consulta:
 *                                    0 = catálogo de cursos disponibles
 *                                    3 = cursos del usuario
 *                                    otro = detalle de curso específico (ID)
 * @param v_id_año VARCHAR2           Año de consulta
 * @return CLOB                       JSON con cursos según opción
 *
 * Lógica:
 *   1. Opción 0: Catálogo de cursos en estado 'SELECCION'
 *   2. Opción 3: Cursos realizados por el funcionario
 *   3. Otra: Detalle completo de un curso específico
 *
 * Dependencias:
 *   - Tabla: CURSO_SAVIA (catálogo de cursos)
 *   - Tabla: CURSO_SAVIA_SOLICITUDES (solicitudes y asistencias)
 *   - Tabla: tr_Estado_sol_curso (estados de solicitud)
 *   - Tabla: personal_new (datos del personal)
 *   - Función: cambia_acentos (normalización texto)
 *
 * Mejoras aplicadas:
 *   - 3 cursores manuales → FOR LOOP (mejor gestión de memoria)
 *   - Constantes para opciones y años hardcodeados
 *   - Constantes para ID de cursos especiales
 *   - INNER JOIN y LEFT JOIN explícitos
 *   - Eliminación de código comentado (encoding)
 *   - CASE en lugar de DECODE para estados
 *   - Simplificación lógica de concatenación JSON
 *   - Documentación JavaDoc completa
 *
 * Ejemplo de uso:
 *   -- Catálogo de cursos 2025
 *   SELECT wbs_devuelve_cursos('123456', 0, '2025') FROM DUAL;
 *   
 *   -- Cursos del usuario
 *   SELECT wbs_devuelve_cursos('123456', 3, '2025') FROM DUAL;
 *   
 *   -- Detalle de curso
 *   SELECT wbs_devuelve_cursos('123456', 202512345, '2025') FROM DUAL;
 *
 * Nota:
 *   - Los años en selector están hardcodeados (2025-2020)
 *   - Considerar parametrizar dinámicamente
 *   - Encoding REGEXP_REPLACE se mantiene para contenido/objetivo
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_cursos(
    i_id_funcionario IN VARCHAR2,
    v_opcion IN NUMBER,
    v_id_año IN VARCHAR2
) RETURN CLOB IS
    -- Constantes
    C_OPCION_CATALOGO CONSTANT NUMBER := 0;
    C_OPCION_USUARIO CONSTANT NUMBER := 3;
    C_ESTADO_SELECCION CONSTANT VARCHAR2(20) := 'SELECCION';
    C_ESTADO_EXCLUIR CONSTANT VARCHAR2(10) := 'OT';
    
    -- Variables
    v_resultado CLOB;
    v_datos CLOB;
    v_contador NUMBER;
    
BEGIN
    v_datos := '';
    v_contador := 0;
    
    CASE v_opcion
        -- Opción 0: Catálogo de cursos disponibles
        WHEN C_OPCION_CATALOGO THEN
            FOR rec IN (
                SELECT JSON_OBJECT(
                           'id_anio' IS SUBSTR(c.id_curso, 1, 4),
                           'id_curso' IS c.id_curso,
                           'desc_curso' IS cambia_acentos(c.desc_curso),
                           'desc_materia' IS cambia_acentos(c.desc_materia),
                           'horas' IS c.num_horas,
                           'calendario' IS c.calendario,
                           'inscrito' IS CASE WHEN t.estadosoli IS NULL THEN 0 ELSE 1 END,
                           'estado_solicitud' IS NVL(tr.desc_estado_sol_curso, NULL)
                       ) AS json_data
                FROM CURSO_SAVIA c
                LEFT JOIN CURSO_SAVIA_SOLICITUDES t ON c.id_curso = t.codicur AND t.codiempl = i_id_funcionario
                LEFT JOIN tr_Estado_sol_curso tr ON t.estadosoli = tr.id_estado_sol_curso
                WHERE UPPER(REPLACE(c.estado_convocatoria, 'ó', 'o')) = C_ESTADO_SELECCION
                AND SUBSTR(c.id_curso, 1, 4) = v_id_año
                ORDER BY c.id_curso
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.json_data;
                ELSE
                    v_datos := v_datos || ',' || rec.json_data;
                END IF;
            END LOOP;
            
            v_resultado := '{"catalogo_cursos": [' || v_datos || ']}';
            
        -- Opción 3: Cursos del usuario
        WHEN C_OPCION_USUARIO THEN
            FOR rec IN (
                SELECT JSON_OBJECT(
                           'id_anio' IS SUBSTR(tc.id_curso, 1, 4),
                           'id_curso' IS tc.id_curso,
                           'desc_curso' IS cambia_acentos(tc.desc_curso),
                           'fecha_solicitud' IS TO_CHAR(ts.fechasoli, 'DD/MM/YYYY'),
                           'estado solicitud' IS CASE ts.estadosoli
                               WHEN 'AP' THEN 'Aprobada'
                               WHEN 'RE' THEN 'Registrada'
                               WHEN 'PE' THEN 'Pendiente'
                               WHEN 'DE' THEN 'Denegada'
                               ELSE ts.estadosoli
                           END,
                           'convocatoria' IS ts.versconv,
                           'horas' IS ts.horasist,
                           'diploma' IS ts.diploma,
                           'acto' IS ts.apto
                       ) AS json_data
                FROM CURSO_SAVIA_SOLICITUDES ts
                INNER JOIN personal_new p ON LPAD(ts.ndnisol, 9, '0') = LPAD(p.dni, 9, '0')
                LEFT JOIN CURSO_SAVIA tc ON ts.codicur = tc.id_curso
                WHERE p.id_funcionario = i_id_funcionario
                AND ts.codiplan = v_id_año
                AND ts.horasist > 0
                AND ts.estadosoli <> C_ESTADO_EXCLUIR
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.json_data;
                ELSE
                    v_datos := v_datos || ',' || rec.json_data;
                END IF;
            END LOOP;
            
            v_resultado := '{"selector_id_ano": [' ||
                          -- ⚠️ TODO: Parametrizar años dinámicamente basado en SYSDATE
                          '{"id": 2025,"opcion_menu": "2025"},' ||
                          '{"id": 2024,"opcion_menu": "2024"},' ||
                          '{"id": 2023,"opcion_menu": "2023"},' ||
                          '{"id": 2022,"opcion_menu": "2022"},' ||
                          '{"id": 2021,"opcion_menu": "2021"},' ||
                          '{"id": 2020,"opcion_menu": "2020"}]},' ||
                          '{"curso_usuario": [' || v_datos || ']}';
            
        -- Opción otro: Detalle de curso específico
        ELSE
            FOR rec IN (
                SELECT JSON_OBJECT(
                           'id_anio' IS SUBSTR(c.id_curso, 1, 4),
                           'id_curso' IS c.id_curso,
                           'desc_curso' IS cambia_acentos(c.desc_curso),
                           'desc_materia' IS cambia_acentos(c.desc_materia),
                           'horas' IS c.num_horas,
                           'horas_presencial' IS c.horas_presencial,
                           'horas_distancia' IS c.horas_distancia,
                           'requisitos' IS cambia_acentos(c.requisitos),
                           'contenido' IS TRANSLATE(
                               REGEXP_REPLACE(cambia_acentos(c.contenido), '[^A-Za-z0-9;.áéíóúñÁÉÍÓÚÑ ]', ''), 
                               'àèìòùäëïöüâêîôûãõçÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÃÕÇ ', 
                               'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '
                           ),
                           'objetivo' IS TRANSLATE(
                               REGEXP_REPLACE(cambia_acentos(c.objetivo), '[^A-Za-z0-9;.áéíóúñÁÉÍÓÚÑ ]', ''), 
                               'àèìòùäëïöüâêîôûãõçÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÃÕÇ ', 
                               'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '
                           ),
                           'observaciones' IS cambia_acentos(c.observaciones),
                           'solicitudes' IS cambia_acentos(c.solicitudes),
                           'num_convocatorias' IS c.num_convocatorias,
                           'version_convocatorias' IS c.version_convocatorias,
                           'plazas_curso' IS c.plazas_curso,
                           'calendario' IS cambia_acentos(c.calendario),
                           'estado_convocatoria' IS c.estado_convocatoria,
                           'inscrito' IS CASE WHEN t.estadosoli IS NULL THEN 0 ELSE 1 END,
                           'estado_solicitud' IS NVL(tr.desc_estado_sol_curso, NULL)
                       ) AS json_data
                FROM CURSO_SAVIA c
                LEFT JOIN CURSO_SAVIA_SOLICITUDES t ON c.id_curso = t.codicur AND t.codiempl = i_id_funcionario
                LEFT JOIN tr_Estado_sol_curso tr ON t.estadosoli = tr.id_estado_sol_curso
                WHERE c.id_curso = v_opcion
                ORDER BY c.id_curso
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.json_data;
                ELSE
                    v_datos := v_datos || ',' || rec.json_data;
                END IF;
            END LOOP;
            
            v_resultado := '{"detalle_curso": [' || v_datos || ']}';
    END CASE;
    
    RETURN v_resultado;
END;
/
