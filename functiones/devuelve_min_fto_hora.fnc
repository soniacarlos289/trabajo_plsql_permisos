create or replace function rrhh.DEVUELVE_MIN_FTO_HORA
  (V_CADENA IN VARCHAR2) return varchar2 is
  Result varchar2(122);

  pos number;
  pos2 number;
   v_horas varchar2(116);
      v_minutos varchar2(115);
         i_signo number;
         i_numero number;

begin
i_numero:=es_numero(V_CADENA);
--no es un numero
IF i_numero = 1 then
    Result:= '' ;
 return(Result);
end if;

 --OBTIENE CAMPO
 pos:=to_number(V_CADENA);

   i_signo:=-0;
 If pos < 0 then
   pos:=abs(pos);
   i_signo:=-1;
 end if;

 v_horas:= trunc(pos/60);
 v_minutos:= trunc(mod(pos,60));
 IF  v_horas = 0 or  v_horas is null then
   v_horas:='0 horas'; 
 ELSE
     v_horas:= v_horas || ' horas ';
 end IF;

  IF v_minutos = 0 or  v_minutos is null then
   v_minutos:='' ;
  ELSE
    v_minutos:= v_minutos || ' minutos ' ;
 end IF;

IF   i_signo = 0 then

 Result:= v_horas || v_minutos ;
ELSE
   Result:= '-' || v_horas || v_minutos ;
END IF;
  return(Result);
end DEVUELVE_MIN_FTO_HORA;
/

