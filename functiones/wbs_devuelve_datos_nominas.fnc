/*******************************************************************************
 * Función: wbs_devuelve_datos_nominas
 * 
 * Propósito:
 *   Devuelve las nóminas de un funcionario en formato JSON. Puede devolver
 *   una lista de nóminas disponibles o el contenido de una nómina específica
 *   en formato PDF Base64.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @param cuantas_nominas NUMBER     Cantidad de nóminas a devolver (24=todas últimas 2 años, 2=últimas 2)
 * @param v_id_nomina VARCHAR2       ID de nómina específica ('0'=lista, otro=PDF)
 * @return CLOB                      JSON con lista de nóminas o PDF en Base64
 *
 * Lógica:
 *   1. Si v_id_nomina = '0': Devuelve lista de nóminas
 *      - Consulta nóminas del funcionario de últimos ~2 años
 *      - Limita a cuantas_nominas registros
 *      - Construye JSON con información de cada nómina
 *   2. Si v_id_nomina != '0': Devuelve PDF de nómina específica
 *      - Busca la nómina por ID
 *      - Codifica en Base64
 *
 * Dependencias:
 *   - Tabla: personal_new (datos del personal)
 *   - Tabla: NOMINA_FUNCIONARIO (nóminas)
 *   - Función: base64encode (codificación Base64)
 *
 * Mejoras aplicadas:
 *   - Cursor manual → FOR LOOP (mejor gestión de memoria)
 *   - DECODE de 12 niveles → función auxiliar get_nombre_mes
 *   - INNER JOIN explícito en lugar de sintaxis antigua con comas
 *   - Eliminación DISTINCT innecesario
 *   - Eliminación de 3 variables no utilizadas
 *   - Constantes para valores mágicos y tipos MIME
 *   - Simplificación lógica de contador
 *   - Documentación JavaDoc completa
 *
 * Ejemplo de uso:
 *   -- Lista de últimas 24 nóminas
 *   SELECT wbs_devuelve_datos_nominas('123456', 24, '0') FROM DUAL;
 *   
 *   -- PDF de nómina específica
 *   SELECT wbs_devuelve_datos_nominas('123456', 0, '0120241234') FROM DUAL;
 *
 * Nota:
 *   - Los ~800 días (período de consulta) equivalen aprox. a 2.2 años
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_datos_nominas(
    i_id_funcionario IN VARCHAR2,
    cuantas_nominas IN NUMBER,
    v_id_nomina IN VARCHAR2
) RETURN CLOB IS
    -- Constantes
    C_LISTA_TODAS CONSTANT VARCHAR2(10) := '0';
    C_LIMITE_COMPLETO CONSTANT NUMBER := 24;
    C_MIME_PDF CONSTANT VARCHAR2(30) := 'application/pdf';
    C_DIAS_CONSULTA CONSTANT NUMBER := 800;  -- ~2.2 años
    
    -- Variables
    v_resultado CLOB;
    v_datos CLOB;
    v_contador NUMBER;
    
    -- Función auxiliar para nombre de mes
    FUNCTION get_nombre_mes(p_mes VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE p_mes
            WHEN '01' THEN 'ENERO'
            WHEN '02' THEN 'FEBRERO'
            WHEN '03' THEN 'MARZO'
            WHEN '04' THEN 'ABRIL'
            WHEN '05' THEN 'MAYO'
            WHEN '06' THEN 'JUNIO'
            WHEN '07' THEN 'JULIO'
            WHEN '08' THEN 'AGOSTO'
            WHEN '09' THEN 'SEPTIEMBRE'
            WHEN '10' THEN 'OCTUBRE'
            WHEN '11' THEN 'NOVIEMBRE'
            WHEN '12' THEN 'DICIEMBRE'
            ELSE ''
        END;
    END get_nombre_mes;
    
BEGIN
    v_datos := '';
    v_contador := 0;
    
    IF v_id_nomina = C_LISTA_TODAS THEN
        -- Devolver lista de nóminas
        FOR rec IN (
            SELECT JSON_OBJECT(
                       'ID_NoMINA' IS LPAD(n.periodo, 6, '0') || n.ID_NOMINA,
                       'Periodo' IS SUBSTR(LPAD(n.periodo, 6, '0'), 3, 4) || ' ' ||
                                    get_nombre_mes(SUBSTR(LPAD(n.periodo, 6, '0'), 1, 2)) ||
                                    ' ID_NOMINA:' || n.ID_NOMINA,
                       'anio' IS SUBSTR(LPAD(n.periodo, 6, '0'), 3, 4),
                       'mes' IS SUBSTR(LPAD(n.periodo, 6, '0'), 1, 2),
                       'cantidad' IS NVL(n.cantidad, 0)
                   ) AS json_data
            FROM personal_new A
            INNER JOIN NOMINA_FUNCIONARIO n ON LPAD(n.NIF, 9, '0') = LPAD(A.DNI, 8, '0') || A.DNI_LETRA
            WHERE A.ID_FUNCIONARIO = i_id_funcionario
            AND SUBSTR(LPAD(n.periodo, 6, '0'), 3, 4) > TO_CHAR(SYSDATE - C_DIAS_CONSULTA, 'YYYY')
            ORDER BY SUBSTR(LPAD(n.periodo, 6, '0'), 3, 4) DESC,
                     SUBSTR(LPAD(n.periodo, 6, '0'), 1, 2) DESC
        ) LOOP
            EXIT WHEN v_contador >= cuantas_nominas AND cuantas_nominas > 0;
            
            IF v_contador = 0 THEN
                v_datos := rec.json_data;
            ELSE
                v_datos := v_datos || ',' || rec.json_data;
            END IF;
            
            v_contador := v_contador + 1;
        END LOOP;
        
        -- Formato de respuesta según cantidad solicitada
        IF cuantas_nominas = C_LIMITE_COMPLETO THEN
            v_resultado := '{"nominas": [' || v_datos || ']}';
        ELSE
            v_resultado := '"nominas": [' || v_datos || ']';
        END IF;
        
    ELSE
        -- Devolver PDF de nómina específica
        BEGIN
            SELECT '"file": [ {"mime": "' || C_MIME_PDF || '","data": "' || 
                   base64encode(n.nomina) || '"}]'
            INTO v_resultado
            FROM personal_new A
            INNER JOIN NOMINA_FUNCIONARIO n ON LPAD(n.NIF, 9, '0') = LPAD(A.DNI, 8, '0') || A.DNI_LETRA
            WHERE A.ID_FUNCIONARIO = i_id_funcionario
            AND LPAD(n.periodo || n.id_nomina, 7, '0') = LPAD(v_id_nomina, 7, '0')
            AND ROWNUM < 2;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_resultado := '';
        END;
    END IF;
    
    RETURN v_resultado;
END;
/

