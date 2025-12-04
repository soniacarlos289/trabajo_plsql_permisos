create or replace procedure rrhh.Chequeo_COMPENSATORIO
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_TOTAL_HORAS out number,
        todo_ok_Basico out integer,msgBasico out varchar2) is

i_hora_inicio number;
i_hora_fin number;
i_minuto_inicio number;
i_minuto_fin number;
i_minuto_diferencia number;
i_hora_diferencia number;

i_minutos_totales number;
i_no_tiene_horas number;
i_disponibles number;
i_fecha_inicio date;
i_fecha_fin date;


begin

todo_ok_basico:=0;
msgBasico:='';

i_fecha_inicio:=to_Date(to_char(V_FECHA_INICIO,'dd/mm/yyyy') || V_HORA_INICIO,'dd/mm/yyyy hh24:mi');
i_fecha_fin:=to_Date(to_char(V_FECHA_FIN,'dd/mm/yyyy') || V_HORA_FIN,'dd/mm/yyyy hh24:mi');





i_minuto_inicio:=substr(V_HORA_INICIO,4,2);
i_minuto_fin:=substr(V_HORA_FIN,4,2);

i_hora_inicio:=substr(V_HORA_INICIO,1,2);
i_hora_fin:=substr(V_HORA_FIN,1,2);

--chm 21/03/2017
IF (I_MINUTO_INICIO = I_MINUTO_FIN) AND (i_hora_inicio = i_hora_fin)
   AND   ( to_date(V_FECHA_INICIO,'dd/mm/yyyy') = to_date(V_FECHA_FIN,'dd/mm/yyyy') )

 THEN
   todo_ok_basico:=1;
   msgBasico:='Operacion no realizada. Hora de Inicio igual que hora final. :)';
   RETURN;


END IF;

IF I_MINUTO_INICIO  > I_MINUTO_FIN THEN

      i_minuto_diferencia:=(i_MINUTO_FIN+60)-i_MINUTO_INICIO ;

      IF i_hora_inicio >= i_hora_fin THEN
            IF V_FECHA_FIN <= V_FECHA_INICIO THEN
            todo_ok_basico:=1;
            msgBasico:='Operacion no realizada. Hora de Inicio Mayor que hora final.';
            RETURN;
            END IF;
      ELSE

            i_hora_diferencia:=i_hora_fin-i_hora_inicio-1;
      END IF;
ELSE

     i_minuto_diferencia:=i_MINUTO_FIN-i_MINUTO_INICIO;

     IF i_hora_inicio > i_hora_fin THEN
         IF V_FECHA_FIN <= V_FECHA_INICIO THEN
            todo_ok_basico:=1;
            msgBasico:='Operacion no realizada. Hora de Inicio Mayor que hora final.';
            RETURN;
          END IF;
     ELSE
             i_hora_diferencia:=i_hora_fin-i_hora_inicio;
     END IF;
END IF;

i_minutos_totales:=   i_hora_diferencia * 60 +i_minuto_diferencia;


i_minutos_totales:=(i_fecha_fin-i_fecha_inicio)*24*60;

--Comprobacion que tiene horas para compensar.
i_no_tiene_horas:=1;
BEGIN
    SELECT
        total-utilizadas
        into i_disponibles
    FROM
        horas_extras_ausencias
    WHERE

        id_funcionario=V_ID_FUNCIONARIO
        and rownum <2;
EXCEPTION
          WHEN NO_DATA_FOUND THEN
           i_no_tiene_horas:=0;
END;


IF i_minutos_totales > i_disponibles OR i_no_tiene_horas=0 OR i_minutos_totales > 1441 then
            todo_ok_basico:=1;
            msgBasico:='Operacion no realizada. No dispone de tantas h. para compensar. ' || i_minutos_totales || ' disp:' || i_disponibles;
            RETURN;
ELSE
   V_TOTAL_HORAS:=i_minutos_totales;
   UPDATE  horas_extras_ausencias
   set utilizadas=utilizadas+i_minutos_totales
   where id_funcionario=V_ID_funcionario and rownum <3;
   --busco que la actualizacion sera correcta.
   IF SQL%ROWCOUNT = 0 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update. ';
             RETURN;
   END IF;
END IF;


end Chequeo_COMPENSATORIO;
/

