create or replace function rrhh.FUNCIONARIO_VACACIONES(V_FECHA_INICIO IN DATE, V_FECHA_FIN IN DATE,V_ID_FUNCIONARIO IN VARCHAR2) return varchar2 is
  Result varchar2(256);
  i_id_unidad varchar2(25);
  i_error varchar2(25);
  i_personas_vacaciones number;
  i_personas_total number;
  i_Desc_unidad varchar2(256);

begin
i_Desc_unidad:='Sin Unidad';
--Unidad de trabajo.
BEGIN
     select distinct r.id_unidad,initcap(desc_unidad)
     into i_id_unidad,i_Desc_unidad
     from rpt r,
          personal_rpt pr,
          unidad u
     where r.id_unidad=pr.id_unidad and
           pr.id_funcionario=V_ID_FUNCIONARIO and
           pr.id_unidad=u.id_Unidad  and
           (F_NUM_PLAZAS> 0 OR L_NUM_PLAZAS > 0);
EXCEPTION
     WHEN NO_DATA_FOUND THEN
              i_error:=0;
              i_Desc_unidad:='Sin Unidad';
END;

i_personas_total:=0;
i_personas_vacaciones:=0;
--Personas de vacaciones
BEGIN
     select count(distinct id_funcionario)
     into i_personas_total
     from personal_rpt
     where id_UNIDAD=i_id_unidad;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_error:=0;
END;


--Personas de vacaciones
BEGIN
     select count(distinct id_funcionario)
     into i_personas_vacaciones
     from permiso
     where id_funcionario in
          (
             select id_funcionario
            from personal_rpt
             where id_UNIDAD=i_id_unidad  and
                (
                 ( fecha_inicio between  V_FECHA_INICIO and V_FECHA_FIN ) OR
                 ( fecha_fin between  V_FECHA_INICIO and V_FECHA_FIN )
                ) and (ANULADO ='NO' OR ANULADO is NULL) and id_estado=80
          );
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_error:=0;
END;


--Result:=    i_Desc_unidad || ' tiene '|| i_personas_vacaciones ||'/' || i_personas_total || '. Entre las fechas de este permiso.';
Result:=    i_Desc_unidad || '  ('|| i_personas_vacaciones ||' de un total de ' || i_personas_total || ' Func.)';
return(Result);
end FUNCIONARIO_VACACIONES;
/

