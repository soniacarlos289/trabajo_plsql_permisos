create or replace function rrhh.FUNCIONARIO_VACACIONES_DETA_TO(V_FECHA_INICIO IN DATE,V_ID_UNIDAD IN VARCHAR2) return varchar2 is
  Result varchar2(256);
  i_id_unidad varchar2(25);
  i_error varchar2(25);
  i_personas_vacaciones number;
  i_personas_total number;
  i_Desc_unidad varchar2(256);
  v_dia_semana varchar2(256);
v_dia_n varchar2(256);
v_mes varchar2(256);


begin
i_Desc_unidad:='Sin Unidad';


i_id_unidad:= V_ID_UNIDAD ||'%';

i_personas_total:=0;
i_personas_vacaciones:=0;
--Personas de total
BEGIN
     select count(distinct id_funcionario)
     into i_personas_total
     from personal_rpt
     where id_UNIDAD like i_id_unidad;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_error:=0;
END;



--Result:=    i_Desc_unidad || ' tiene '|| i_personas_vacaciones ||'/' || i_personas_total || '. Entre las fechas de este permiso.';
--Result:=    i_Desc_unidad || '  ('|| i_personas_vacaciones ||' de un total de ' || i_personas_total || ' Func.)';
Result:=  i_personas_total;
return(Result);
end FUNCIONARIO_VACACIONES_DETA_TO;
/

