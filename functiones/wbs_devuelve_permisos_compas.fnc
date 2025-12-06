/*******************************************************************************
 * Función: wbs_devuelve_permisos_compas
 * 
 * Propósito:
 *   Devuelve compañeros de trabajo que están fuera de la oficina (en permiso)
 *   en el mismo grupo del funcionario solicitante.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario solicitante
 * @param cuantos_permisos NUMBER    Cantidad de resultados (0=todos)
 * @return VARCHAR2                  JSON con array de compañeros fuera
 *
 * Lógica:
 *   1. Busca funcionarios que están en el mismo grupo de firma
 *   2. Filtra por permisos activos hoy (entre fecha_inicio y fecha_fin)
 *   3. Solo muestra permisos en estado '80' (aprobado/activo)
 *   4. Construye JSON con datos y foto de cada compañero
 *
 * Dependencias:
 *   - Tabla: funcionario_firma (relación de grupos de trabajo)
 *   - Tabla: personal_new (datos del empleado)
 *   - Tabla: permiso (solicitudes de permiso)
 *
 * Mejoras aplicadas:
 *   - Conversión cursor manual → FOR LOOP
 *   - Constantes nombradas para estado y URL
 *   - INNER JOIN explícito en lugar de sintaxis antigua
 *   - TRUNC para comparaciones de fechas con SYSDATE
 *   - Inicialización explícita de variables
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   - Estado '80' representa permisos aprobados y activos
 *   - URL de fotos apunta a servidor de producción
 *   - La función no filtra al propio funcionario solicitante
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Cursor a FOR LOOP, constantes
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_permisos_compas(
    i_id_funcionario IN VARCHAR2,
    cuantos_permisos IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes
    C_ESTADO_APROBADO     CONSTANT VARCHAR2(2) := '80';
    C_URL_FOTO_BASE       CONSTANT VARCHAR2(100) := 'http://probarcelo.aytosa.inet/fotos_empleados/';
    
    -- Variables
    v_resultado           VARCHAR2(12000);
    v_datos               VARCHAR2(12000);
    v_contador            NUMBER := 0;
    
BEGIN
    v_datos := '';
    
    -- Itera sobre compañeros que están fuera de la oficina hoy
    FOR rec IN (
        SELECT DISTINCT
            JSON_OBJECT(
                'id_funcionario' IS pe.id_funcionario,
                'nombre' IS pe.nombre,
                'ape1' IS pe.ape1,
                'ape2' IS pe.ape2,
                'foto' IS C_URL_FOTO_BASE || pe.id_funcionario || '.jpg',
                'hasta' IS per.fecha_fin
            ) AS datos_json
        FROM funcionario_firma f
        INNER JOIN funcionario_firma f2 ON f.id_js = f2.id_js
        INNER JOIN personal_new pe ON f2.id_funcionario = pe.id_funcionario
        INNER JOIN permiso per ON per.id_funcionario = pe.id_funcionario
        WHERE f.id_funcionario = i_id_funcionario
          AND TRUNC(SYSDATE) BETWEEN per.fecha_inicio AND per.fecha_fin
          AND per.id_estado = C_ESTADO_APROBADO
        ORDER BY 1
    ) LOOP
        v_contador := v_contador + 1;
        
        -- Limita el número de resultados si se especificó
        IF cuantos_permisos = 0 OR v_contador <= cuantos_permisos THEN
            IF v_contador = 1 THEN
                v_datos := rec.datos_json;
            ELSE
                v_datos := v_datos || ',' || rec.datos_json;
            END IF;
        END IF;
    END LOOP;
    
    v_resultado := '"fuera_oficina": [' || v_datos || ']';
    RETURN v_resultado;
    
END wbs_devuelve_permisos_compas;
/

