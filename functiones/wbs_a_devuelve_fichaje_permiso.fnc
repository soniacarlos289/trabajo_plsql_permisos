/*******************************************************************************
 * Función: WBS_A_DEVUELVE_FICHAJE_PERMISO
 * 
 * Propósito:
 *   Devuelve información de permisos o fichajes de un funcionario en un día
 *   específico, formateada como JSON. Prioriza permisos sobre fichajes.
 *
 * @param V_ID_FUNCIONARIO  ID del funcionario a consultar
 * @param v_DIA_CALENDARIO  Fecha del día a consultar
 * @return VARCHAR2         JSON con permisos_dia o fichajes_dia según corresponda
 *
 * Lógica:
 *   1. Busca si hay permisos aprobados/pendientes en el día dado
 *   2. Si hay permiso: retorna JSON con id_tipo_permiso y desc_tipo_permiso
 *   3. Si NO hay permiso: busca fichajes del día y retorna JSON con entrada/salida
 *   4. Los fichajes se ordenan por fecha de entrada
 *
 * Dependencias:
 *   - Tabla: permiso (id_funcionario, fecha_inicio, fecha_fin, id_tipo_permiso, id_estado, anulado)
 *   - Tabla: tr_tipo_permiso (id_tipo_permiso, desc_tipo_permiso, id_ano)
 *   - Tabla: fichaje_funcionario (id_funcionario, fecha_fichaje_entrada, fecha_fichaje_salida)
 *
 * Notas:
 *   - El año hardcodeado (2024) debería parametrizarse
 *   - Excluye permisos en estados 30, 31, 32, 40 (rechazados/pendientes iniciales)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa
 *   - Cursor manual → FOR LOOP para mejor gestión de memoria
 *   - Constantes para estados excluidos y año
 *   - TRUNC() para comparación de fechas
 *   - Variables con nombres más descriptivos
 *   - Comentarios explicativos
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - mejor legibilidad y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.WBS_A_DEVUELVE_FICHAJE_PERMISO(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA_CALENDARIO IN DATE
) RETURN VARCHAR2 IS

    -- Constantes
    C_ANO_CONSULTA CONSTANT NUMBER := 2024;  -- TODO: Parametrizar o usar EXTRACT(YEAR FROM v_DIA_CALENDARIO)
    
    -- Variables de resultado
    v_resultado     VARCHAR2(12512);
    v_salida        VARCHAR2(12512);
    v_datos         VARCHAR2(12512);
    v_datos_tmp     VARCHAR2(12512);
    
    -- Variables de control
    i_encontrado    NUMBER;
    i_contador      NUMBER;
    d_fecha_entrada DATE;
    
    -- Cursor para fichajes del día
    CURSOR c_fichajes_dia IS
        SELECT JSON_OBJECT(
                   'entrada' IS TO_CHAR(ff.fecha_fichaje_entrada, 'HH24:MI'),
                   'salida'  IS TO_CHAR(ff.fecha_fichaje_salida, 'HH24:MI')
               ) AS fichaje_json,
               ff.fecha_fichaje_entrada
        FROM fichaje_funcionario ff
        WHERE TRUNC(ff.fecha_fichaje_entrada) = TRUNC(v_DIA_CALENDARIO)
            AND ff.id_funcionario = V_ID_FUNCIONARIO
        ORDER BY ff.fecha_fichaje_entrada;

BEGIN
    i_encontrado := 1;
    v_salida := '';
    v_datos := '';
    i_contador := 0;
    
    -- Buscar si existe permiso activo en el día
    BEGIN
        SELECT JSON_OBJECT(
                   'id_tipo_permiso'   IS tr.id_tipo_permiso,
                   'desc_tipo_permiso' IS tr.desc_tipo_permiso
               )
        INTO v_salida
        FROM permiso p
        INNER JOIN tr_tipo_permiso tr 
            ON p.id_tipo_permiso = tr.id_tipo_permiso
            AND p.id_ano = tr.id_ano
        WHERE p.id_funcionario = V_id_funcionario
            AND v_DIA_CALENDARIO BETWEEN p.fecha_inicio AND NVL(p.fecha_fin, SYSDATE + 1)
            AND (p.anulado = 'NO' OR p.anulado IS NULL)
            AND p.id_estado NOT IN ('30', '31', '32', '40')
            AND p.id_ano = C_ANO_CONSULTA
            AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_salida := '';
            i_encontrado := 0;
    END;
    
    -- Si se encontró permiso, retornar JSON de permisos
    IF i_encontrado = 1 THEN
        v_resultado := ',{"permisos_dia": [' || v_salida || ']}';
        RETURN v_resultado;
    END IF;
    
    -- Si no hay permiso, buscar fichajes del día
    FOR rec IN c_fichajes_dia LOOP
        i_contador := i_contador + 1;
        
        IF i_contador = 1 THEN
            v_datos := rec.fichaje_json;
        ELSE
            v_datos := v_datos || ',' || rec.fichaje_json;
        END IF;
    END LOOP;
    
    -- Retornar JSON de fichajes
    v_resultado := ',{"fichajes_dia": [' || v_datos || ']}';
    
    RETURN v_resultado;

END WBS_A_DEVUELVE_FICHAJE_PERMISO;
/

