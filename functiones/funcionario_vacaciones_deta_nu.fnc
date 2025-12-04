create or replace function rrhh.FUNCIONARIO_VACACIONES_DETA_NU(V_FECHA_INICIO IN DATE,V_ID_UNIDAD IN VARCHAR2) return varchar2 is
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


i_id_unidad:= V_ID_UNIDAD ||'%';


--Personas de vacaciones
BEGIN
     select count(distinct id_funcionario)
     into i_personas_vacaciones
     from rrhh.permiso
     where id_funcionario in
          (
             select id_funcionario
            from personal_rpt
             where id_UNIDAD LIKE i_id_unidad  and
                (
                 ( v_fecha_inicio between  FECHA_INICIO and FECHA_FIN )
                ) and (ANULADO ='NO' OR ANULADO is NULL) and id_estado=80
          );
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_error:=0;
END;


--Result:=    i_Desc_unidad || ' tiene '|| i_personas_vacaciones ||'/' || i_personas_total || '. Entre las fechas de este permiso.';
--Result:=    i_Desc_unidad || '  ('|| i_personas_vacaciones ||' de un total de ' || i_personas_total || ' Func.)';
Result:= i_personas_vacaciones ;
return(Result);
end FUNCIONARIO_VACACIONES_DETA_NU;
/

