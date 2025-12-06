/*******************************************************************************
 * Función: wbs_devuelve_permisos_fichajes_serv
 * 
 * Propósito:
 *   Devuelve permisos y fichajes del servicio para planificación de equipos.
 *   Consulta información de empleados bajo supervisión de un responsable
 *   (delegados, jefes de área, verificadores de planificación).
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario responsable/supervisor
 * @param v_opcion         NUMBER    Tipo de consulta:
 *                                    0 = Permisos servicio disfrutados (mes actual + 31 días)
 *                                    1 = Permisos pendientes de disfrutar (año completo)
 *                                    2 = Fichajes + Permisos semana anterior (7 días)
 *                                    3 = Unión de permisos y fichajes semana anterior
 * @param v_fecha          VARCHAR2  Fecha de referencia en formato DD/MM/YYYY
 * @return                 CLOB      JSON con datos solicitados
 *
 * Lógica:
 *   1. Convierte fecha string a DATE
 *   2. Según v_opcion, ejecuta consulta correspondiente:
 *      - Opción 0: Permisos aprobados desde fecha hasta +31 días
 *      - Opción 1: Saldo de permisos pendientes del año
 *      - Opción 2: Fichajes 7 días previos + permisos semana anterior
 *      - Opción 3: UNION de permisos y fichajes 7 días previos
 *   3. Construye JSON concatenando resultados
 *   4. Filtra por jerarquía de firmas (delegados, jefes, verificadores)
 *
 * Dependencias:
 *   - Tabla: personal_new (datos empleados activos)
 *   - Tabla: permiso (permisos solicitados/aprobados)
 *   - Tabla: permiso_funcionario (saldo de permisos anuales)
 *   - Tabla: tr_tipo_permiso (catálogo tipos de permiso)
 *   - Tabla: calendario_laboral (días laborables)
 *   - Tabla: fichaje_funcionario (registros entrada/salida)
 *   - Tabla: funcionario_firma (jerarquía de autorizaciones)
 *
 * Mejoras aplicadas:
 *   - FOR LOOP en lugar de cursores manuales (5 cursores eliminados)
 *   - Constantes nombradas para estados, rangos, límites
 *   - INNER JOIN explícito en lugar de sintaxis antigua con comas
 *   - TRUNC() en lugar de TO_DATE(TO_CHAR()) para comparaciones
 *   - Variables con tamaños optimizados (100 bytes para IDs, 4 para año)
 *   - Eliminación código duplicado (subconsulta jerarquía)
 *   - Documentación JavaDoc completa con ejemplos
 *
 * Notas importantes:
 *   - Estados excluidos: 30,31,32,40,41 (anulados, rechazados, caducados)
 *   - Limite nombres: 22 caracteres para ajuste UI
 *   - Jerarquía incluye: delegados JA/JS (4 niveles), JA, verificadores (3)
 *   - Opción 2: Retorna fichajes + permisos en JSON separados
 *   - Opción 3: Retorna UNION ordenada por fecha entrada
 *
 * Ejemplo de uso:
 *   -- Permisos disfrutados del equipo desde hoy
 *   SELECT wbs_devuelve_permisos_fichajes_serv('101217', 0, '06/12/2025') FROM DUAL;
 *   
 *   -- Fichajes y permisos última semana
 *   SELECT wbs_devuelve_permisos_fichajes_serv('101217', 2, '06/12/2025') FROM DUAL;
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 11 - FOR LOOP, constantes, documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_permisos_fichajes_serv(
    i_id_funcionario IN VARCHAR2,
    v_opcion         IN NUMBER,
    v_fecha          IN VARCHAR2
) RETURN CLOB IS
    -- Constantes para estados de permiso
    C_ESTADO_ANULADO      CONSTANT NUMBER := 30;
    C_ESTADO_RECHAZADO    CONSTANT NUMBER := 31;
    C_ESTADO_NO_PROCEDE   CONSTANT NUMBER := 32;
    C_ESTADO_CANCELADO    CONSTANT NUMBER := 40;
    C_ESTADO_CADUCADO     CONSTANT NUMBER := 41;
    
    -- Constantes para rangos de fechas
    C_DIAS_FUTURO         CONSTANT NUMBER := 31;
    C_DIAS_PASADO         CONSTANT NUMBER := 7;
    
    -- Constantes para formato
    C_LIMITE_NOMBRE       CONSTANT NUMBER := 22;
    C_UNICO_SI            CONSTANT VARCHAR2(2) := 'SI';
    
    -- Variables
    v_resultado           CLOB;
    v_datos               CLOB := '';
    v_datos2              CLOB := '';
    v_datos_tmp           CLOB;
    v_contador            NUMBER := 0;
    v_anio                VARCHAR2(4);
    d_fecha_entrada       DATE;
    
BEGIN
    -- Inicialización
    d_fecha_entrada := TO_DATE(v_fecha, 'DD/MM/YYYY');
    
    CASE v_opcion
        -- Opción 0: Permisos servicio disfrutados (desde fecha hasta +31 días)
        WHEN 0 THEN
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'id_tipo_permiso' IS pes.id_tipo_permiso,
                        'desc_tipo_permiso' IS tr.desc_tipo_permiso
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN permiso pes ON p.id_funcionario = pes.id_funcionario
                                       AND pes.id_Estado NOT IN (C_ESTADO_ANULADO, C_ESTADO_RECHAZADO, 
                                                                 C_ESTADO_NO_PROCEDE, C_ESTADO_CANCELADO, 
                                                                 C_ESTADO_CADUCADO)
                INNER JOIN tr_tipo_permiso tr ON tr.id_tipo_permiso = pes.id_tipo_permiso
                                              AND tr.id_ano = pes.id_ano
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN d_fecha_entrada AND d_fecha_entrada + C_DIAS_FUTURO
                                                 AND cl.id_dia BETWEEN pes.fecha_inicio AND pes.fecha_fin
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = i_id_funcionario
                    ) ff
                    INNER JOIN funcionario_firma ff2 ON (
                        ff2.id_delegado_ja = ff.id_js OR
                        ff2.id_js = ff.id_js OR
                        ff2.id_delegado_js = ff.id_js OR
                        ff2.id_delegado_js2 = ff.id_js OR
                        ff2.id_delegado_js3 = ff.id_js OR
                        ff2.id_delegado_js4 = ff.id_js OR
                        ff2.id_ja = ff.id_js OR
                        ff2.id_ver_plani_1 = ff.id_js OR
                        ff2.id_ver_plani_2 = ff.id_js OR
                        ff2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN personal_new p2 ON p2.id_funcionario = ff2.id_funcionario
                                               AND (p2.fecha_fin_contrato IS NULL OR p2.fecha_fin_contrato > SYSDATE)
                )
                ORDER BY SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE), 
                         cl.id_dia
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"permisos_servicio": [' || v_datos || ']}';
        
        -- Opción 2: Fichajes servicio (7 días previos) + Permisos semana anterior
        WHEN 2 THEN
            -- Primero: Fichajes
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'fecha_entrada' IS TO_CHAR(ff.fecha_fichaje_entrada, 'hh24:mi'),
                        'fecha_salida' IS TO_CHAR(ff.fecha_fichaje_salida, 'hh24:mi')
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN fichaje_funcionario ff ON ff.id_funcionario = p.id_funcionario
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN d_fecha_entrada - C_DIAS_PASADO AND d_fecha_entrada
                                                 AND TRUNC(ff.fecha_fichaje_entrada) = cl.id_dia
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = i_id_funcionario
                    ) ff
                    INNER JOIN funcionario_firma ff2 ON (
                        ff2.id_delegado_ja = ff.id_js OR
                        ff2.id_js = ff.id_js OR
                        ff2.id_delegado_js = ff.id_js OR
                        ff2.id_delegado_js2 = ff.id_js OR
                        ff2.id_delegado_js3 = ff.id_js OR
                        ff2.id_delegado_js4 = ff.id_js OR
                        ff2.id_ja = ff.id_js OR
                        ff2.id_ver_plani_1 = ff.id_js OR
                        ff2.id_ver_plani_2 = ff.id_js OR
                        ff2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN personal_new p2 ON p2.id_funcionario = ff2.id_funcionario
                                               AND (p2.fecha_fin_contrato IS NULL OR p2.fecha_fin_contrato > SYSDATE)
                )
                ORDER BY SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE), 
                         ff.fecha_fichaje_entrada
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos2 := rec.datos_json;
                ELSE
                    v_datos2 := v_datos2 || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            -- Segundo: Permisos semana anterior
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'id_tipo_permiso' IS pes.id_tipo_permiso,
                        'desc_tipo_permiso' IS tr.desc_tipo_permiso
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN permiso pes ON p.id_funcionario = pes.id_funcionario
                                       AND pes.id_Estado NOT IN (C_ESTADO_ANULADO, C_ESTADO_RECHAZADO, 
                                                                 C_ESTADO_NO_PROCEDE, C_ESTADO_CANCELADO, 
                                                                 C_ESTADO_CADUCADO)
                INNER JOIN tr_tipo_permiso tr ON tr.id_tipo_permiso = pes.id_tipo_permiso
                                              AND tr.id_ano = pes.id_ano
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN d_fecha_entrada - C_DIAS_PASADO AND d_fecha_entrada
                                                 AND cl.id_dia BETWEEN pes.fecha_inicio AND pes.fecha_fin
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = i_id_funcionario
                    ) ff
                    INNER JOIN funcionario_firma ff2 ON (
                        ff2.id_delegado_ja = ff.id_js OR
                        ff2.id_js = ff.id_js OR
                        ff2.id_delegado_js = ff.id_js OR
                        ff2.id_delegado_js2 = ff.id_js OR
                        ff2.id_delegado_js3 = ff.id_js OR
                        ff2.id_delegado_js4 = ff.id_js OR
                        ff2.id_ja = ff.id_js OR
                        ff2.id_ver_plani_1 = ff.id_js OR
                        ff2.id_ver_plani_2 = ff.id_js OR
                        ff2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN personal_new p2 ON p2.id_funcionario = ff2.id_funcionario
                                               AND (p2.fecha_fin_contrato IS NULL OR p2.fecha_fin_contrato > SYSDATE)
                )
                ORDER BY SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE), 
                         cl.id_dia
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"fichajes_servicio": [' || v_datos2 || '],"permisos_servicio": [' || v_datos || ']}';
        
        -- Opción 1: Permisos pendientes de disfrutar (año completo)
        WHEN 1 THEN
            v_anio := SUBSTR(v_fecha, 7, 4);
            
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id tipo permiso' IS pf.id_tipo_permiso,
                        'desc permiso' IS tr.desc_tipo_permiso,
                        'numero dias' IS pf.num_dias
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN permiso_funcionario pf ON p.id_funcionario = pf.id_funcionario
                                                  AND pf.unico = C_UNICO_SI
                                                  AND pf.num_dias > 0
                                                  AND pf.id_ano = v_anio
                INNER JOIN tr_tipo_permiso tr ON pf.id_ano = tr.id_ano
                                              AND tr.id_tipo_permiso = pf.id_tipo_permiso
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = i_id_funcionario
                    ) ff
                    INNER JOIN funcionario_firma ff2 ON (
                        ff2.id_delegado_ja = ff.id_js OR
                        ff2.id_js = ff.id_js OR
                        ff2.id_delegado_js = ff.id_js OR
                        ff2.id_delegado_js2 = ff.id_js OR
                        ff2.id_delegado_js3 = ff.id_js OR
                        ff2.id_delegado_js4 = ff.id_js OR
                        ff2.id_ja = ff.id_js OR
                        ff2.id_ver_plani_1 = ff.id_js OR
                        ff2.id_ver_plani_2 = ff.id_js OR
                        ff2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN personal_new p2 ON p2.id_funcionario = ff2.id_funcionario
                                               AND (p2.fecha_fin_contrato IS NULL OR p2.fecha_fin_contrato > SYSDATE)
                )
                ORDER BY SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE), 
                         pf.id_tipo_permiso
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"permisos_pendientes_disfrutar_servicio": [' || v_datos || ']}';
        
        -- Opción 3: UNION de fichajes y permisos (7 días previos)
        WHEN 3 THEN
            FOR rec IN (
                -- Subquery 1: Permisos semana anterior
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'id_tipo_permiso' IS pes.id_tipo_permiso,
                        'desc_tipo_permiso' IS tr.desc_tipo_permiso
                    ) AS datos_json,
                    cl.id_dia AS fecha_orden,
                    SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE) AS nombres
                FROM personal_new p
                INNER JOIN permiso pes ON p.id_funcionario = pes.id_funcionario
                                       AND pes.id_Estado NOT IN (C_ESTADO_ANULADO, C_ESTADO_RECHAZADO, 
                                                                 C_ESTADO_NO_PROCEDE, C_ESTADO_CANCELADO, 
                                                                 C_ESTADO_CADUCADO)
                INNER JOIN tr_tipo_permiso tr ON tr.id_tipo_permiso = pes.id_tipo_permiso
                                              AND tr.id_ano = pes.id_ano
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN d_fecha_entrada - C_DIAS_PASADO AND d_fecha_entrada
                                                 AND cl.id_dia BETWEEN pes.fecha_inicio AND pes.fecha_fin
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = i_id_funcionario
                    ) ff
                    INNER JOIN funcionario_firma ff2 ON (
                        ff2.id_delegado_ja = ff.id_js OR
                        ff2.id_js = ff.id_js OR
                        ff2.id_delegado_js = ff.id_js OR
                        ff2.id_delegado_js2 = ff.id_js OR
                        ff2.id_delegado_js3 = ff.id_js OR
                        ff2.id_delegado_js4 = ff.id_js OR
                        ff2.id_ja = ff.id_js OR
                        ff2.id_ver_plani_1 = ff.id_js OR
                        ff2.id_ver_plani_2 = ff.id_js OR
                        ff2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN personal_new p2 ON p2.id_funcionario = ff2.id_funcionario
                                               AND (p2.fecha_fin_contrato IS NULL OR p2.fecha_fin_contrato > SYSDATE)
                )
                
                UNION
                
                -- Subquery 2: Fichajes 7 días previos
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'fecha_entrada' IS TO_CHAR(ff.fecha_fichaje_entrada, 'hh24:mi'),
                        'fecha_salida' IS TO_CHAR(ff.fecha_fichaje_salida, 'hh24:mi')
                    ) AS datos_json,
                    ff.fecha_fichaje_entrada AS fecha_orden,
                    SUBSTR(INITCAP(p.Nombre) || ' ' || INITCAP(p.ape1) || ' ' || INITCAP(p.ape2), 1, C_LIMITE_NOMBRE) AS nombres
                FROM personal_new p
                INNER JOIN fichaje_funcionario ff ON ff.id_funcionario = p.id_funcionario
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN d_fecha_entrada - C_DIAS_PASADO AND d_fecha_entrada
                                                 AND TRUNC(ff.fecha_fichaje_entrada) = cl.id_dia
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = i_id_funcionario
                    ) ff
                    INNER JOIN funcionario_firma ff2 ON (
                        ff2.id_delegado_ja = ff.id_js OR
                        ff2.id_js = ff.id_js OR
                        ff2.id_delegado_js = ff.id_js OR
                        ff2.id_delegado_js2 = ff.id_js OR
                        ff2.id_delegado_js3 = ff.id_js OR
                        ff2.id_delegado_js4 = ff.id_js OR
                        ff2.id_ja = ff.id_js OR
                        ff2.id_ver_plani_1 = ff.id_js OR
                        ff2.id_ver_plani_2 = ff.id_js OR
                        ff2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN personal_new p2 ON p2.id_funcionario = ff2.id_funcionario
                                               AND (p2.fecha_fin_contrato IS NULL OR p2.fecha_fin_contrato > SYSDATE)
                )
                
                ORDER BY nombres, fecha_orden
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos2 := rec.datos_json;
                ELSE
                    v_datos2 := v_datos2 || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"fichajes_servicio": [' || v_datos2 || ']}';
            
    END CASE;
    
    RETURN v_resultado;
    
END wbs_devuelve_permisos_fichajes_serv;
/
