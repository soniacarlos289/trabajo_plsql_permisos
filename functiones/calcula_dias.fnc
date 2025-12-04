create or replace function rrhh.CALCULA_DIAS(D_FECHA_INICIO IN date ,D_FECHA_FIN IN date,V_CADENA IN VARCHAR2) return number is
  Result number;
begin

 IF V_CADENA='L' THEN
 SELEct decode(count(*)-1,0,1,count(*)-1)   into Result
 from rrhh.calendario_laboral
  where id_dia  between  D_FECHA_INICIO and   D_FECHA_FIN and LABORAL='SI';
 ELSE  IF V_CADENA='N' THEN
        SELEct count(*)   into Result
         from rrhh.calendario_laboral
          where id_dia  between  D_FECHA_INICIO and   D_FECHA_FIN;
       end if;
 END IF;

IF  Result = -1 THEN
  Result:= 0;
END IF;

  return(Result);
end CALCULA_DIAS;
/

