create or replace function rrhh.ENTRADA_SALIDA(vpin varchar2) return varchar2 is
  Result varchar2(1024);
begin
   select  DECODE(MOD(count(*),2),1,'Entrada','Salida')
   into Result
   from transacciones t
where
t.pin=vpin and
t.fecha=to_DATE(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY')
and t.numserie<>0 and t.pin<>'0000';
  return(Result);
end ENTRADA_SALIDA;
/

