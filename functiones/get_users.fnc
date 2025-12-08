create or replace function rrhh.GET_USERS(V_PROPIEDAD in varchar2,V_login in varchar2,salida out clob) return number is
  Result clob;
/*(&(objectclass=person)(samaccountname=adm_carlos)(cn=*)(sn=*)(description=*)(physicaldeliveryofficename=*))*/
   l_ldap_host    VARCHAR2(256) := 'leonardo.aytosa.inet';
  l_ldap_port    VARCHAR2(256) := '389';
  l_ldap_user    VARCHAR2(256) := 'intranet@aytosa.inet';
  l_ldap_passwd  VARCHAR2(256) := '2d';
 -- l_ldap_user    VARCHAR2(256) := 'carlos@aytosa.inet';
  --l_ldap_passwd  VARCHAR2(256) := '';
  p_sFiltro       varchar2(1024);
  l_retval       PLS_INTEGER;
  l_session      DBMS_LDAP.session;
  l_attrs     dbms_ldap.string_collection;
  l_entry     dbms_ldap.message;
  l_ldap_base   VARCHAR2(256):='DC=aytosa,DC=inet';
 l_message     dbms_ldap.MESSAGE;
 l_num_entries number;
 l_dn        VARCHAR2(256);
 l_attr_name VARCHAR2(256);
l_ber_element  dbms_ldap.ber_element;
l_vals      dbms_ldap.string_collection;
begin


 --composicion del filtro de busqueda en directorio activo
      p_sfiltro:='' ;
     p_sfiltro:='(&(objectclass=user)(objectClass=person)(!(|(userAccountControl=514)(userAccountControl=66050)(userAccountControl=66082)))(samaccountname=';
   
       p_sfiltro:= p_sfiltro || V_login ;
      p_sfiltro:= p_sfiltro || ')';
   p_sfiltro:= p_sfiltro || '(cn=*)(sn=*)(physicaldeliveryofficename=*)(mail=*)(description=*)(distinguishedName=*)(accountExpires=*)(!(description=222222))(!(description=555555))(!(description=999999))(!(description=111111)) )';
 --p_sfiltro:= p_sfiltro || ' )';

/*p_sfiltro:= '(&(objectClass=user)(objectClass=person)(!(|(userAccountControl=514)(userAccountControl=66050)(userAccountControl=66082)))
           (description=*)(cn=*)(sn=*)(physicaldeliveryofficename=*)(mail=*)(description=*)(distinguishedName=*)(accountExpires=*)
           (!(description=999999))(!(description=111111))(!(description=000000))(!(description=222222))(!(description=555555))

           )';*/
  -- p_sfiltro:='(&(objectClass=user)(description=*)(accountExpires=*)(!(description=999999))(!(description=111111)))';

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

  Result:=';';

  IF l_num_entries > 0 THEN
    l_entry := DBMS_LDAP.first_entry(ld  => l_session,
                                     msg => l_message);

    << entry_loop >>
    WHILE l_entry IS NOT NULL LOOP
      -- Get all the attributes for this entry.
      l_attr_name := DBMS_LDAP.first_attribute(ld        => l_session,
                                               ldapentry => l_entry,
                                               ber_elem  => l_ber_element);
     l_attr_name := v_PROPIEDAD;

     l_vals := DBMS_LDAP.get_values (ld        => l_session,
                                        ldapentry => l_entry,
                                        attr      => l_attr_name);
        << values_loop >>
        FOR i IN l_vals.FIRST .. l_vals.LAST LOOP
       -- IF l_attr_name = v_PROPIEDAD  then
           Result:=Result||SUBSTR( TO_CHAR(l_vals(i)) ,1,200)||';' ;
          --  DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || l_attr_name || ' = ' || SUBSTR( TO_CHAR(l_vals(i)) ,1,200));
        --end if;
        END LOOP values_loop;


     /* PARA RECORRER TODOS*/
     /*<< attributes_loop >>
      WHILE l_attr_name IS NOT NULL LOOP
        -- Get all the values for this attribute.
      -- IF l_attr_name = v_PROPIEDAD  then
        l_vals := DBMS_LDAP.get_values (ld        => l_session,
                                        ldapentry => l_entry,
                                        attr      => l_attr_name);
        << values_loop >>
        FOR i IN l_vals.FIRST .. l_vals.LAST LOOP
       -- IF l_attr_name = v_PROPIEDAD  then
         --  Result:=SUBSTR( TO_CHAR(l_vals(i)) ,1,200);
            DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || l_attr_name || ' = ' || SUBSTR( TO_CHAR(l_vals(i)) ,1,200));
        --end if;
        END LOOP values_loop;
        l_attr_name := DBMS_LDAP.next_attribute(ld        => l_session,
                                                ldapentry => l_entry,
                                                ber_elem  => l_ber_element);
      END LOOP attibutes_loop;*/
      l_entry := DBMS_LDAP.next_entry(ld  => l_session,
                                         msg => l_entry);

        Result:=Result||chr(13) ;
    END LOOP entry_loop;
  END IF;

  l_retval := DBMS_LDAP.unbind_s(ld => l_session);

 salida:=result;
  return(0);
end GET_USERS;
/

