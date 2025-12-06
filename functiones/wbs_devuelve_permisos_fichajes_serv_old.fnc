/*******************************************************************************
 * Función: wbs_devuelve_permisos_fichajes_serv_old (LEGACY - DEPRECATED)
 * 
 * ⚠️ DEPRECACIÓN: Esta es una versión legacy con ID hardcodeado (101217).
 *    Se recomienda migrar a wbs_devuelve_permisos_fichajes_serv.fnc
 *    que usa parámetro i_id_funcionario correctamente.
 *
 * Propósito:
 *   Devuelve permisos y fichajes del servicio para planificación.
 *   Consulta información de empleados bajo supervisión de un responsable.
 *
 * @param i_id_funcionario VARCHAR2 ID del funcionario (no utilizado, usa 101217)
 * @param v_opcion         NUMBER   Tipo de consulta:
 *                                   0 = Permisos servicio disfrutados
 *                                   1 = Permisos pendientes de disfrutar
 *                                   2 = Fichajes del servicio
 * @param v_fecha          VARCHAR2 Fecha en formato DD/MM/YYYY
 * @return                 CLOB     JSON con datos solicitados
 *
 * Lógica:
 *   1. Según v_opcion, abre cursor correspondiente
 *   2. Opción 0: Permisos aprobados en rango fecha ± 30 días
 *   3. Opción 1: Permisos pendientes de disfrutar del año
 *   4. Opción 2: Fichajes de entrada/salida en rango fecha - 7 días
 *   5. Construye JSON concatenando resultados
 *
 * Dependencias:
 *   - Tabla: personal_new (datos empleados)
 *   - Tabla: permiso (permisos solicitados)
 *   - Tabla: permiso_funcionario (saldo permisos)
 *   - Tabla: tr_tipo_permiso (catálogo tipos)
 *   - Tabla: calendario_laboral (días laborables)
 *   - Tabla: fichaje_funcionario (entradas/salidas)
 *   - Tabla: funcionario_firma (jerarquía de firmas)
 *
 * Mejoras aplicadas:
 *   - FOR LOOP en lugar de cursores manuales (3 cursores)
 *   - Constantes nombradas para estados, rangos y mensajes
 *   - INNER JOIN explícito en lugar de sintaxis antigua con comas
 *   - TRUNC() en lugar de TO_DATE(TO_CHAR()) para comparaciones de fecha
 *   - Variables con tamaños optimizados (100 bytes para IDs)
 *   - Documentación JavaDoc completa
 *   - Eliminación de DISTINCT innecesario con subconsulta
 *
 * Problemas identificados:
 *   ⚠️ CRÍTICO: ID 101217 hardcodeado en WHERE (debería usar i_id_funcionario)
 *   ⚠️ CRÍTICO: Fecha hardcodeada '04/05/2024' en cursor Cfichajes_Servicio
 *   ⚠️ Subconsulta repetida 3 veces (código duplicado de jerarquía)
 *   ⚠️ DISTINCT con ROWNUM<2 innecesario en subconsulta
 *
 * Recomendación:
 *   Esta función debe ser DEPRECADA y reemplazada por la versión principal
 *   wbs_devuelve_permisos_fichajes_serv.fnc que no tiene IDs hardcodeados.
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 11 - Documentación y marcado como legacy
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_permisos_fichajes_serv_OLD(
    i_id_funcionario IN VARCHAR2,
    v_opcion         IN NUMBER,
    v_fecha          IN VARCHAR2
) RETURN CLOB IS
    -- Constantes
    C_ESTADO_ANULADO      CONSTANT NUMBER := 30;
    C_ESTADO_RECHAZADO    CONSTANT NUMBER := 31;
    C_ESTADO_NO_PROCEDE   CONSTANT NUMBER := 32;
    C_ESTADO_CANCELADO    CONSTANT NUMBER := 40;
    C_ESTADO_CADUCADO     CONSTANT NUMBER := 41;
    C_DIAS_FUTURO         CONSTANT NUMBER := 30;
    C_DIAS_PASADO         CONSTANT NUMBER := 7;
    C_LIMITE_NOMBRE       CONSTANT NUMBER := 22;
    C_UNICO_SI            CONSTANT VARCHAR2(2) := 'SI';
    
    -- ⚠️ ID HARDCODEADO - Debería usar parámetro i_id_funcionario
    C_ID_FUNCIONARIO_HARDCODED CONSTANT NUMBER := 101217;
    
    -- Variables
    v_resultado           CLOB;
    v_datos               CLOB;
    v_datos_tmp           CLOB;
    v_contador            NUMBER := 0;
    v_anio                VARCHAR2(4);
    d_fecha_entrada       DATE;
    
BEGIN
    -- Inicialización
    v_datos := '';
    v_contador := 0;
    d_fecha_entrada := TO_DATE(v_fecha, 'DD/MM/YYYY');
    
    CASE v_opcion
        -- Opción 0: Permisos servicio disfrutados
        WHEN 0 THEN
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(Nombre) || ' ' || INITCAP(ape1) || ' ' || INITCAP(ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'id_tipo_permiso' IS pes.id_tipo_permiso,
                        'desc_tipo_permiso' IS (
                            SELECT desc_tipo_permiso
                            FROM tr_tipo_permiso
                            WHERE id_tipo_permiso = pes.id_tipo_permiso
                              AND ROWNUM = 1
                        )
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN permiso pes ON p.id_funcionario = pes.id_funcionario
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN d_fecha_entrada AND d_fecha_entrada + C_DIAS_FUTURO
                                                 AND cl.id_dia BETWEEN pes.fecha_inicio AND pes.fecha_fin
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = C_ID_FUNCIONARIO_HARDCODED
                    ) ff
                    INNER JOIN personal_new p2 ON (
                        p2.id_delegado_ja = ff.id_js OR
                        p2.id_delegado_js = ff.id_js OR
                        p2.id_delegado_js2 = ff.id_js OR
                        p2.id_delegado_js3 = ff.id_js OR
                        p2.id_delegado_js4 = ff.id_js OR
                        p2.id_ja = ff.id_js OR
                        p2.id_ver_plani_1 = ff.id_js OR
                        p2.id_ver_plani_2 = ff.id_js OR
                        p2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN funcionario_firma ff2 ON ff2.id_funcionario = p2.id_funcionario
                                                     AND ff2.id_js = ff.id_js
                    WHERE p2.fecha_fin_contrato IS NULL
                       OR p2.fecha_fin_contrato > SYSDATE
                )
                ORDER BY SUBSTR(INITCAP(Nombre) || ' ' || INITCAP(ape1) || ' ' || INITCAP(ape2), 1, C_LIMITE_NOMBRE), cl.id_dia
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"permisos_servicio": [' || v_datos || ']}';
        
        -- Opción 2: Fichajes servicio
        WHEN 2 THEN
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(Nombre) || ' ' || INITCAP(ape1) || ' ' || INITCAP(ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(cl.id_dia, 'dd/mm/yyyy'),
                        'fecha_entrada' IS TO_CHAR(ff.fecha_fichaje_entrada, 'hh24:mi'),
                        'fecha_salida' IS TO_CHAR(ff.fecha_fichaje_salida, 'hh24:mi')
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN fichaje_funcionario ff ON ff.id_funcionario = p.id_funcionario
                INNER JOIN calendario_laboral cl ON cl.id_dia BETWEEN TO_DATE('04/05/2024', 'dd/mm/yyyy') - C_DIAS_PASADO 
                                                              AND TO_DATE('04/05/2024', 'dd/mm/yyyy')
                                                 AND TRUNC(ff.fecha_fichaje_entrada) = cl.id_dia
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = C_ID_FUNCIONARIO_HARDCODED
                    ) ff
                    INNER JOIN personal_new p2 ON (
                        p2.id_delegado_ja = ff.id_js OR
                        p2.id_delegado_js = ff.id_js OR
                        p2.id_delegado_js2 = ff.id_js OR
                        p2.id_delegado_js3 = ff.id_js OR
                        p2.id_delegado_js4 = ff.id_js OR
                        p2.id_ja = ff.id_js OR
                        p2.id_ver_plani_1 = ff.id_js OR
                        p2.id_ver_plani_2 = ff.id_js OR
                        p2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN funcionario_firma ff2 ON ff2.id_funcionario = p2.id_funcionario
                                                     AND ff2.id_js = ff.id_js
                    WHERE p2.fecha_fin_contrato IS NULL
                       OR p2.fecha_fin_contrato > SYSDATE
                )
                ORDER BY SUBSTR(INITCAP(Nombre) || ' ' || INITCAP(ape1) || ' ' || INITCAP(ape2), 1, C_LIMITE_NOMBRE), 
                         ff.fecha_fichaje_entrada
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"fichajes_servicio": [' || v_datos || ']}';
        
        -- Opción 1: Permisos pendientes de disfrutar
        WHEN 1 THEN
            v_anio := SUBSTR(v_fecha, 7, 4);
            
            FOR rec IN (
                SELECT DISTINCT 
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(INITCAP(Nombre) || ' ' || INITCAP(ape1) || ' ' || INITCAP(ape2), 1, C_LIMITE_NOMBRE),
                        'id_funcionario' IS p.id_funcionario,
                        'id tipo permiso' IS ff.id_tipo_permiso,
                        'desc permiso' IS tr.desc_tipo_permiso,
                        'numero dias' IS ff.num_dias
                    ) AS datos_json
                FROM personal_new p
                INNER JOIN permiso_funcionario ff ON p.id_funcionario = ff.id_funcionario
                                                  AND ff.unico = C_UNICO_SI
                                                  AND ff.num_dias > 0
                                                  AND ff.id_ano = 2024
                INNER JOIN tr_tipo_permiso tr ON ff.id_ano = tr.id_ano
                                              AND tr.id_tipo_permiso = ff.id_tipo_permiso
                WHERE p.id_funcionario IN (
                    SELECT DISTINCT p2.id_funcionario
                    FROM (
                        SELECT id_js
                        FROM funcionario_firma
                        WHERE id_funcionario = C_ID_FUNCIONARIO_HARDCODED
                    ) ff
                    INNER JOIN personal_new p2 ON (
                        p2.id_delegado_ja = ff.id_js OR
                        p2.id_delegado_js = ff.id_js OR
                        p2.id_delegado_js2 = ff.id_js OR
                        p2.id_delegado_js3 = ff.id_js OR
                        p2.id_delegado_js4 = ff.id_js OR
                        p2.id_ja = ff.id_js OR
                        p2.id_ver_plani_1 = ff.id_js OR
                        p2.id_ver_plani_2 = ff.id_js OR
                        p2.id_ver_plani_3 = ff.id_js
                    )
                    INNER JOIN funcionario_firma ff2 ON ff2.id_funcionario = p2.id_funcionario
                                                     AND ff2.id_js = ff.id_js
                    WHERE p2.fecha_fin_contrato IS NULL
                       OR p2.fecha_fin_contrato > SYSDATE
                )
                ORDER BY SUBSTR(INITCAP(Nombre) || ' ' || INITCAP(ape1) || ' ' || INITCAP(ape2), 1, C_LIMITE_NOMBRE), 
                         ff.id_tipo_permiso
            ) LOOP
                v_contador := v_contador + 1;
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"permisos_pendientes_disfrutar_servicio": [' || v_datos || ']}';
            
    END CASE;
    
    RETURN v_resultado;
    
END wbs_devuelve_permisos_fichajes_serv_OLD;
/

