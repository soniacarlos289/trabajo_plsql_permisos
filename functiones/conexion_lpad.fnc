create or replace function rrhh.CONEXION_LPAD(
    p_username        in    varchar2,
    p_password        in    varchar2)
return boolean is
  l_retval PLS_INTEGER;
  l_retval2 PLS_INTEGER;
  l_session dbms_ldap.session;
  l_ldap_host VARCHAR2(256);
  l_ldap_port VARCHAR2(256);
  l_ldap_user VARCHAR2(256);
  l_ldap_base VARCHAR2(256);
BEGIN
  l_retval := -1;
  dbms_ldap.use_exception := TRUE;
  l_ldap_host := 'leonardo.aytosa.inet';
  l_ldap_port := '389';
  l_ldap_user := p_username||'@aytosa.inet';
  l_session := dbms_ldap.init(l_ldap_host, l_ldap_port);
  l_retval := dbms_ldap.simple_bind_s(l_session,l_ldap_user,p_password);

  RETURN TRUE;
  dbms_output.put_line('Return value: ' || l_retval);
  l_retval2 := dbms_ldap.unbind_s(l_session);

EXCEPTION
  WHEN OTHERS THEN
  RETURN FALSE;
    dbms_output.put_line(rpad('ldap session ', 25, ' ') || ': ' ||
    rawtohex(substr(l_session, 1, 8)) || '(returned from init)');
    dbms_output.put_line('error: ' || SQLERRM || ' ' || SQLCODE);
    dbms_output.put_line('user: ' || l_ldap_user);
    dbms_output.put_line('host: ' || l_ldap_host);
    dbms_output.put_line('port: ' || l_ldap_port);
    l_retval := dbms_ldap.unbind_s(l_session);
END;
/

