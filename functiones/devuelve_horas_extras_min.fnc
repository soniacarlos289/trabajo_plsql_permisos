create or replace function rrhh.DEVUELVE_HORAS_EXTRAS_MIN
  (V_HORA_INICIO IN VARCHAR2,V_HORA_FIN IN VARCHAR2,v_id_tipo_horas in number) return varchar2 is
  Result number;

 i_hora_inicio number;
 i_hora_fin number;
 i_minuto_inicio number;
 i_minuto_fin     number;
 i_factor number;

 i_minutos number;
 i_minutos_diferencia number;
 i_horas_diferencia number;

begin
  i_hora_inicio:=to_number(substr(V_HORA_INICIO,1,2));
         i_hora_fin:=to_number(substr(V_HORA_FIN,1,2));
         i_minuto_inicio:=to_number(substr(V_HORA_INICIO,4,2));
         i_minuto_fin:=to_number(substr(V_HORA_FIN,4,2));


         IF i_MINUTO_INICIO  > i_MINUTO_FIN THEN
            i_minutos_diferencia:=(i_MINUTO_FIN+60)-i_MINUTO_INICIO ;
            i_horas_diferencia:=i_hora_fin-i_hora_inicio-1;
         ELSE
            i_minutos_diferencia:=i_MINUTO_FIN-i_MINUTO_INICIO ;
            i_horas_diferencia:=i_hora_fin-i_hora_inicio;
        END IF;

        --factor
        i_factor:=1;
        select factor into i_factor from TR_TIPO_HORA WHERE ID_TIPO_HORAs=v_id_tipo_horas;


         i_minutos:=(i_horas_diferencia*60+i_minutos_diferencia)*i_factor;

         Result:=i_minutos;
  return(Result);
end DEVUELVE_HORAS_EXTRAS_MIN;
/

