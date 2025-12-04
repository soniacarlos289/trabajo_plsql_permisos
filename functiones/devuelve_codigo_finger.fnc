create or replace function rrhh.DEVUELVE_CODIGO_FINGER
  (I_ID_FUNCIONARIO IN VARCHAR2) return varchar2 is
  Result varchar2(122);

begin

       Begin
       SELECT distinct id_fichaje
            into result
        FROM apliweb.usuario u
        where u.id_funcionario=I_id_funcionario;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          result:='0';
         END;

  return(Result);
end DEVUELVE_CODIGO_FINGER;
/

