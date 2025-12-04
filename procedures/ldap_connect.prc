CREATE OR REPLACE PROCEDURE RRHH."LDAP_CONNECT" is
/*
Host: leonardo.aytosa.inet
Puerto: 389
Base: DC=aytosa,DC=inet

Credenciales de acceso:
Este es tu DN del adm_carlos: CN=CARLOS HEREDIA M.,OU=ADMIN_SERVIDORES,OU=Administradores,OU=SERVIDORES,DC=aytosa,DC=inet
Tendrás que poner también tu password.


*/

  l_ldap_host    VARCHAR2(256) := 'leonardo.aytosa.inet';
  l_ldap_port    VARCHAR2(256) := '389';
  l_ldap_user    VARCHAR2(256) := 'intranet@aytosa.inet';
  l_ldap_passwd  VARCHAR2(256) := 'CE$jkf.2d';
  l_retval       PLS_INTEGER;
  l_session      DBMS_LDAP.session;
BEGIN
  -- Choose to raise exceptions.
  --DBMS_LDAP.USE_EXCEPTION := TRUE;
  DBMS_OUTPUT.PUT_LINE('Connecting');
  -- Connect to the LDAP server.
  l_session := DBMS_LDAP.init(l_ldap_host,l_ldap_port);
  DBMS_OUTPUT.PUT_LINE('Init done ..Session is ' || l_session);
  l_retval := DBMS_LDAP.simple_bind_s( ld => l_session,
                                       dn =>  l_ldap_user,
                                       passwd => l_ldap_passwd);


  DBMS_OUTPUT.PUT_LINE('Connected');
  -- Disconnect from the LDAP server.
  l_retval := DBMS_LDAP.unbind_s(l_session);
  DBMS_OUTPUT.PUT_LINE('L_RETVAL: ' || l_retval);
  dbms_output.put_line('All Done!!');
EXCEPTION
WHEN OTHERS THEN
      raise_application_error(-20001,'Error - '||SQLCODE||' '||SQLERRM);

end LDAP_CONNECT;

/*  using pl/sql
web mavin replied to Alexis Flores
11-Sep-09 06:09 AM
Reply

You could use DBMS_LDAP package. Refer the below function and see if it helps you.

FUNCTION GET_USERS(p_sFiltro VARCHAR2) RETURN NUMBER
  IS  --
BEGIN
  DBMS_LDAP.USE_EXCEPTION := TRUE;

  l_session := DBMS_LDAP.init(hostname => l_ldap_host,
                              portnum  => l_ldap_port);

  l_retval := DBMS_LDAP.simple_bind_s(ld     => l_session,
                                      dn     => l_ldap_user,
                                      passwd => l_ldap_passwd);

  l_attrs(1) :=  '*';
  l_retval := DBMS_LDAP.search_s(ld       => l_session,
                                 base     => l_ldap_base,
                                 scope    => DBMS_LDAP.SCOPE_SUBTREE,
                                 filter   => p_sFiltro,
                                 attrs    => l_attrs,
                                 attronly => 0,
                                 res      => l_message);

  l_num_entries := DBMS_LDAP.count_entries(ld => l_session, msg => l_message);
  IF l_num_entries > 0 THEN
    l_entry := DBMS_LDAP.first_entry(ld  => l_session,
                                     msg => l_message);

    << entry_loop >>
    WHILE l_entry IS NOT NULL LOOP
      -- Get all the attributes for this entry.
      l_attr_name := DBMS_LDAP.first_attribute(ld        => l_session,
                                               ldapentry => l_entry,
                                               ber_elem  => l_ber_element);
      << attributes_loop >>
      WHILE l_attr_name IS NOT NULL LOOP
        -- Get all the values for this attribute.
        l_vals := DBMS_LDAP.get_values (ld        => l_session,
                                        ldapentry => l_entry,
                                        attr      => l_attr_name);
        << values_loop >>
        FOR i IN l_vals.FIRST .. l_vals.LAST LOOP
          DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || l_attr_name || ' = ' || SUBSTR( TO_CHAR(l_vals(i)) ,1,200));
        END LOOP values_loop;
        l_attr_name := DBMS_LDAP.next_attribute(ld        => l_session,
                                                ldapentry => l_entry,
                                                ber_elem  => l_ber_element);
      END LOOP attibutes_loop;
      l_entry := DBMS_LDAP.next_entry(ld  => l_session,
                                         msg => l_entry);
    END LOOP entry_loop;
  END IF;

  l_retval := DBMS_LDAP.unbind_s(ld => l_session);
   return 0;
END;*/
/

