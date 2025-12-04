create or replace procedure rrhh.AVISO_LEGAL_FUNCIONARIOS(
          V_ID_FUNCIONARIO in number

          ) is


 pos  integer;

begin


  BEGIN
              insert into aviso_legal_funcionario_2019
                     (id_funcionario, fecha_modi)
               values
                  (v_id_funcionario, sysdate);
                     EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                      pos := 0;
              END;


END AVISO_LEGAL_FUNCIONARIOS;
/

