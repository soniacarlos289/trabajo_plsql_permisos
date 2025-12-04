create or replace function rrhh.

 PERSONAS_SINRPT(V_FECHA_INICIO         IN DATE,
                 V_FECHA_FIN            IN DATE,
                 V_ID_FUNCIONARIO_FIRMA IN VARCHAR2) return varchar2 is

  Result                varchar2(4000);
  v_lista_funcionario   varchar2(4000);
  i_id_funcionario      number;
  i_no_hay_datos        number;
  i_personas_vacaciones number;
  i_personas_total      number;
  i_temp                number;
  i_Desc_unidad         varchar2(512);

  cursor c1 is
    select id_funcionario
      from rrhh.funcionario_firma
     where (id_js = V_ID_FUNCIONARIO_FIRMA or
           id_delegado_js = V_ID_FUNCIONARIO_FIRMA or
           id_ja = V_ID_FUNCIONARIO_FIRMA)
    minus
    select id_funcionario
      from personal_rpt
     where id_unidad like
           (select id_unidad || '%'
              from personal_rpt
             where id_funcionario = V_ID_FUNCIONARIO_FIRMa);
begin
  v_lista_funcionario   := '';
  i_no_hay_datos        := 0;
  i_personas_vacaciones := 0;
  i_personas_total      := 0;
  i_Desc_unidad         := 'No incluida en la RPT';
  OPEN C1;
  LOOP
    FETCH C1
      INTO i_id_funcionario;
    EXIT WHEN C1%NOTFOUND;

    IF i_no_hay_datos = 0 then
      v_lista_funcionario := '''' || i_id_funcionario || '''';
    ELSE
      v_lista_funcionario := v_lista_funcionario || ',''' ||
                             i_id_funcionario || '''';
    END IF;

    i_personas_total := 1 + i_personas_total;

    BEGIN
      select count(distinct p.id_funcionario)
        into i_temp
        from permiso p
       where p.id_funcionario = i_id_funcionario
         and rownum < 2
         and ((fecha_inicio between V_FECHA_INICIO and V_FECHA_FIN) OR
             (fecha_fin between V_FECHA_INICIO and V_FECHA_FIN))
         and (ANULADO = 'NO' OR ANULADO is NULL)
         and id_estado = 80;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_temp := 0;
    END;
    i_personas_vacaciones := i_personas_vacaciones + i_temp;

  END LOOP;
  CLOSE C1;

  -- if  length(v_lista_funcionario)> 0 Then
  --   v_lista_funcionario:= '('|| v_lista_funcionario || ')';
  --end if;

  --Result:=    i_Desc_unidad || ' tiene '|| i_personas_vacaciones ||'/' || i_personas_total || '. Entre las fechas de este permiso.';
  Result := i_Desc_unidad || '  (' || i_personas_vacaciones ||
            ' de un total de ' || i_personas_total || ' Func.)';
  return(Result);

end PERSONAS_SINRPT;
/

