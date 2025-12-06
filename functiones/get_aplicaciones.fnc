/*******************************************************************************
 * Función: GET_APLICACIONES
 * 
 * Propósito:
 *   Consulta un grupo de aplicación en Active Directory a través de LDAP y 
 *   obtiene valores de una propiedad específica del grupo. Retorna los valores
 *   en formato delimitado por punto y coma.
 *
 * @param V_PROPIEDAD   Nombre de la propiedad LDAP a obtener (ej: 'member')
 * @param V_aplicacion  Nombre del grupo de aplicación (sAMAccountName)
 * @param salida        Parámetro OUT que contiene los valores separados por ';'
 * 
 * @return NUMBER  0 si la operación fue exitosa
 *
 * Lógica:
 *   1. Conecta a Active Directory vía LDAP
 *   2. Construye filtro de búsqueda para grupo específico
 *   3. Busca en la OU de aplicaciones web
 *   4. Extrae valores de la propiedad solicitada
 *   5. Concatena valores separados por punto y coma
 *   6. Retorna valores en parámetro OUT
 *
 * Dependencias:
 *   - Package: DBMS_LDAP (Oracle LDAP)
 *   - Active Directory: leonardo.aytosa.inet
 *
 * Consideraciones de Seguridad:
 *   ⚠️ CRÍTICO: Credenciales hardcodeadas en código
 *   ⚠️ CRÍTICO: Contraseña en texto plano visible en código
 *   ⚠️ Uso de LDAP no seguro (puerto 389)
 *   
 *   RECOMENDACIONES URGENTES:
 *   - Mover credenciales a tabla de configuración cifrada
 *   - Migrar a LDAPS (puerto 636) con SSL/TLS
 *   - Implementar Oracle Wallet para gestión de credenciales
 *   - Auditar accesos a esta función
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para configuración LDAP
 *   - Eliminación de código comentado extenso
 *   - Documentación completa JavaDoc
 *   - Variables con nombres descriptivos
 *   - Advertencias de seguridad documentadas
 *   - Manejo de sesión mejorado con cierre en excepción
 *   - Constante para delimitador
 *
 * Historial:
 *   - 2025-12: Optimización, documentación y advertencias de seguridad
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.GET_APLICACIONES(
    V_PROPIEDAD IN VARCHAR2,
    V_aplicacion IN VARCHAR2,
    salida OUT CLOB
) RETURN NUMBER IS
    -- Constantes LDAP (⚠️ SEGURIDAD: Mover a configuración cifrada)
    C_LDAP_HOST     CONSTANT VARCHAR2(256) := 'leonardo.aytosa.inet';
    C_LDAP_PORT     CONSTANT VARCHAR2(256) := '389';  -- ⚠️ Usar 636 para LDAPS
    C_LDAP_USER     CONSTANT VARCHAR2(256) := 'intranet@aytosa.inet';
    C_LDAP_PASSWD   CONSTANT VARCHAR2(256) := 'CE$jkf.2d';  -- ⚠️ CRÍTICO: Contraseña hardcodeada
    C_LDAP_BASE     CONSTANT VARCHAR2(256) := 'OU=Aplicaciones Web,OU=Seccion Aplicaciones Corporativas,OU=APLICACIONES,DC=aytosa,DC=inet';
    
    -- Constantes de búsqueda
    C_DELIMITER     CONSTANT VARCHAR2(1) := ';';
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
    -- Construir filtro de búsqueda LDAP para grupo
    v_filtro := '(&(objectclass=group)(sAMAccountName=' || V_aplicacion || '))';
    
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
            
            -- Siguiente entrada
            v_entry := DBMS_LDAP.next_entry(
                ld  => v_session,
                msg => v_entry
            );
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
        
END GET_APLICACIONES;
/

