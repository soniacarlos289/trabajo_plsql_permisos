create or replace procedure rrhh.CHEQUEA_DA_FINAL_faltan is

  --Variables
  i_dni                         varchar2(8);
  nif varchar2(9);
  i_nombre                      varchar2(60);
  i_nombre_ca                   varchar2(255);
  i_encontrado_usuario_aesal    number;
  i_encontrado_usuario_personal number;
  i_encontrado_2_usuarioS_pers  number;
  i_FUNCIONARIO_IGUAL           number;
  i_FUNCIONARIO_IGUAL_PER       number;
  i_insertados                  number;
  i_id_ope_con                  varchar2(5);
  i_numero                      number;
  i_leidos                      number;
  i_resultado                   number;
  i_resultado_s                 number;
  i_inserta                     number;
  i_actualiza                   number;
  i_pin                         varchar2(5);
  p_pin                         varchar2(5);
  i_cuenta                      number;
  p_sfiltro                     varchar2(256);
  V_salida                      varchar2(32710);
  V_login                       varchar2(255);
  i_id_fichaje                  number;
  i_firma                       number;
  i_id_funcionario              number;
  i_id_funcionario_da           varchar2(146);
  V_salida_dis                  varchar2(30000);
  V_salida_des                  varchar2(30000);
  V_salida_apli                varchar2(30000);
   V_salida_depart                varchar2(30000);
   V_salida_aplicaciones                varchar2(30000);
   V_salida_disName                varchar2(30000);
  V_salida_ofi                  varchar2(3000);
  v_usuario                     varchar2(300);
  V_id_fichajes                 varchar2(5);
  V_FIRMA                       varchar2(30);
  V_ID_FUNCIONARIO              varchar2(30);
  p_id_funcionario              varchar2(30);
  i_posicion_a                  number;
  i_posicion_b                  number;
  i                             number;
  a                             number;
  v_cadena                      varchar2(130);
  v_dni                         varchar2(130);
  i_envio                       Number;
i_id_departamento               number;
begin

  i_envio := 1;
  
 -- mjsanchezch@aytosalamanca.es

--nhernandezl@aytosalamanca.es
--msanchezvi@aytosalamanca.es
--jarodriguezg@aytosalamanca.es
--mperezru@aytosalamanca.es
--meperezr@aytosalamanca.es
--gjimenez@aytosalamanca.es
--migonzalez@aytosalamanca.es
--fgarciap@aytosalamanca.es
--mslopez@aytosalamanca.es
--mjmartinp@aytosalamanca.es
--mtgarciad@aytosalamanca.es
  v_usuario:='jcavero';
--,'ammateos','lholgado','phernandezs'
--'mmartinsa','asanchezg'
      IF V_USUARIO IS NOT NULL --and  v_usuario='nhernandezl'   
        then
      -- a:=601;
      -- DBMS_OUTPUT.PUT_LINE('HOLA');


   -- mmanjont
   --  i_resultado := RRHH.get_users('description', v_usuario, V_salida_des);
      

