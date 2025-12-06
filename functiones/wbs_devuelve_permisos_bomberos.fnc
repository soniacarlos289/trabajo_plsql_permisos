/*******************************************************************************
 * Función: wbs_devuelve_permisos_bomberos
 * 
 * Propósito:
 *   Devuelve permisos y guardias de bomberos para el planificador de servicio,
 *   mostrando los turnos asignados y sus permisos para un período de 10 días.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario (no usado actualmente)
 * @param v_opcion         NUMBER    Opción de consulta (0=permisos servicio)
 * @param v_fecha          VARCHAR2  Fecha base para la consulta (formato DD/MM/YYYY)
 * @return CLOB                      JSON con permisos y turnos de bomberos
 *
 * Lógica:
 *   1. Convierte la fecha de entrada a tipo DATE
 *   2. Según opción (actualmente solo 0), recupera guardias y permisos
 *   3. Para cada bombero activo (tipo 23), muestra sus 3 turnos:
 *      - Turno 1: 14:00-22:00
 *      - Turno 2: 22:00-06:00
 *      - Turno 3: 04:00-14:00
 *   4. Construye JSON con datos del bombero y estado de cada turno
 *
 * Dependencias:
 *   - Tabla: bomberos_guardias_plani (planificación de guardias)
 *   - Tabla: permiso (solicitudes de permiso)
 *   - Tabla: personal_new (datos del empleado)
 *   - Tabla: tr_tipo_permiso (tipos de permiso por año)
 *
 * Mejoras aplicadas:
 *   - Conversión cursor manual → FOR LOOP
 *   - Constantes nombradas para tipo de funcionario, año límite, rangos
 *   - CASE en lugar de DECODE anidado (mejora legibilidad)
 *   - TRUNC en lugar de TO_DATE(TO_CHAR()) para comparaciones de fecha
 *   - LEFT JOIN explícito en lugar de sintaxis antigua con (+)
 *   - Inicialización explícita de variables
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   ⚠️ Año 2023 hardcodeado como límite inferior (TODO: parametrizar)
 *   - Período de consulta: fecha_entrada-1 hasta fecha_entrada+9 (10 días)
 *   - Solo considera bomberos activos (sin fecha_baja o fecha_baja futura)
 *   - ID '99999' representa "Guardia Bombero" (sin permiso)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Cursor a FOR LOOP, DECODE a CASE
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_permisos_bomberos(
    i_id_funcionario IN VARCHAR2,
    v_opcion         IN NUMBER,
    v_fecha          IN VARCHAR2
) RETURN CLOB IS
    -- Constantes
    C_TIPO_BOMBERO        CONSTANT NUMBER := 23;
    C_ANIO_LIMITE         CONSTANT NUMBER := 2023;
    C_ID_GUARDIA_BOMBERO  CONSTANT VARCHAR2(5) := '99999';
    C_DESC_GUARDIA        CONSTANT VARCHAR2(20) := 'Guardia Bombero';
    C_DIAS_ANTERIORES     CONSTANT NUMBER := 1;
    C_DIAS_POSTERIORES    CONSTANT NUMBER := 9;
    C_LONGITUD_NOMBRE     CONSTANT NUMBER := 22;
    
    -- Variables
    v_resultado           CLOB;
    v_datos               CLOB;
    v_contador            NUMBER := 0;
    d_fecha_entrada       DATE;
    
BEGIN
    v_datos := '';
    d_fecha_entrada := TO_DATE(v_fecha, 'DD/MM/YYYY');
    
    CASE v_opcion
        -- Opción 0: permisos servicio disfrutados
        WHEN 0 THEN
            -- Itera sobre guardias y permisos de bomberos
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'nombre' IS SUBSTR(
                            INITCAP(p.nombre) || ' ' || 
                            INITCAP(p.ape1) || ' ' || 
                            INITCAP(p.ape2),
                            1,
                            C_LONGITUD_NOMBRE
                        ),
                        'id_funcionario' IS p.id_funcionario,
                        'id_dia' IS TO_CHAR(bp.desde, 'DD/MM/YYYY'),
                        'turno_1_id_permiso' IS CASE 
                            WHEN pe.id_funcionario IS NULL THEN C_ID_GUARDIA_BOMBERO
                            WHEN pe.tu1_14_22 = 0 THEN C_ID_GUARDIA_BOMBERO
                            ELSE tr.id_tipo_permiso
                        END,
                        'turno_1_desc_permiso' IS CASE 
                            WHEN pe.id_funcionario IS NULL THEN C_DESC_GUARDIA
                            WHEN pe.tu1_14_22 = 0 THEN C_DESC_GUARDIA
                            ELSE tr.desc_tipo_permiso
                        END,
                        'turno_2_id_permiso' IS CASE 
                            WHEN pe.id_funcionario IS NULL THEN C_ID_GUARDIA_BOMBERO
                            WHEN pe.tu2_22_06 = 0 THEN C_ID_GUARDIA_BOMBERO
                            ELSE tr.id_tipo_permiso
                        END,
                        'turno_2_desc_permiso' IS CASE 
                            WHEN pe.id_funcionario IS NULL THEN C_DESC_GUARDIA
                            WHEN pe.tu2_22_06 = 0 THEN C_DESC_GUARDIA
                            ELSE tr.desc_tipo_permiso
                        END,
                        'turno_3_id_permiso' IS CASE 
                            WHEN pe.id_funcionario IS NULL THEN C_ID_GUARDIA_BOMBERO
                            WHEN pe.tu3_04_14 = 0 THEN C_ID_GUARDIA_BOMBERO
                            ELSE tr.id_tipo_permiso
                        END,
                        'turno_3_desc_permiso' IS CASE 
                            WHEN pe.id_funcionario IS NULL THEN C_DESC_GUARDIA
                            WHEN pe.tu3_04_14 = 0 THEN C_DESC_GUARDIA
                            ELSE tr.desc_tipo_permiso
                        END
                    ) AS datos_json,
                    bp.desde,
                    SUBSTR(
                        INITCAP(p.nombre) || ' ' || 
                        INITCAP(p.ape1) || ' ' || 
                        INITCAP(p.ape2),
                        1,
                        C_LONGITUD_NOMBRE
                    ) AS nombres
                FROM bomberos_guardias_plani bp
                INNER JOIN personal_new p ON TO_NUMBER(bp.funcionario) = p.id_funcionario
                LEFT JOIN permiso pe ON TO_NUMBER(bp.funcionario) = pe.id_funcionario
                                     AND TRUNC(bp.desde) BETWEEN pe.fecha_inicio AND pe.fecha_fin
                LEFT JOIN tr_tipo_permiso tr ON tr.id_tipo_permiso = pe.id_tipo_permiso
                                             AND tr.id_ano = pe.id_ano
                WHERE SUBSTR(bp.guardia, 1, 4) > C_ANIO_LIMITE
                  AND TO_NUMBER(bp.funcionario) > 10000
                  AND TRUNC(bp.desde) BETWEEN d_fecha_entrada - C_DIAS_ANTERIORES 
                                          AND d_fecha_entrada + C_DIAS_POSTERIORES
                  AND p.tipo_funcionario2 = C_TIPO_BOMBERO
                  AND (p.fecha_baja IS NULL OR p.fecha_baja > SYSDATE)
                ORDER BY nombres, bp.desde
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := '{"permisos_servicio": [' || v_datos || ']}';
    END CASE;
    
    RETURN v_resultado;
    
END wbs_devuelve_permisos_bomberos;
/

