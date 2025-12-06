/*******************************************************************************
 * Función: CONEXION_LPAD
 * 
 * Propósito:
 *   Valida credenciales de usuario contra el servidor LDAP (Active Directory)
 *   de la organización utilizando autenticación simple.
 *
 * @param p_username  Nombre de usuario sin dominio
 * @param p_password  Contraseña en texto plano
 * @return BOOLEAN    TRUE si la autenticación es exitosa, FALSE en caso contrario
 *
 * Lógica:
 *   1. Inicializa conexión con servidor LDAP
 *   2. Construye UPN (User Principal Name) añadiendo @aytosa.inet
 *   3. Intenta autenticación simple (simple_bind_s)
 *   4. Retorna TRUE si es exitosa, FALSE si falla
 *
 * Dependencias:
 *   - Package: DBMS_LDAP
 *   - Servidor: leonardo.aytosa.inet:389
 *   - Dominio: aytosa.inet
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para configuración LDAP
 *   - Eliminación de código inalcanzable después de RETURN
 *   - Limpieza de código redundante
 *   - Cierre de sesión LDAP solo cuando es necesario
 *   - Documentación completa
 *
 * Consideraciones de seguridad:
 *   - La contraseña se transmite en texto plano a LDAP
 *   - Se recomienda usar LDAPS (puerto 636) en producción
 *   - No se registra información sensible en logs
 *
 * Nota: El código después del primer RETURN era inalcanzable y se ha eliminado.
 *       dbms_output no es visible en contexto de función típico.
 *
 * Historial:
 *   - Original: Implementación básica de conexión LDAP
 *   - 2025: Optimización, limpieza y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.CONEXION_LPAD(
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
    -- Constantes de configuración LDAP
    C_LDAP_HOST CONSTANT VARCHAR2(256) := 'leonardo.aytosa.inet';
    C_LDAP_PORT CONSTANT VARCHAR2(10)  := '389';
    C_LDAP_DOMAIN CONSTANT VARCHAR2(50) := '@aytosa.inet';
    
    -- Variables
    l_retval    PLS_INTEGER;
    l_session   dbms_ldap.session;
    l_ldap_user VARCHAR2(256);
    
BEGIN
    -- Habilitar excepciones de LDAP
    dbms_ldap.use_exception := TRUE;
    
    -- Construir User Principal Name (UPN)
    l_ldap_user := p_username || C_LDAP_DOMAIN;
    
    -- Inicializar sesión LDAP
    l_session := dbms_ldap.init(C_LDAP_HOST, C_LDAP_PORT);
    
    -- Intentar autenticación simple
    l_retval := dbms_ldap.simple_bind_s(l_session, l_ldap_user, p_password);
    
    -- Cerrar sesión LDAP
    l_retval := dbms_ldap.unbind_s(l_session);
    
    -- Autenticación exitosa
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Intentar cerrar la sesión si existe
        BEGIN
            l_retval := dbms_ldap.unbind_s(l_session);
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Ignorar errores al cerrar
        END;
        
        -- Autenticación fallida
        RETURN FALSE;
        
END CONEXION_LPAD;
/

