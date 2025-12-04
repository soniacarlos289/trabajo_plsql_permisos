create or replace function rrhh.
Actualiza_APLICACIONES_DA(V_aplicaciones in varchar2) return number is
  Result varchar2(200);
  v_result varchar2(8000);
  v_salida varchar2(8000);
  v_cadena_inter varchar2(8000);
  posisicion_aste number;
  posisicion_aste1 number;
  posisicion_ou1 number;
  posisicion_coma_de_ou1 number;
  posisicion_cn number;
  posisicion_coma_de_cn number;
  cadena0 varchar2(8000);
  nombre_aplicacion varchar2(300);
  nombre_rol varchar2(300);
  i number;
  a number;

begin

v_cadena_inter:=V_aplicaciones;
i:=length(v_cadena_inter);
while i >=0 LOOP

  posisicion_aste  := instr(v_cadena_inter, ';', 1,1) + 1;
  posisicion_aste1 := instr(v_cadena_inter, ';', 1,2) + 1;
  cadena0          := substr(v_cadena_inter,
                             posisicion_aste,
                             posisicion_aste1 - posisicion_aste);
  v_cadena_inter:=substr(v_cadena_inter,posisicion_aste1,i);
  i:=length(v_cadena_inter);
  a:=a+1;

  /*Aplicaciones*/
  if  instr(cadena0,'OU=APLICACIONES',1) > 0 then
    --Nombre aplicación
    posisicion_ou1:=          instr(cadena0,'OU=',1);
    posisicion_coma_de_ou1:=  instr(cadena0,'OU=', posisicion_ou1);
    nombre_aplicacion:=substr(cadena0,
                             posisicion_ou1+3,
                             posisicion_coma_de_ou1 - posisicion_ou1-3);
    --ROL
    posisicion_cn:=  instr(cadena0,'CN=',1);
    posisicion_coma_de_cn:=  instr(cadena0,'CN=', posisicion_cn);
    nombre_rol:=substr(cadena0,
                             posisicion_cn+3,
                             posisicion_coma_de_cn - posisicion_cn-3);
     DBMS_OUTPUT.PUT_LINE(' Aplicación: ' ||nombre_aplicacion || '. ' ||
                          ' Rol=' || nombre_rol);

  end if;

  IF a > 300 then
    i:=0;
  end if;


END LOOP;

  return(0);
end Actualiza_APLICACIONES_DA;
/

