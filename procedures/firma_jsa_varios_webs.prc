create or replace procedure rrhh.FIRMA_JSA_VARIOS_webs(
          V_ID_TIPO_PERMISO in varchar2,
          V_ID_FUNCIONARIO_FIRMA in varchar2,
          V_ID_TODOS_PERMISOS in varchar2,
          V_ID_TIPO_FIRMA   in varchar2,
           V_ID_MOTIVO_DENIEGA   in varchar2,
           V_CLAVE_FIRMA in varchar2,
           v_observaciones in out varchar2,
           V_operacion_ok out  varchar2
          ) is




 msgBasico  varchar2(255);

v_id_permiso varchar2(128);
i_id_permiso_n number;

  todo_ok_basico number;
 i integer;
 i_pc number;
begin

   msgBasico:='';
    V_operacion_ok:= 0;
IF (V_ID_TIPO_FIRMA = 0 and V_ID_MOTIVO_DENIEGA is not null)  or V_ID_TIPO_FIRMA=1 THEN

--chm 23/11/2017
 --Compruebo que el funcionario no este primero en las horas sindicales
 --a Ausencia, P PErmiso
 IF    V_ID_TIPO_PERMISO = 'A' THEN
    FOR i IN 1 .. 75 LOOP --15


        v_id_permiso:=substr(V_ID_TODOS_PERMISOS, instr(V_ID_TODOS_PERMISOS,';',1,i)+1, instr(V_ID_TODOS_PERMISOS,';',1,i+1)- instr(V_ID_TODOS_PERMISOS,';',1,i)-1);

         --Comprobamos que es numero
        if   es_numero(v_id_permiso) = 0 then
            i_id_permiso_n:=to_number(v_id_permiso);
        else
            i_id_permiso_n:=0;
        end if;
        if i_id_permiso_n > 0 then
            i_pc:=1+i_pc;


                  firma_ausencia_jsa(V_ID_TIPO_FIRMA,
                                      v_id_funcionario_firma,
                                     i_id_permiso_n,
                                    V_ID_MOTIVO_DENIEGA ,
                                     todo_ok_basico ,
                                       msgbasico );

                  v_observaciones:=msgbasico;
                  todo_ok_basico:= todo_ok_basico;

             insert into permiso_validacion_todos
                         (id_permiso, tipo_permiso, resultado, mensaje, id_funcionario_firma, fecha_firma, clave_firma,
                         ID_OPERACION)
                       values
                    (i_id_permiso_n,V_ID_TIPO_PERMISO, todo_ok_basico,msgbasico, v_id_funcionario_firma, sysdate,
                     v_clave_firma,V_ID_TIPO_FIRMA);


         end if;

        END LOOP;


 ELSE IF V_ID_TIPO_PERMISO = 'P' THEN
    FOR i IN 1 .. 75 LOOP   --15 cambiado


              v_id_permiso:=substr(V_ID_TODOS_PERMISOS, instr(V_ID_TODOS_PERMISOS,';',1,i)+1, instr(V_ID_TODOS_PERMISOS,';',1,i+1)- instr(V_ID_TODOS_PERMISOS,';',1,i)-1);
         --Comprobamos que es numero
        if   es_numero(v_id_permiso) = 0 then
            i_id_permiso_n:=to_number(v_id_permiso);
        else
            i_id_permiso_n:=0;
        end if;
        if i_id_permiso_n > 0 then
            i_pc:=1+i_pc;


            firma_permiso_jsa_new(V_ID_TIPO_FIRMA,
                                   v_id_funcionario_firma,
                                   i_id_permiso_n,
                                   V_ID_MOTIVO_DENIEGA ,
                                 todo_ok_basico ,
                                 msgbasico );

            v_observaciones:=msgbasico;
           todo_ok_basico:= todo_ok_basico;

            /* insert into permiso_validacion_todos
                         (id_permiso, tipo_permiso, resultado, mensaje, id_funcionario_firma, fecha_firma, clave_firma
                         ,ID_OPERACION
                         )
                       values
                    (i_id_permiso_n,V_ID_TIPO_PERMISO,todo_ok_basico,msgbasico, v_id_funcionario_firma, sysdate, v_clave_firma
                     ,V_ID_TIPO_FIRMA);
                    */

         end if;

        END LOOP;
      END IF;
 END IF; --Fin a Ausencia, P PErmiso

else

msgBasico:='ID FIRMA vacio';
 V_operacion_ok:= 1;
  if (V_ID_MOTIVO_DENIEGA=''and V_ID_TIPO_FIRMA = 0) then
   msgBasico:='Motivo denegacion no puede estar vacio';

  end if;




end if;






COMMIT;
v_observaciones:=msgBasico;


END FIRMA_JSA_VARIOS_webs;
/