--       DBMS_OUTPUT.PUT_LINE(V_salida_des);

        V_salida_apli:='';
        
        v_usuario:=replace(v_usuario,chr(13),'');
        DBMS_OUTPUT.PUT_LINE(  v_USUARIO);

     IF instr(v_usuario,'.',1) = 0 AND  substr(v_usuario,1,4) <> 'adm_'
        and v_usuario='ravicente'
       then

         i_resultado := RRHH.get_users('memberOf', v_usuario, V_salida_apli);

       end if;
        i_inserta                     := 0;
      i_resultado := RRHH.get_users('displayName', v_usuario, V_salida_dis);
      i_resultado := RRHH.get_users('description', v_usuario, V_salida_des);
      i_resultado := RRHH.get_users('physicalDeliveryOfficeName', v_usuario,  V_salida_depart );
      i_resultado := RRHH.get_users('distinguishedName', v_usuario,  V_salida_disName );
     --     V_salida_disName:='';
   


      V_salida_dis := REPLACE(V_salida_dis, ';', '');
      V_salida_des := REPLACE(V_salida_dEs, ';', '');
      V_salida_depart:= REPLACE(V_salida_depart, ';', '');
       V_salida_disName:= REPLACE( V_salida_disName, ';', '');
      i_encontrado_usuario_aesal    := 1;
      i_encontrado_usuario_personal := 1;
      i_encontrado_2_usuarioS_pers  := 1;
      i_FUNCIONARIO_IGUAL_per       := 1;
      i_inserta                     := 0; --añadirlo aesal.
  DBMS_OUTPUT.PUT_LINE(V_salida_des);
      i_FUNCIONARIO_IGUAL := 1;

      --Actualiza la tabla de aplicaciones
     actualiza_aplicaciones_da_p(V_salida_apli,v_usuario);

      BEGIN
        select id_fichaje, FIRMA, ID_FUNCIONARIO
          into V_id_fichajes, V_FIRMA, V_ID_FUNCIONARIO
          from apliweb_usuario
         where login = v_usuario;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_encontrado_usuario_aesal := 0;
          V_ID_FUNCIONARIO           := 0;
          i_inserta := 1;
      END;
      
 if  V_ID_FUNCIONARIO      =0 THEN
   
      IF lpad(V_salida_des, 6, '0') = lpad(V_ID_FUNCIONARIO, 6, '0') tHEN
        i_FUNCIONARIO_IGUAL := 1;
      ELSE
        i_FUNCIONARIO_IGUAL := 0;
      end if;

      p_id_funcionario := 0;

      --buSCAMOS EN LA TABLA DE PERSONAL
      BEGIN
        select distinct id_funcionario, lpad(dni,8,'0')
          into p_id_funcionario, v_dni
          from personal_new
         where nombre || ' ' || ape1 || ' ' || ape2 = V_salida_dis
           AND (FECHA_BAJA IS NULL OR FECHA_BAJA > SYSDATE);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_encontrado_usuario_personal := 0;
          p_id_funcionario              := 0;
          v_dni                         := 0;
        WHEN TOO_MANY_ROWS THEN
          i_encontrado_2_usuarioS_perS := 0;
          v_dni                        := 0;
      END;
   DBMS_OUTPUT.PUT_LINE(  v_USUARIO  || ' ' ||  p_id_funcionario);

         IF v_usuario='crmf1.ti' then
         p_id_funcionario:=999966;
          v_dni:='07954264J';


       end if;
       IF v_usuario='crmf2.ti' then
          p_id_funcionario:=999977;
          v_dni:='07954264J';

       end if;
       IF v_usuario='mgarciaga' then
           p_id_funcionario:=961019;
         -- v_dni:='07838851';
       end if;

       if v_usuario='maromero' THEN
          p_id_funcionario:='962377';
          v_dni:='07982310';
       end if;

      --HAcemos una segunda busqueda por ID_funcionario de la tabla AESAL
      --Por si acaso el nombre,ape1,ape2 estuviera mal
      IF p_id_funcionario = 0  then

        BEGIN
          select distinct id_funcionario, lpad(dni,8,'0')
            into p_id_funcionario, v_dni
            from personal_new
           where lpad(id_funcionario,6,'0') = lpad(V_salida_des,6,'0');
      --       AND (FECHA_BAJA IS NULL OR FECHA_BAJA > SYSDATE);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_encontrado_usuario_personal := 0;
            p_id_funcionario              := 0;
            v_dni                         := 0;
          WHEN TOO_MANY_ROWS THEN
            i_encontrado_2_usuarioS_perS := 0;
            v_dni                        := 0;
        END;
      END IF;

      --comparamos con el real
      IF lpad(V_salida_des, 6, '0') = lpad(p_id_funcionario, 6, '0') tHEN
        i_FUNCIONARIO_IGUAL_per := 1;
          ---AÑADO CORREO ELECTRONICO
          

      ELSE
        i_FUNCIONARIO_IGUAL_per := 0;
      end if;

      IF i_encontrado_usuario_personal = 1 THEN
        if i_FUNCIONARIO_IGUAL = 0 THEN

          IF V_ID_FUNCIONARIO = 0 then
            v_cadena  := 'Falta id f';
            i_inserta := 1;
          else
            v_cadena := 'Atributo description (ID_FUNCIONARIO) incorrecto. ';

            i_envio := i_envio + 1;
            if i_envio < 4 then

              --Office DA
              i_resultado_s := RRHH.get_users('physicalDeliveryOfficeName',
                                         v_usuario,
                                         V_salida_ofi);

               envio_correo('noresponda@aytosalamanca.es',
                           'carlos@aytosalamanca.es',
                           '',
                           'Error. Id funcionario en Directorio Activo incorrecto.',
                           v_cadena ||  chr(10)||  ' Usuario: ' || v_USUARIO ||
                             chr(10)||
                           '. Office: ' || V_salida_ofi || ' ' ||   chr(10)||
                           V_salida_dis || ' description=' ||
                           V_id_funcionario);
            end if;

          END IF;


        else



          --id funcionario diferente
          if i_FUNCIONARIO_IGUAL_PER = 0 and
             i_encontrado_2_usuarioS_perS = 1 then
            v_cadena         := 'Mal ID';
            v_id_funcionario := p_id_funcionario;
            DBMS_OUTPUT.PUT_LINE(v_cadena || ' Usuario:' || v_USUARIO || ' ' ||
                                 V_salida_dis || ' ID=' ||
                                 V_id_funcionario || '--' || V_salida_des);

          end if;

        end if;

      end if;
     IF substr(lpad(v_dni,8,'0'),1,1) <> 'X' AND
        substr(lpad(v_dni,8,'0'),1,1) <> 'Y' AND v_usuario<>'crmf1.ti' AND v_usuario<>'crmf2.ti' THEN
      --Buscamos el id_fichaje.
      BEGIN
        select distinct lpad(o.CODIGO, 5, '0')
          into i_pin
          from persona o, rrhh.personal_new p
         where  (substr(lpad(o.dni,9,'0'),1,8)  = lpad(p.dni,8,'0')  OR
                 substr(lpad(o.dni,8,'0'),1,8)  = lpad(p.dni,8,'0') )
           and lpad(p.dni,8,'0') = lpad(v_dni,8,'0')
           and v_dni <> 0
           and v_dni is not null and rownum<2;
      --     and (fechabaja > sysdate or fechabaja is null);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_pin := null;
      END;
      END IF;
      i_cuenta := 0;
       IF v_usuario='crmf1.ti' then
                   i_pin := '00202';
       end if;
       IF v_usuario='crmf2.ti' then
          i_pin := '00202';
       end if;
        if v_usuario='maromero' THEN
          i_pin := '01057';
       end if;

      --Buscamos la firma
      BEGIN
        select count(*)
          into i_cuenta
          from funcionario_firma
         where (id_js = p_id_funcionario OR
               id_delegado_js = p_id_funcionario OR
                id_delegado_js2 = p_id_funcionario OR
                 id_delegado_js3 = p_id_funcionario OR
                  id_delegado_js4 = p_id_funcionario OR
                  id_delegado_ja = p_id_funcionario OR
               id_ja = p_id_funcionario OR
               id_ver_plani_1 = p_id_funcionario or
               id_ver_plani_2 = p_id_funcionario or
               id_ver_plani_3 =p_id_funcionario
               )
           and p_id_funcionario <> 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_cuenta := 0;
      END;
      IF I_CUENTA > 0 then
        I_CUENTA := 1;
      END IF;

      -- FINGER PARA LA POLICIA TABLA DE M4 dela relaciones en caso sea
      if nvl(i_pin, 0) = 0 then
        BEGIN
          select distinct lpad(CODIGO, 5, '0')
            into p_pin
            from persona p, personal_new pe
           where codigo > 1700
             and trim(apellidos) = trim(ape1(+)) || ' ' || trim(ape2(+))
             and trim(p.nombre) = trim(pe.nombre(+))
             and pe.nombre || ' ' || ape1 || ' ' || ape2 = V_salida_dis;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            p_pin := NULL;
        END;
        i_pin:=p_pin;
      end if;

      i_actualiza := 0;
      --SI es hay que actualizar
      IF V_id_fichajes = i_pin AND V_FIRMA = I_CUENTA AND
         i_FUNCIONARIO_IGUAL_PER = 1 THEN
        i_actualiza := 0;
      ELSE
        i_actualiza := 1;
      END IF;

       --Añadido el 14 de Agosto 2012
       Begin
       select distinct id_departamento into i_id_departamento
        from apliweb_DEPARTAMENTO t
        where da=V_salida_depart and rownum<2;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_id_departamento := NULL;
        END;
      if  i_id_departamento> 0 then
          update apliweb_usuario
             set  id_depto=i_id_departamento
           where login = v_usuario;
      end if;

      --Insertamos si es necesario
      If i_inserta = 1 THEN
       NIF:=VALIDANIF(V_DNI);


        BEGIN


          insert into apliweb_usuario
          values
            (v_usuario, '', i_pin, I_CUENTA, p_id_funcionario, '',v_dni,'',nif,V_salida_depart,V_salida_disName,i_id_departamento);
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            i_inserta := 0;
        END;
      -- rollback;
        commit;
        --TABLA DONDE SE GUARDA LA RELACION
          --id FUNCIONACIO PERSONAL
          --dni meta4
          --LOGIN dIRECTORIO ACTIVO.
           if nvl(i_pin,0)=0 then
            i_pin:= p_pin;
        end if;
      ELSE
        IF i_actualiza = 1 THEN
          update apliweb_usuario
             set id_fichaje     = i_pin,
                 FIRMA          = I_CUENTA,
                 DNI=v_dni,
                 NIF=VALIDANIF(V_DNI),
                 ID_FUNCIONARIO = p_id_funcionario,
                 departamento=V_salida_depart,
                 DIST_NAME=V_salida_disName
                -- id_depto=i_id_departamento
           where login = v_usuario;
          if nvl(i_pin, 0) = 0 then
            i_pin := p_pin;
          end if;
        END IF;

      END IF;

   --  rollback;
        commit;
 end if;
        end if;

 


--rollback;
        commit;

update apliweb_usuario
set id_fichaje='00000' , dni =null , nif = null, id_funcionario='999999'
where login ='mcprevencion1.ri';
--rollback;
       commit;

end CHEQUEA_DA_FINAL_FALTAN;
/

