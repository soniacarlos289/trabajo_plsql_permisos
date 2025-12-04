CREATE OR REPLACE FUNCTION RRHH.FECHA_HOY_ENTRE_DOS(fecha_1 date,fecha_2 date) RETURN varchar2 IS
i_cuenta number;

BEGIN

  i_cuenta:=0;

   BEGIN
       select 1 into i_cuenta  from dual
    where to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy') between fecha_1 and fecha_2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       i_cuenta:=0;
    END;




    RETURN i_cuenta;

END;
/

