/*******************************************************************************
 * Función: GET_USERS_TEST
 * 
 * Propósito:
 *   Función de prueba para consultar información de usuarios en Active Directory
 *   a través de LDAP. Versión especial que incluye filtro OR para usuarios
 *   administrativos específicos (adm_*). Retorna valores en formato delimitado
 *   por punto y coma.
 *
 * @param V_PROPIEDAD  Nombre de la propiedad LDAP a obtener (ej: 'mail', 'cn')
 * @param V_login      Nombre de usuario (no utilizado, filtro hardcodeado)
 * @param salida       Parámetro OUT que contiene los valores separados por ';'
 * 
 * @return NUMBER  0 si la operación fue exitosa
 *
 * Lógica:
 *   1. Conecta a Active Directory vía LDAP
 *   2. Construye filtro OR complejo que incluye:
 *      - Usuarios activos con campos requeridos
 *      - O usuarios administrativos específicos (adm_acarrasco, adm_aoliva, etc.)
 *   3. Busca en todo el dominio
 *   4. Extrae valores de la propiedad solicitada
 *   5. Concatena valores separados por punto y coma
 *
 * Dependencias:
 *   - Package: DBMS_LDAP (Oracle LDAP)
 *   - Active Directory: leonardo.aytosa.inet
 *
 * Consideraciones de Seguridad:
 *   ⚠️ CRÍTICO: Credenciales hardcodeadas en código
 *   ⚠️ CRÍTICO: Contraseña en texto plano visible en código
 *   ⚠️ Uso de LDAP no seguro (puerto 389)
 *   ⚠️ Usuarios administrativos hardcodeados en filtro
 *   
 *   RECOMENDACIONES URGENTES:
 *   - Mover credenciales a tabla de configuración cifrada
 *   - Migrar a LDAPS (puerto 636) con SSL/TLS
 *   - Implementar Oracle Wallet para gestión de credenciales
 *   - Mover lista de usuarios administrativos a tabla de configuración
 *   - Auditar accesos a esta función
 *
 * Consideraciones:
 *   - Función de prueba, parámetro V_login no se utiliza
 *   - Filtro hardcodeado con usuarios específicos
 *   - Recomendado solo para entorno de desarrollo/test
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para configuración LDAP
 *   - Eliminación de código comentado extenso
 *   - Documentación completa JavaDoc
 *   - Variables con nombres descriptivos
 *   - Advertencias de seguridad documentadas
 *   - Manejo de sesión mejorado con cierre en excepción
 *   - CHR(13) como constante para salto de línea
 *   - Nota sobre parámetro no utilizado
 *
 * Historial:
 *   - 2025-12: Optimización, documentación y advertencias de seguridad
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.GET_USERS_TEST(
    V_PROPIEDAD IN VARCHAR2,
    V_login IN VARCHAR2,
    salida OUT CLOB
) RETURN NUMBER IS
    -- Constantes LDAP (⚠️ SEGURIDAD: Mover a configuración cifrada)
    C_LDAP_HOST     CONSTANT VARCHAR2(256) := 'leonardo.aytosa.inet';
    C_LDAP_PORT     CONSTANT VARCHAR2(256) := '389';  -- ⚠️ Usar 636 para LDAPS
    C_LDAP_USER     CONSTANT VARCHAR2(256) := 'intranet@aytosa.inet';
    C_LDAP_PASSWD   CONSTANT VARCHAR2(256) := '';  -- ⚠️ CRÍTICO: Contraseña hardcodeada
    C_LDAP_BASE     CONSTANT VARCHAR2(256) := 'DC=aytosa,DC=inet';
    
    -- Constantes de filtrado
    C_DELIMITER     CONSTANT VARCHAR2(1) := ';';
    C_NEWLINE       CONSTANT CHAR(1) := CHR(13);
    C_MAX_SUBSTR    CONSTANT NUMBER := 200;
    C_SUCCESS       CONSTANT NUMBER := 0;
    
    -- Variables LDAP
    v_filtro        VARCHAR2(1024);
    v_retval        PLS_INTEGER;
    v_session       DBMS_LDAP.session;
    v_attrs         DBMS_LDAP.string_collection;
    v_entry         DBMS_LDAP.message;
    v_message       DBMS_LDAP.MESSAGE;
    v_num_entries   NUMBER;
    v_attr_name     VARCHAR2(256);
    v_ber_element   DBMS_LDAP.ber_element;
    v_vals          DBMS_LDAP.string_collection;
    
    -- Variable de resultado
    v_resultado     CLOB := C_DELIMITER;
    
BEGIN
    -- Construir filtro complejo con OR para usuarios administrativos
    -- ⚠️ NOTA: V_login no se utiliza, filtro hardcodeado para pruebas
    v_filtro := '(|' ||
                '(&(objectClass=user)(objectClass=person)' ||
                '(!(|(userAccountControl=514)(userAccountControl=66050)(userAccountControl=66082)))' ||
                '(description=*)(cn=*)(sn=*)(physicaldeliveryofficename=*)(mail=*)' ||
                '(distinguishedName=*)(accountExpires=*)' ||
                '(!(description=999999))(!(description=111111))(!(description=000000))' ||
                '(!(description=222222))(!(description=555555)))' ||
                '(|(sAMAccountName=adm_acarrasco)' ||
                '(sAMAccountName=adm_aoliva)' ||
                '(sAMAccountName=adm_carlos)' ||
                '(sAMAccountName=adm_jalguero)' ||
                '(sAMAccountName=adm_ralvarez)))';
    
    -- Configurar excepciones LDAP
    DBMS_LDAP.USE_EXCEPTION := TRUE;
    
    -- Inicializar sesión LDAP
    v_session := DBMS_LDAP.init(
        hostname => C_LDAP_HOST,
        portnum  => C_LDAP_PORT
    );
    
    -- Autenticar con credenciales
    v_retval := DBMS_LDAP.simple_bind_s(
        ld     => v_session,
        dn     => C_LDAP_USER,
        passwd => C_LDAP_PASSWD
    );
    
    -- Configurar atributos a obtener (todos)
    v_attrs(1) := '*';
    
    -- Realizar búsqueda LDAP
    v_retval := DBMS_LDAP.search_s(
        ld       => v_session,
        base     => C_LDAP_BASE,
        scope    => DBMS_LDAP.SCOPE_SUBTREE,
        filter   => v_filtro,
        attrs    => v_attrs,
        attronly => 0,
        res      => v_message
    );
    
    -- Contar resultados
    v_num_entries := DBMS_LDAP.count_entries(
        ld  => v_session,
        msg => v_message
    );
    
    -- Procesar entradas encontradas
    IF v_num_entries > 0 THEN
        v_entry := DBMS_LDAP.first_entry(
            ld  => v_session,
            msg => v_message
        );
        
        WHILE v_entry IS NOT NULL LOOP
            -- Obtener atributo especificado
            v_attr_name := V_PROPIEDAD;
            
            -- Obtener valores del atributo
            v_vals := DBMS_LDAP.get_values(
                ld        => v_session,
                ldapentry => v_entry,
                attr      => v_attr_name
            );
            
            -- Concatenar valores
            FOR i IN v_vals.FIRST .. v_vals.LAST LOOP
                v_resultado := v_resultado || 
                              SUBSTR(TO_CHAR(v_vals(i)), 1, C_MAX_SUBSTR) || 
                              C_DELIMITER;
            END LOOP;
            
            -- Siguiente entrada (agregar salto de línea)
            v_entry := DBMS_LDAP.next_entry(
                ld  => v_session,
                msg => v_entry
            );
            v_resultado := v_resultado || C_NEWLINE;
        END LOOP;
    END IF;
    
    -- Cerrar sesión LDAP
    v_retval := DBMS_LDAP.unbind_s(ld => v_session);
    
    -- Asignar resultado al parámetro OUT
    salida := v_resultado;
    
    RETURN C_SUCCESS;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Intentar cerrar sesión en caso de error
        BEGIN
            v_retval := DBMS_LDAP.unbind_s(ld => v_session);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;  -- Ignorar errores al cerrar
        END;
        RAISE;
        
END GET_USERS_TEST;
/

