/*******************************************************************************
 * Función: wbs_devuelve_saldo_bolsas
 * 
 * Propósito:
 *   Devuelve el saldo y movimientos de las bolsas de horas del funcionario:
 *   conciliación, productividad y horas extras.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @param opcion           VARCHAR2  Tipo de consulta (r/p/e/c)
 * @param anio             VARCHAR2  Año a consultar
 * @return VARCHAR2                  JSON con saldos y movimientos
 *
 * Opciones:
 *   - 'r': Resumen de saldos (todas las bolsas)
 *   - 'p': Bolsa de productividad con movimientos detallados
 *   - 'e': Bolsa de horas extras con movimientos detallados
 *   - 'c': Bolsa de conciliación con movimientos detallados
 *
 * Lógica:
 *   1. Recupera saldo de cada bolsa según tablas específicas
 *   2. Calcula horas disponibles, utilizadas y recuperadas
 *   3. Según opción, devuelve resumen o detalle con movimientos
 *   4. Utiliza función devuelve_min_fto_hora para formatear minutos como "X horas Y min"
 *
 * Dependencias:
 *   - Tabla: bolsa_concilia (saldo conciliación)
 *   - Tabla: bolsa_concilia_mov (movimientos conciliación)
 *   - Tabla: bolsa_saldo (saldo productividad)
 *   - Tabla: bolsa_movimiento (movimientos productividad)
 *   - Tabla: horas_extras_ausencias (saldo horas extras)
 *   - Tabla: horas_extras (detalle horas extras)
 *   - Función: devuelve_min_fto_hora (formateo de minutos)
 *
 * Mejoras aplicadas:
 *   - Conversión 3 cursores manuales → FOR LOOP
 *   - Constantes nombradas para tipos, límites y años
 *   - CASE en lugar de DECODE para tipo de movimiento
 *   - INNER JOIN explícito en lugar de sintaxis antigua
 *   - Eliminación de variables no utilizadas
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   ⚠️ Años 2021-2025 hardcodeados en periodos de consulta (TODO: parametrizar)
 *   - Límite conciliación: 50 horas (3000 minutos)
 *   - Límite productividad: 75 horas (4500 minutos)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Cursores a FOR LOOP, constantes
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_saldo_bolsas(
    i_id_funcionario IN VARCHAR2,
    opcion           IN VARCHAR2,
    anio             IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_TIPO_EXCESO         CONSTANT NUMBER := 1;
    C_ANULADO_NO          CONSTANT VARCHAR2(2) := 'NO';
    C_ANULADO_CERO        CONSTANT VARCHAR2(1) := '0';
    C_LIMITE_CONCILIA_MIN CONSTANT NUMBER := 3000;  -- 50 horas
    C_LIMITE_PRODUCT_MIN  CONSTANT NUMBER := 4500;  -- 75 horas
    C_MIN_POR_HORA        CONSTANT NUMBER := 60;
    
    -- Variables
    v_resultado           VARCHAR2(12000);
    v_bolsa_extras_r      VARCHAR2(1232);
    v_bolsa_extras_d      VARCHAR2(1232);
    v_bolsa_concilia_r    VARCHAR2(1232);
    v_bolsa_concilia_d    VARCHAR2(1232);
    v_bolsa_product_r     VARCHAR2(1232);
    v_bolsa_product_d     VARCHAR2(1232);
    v_datos               VARCHAR2(12000);
    v_contador            NUMBER;
    
BEGIN
    v_bolsa_extras_r := '';
    v_bolsa_extras_d := '';
    v_bolsa_concilia_r := '';
    v_bolsa_concilia_d := '';
    v_bolsa_product_r := '';
    v_bolsa_product_d := '';
    
    -- Recupera saldo de bolsa de conciliación
    BEGIN
        SELECT
            JSON_OBJECT('bolsa_horas_conciliacion' IS devuelve_min_fto_hora(C_LIMITE_CONCILIA_MIN - utilizadas)),
            '{"periodos_consulta_anio":[2025,2024]},' ||
            JSON_OBJECT(
                'periodo_anio' IS anio,
                'horas_saldo' IS '50 horas',
                'horas_disponibles' IS devuelve_min_fto_hora(C_LIMITE_CONCILIA_MIN - utilizadas),
                'horas_utilizadas' IS NVL(devuelve_min_fto_hora(utilizadas), 0),
                'horas_recuperadas' IS NVL(devuelve_min_fto_hora(NVL(exceso_jornada, 0)), 0),
                'horas_faltan' IS NVL(devuelve_min_fto_hora(
                    NVL(CASE 
                        WHEN utilizadas - exceso_jornada < 0 THEN 0
                        ELSE utilizadas - exceso_jornada
                    END, 0)
                ), '0 Horas')
            )
        INTO v_bolsa_concilia_r, v_bolsa_concilia_d
        FROM bolsa_concilia
        WHERE id_funcionario = i_id_funcionario
          AND id_ano = anio
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_bolsa_concilia_r := '"bolsa_horas_conciliacion":"0 horas "';
            v_bolsa_concilia_d := '{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' || anio || ',"horas_saldo":"0 horas","horas_disponibles":"0 horas ","horas_utilizadas":"0","horas_recuperadas":"0","horas_faltan":"0 Horas"}';
        WHEN OTHERS THEN
            v_bolsa_concilia_r := '"bolsa_horas_conciliacion":"0 horas "';
            v_bolsa_concilia_d := '{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' || anio || ',"horas_saldo":"0 horas","horas_disponibles":"0 horas ","horas_utilizadas":"0","horas_recuperadas":"0","horas_faltan":"0 Horas"}';
    END;
    
    -- Recupera saldo de bolsa de productividad
    BEGIN
        SELECT
            JSON_OBJECT('bolsa_horas_productividad' IS devuelve_min_fto_hora(C_LIMITE_PRODUCT_MIN - SUM(horas_excesos))),
            '{"periodos_consulta_anio":[2025,2024]},' ||
            JSON_OBJECT(
                'periodo_anio' IS anio,
                'bolsa_horas_productividad' IS devuelve_min_fto_hora(C_LIMITE_PRODUCT_MIN - SUM(horas_excesos))
            )
        INTO v_bolsa_product_r, v_bolsa_product_d
        FROM bolsa_saldo
        WHERE id_funcionario = i_id_funcionario
          AND id_ano = anio
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_bolsa_product_r := '"bolsa_horas_productividad":"0 horas "';
            v_bolsa_product_d := '{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' || anio || ',"bolsa_horas_productividad":"0 horas "}';
        WHEN OTHERS THEN
            v_bolsa_product_r := '"bolsa_horas_productividad":"0 horas "';
            v_bolsa_product_d := '{"periodos_consulta_anio":[2025,2024]},{"periodo_anio":' || anio || ',"bolsa_horas_productividad":"0 horas "}';
    END;
    
    -- Recupera saldo de bolsa de horas extras
    BEGIN
        SELECT
            JSON_OBJECT('bolsa_horas_extras' IS devuelve_min_fto_hora(total - utilizadas)),
            '{"periodos_consulta_anio":[2025,2024,2023,2022,2021]},' ||
            JSON_OBJECT(
                'periodo_anio' IS anio,
                'horas_total' IS devuelve_min_fto_hora(total),
                'horas_disponible' IS devuelve_min_fto_hora(total - utilizadas),
                'horas_utilizadas' IS devuelve_min_fto_hora(utilizadas),
                'saldo_bolsa' IS devuelve_min_fto_hora(total - utilizadas)
            )
        INTO v_bolsa_extras_r, v_bolsa_extras_d
        FROM horas_extras_ausencias
        WHERE id_funcionario = i_id_funcionario
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_bolsa_extras_r := '{"bolsa_horas_extras":"0 horas "}';
            v_bolsa_extras_d := '{"periodos_consulta_anio":[2025,2024,2023,2022,2021]},{"periodo_anio":' || anio || ',"horas_total":"0 horas","horas_disponible":"0 horas","horas_utilizadas":"0 horas","saldo_bolsa":"0 horas"}';
        WHEN OTHERS THEN
            v_bolsa_extras_r := '{"bolsa_horas_extras":"0 horas "}';
            v_bolsa_extras_d := '{"periodos_consulta_anio":[2025,2024,2023,2022,2021]},{"periodo_anio":' || anio || ',"horas_total":"0 horas","horas_disponible":"0 horas","horas_utilizadas":"0 horas","saldo_bolsa":"0 horas"}';
    END;
    
    -- Limpia llaves de los JSON
    v_bolsa_extras_r := REPLACE(REPLACE(v_bolsa_extras_r, '{', ''), '}', '');
    v_bolsa_concilia_r := REPLACE(REPLACE(v_bolsa_concilia_r, '{', ''), '}', '');
    v_bolsa_product_r := REPLACE(REPLACE(v_bolsa_product_r, '{', ''), '}', '');
    
    -- Procesa según opción seleccionada
    CASE opcion
        -- Resumen de saldos
        WHEN 'r' THEN
            v_resultado := v_bolsa_extras_r || ',' || v_bolsa_concilia_r || ',' || v_bolsa_product_r;
        
        -- Bolsa de productividad con movimientos
        WHEN 'p' THEN
            v_contador := 0;
            v_datos := '';
            
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'fecha' IS TO_CHAR(bm.fecha_movimiento, 'DD/MM/YYYY'),
                        'periodo' IS bm.periodo,
                        'descripcion' IS bt.desc_tipo_movimiento,
                        'total_horas' IS NVL(devuelve_min_fto_hora(bm.exceso_en_horas * C_MIN_POR_HORA + bm.excesos_en_minutos), 0)
                    ) AS datos_json,
                    bm.periodo
                FROM bolsa_movimiento bm
                INNER JOIN bolsa_tipo_movimiento bt ON bm.id_tipo_movimiento = bt.id_tipo_movimiento
                WHERE bm.id_funcionario = i_id_funcionario
                  AND bm.anulado = 0
                  AND bm.id_ano = anio
                ORDER BY bm.periodo
            ) LOOP
                IF v_contador = 0 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
                v_contador := v_contador + 1;
            END LOOP;
            
            v_resultado := v_bolsa_product_d || ',{' || '"movimientos_bolsa": [' || v_datos || ']}';
        
        -- Bolsa de conciliación con movimientos
        WHEN 'c' THEN
            v_datos := '';
            v_contador := 0;
            
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'id_anio' IS id_ano,
                        'fecha' IS TO_CHAR(fecha_movimiento, 'DD/MM/YYYY'),
                        'Tipo_Horas' IS CASE 
                            WHEN id_tipo_mov = C_TIPO_EXCESO THEN 'EXCESO SALDO'
                            ELSE 'PERMISO'
                        END,
                        'total_horas' IS NVL(devuelve_min_fto_hora(exceso), 0)
                    ) AS datos_json,
                    fecha_movimiento
                FROM bolsa_concilia_mov
                WHERE (anulado IS NULL OR anulado = C_ANULADO_CERO)
                  AND id_funcionario = i_id_funcionario
                  AND id_ano = anio
                ORDER BY fecha_movimiento
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := v_bolsa_concilia_d || ',{' || '"movimientos_concilia": [' || v_datos || ']}';
        
        -- Bolsa de horas extras con movimientos
        WHEN 'e' THEN
            v_datos := '';
            v_contador := 0;
            
            FOR rec IN (
                SELECT DISTINCT
                    JSON_OBJECT(
                        'anio' IS he.anio,
                        'fecha' IS TO_CHAR(he.fecha_horas, 'DD/MM/YYYY'),
                        'hora_inicio' IS he.hora_inicio,
                        'hora_fin' IS he.hora_fin,
                        'tipo_horas' IS th.desc_tipo_horas,
                        'total_horas' IS he.total_horas
                    ) AS datos_json
                FROM horas_extras he
                INNER JOIN tr_tipo_hora th ON th.id_tipo_horas = he.id_tipo_horas
                WHERE he.id_ano = anio
                  AND he.id_funcionario = i_id_funcionario
                  AND (he.anulado = C_ANULADO_NO OR he.anulado IS NULL)
            ) LOOP
                v_contador := v_contador + 1;
                
                IF v_contador = 1 THEN
                    v_datos := rec.datos_json;
                ELSE
                    v_datos := v_datos || ',' || rec.datos_json;
                END IF;
            END LOOP;
            
            v_resultado := v_bolsa_extras_d || ',{' || '"movimientos_horas": [' || v_datos || ']}';
    END CASE;
    
    RETURN v_resultado;
    
END wbs_devuelve_saldo_bolsas;
/

