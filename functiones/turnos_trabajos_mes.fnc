create or replace function rrhh.TURNOS_TRABAJOS_MES(i_ID_FUNCIONARIO IN VARCHAR2,ID_TIPO_FUNCIONARIO in number,
i_MES IN number,i_id_Anno in number)
 return varchar2 is
  Result varchar2(100);

  i_contador varchar2(130);
  i_resultado number;
  i_prox_anno number;

  v_resultado varchar2(200);

BEGIN

  i_prox_anno:=i_id_Anno+1;

  v_resultado:='';

IF ID_TIPO_FUNCIONARIO<>23 THEN
      --turno mañana
      BEGIN
      select     DECODE(trunc(sum(horas_fichadas)/60),null,'','. M->' ||  trunc(sum(horas_fichadas)/60)  ) as horas
           into  i_contador
      from FICHAJE_FUNCIONARIO fc, personal_new f
       where
             to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
                  between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
                  and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)  and turno in (1,0)
             and fc.id_funcionario=f.id_funcionario and (f.fecha_fin_contrato is null or f.fecha_fin_contrato>sysdate)
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
             and fc.id_funcionario=f.id_funcionario and (f.fecha_fin_contrato is null or f.fecha_fin_contrato>sysdate)
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
             and fc.id_funcionario=f.id_funcionario and (f.fecha_fin_contrato is null or f.fecha_fin_contrato>sysdate)
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
             and fc.id_funcionario=f.id_funcionario and (f.fecha_fin_contrato is null or f.fecha_fin_contrato>sysdate)
             and fc.id_funcionario=i_ID_FUNCIONARIO;
      EXCEPTION
                WHEN NO_DATA_FOUND THEN
                i_contador:='';
      END;
 ELSE
      Begin
        select  'Total-> ' || SUM(decode(id_tipo_permiso,NULL,((hasta-desde)* 24),0))
             into  i_contador
          from BOMBEROS_GUARDIAS_PLANI B,permiso p
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


  v_resultado:= i_contador || v_resultado;





  Result:= v_resultado;
  return(Result);
end TURNOS_TRABAJOS_MES;
/

