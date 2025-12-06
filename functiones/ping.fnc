/*******************************************************************************
 * Función: PING
 * 
 * Propósito:
 *   Verifica si un host es accesible en la red mediante una conexión TCP/IP.
 *   Intenta conectar al puerto especificado (por defecto 1000) para determinar
 *   si el host responde.
 *
 * @param p_HOST_NAME  Nombre del host o dirección IP a verificar
 * @param p_PORT       Puerto TCP a usar para la verificación (por defecto 1000)
 * @return VARCHAR2    'OK' si el host es accesible, 'ERROR' si no responde
 *
 * Lógica:
 *   1. Intenta abrir una conexión TCP al host:puerto especificado
 *   2. Si la conexión se establece, cierra inmediatamente y retorna 'OK'
 *   3. Si hay error de red, analiza el mensaje de error:
 *      - Si contiene 'HOST': el host no es accesible → retorna 'ERROR'
 *      - Si contiene 'LISTENER': el host es accesible pero puerto cerrado → retorna 'OK'
 *      - Cualquier otro error: propaga la excepción
 *
 * Dependencias:
 *   - Package: UTL_TCP (Oracle Network Package)
 *
 * Notas:
 *   - El puerto 1000 por defecto se usa para evitar conflictos con servicios comunes
 *   - Un "listener not found" indica que el host responde, aunque no en ese puerto
 *   - No es un PING ICMP real, sino una verificación de conectividad TCP
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa con ejemplos
 *   - Comentarios explicativos de la lógica de detección
 *   - Ya estaba bien optimizado (constantes, manejo de excepciones)
 *
 * Ejemplos:
 *   SELECT RRHH.PING('10.0.0.1', 80) FROM DUAL;        -- Verifica en puerto 80
 *   SELECT RRHH.PING('servidor.local') FROM DUAL;      -- Usa puerto 1000 por defecto
 *   SELECT RRHH.PING('200.100.50.25', 1521) FROM DUAL; -- Verifica Oracle listener
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - documentación completa
 ******************************************************************************/
CREATE OR REPLACE FUNCTION RRHH.PING(
    p_HOST_NAME VARCHAR2,
    p_PORT      NUMBER DEFAULT 1000
) RETURN VARCHAR2 IS

    -- Constantes para valores de retorno
    C_PING_OK    CONSTANT VARCHAR2(10) := 'OK';
    C_PING_ERROR CONSTANT VARCHAR2(10) := 'ERROR';
    
    -- Conexión TCP/IP al servidor
    v_tcp_connection UTL_TCP.CONNECTION;

BEGIN
    -- Intentar abrir conexión TCP al host
    v_tcp_connection := UTL_TCP.open_connection(
        remote_host => p_HOST_NAME,
        remote_port => p_PORT
    );
    
    -- Si se conectó exitosamente, cerrar y confirmar accesibilidad
    UTL_TCP.close_connection(v_tcp_connection);
    RETURN C_PING_OK;

EXCEPTION
    WHEN UTL_TCP.NETWORK_ERROR THEN
        -- Analizar el tipo de error de red
        IF UPPER(SQLERRM) LIKE '%HOST%' THEN
            -- Host inaccesible (no responde en absoluto)
            RETURN C_PING_ERROR;
        ELSIF UPPER(SQLERRM) LIKE '%LISTENER%' THEN
            -- Host accesible pero sin listener en ese puerto
            -- Esto confirma que el PING funciona (host responde)
            RETURN C_PING_OK;
        ELSE
            -- Error de red desconocido: propagar para diagnóstico
            RAISE;
        END IF;
        
END PING;
/

