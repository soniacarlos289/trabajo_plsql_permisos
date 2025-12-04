create or replace procedure rrhh.numero_fichaje_persona_n(v_codigo out number,pin1 out number, pin2 out number) is
  i_contador number;
--  v_codigo varchar2(6);
  i_encontrado number;
  
BEGIN
i_contador:=3500;
i_encontrado:=0;

WHILE i_contador <= 20000 and i_encontrado = 0
LOOP
   BEGIN
    select codigo
    into  v_codigo
    from persona
    where (to_number(codigo) = i_contador OR
          to_number(numtarjeta) = i_contador ) and rownum<2;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
        i_encontrado:= i_contador;
   END;
   v_codigo:= i_encontrado ;
   i_contador :=  i_contador +1;  
   --Buscamos los dos codigos no este 
   If i_encontrado > 0 then
       i_encontrado:=0;
        BEGIN
      select codigo
      into  v_codigo
      from persona
      where (to_number(codigo) = i_encontrado OR to_number( '2' ||substr(codigo,2,4) ) = i_encontrado) and rownum<2;
     EXCEPTION
         WHEN NO_DATA_FOUND THEN
          i_encontrado:= i_contador;
     END;     
   end if;
   
END LOOP;


i_encontrado:=0;

i_contador:=3500;

WHILE i_contador <= 10000 and i_encontrado = 0
LOOP
   BEGIN
    select numtarjeta
    into  pin1
    from persona
    where (
          to_number(numtarjeta) = i_contador ) and rownum<2;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
        i_encontrado:= i_contador;
   END;
   i_contador :=  i_contador +1;  
   pin1:=i_encontrado;    
END LOOP;

i_contador:=pin1+1;
i_encontrado:=0;
WHILE i_contador <= 10000 and i_encontrado = 0
LOOP
   BEGIN
    select numtarjeta
    into  pin2
    from persona
    where (
          to_number(numtarjeta) = i_contador ) and rownum<2;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
        i_encontrado:= i_contador;
   END;
   i_contador :=  i_contador +1;      
   pin2:=i_encontrado;
END LOOP;




end numero_fichaje_persona_n;
/

