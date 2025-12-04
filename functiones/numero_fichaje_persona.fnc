create or replace function rrhh.NUMERO_FICHAJE_PERSONA return varchar2 is
  Result number;
  i_contador number;
  v_codigo varchar2(6);
  i_encontrado number;
BEGIN

i_contador:=3300;
i_encontrado:=0;
WHILE i_contador <= 20000 and i_encontrado = 0
LOOP
   BEGIN
    select codigo
    into  v_codigo
    from persona
    where (to_number(codigo) = i_contador OR
          to_number(numtarjeta) = i_contador OR          
          to_number(numtarjeta) = i_contador+1 ) and rownum<2;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
        i_encontrado:= i_contador;
   END;

   i_contador :=  i_contador +1;

END LOOP;


Result:= i_encontrado ;
return(Result);
end  NUMERO_FICHAJE_PERSONA;
/

