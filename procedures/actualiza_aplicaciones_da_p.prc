create or replace procedure rrhh.Actualiza_APLICACIONES_DA_P(V_aplicaciones in varchar2,
                                                        v_login        in varchar2) is

  v_result               varchar2(8000);
  v_salida               varchar2(8000);
  v_cadena_inter         varchar2(28000);
  posisicion_aste        number;
  posisicion_aste1       number;
  posisicion_ou1         number;
  posisicion_coma_de_ou1 number;
  posisicion_cn          number;
  posisicion_coma_de_cn  number;
  cadena0                varchar2(8000);
  nombre_aplicacion      varchar2(300);
  nombre_rol             varchar2(300);
  i                      number;
  a                      number;
  i_inserta              number;
  V_salida_name          varchar2(8000);
  V_salida_info          varchar2(8000);
  V_salida_description   varchar2(8000);
  i_resultado            number;
begin

  v_cadena_inter := V_aplicaciones;
  i              := length(v_cadena_inter);
  a              := 0;
  while i >= 0 LOOP

    posisicion_aste  := instr(v_cadena_inter, ';', 1, 1) + 1;
    posisicion_aste1 := instr(v_cadena_inter, ';', 1, 2) + 1;
    cadena0          := substr(v_cadena_inter,
                               posisicion_aste,
                               posisicion_aste1 - posisicion_aste);
    v_cadena_inter   := ';' || substr(v_cadena_inter, posisicion_aste1, i);
    i                := length(v_cadena_inter);
    a                := a + 1;
    -- DBMS_OUTPUT.PUT_LINE( v_cadena_inter);
    /*Aplicaciones*/
    if instr(cadena0, 'OU=Aplicaciones Web', 1) > 0 then
      --Nombre aplicación
      posisicion_ou1         := instr(cadena0, 'OU=', 1);
      posisicion_coma_de_ou1 := instr(cadena0, ',', posisicion_ou1);
      nombre_aplicacion      := substr(cadena0,
                                       posisicion_ou1 + 3,
                                       posisicion_coma_de_ou1 -
                                       posisicion_ou1 - 3);
      --ROL
      posisicion_cn         := instr(cadena0, 'CN=', 1);
      posisicion_coma_de_cn := instr(cadena0, ',', posisicion_cn);
      nombre_rol            := substr(cadena0,
                                      posisicion_cn + 3,
                                      posisicion_coma_de_cn - posisicion_cn - 3);

      IF substr(nombre_rol, 1, 5) = 'GA_R_' THEN
        i_resultado := get_aplicaciones('name', nombre_rol, V_salida_name);

        /* IF nombre_rol <> 'GA_R_UNIONHECHO' THEN
           i_resultado := get_aplicaciones('info', nombre_rol, V_salida_info);
         END IF;*/
       i_resultado := get_aplicaciones('description',
                                        nombre_rol,
                                        V_salida_description);

        BEGIN
          insert into apliweb_aplicacion
          values
            (replace(nombre_aplicacion, ';', ''),
              replace(V_salida_description, ';', ''),
             replace(V_salida_info, ';', ''));
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            i_inserta := 0;
        END;
      END IF;

      BEGIN
        insert into apliweb_roles
        values
          (v_login, nombre_rol, nombre_aplicacion);
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          i_inserta := 0;
      END;
      commit;
    end if;

    IF a > 300 then
      i := -1;
    end if;

  END LOOP;

end Actualiza_APLICACIONES_DA_P;
/

