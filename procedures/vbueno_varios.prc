CREATE OR REPLACE PROCEDURE RRHH."VBUENO_VARIOS" (
          V_ID_TIPO_PERMISO in varchar2,
          V_ID_FUNCIONARIO_FIRMA in varchar2,
          V_ID_TODOS_PERMISOS in varchar2,
          V_ID_TIPO_FIRMA   in varchar2,
           V_ID_MOTIVO_DENIEGA   in varchar2,
           V_CLAVE_FIRMA in varchar2
          ) is




 msgBasico  varchar2(255);

v_id_permiso varchar2(128);
i_id_permiso_n number;

  todo_ok_basico number;
 i integer;
 i_pc number;
 i_error_exc number;
begin

--chm 23/11/2017
 --Compruebo que el funcionario no este primero en las horas sindicales
 --a Ausencia, P PErmiso
 IF    V_ID_TIPO_PERMISO = 'A' THEN
    FOR i IN 1 .. 15 LOOP


        v_id_permiso:=substr(V_ID_TODOS_PERMISOS, instr(V_ID_TODOS_PERMISOS,';',1,i)+1, instr(V_ID_TODOS_PERMISOS,';',1,i+1)- instr(V_ID_TODOS_PERMISOS,';',1,i)-1);

         --Comprobamos que es numero
        if   es_numero(v_id_permiso) = 0 then
            i_id_permiso_n:=to_number(v_id_permiso);
        else
            i_id_permiso_n:=0;
        end if;
        if i_id_permiso_n > 0 then
            i_pc:=1+i_pc;

                   vbueno_ausencia_rrhh(V_ID_TIPO_FIRMA,
                    v_id_funcionario_firma,
                       i_id_permiso_n,
                    V_ID_MOTIVO_DENIEGA ,
                    todo_ok_basico ,
                    msgbasico );

            --chcm 17/12/2020 añadido excepetion
            begin
             insert into permiso_validacion_todos
                         (id_permiso, tipo_permiso, resultado, mensaje, id_funcionario_firma, fecha_firma, clave_firma,
                         ID_OPERACION)
                       values
                    (i_id_permiso_n,V_ID_TIPO_PERMISO, todo_ok_basico,msgbasico, v_id_funcionario_firma, sysdate,
                     v_clave_firma,V_ID_TIPO_FIRMA);
                     EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                     i_error_exc:=0;
            end;

         end if;

        END LOOP;


 ELSE IF V_ID_TIPO_PERMISO = 'P' THEN
    FOR i IN 1 .. 15 LOOP


              v_id_permiso:=substr(V_ID_TODOS_PERMISOS, instr(V_ID_TODOS_PERMISOS,';',1,i)+1, instr(V_ID_TODOS_PERMISOS,';',1,i+1)- instr(V_ID_TODOS_PERMISOS,';',1,i)-1);
         --Comprobamos que es numero
        if   es_numero(v_id_permiso) = 0 then
            i_id_permiso_n:=to_number(v_id_permiso);
        else
            i_id_permiso_n:=0;
        end if;
        if i_id_permiso_n > 0 then
            i_pc:=1+i_pc;

                  vbueno_permiso_rrhh(V_ID_TIPO_FIRMA,
                    v_id_funcionario_firma,
                       i_id_permiso_n,
                    V_ID_MOTIVO_DENIEGA ,
                    todo_ok_basico ,
                    msgbasico );
             insert into permiso_validacion_todos
                         (id_permiso, tipo_permiso, resultado, mensaje, id_funcionario_firma, fecha_firma, clave_firma
                         ,ID_OPERACION
                         )
                       values
                    (i_id_permiso_n,V_ID_TIPO_PERMISO,todo_ok_basico,msgbasico, v_id_funcionario_firma, sysdate, v_clave_firma
                     ,V_ID_TIPO_FIRMA);


         end if;

        END LOOP;
      END IF;
 END IF; --Fin a Ausencia, P PErmiso







COMMIT;


END VBUENO_VARIOS;
/

