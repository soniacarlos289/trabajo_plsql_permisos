create or replace function rrhh.TURNOS_FICHAES_POLICIA_MES(i_ID_FUNCIONARIO IN VARCHAR2,
i_MES IN number,i_id_Anno in number)
 return varchar2 is
  Result varchar2(100);

  i_contador varchar2(30);
  i_resultado number;
  i_prox_anno number;

  v_resultado varchar2(200);

BEGIN

  i_prox_anno:=i_id_Anno+1;

  v_resultado:='';

  --turno mañana
  BEGIN
  select     DECODE(trunc(sum(horas_fichadas)/60),null,'','. M->' ||  trunc(sum(horas_fichadas)/60)  ) as horas
       into  i_contador
  from FICHAJE_FUNCIONARIO fc, personal_new f
   where
         to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
              between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
              and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)  and turno in (1,0)
         and fc.id_funcionario=f.id_funcionario
         and fc.id_funcionario=i_ID_FUNCIONARIO;
  EXCEPTION
            WHEN NO_DATA_FOUND THEN
            i_contador:='';
  END;

  v_resultado:=  v_resultado || i_contador;
  --turno tarde
  BEGIN
  select     DECODE(trunc(sum(horas_fichadas)/60),null,'', '. T->' || trunc(sum(horas_fichadas)/60)  ) as horas
       into  i_contador
  from FICHAJE_FUNCIONARIO fc, personal_new f
   where
         to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
              between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
              and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)  and turno in (2)
         and fc.id_funcionario=f.id_funcionario
         and fc.id_funcionario=i_ID_FUNCIONARIO;
  EXCEPTION
            WHEN NO_DATA_FOUND THEN
            i_contador:='';
  END;
  v_resultado:=  v_resultado || i_contador;

  --turno noche
  BEGIN
  select    DECODE(trunc(sum(horas_fichadas)/60),null,'', '. N->' || trunc(sum(horas_fichadas)/60)  ) as horas
       into  i_contador
  from FICHAJE_FUNCIONARIO fc, personal_new f
   where
         to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
              between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
              and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)  and turno in (3)
         and fc.id_funcionario=f.id_funcionario
         and fc.id_funcionario=i_ID_FUNCIONARIO;
  EXCEPTION
            WHEN NO_DATA_FOUND THEN
            i_contador:='';
  END;
  v_resultado:=  v_resultado || i_contador;

  --total horas
  BEGIN
  select    ' Total-> ' || nvl(trunc(sum(horas_fichadas)/60),0)  as horas
       into  i_contador
  from FICHAJE_FUNCIONARIO fc, personal_new f
   where
         to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
              between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
              and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)
         and fc.id_funcionario=f.id_funcionario
         and fc.id_funcionario=i_ID_FUNCIONARIO;
  EXCEPTION
            WHEN NO_DATA_FOUND THEN
            i_contador:='';
  END;
  v_resultado:= i_contador || v_resultado;





  Result:= v_resultado;
  return(Result);
end TURNOS_FICHAES_POLICIA_MES;
/

