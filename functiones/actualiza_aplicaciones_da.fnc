/**
 * ==============================================================================
 * Funcion: ACTUALIZA_APLICACIONES_DA
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Parsea una cadena LDAP que contiene informacion de aplicaciones y roles,
 *   extrayendo y mostrando los nombres de aplicaciones y sus roles asociados.
 *   La cadena de entrada sigue el formato Distinguished Name (DN) de LDAP.
 *
 * PARAMETROS:
 *   @param V_aplicaciones (VARCHAR2) - Cadena LDAP con formato DN que contiene
 *                                       multiples entradas separadas por punto y coma.
 *                                       Ejemplo: "...;CN=Admin,OU=MIAPP,OU=APLICACIONES,...;..."
 *
 * RETORNO:
 *   @return NUMBER - Siempre retorna 0 indicando ejecucion completada.
 *                    Los resultados se muestran via DBMS_OUTPUT.
 *
 * LOGICA:
 *   1. Itera sobre la cadena separando por delimitador ';'
 *   2. Filtra solo entradas que contienen 'OU=APLICACIONES'
 *   3. Extrae el nombre de la aplicacion del atributo OU
 *   4. Extrae el rol del atributo CN
 *   5. Muestra los resultados via DBMS_OUTPUT
 *
 * LIMITACIONES:
 *   - Maximo 300 iteraciones para prevenir bucles infinitos
 *   - Solo procesa entradas con 'OU=APLICACIONES'
 *
 * MEJORAS v2.0:
 *   - Inicializacion explicita de contador
 *   - Variables con tamanios optimizados
 *   - Documentacion completa
 *   - Codigo mas legible con indentacion consistente
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.ACTUALIZA_APLICACIONES_DA(
    V_aplicaciones IN VARCHAR2
) RETURN NUMBER IS
    -- Constantes
    C_MAX_ITERACIONES   CONSTANT NUMBER := 300;
    C_DELIMITADOR       CONSTANT VARCHAR2(1) := ';';
    C_FILTRO_APP        CONSTANT VARCHAR2(20) := 'OU=APLICACIONES';
    
    -- Variables de trabajo
    v_cadena_inter      VARCHAR2(8000);
    v_segmento          VARCHAR2(2000);
    v_nombre_aplicacion VARCHAR2(300);
    v_nombre_rol        VARCHAR2(300);
    
    -- Posiciones para parsing
    v_pos_inicio        NUMBER;
    v_pos_fin           NUMBER;
    v_pos_ou            NUMBER;
    v_pos_cn            NUMBER;
    v_pos_coma          NUMBER;
    
    -- Contadores
    v_longitud          NUMBER;
    v_contador          NUMBER := 0;
    
BEGIN
    -- Inicializar cadena de trabajo
    v_cadena_inter := V_aplicaciones;
    v_longitud := LENGTH(v_cadena_inter);
    
    -- Iterar mientras haya contenido en la cadena
    WHILE v_longitud > 0 LOOP
        -- Encontrar posiciones de los delimitadores
        v_pos_inicio := INSTR(v_cadena_inter, C_DELIMITADOR, 1, 1) + 1;
        v_pos_fin    := INSTR(v_cadena_inter, C_DELIMITADOR, 1, 2) + 1;
        
        -- Extraer segmento actual
        v_segmento := SUBSTR(v_cadena_inter, v_pos_inicio, v_pos_fin - v_pos_inicio);
        
        -- Avanzar en la cadena
        v_cadena_inter := SUBSTR(v_cadena_inter, v_pos_fin, v_longitud);
        v_longitud := LENGTH(v_cadena_inter);
        v_contador := v_contador + 1;
        
        -- Procesar solo si es una entrada de aplicaciones
        IF INSTR(v_segmento, C_FILTRO_APP, 1) > 0 THEN
            -- Extraer nombre de aplicacion (OU=)
            v_pos_ou := INSTR(v_segmento, 'OU=', 1);
            v_pos_coma := INSTR(v_segmento, ',', v_pos_ou);
            IF v_pos_coma = 0 THEN
                v_pos_coma := LENGTH(v_segmento) + 1;
            END IF;
            v_nombre_aplicacion := SUBSTR(v_segmento, v_pos_ou + 3, v_pos_coma - v_pos_ou - 3);
            
            -- Extraer rol (CN=)
            v_pos_cn := INSTR(v_segmento, 'CN=', 1);
            v_pos_coma := INSTR(v_segmento, ',', v_pos_cn);
            IF v_pos_coma = 0 THEN
                v_pos_coma := LENGTH(v_segmento) + 1;
            END IF;
            v_nombre_rol := SUBSTR(v_segmento, v_pos_cn + 3, v_pos_coma - v_pos_cn - 3);
            
            -- Mostrar resultado
            DBMS_OUTPUT.PUT_LINE('Aplicacion: ' || v_nombre_aplicacion || '. Rol=' || v_nombre_rol);
        END IF;
        
        -- Proteccion contra bucle infinito
        IF v_contador > C_MAX_ITERACIONES THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN 0;
END ACTUALIZA_APLICACIONES_DA;
/

