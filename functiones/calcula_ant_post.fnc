create or replace function rrhh.CALCULA_ANT_POST(v_FECHA in DATE,TIPO in VARCHAR2) return date is
  Result date;
begin
--Calcula el anterior
 IF TIPO='A' then
  select max(id_dia)
   into result
   from calendario_laboral
    where id_dia between   V_FECHA-8 and
    V_FECHA-1 and laboral='SI';
  ELSE
  select min(id_dia)
   into result
   from calendario_laboral
    where id_dia between   V_FECHA+1 and
    V_FECHA+8 and laboral='SI';
  END IF;
  return(Result);
end CALCULA_ANT_POST;
/

