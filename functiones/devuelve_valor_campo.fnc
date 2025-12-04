create or replace function rrhh.DEVUELVE_VALOR_CAMPO
  (V_CADENA IN VARCHAR2,V_CAMPO IN VARCHAR2) return varchar2 is
  Result varchar2(122);

  pos number;
  pos2 number;
begin

 --OBTIENE CAMPO
 pos:=instr(V_CADENA, V_CAMPO,1,1)+length(V_CAMPO);
 pos2:=instr (V_CADENA,';', pos,1);

 if pos2-pos> 0  then
     Result:=substr(V_CADENA, pos,pos2-pos);
 else
      Result:='';
 end if;

  return(Result);
end DEVUELVE_VALOR_CAMPO;
/

