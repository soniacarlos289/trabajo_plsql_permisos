create or replace function rrhh.DEVUELVE_OBSERVACIONES_FICHAJE
  (V_ID_FUNCIONARIO IN VARCHAR2,V_ID_TIPO_FUNCIONARIO IN VARCHAR2,V_OBSERVACIONES IN VARCHAR2,
   V_FICHAJE_ENTRADA in date,v_HH in number,V_HR in number
  ) return varchar2 is
  Result varchar2(522);

  pos number;
  pos2 number;
   v_horas varchar2(5);
      v_minutos varchar2(5);
         i_signo number;
   v_obser    varchar2(555);
   v_laboral   varchar2(555);
   dia_semana number;
V_observaciones_con varchar2(1000);
begin

select laboral
       into v_laboral
from calendario_laboral
 where id_dia = to_date(to_char(V_FICHAJE_ENTRADA,'dd/mm/yyyy'),'dd/mm/yyyy');

 --Si da 1 se ejecuta desde la web
 --si da 2 se ejecuta desde pl/sql
select tO_char(to_date('07/01/2019','dd/mm/yyyy'), 'D') into  dia_semana  from dual;

If dia_semana = 1 THEN
   dia_semana:=1;
ELSE
  dia_semana:=0;
End if;



IF V_ID_TIPO_FUNCIONARIO =21 then
      Result:= V_OBSERVACIONES;
   return(Result);
END IF;

  --es sabado
  IF to_number(to_char(V_FICHAJE_ENTRADA,'d'))+dia_semana= 7  THEN
  --esta entre las 07:00 a 16:00 cuenta para saldo

     if  1415-to_number(to_char(V_FICHAJE_ENTRADA,'hh24mi'))<0 THEN
         v_obser:='NO COMPUTA PARA SALDO.';
         Result:= V_OBSER;
         return(Result);
     END IF;
  ELSE IF v_HH <> 0 and V_HR = 0 then
             v_obser:='SIN FICHAJE EN EL DÍA   <img src="../../imagen/icono_advertencia.jpg"
                                  alt="INCIDENCIA"  width="22" height="22" border="0" >';
             Result:= V_OBSER;
             return(Result);
        ELSE  IF v_HH = 0 and V_HR <> 0 AND V_LABORAL='NO' then
                   v_obser:='';--LO QUITO chm 14/03/2019. 'NO COMPUTA PARA SALDO.'
                   Result:= V_OBSER;
                   return(Result);
             END IF;
        END IF;
  END IF;

 BEGIN
  SELECT distinct    observaciones
      into V_observaciones_con
  FROM FICHAJE_INCIDENCIA f, personal_new pe, tr_tipo_incidencia tr
 where (fecha_baja is null or fecha_baja > sysdate - 1)
   and f.id_funcionario = pe.id_funcionario
   and f.id_tipo_incidencia = tr.id_tipo_incidencia
   and f.id_funcionario=V_ID_FUNCIONARIO
   and f.fecha_incidencia=V_FICHAJE_ENTRADA
   and id_Estado_inc = 0 and rownum<2;
EXCEPTION
      WHEN NO_DATA_FOUND THEN
          V_observaciones_con:='';
END;



    Result:= '' ||V_observaciones_con;
         return(Result);

end DEVUELVE_OBSERVACIONES_FICHAJE;
/

