create or replace function rrhh.DEVUELVE_DIA_JORNADA(V_CADENA VARCHAR2,ID_DIA date) RETURN number IS
  Result number;

 v_Cadenas_d varchar2(15);
 dia_semana number;
 dia_semana_lunes number;
 dia_s          number;
 -- 1 1 1 1 1 0 0
begin

  --Si da 1 se ejecuta desde la web
  --si da 2 se ejecuta desde pl/sql
  select tO_char(to_date('07/01/2019','dd/mm/yyyy'), 'D') into  dia_semana_lunes  from dual;


  If dia_semana_lunes = 2 THEN
      dia_semana_lunes:=-1;
  ELSE
     dia_semana_lunes:=0;
  End if;

  select tO_char(ID_DIA, 'D') into  dia_semana  from dual;


  dia_s:=dia_semana+dia_semana_lunes;

  IF dia_s =0  THEN

     dia_s:=7;
  end if;
 v_Cadenas_d:=substr(V_CADENA,dia_s,1);

 IF  es_numero(v_Cadenas_d)= 1 then
   Result:=0;
 ELSE
   Result:=to_number(v_Cadenas_d);
 END IF;


 -- Result:=dia_semana_lunes ;



  return(Result);
end DEVUELVE_DIA_JORNADA;
/

