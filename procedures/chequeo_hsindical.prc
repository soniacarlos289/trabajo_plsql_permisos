create or replace procedure rrhh.Chequeo_Hsindical
       (
        V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_AUSENCIA in varchar2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        v_total_horas in number,
        todo_ok_Basico out integer,msgBasico out varchar2) is


i_mes_inicio number;
i_mes_fin number;
i_mes_actual number;
i_año_inicio number;
i_año_fin number;
i_año_actual number;

i_horas_quedan number;

begin

todo_ok_basico:=0;
msgBasico:='';

--Debera ser mismo mes...y actual.
i_mes_inicio:=to_char(V_FECHA_INICIO,'MM');
i_mes_fin:=to_char(V_FECHA_FIN,'MM');
--i_mes_actual:=to_char(sysdate,'MM');


i_año_inicio:=to_char(V_FECHA_INICIO,'YYYY');
i_año_fin:=to_char(V_FECHA_FIN,'YYYY');
i_año_actual:=to_char(sysdate,'YYYY');
/*
IF (i_mes_inicio<>i_mes_fin and i_mes_inicio<> i_mes_actual) OR
   (i_año_inicio<>i_año_fin and i_año_inicio<> i_año_actual) THEN
    todo_ok_basico:=1;
    msgBasico:='Operacion no realizada. Las fechas deberan ser en el mismo mes y mes actual.';
    RETURN;
END IF;
*/
--Buscamos las minutos que tiene para ese mes.
   BEGIN
         select total_horas-total_utilizadas
           into i_horas_quedan
           from HORA_SINDICAL
          where
                id_ano=V_ID_ANO AND
                id_MES=i_mes_inicio and
                id_funcionario=V_ID_FUNCIONARIO AND
                ID_TIPO_AUSENCIA= V_ID_TIPO_AUSENCIA;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                   i_horas_quedan:=0;

    END;

    --NO LE QUEDAN HORAS PARA ESE MES.
    IF i_horas_quedan <= 0  OR  i_horas_quedan <  v_total_horas THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. Horas solicitadas mayor que disponible. Horas Disponibles'||' '||i_horas_quedan/60 || 'h.';
           RETURN;
    END IF;


end Chequeo_Hsindical;
/

