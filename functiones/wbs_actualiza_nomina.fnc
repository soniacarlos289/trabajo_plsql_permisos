create or replace function rrhh.wbs_actualiza_nomina(v_id_funcionario IN VARCHAR2,
                                              fichero          in blob)
  return varchar2 is
  Resultado     varchar2(12000);
  observaciones varchar2(12000);
  contador      number;

begin
  observaciones := 'biem';
  contador := 1;

--  delete nomina_funcionario where id_funcionario = v_id_funcionario;
  commit;

  Update nomina_funcionario
  set
  nomina=fichero;-- where nif='07954264J';
  commit;

  commit;
  resultado := observaciones;
  return(Resultado);
end;
/

