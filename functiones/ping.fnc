CREATE OR REPLACE FUNCTION RRHH.PING(p_HOST_NAME VARCHAR2,
                                p_PORT      NUMBER DEFAULT 1000)


  RETURN VARCHAR2 --Retorna 'OK', 'ERROR'
 IS
  C_PING_OK    CONSTANT VARCHAR2(10) := 'OK';
  C_PING_ERROR CONSTANT VARCHAR2(10) := 'ERROR';
  tcpConnection UTL_TCP.CONNECTION; --TCP/IP connection to the server
BEGIN
  tcpConnection := UTL_TCP.open_connection(remote_host => p_HOST_NAME,
                                           remote_port => p_PORT);
  UTL_TCP.close_connection(tcpConnection);
  --Que raro...el host tiene abierto el puerto 1000...
  RETURN C_PING_OK;
EXCEPTION
  WHEN UTL_TCP.NETWORK_ERROR THEN
    IF (UPPER(SQLERRM) LIKE '%HOST%') THEN
      --Host inaccesible
      RETURN C_PING_ERROR;
    ELSIF (UPPER(SQLERRM) LIKE '%LISTENER%') THEN
      --El host es accesible, pero no hay listener => el PING si funciono!
      RETURN C_PING_OK;
    ELSE
      --Mensaje SQLERRM desconocido: este es un error grave!
      RAISE;
    END IF;
END PING;
/

