create or replace function rrhh.DEVUELVE_LUNES_AGUA
  (V_ANO IN VARCHAR2) return varchar2 is
  Result date;

 i_id_dia date;

begin

BEGIN
    select id_dia
    into i_id_dia from calendario_laboral where id_ano=V_ANO and observacion like '%Agua%';
EXCEPTION
      WHEN NO_DATA_FOUND THEN
          i_id_dia:='';
END;

Result:=i_id_dia;



  return(Result);
end DEVUELVE_LUNES_AGUA;
/

