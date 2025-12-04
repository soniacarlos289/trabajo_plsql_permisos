create or replace function rrhh.HORAS_TRAJADAS_MES(i_ID_FUNCIONARIO IN VARCHAR2,
ID_TIPO_FUNCIONARIO in number,i_MES IN number,i_id_Anno in number)
 return varchar2 is
  Result varchar2(100);

  i_contador number;
  i_resultado number;
  i_prox_anno number;

BEGIN

  i_prox_anno:=i_id_Anno+1;

  IF ID_TIPO_FUNCIONARIO<>23 THEN
      BEGIN
      select  sum(horas_fichadas)
           into  i_contador
      from FICHAJE_FUNCIONARIO fc, personal_new f
       where
             to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
                  between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
                  and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)
             and fc.id_funcionario=f.id_funcionario and (f.fecha_fin_contrato is null or f.fecha_fin_contrato>sysdate)
             and fc.id_funcionario=i_ID_FUNCIONARIO;
      EXCEPTION
                WHEN NO_DATA_FOUND THEN
                i_contador:=0;
      END;
  ELSE
     BEGIN
      select    SUM(decode(id_tipo_permiso,NULL,((hasta-desde)* 24*60),0))
           into  i_contador
        from BOMBEROS_GUARDIAS_PLANI b,permiso p
       where
            hasta
                  between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
                  and      (to_char(hasta,'mm')=i_mes OR 13=i_mes)
             and funcionario=i_ID_FUNCIONARIO
             AND B.FUNCIONARIO=P.id_FUNCIONARIO(+)
             AND hasta between P.fecha_inicio(+)-1 and P.fecha_fin(+)+1  and id_estado(+)=80;
      EXCEPTION
                WHEN NO_DATA_FOUND THEN
                i_contador:=0;
      END;

  END IF;


  Result:= devuelve_min_fto_hora(i_contador);
  return(Result);
end HORAS_TRAJADAS_MES;
/

