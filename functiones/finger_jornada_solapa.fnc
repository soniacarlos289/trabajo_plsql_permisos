create or replace function rrhh.FINGER_JORNADA_SOLAPA(V_FECHA_INICIO IN DATE,
                                                 V_FECHA_FIN IN DATE,V_ID_FUNCIONARIO in varchar2)
 return number is
  Result number;
 i_contador number;


begin



BEGIN
     select count(distinct id_funcionario)
     into i_contador
     from fichaje_funcionario_jornada
     where id_funcionario =V_ID_FUNCIONARIO
            and
                (
                 ( v_fecha_inicio between  FECHA_INICIO and FECHA_FIN ) OR
                 ( nvl(v_fecha_fin,to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'))
                           between  FECHA_INICIO and FECHA_FIN )

          );
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_contador:=0;
END;

Result:= i_contador ;
return(Result);
end FINGER_JORNADA_SOLAPA;
/

