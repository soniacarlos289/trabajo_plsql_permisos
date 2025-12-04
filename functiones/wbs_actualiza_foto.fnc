create or replace function rrhh.wbs_actualiza_foto(v_id_funcionario IN VARCHAR2,
                                              fichero          in blob)
  return varchar2 is
  Resultado     varchar2(12000);
  observaciones varchar2(12000);
  contador      number;

begin
  observaciones := 'nulo';
  contador := 1;

  delete foto_funcionario where id_funcionario = v_id_funcionario;
  commit;
  BEGIN
    insert into foto_funcionario
    values
      (v_id_funcionario, fichero, sysdate);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      observaciones := 'Error insercion';
    WHEN DUP_VAL_ON_INDEX THEN
      observaciones := 'Error insercion fichero ya existe';
  END;

  commit;
  resultado := observaciones;
  return(Resultado);
end;
/

