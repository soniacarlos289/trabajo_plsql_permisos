create or replace function rrhh.DEVUELVE_PERIODO
  (V_CADENA IN VARCHAR2) return varchar2 is
  Result varchar2(122);

 mes_ano varchar2(15);
 v_cadena_d  date;

begin

IF LENGTH(V_CADENA) = 6 then
  v_cadena_d:=sysdate;
else
  v_cadena_d:=to_date(v_cadena ,'dd/mm/yyyy');

END IF;

BEGIN
    SELECT MES||ANO
         into mes_ano
      FROM webperiodo
      where to_date(to_char(V_CADENA_D,'DD/mm/yyyy'),'DD/mm/yyyy') between inicio and fin;
EXCEPTION
      WHEN NO_DATA_FOUND THEN
          MES_ANO:='012019';
END;

IF MES_ANO = '012019' THEN
   SELECT MES||ANO
        into mes_ano
      FROM webperiodo
      where sysdate between inicio and fin;
END IF;

Result:=MES_ANO;

IF V_CADENA<>'000000' AND LENGTH(V_CADENA) = 6 THEN
     Result:=V_CADENA;
END IF;


  return(Result);
end DEVUELVE_PERIODO;
/

