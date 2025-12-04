create or replace function rrhh.CALCULA_BOMBEROS_OPCION(v_ID_ANO varchar2,V_ID_FUNCIONARIO in VARCHAR2,v_id_tipo_permiso in varchar2) return varchar2 is
  Result varchar2(250);
 id_permiso varchar2(259);
 i_id_bombero number;
begin
id_permiso:='';
i_id_bombero:=0;

--busco si tiene permisos
BEGIN
 SELECT count(*)
  into i_id_bombero
  from permiso_funcionario a
 where a.id_ano=V_ID_ANO and
      a.id_funcionario=V_ID_FUNCIONARIO and
      a.id_tipo_permiso in ('02081','02082','02162','02241','02242');
EXCEPTION
 WHEN NO_DATA_FOUND THEN
  i_id_bombero:=0;
END;
result:='';
IF  i_id_bombero > 0 THEN
 BEGIN
  SELECT
   MIN(ID_TIPO_PERMISO)
   into id_permiso
   from permiso_funcionario a
  where a.id_ano=V_ID_ANO and
      a.id_funcionario=V_ID_FUNCIONARIO
      and  a.id_tipo_permiso in ('02081','02082','02162','02241','02242')
      and ((a.id_tipo_permiso ='02162' and num_dias<>2 )
      OR (a.id_tipo_permiso ='02241' and num_dias=0)
      OR (a.id_tipo_permiso ='02081' and num_dias=0)
      );
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    result:='';
  END;
  IF id_permiso='02162' AND
    (V_ID_TIPO_PERMISO='02081' OR
    V_ID_TIPO_PERMISO='02241'  )THEN
       result:= '0';
  ELSE IF (id_permiso='02241' OR  id_permiso='02081') AND
        (V_ID_TIPO_PERMISO='02082' OR V_ID_TIPO_PERMISO='02162'
       OR V_ID_TIPO_PERMISO='02242')
       THEN
        result:= '0';
       ELSE
        result:=V_ID_TIPO_PERMISO;
       END IF;
  END IF;
  IF id_permiso is NULL then
       result:= V_ID_TIPO_PERMISO;
  END IF;

END IF;
   return(Result);
end CALCULA_BOMBEROS_OPCION;
/

