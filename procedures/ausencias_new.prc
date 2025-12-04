create or replace procedure rrhh.AUSENCIAS_NEW(
          V_ID_ANO in out number,
          V_ID_FUNCIONARIO in number,
          V_ID_TIPO_FUNCIONARIO2 out varchar2,
          V_ID_TIPO_AUSENCIA in varchar2,
          V_ID_ESTADO_AUSENCIA in varchar2,
          V_FECHA_INICIO in DATE,
          V_FECHA_FIN in out DATE,
          V_HORA_INICIO  in out varchar2,
          V_HORA_FIN  in out varchar2,
          V_JUSTIFICACION in varchar2,
          V_IP in varchar2,msgsalida out varchar2,todook out varchar2) is

i_ficha number;
v_num_dias number;
v_id_tipo_dias_per varchar2(1);
v_codpers varchar2(5);
i_total_horas number;
i_todo_ok_B number;
msgBasico  varchar2(256);
v_id_tipo_dias_ent  varchar2(256);
i_codpers varchar(5);
i_id_funcionario number;
v_num_dias_tiene_per number;
i_formato_fecha_inicio date;
i_formato_fecha_fin date;
i_diferencia_TOTAL date;
i_total_dias number;
i_contador number;
i_operacion_solapamiento varchar2(1024);
 i_horas_v varchar2(2);
  i_minutos_v varchar2(2);
i_horas_quedan number;
V_ID_TIPO_FUNCIONARIO varchar2(2);
begin

--chm 10/02/2017
 --Compruebo el tipo de funcionario de la solicitud
 
 
 v_id_tipo_funcionario:=0;
  BEGIN
    select tipo_funcionario2
      into v_id_tipo_funcionario
      from personal_new pe
     where id_funcionario = V_id_funcionario  and rownum<2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_id_tipo_funcionario:=-1;
  END;

   IF v_id_tipo_funcionario = -1 then
   todook:='1';
    msgBasico      := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
 /* 
  todook:='1';
    msgsalida:='Por motivos de Administración no se pueden solicitar ausencias hasta 13:00. Perdón por las molestias' || V_ID_TIPO_FUNCIONARIO;
   return;
rollback;
 */
i_horas_quedan:=0;

V_FECHA_FIN:=V_FECHA_INICIO;
 if V_ID_ANO = 0 THEN
   V_ID_ANO:=to_char(sysdate,'YYYY');
 END IF;

--chm 8/05/2019
if length(V_HORA_INICIO)<5 then
  i_horas_v:=  lpad(substr(V_HORA_INICIO,1,instr(V_HORA_INICIO,':',1)-1),2,'0');
  i_minutos_v:= lpad(substr(V_HORA_INICIO,instr(V_HORA_INICIO,':',1)+1,2),2,'0');
  V_HORA_INICIO:=i_horas_v || ':'||i_minutos_v;
END IF;
--chm 8/05/2019
if length(V_HORA_FIN)<5 then
  i_horas_v:=  lpad(substr(V_HORA_FIN,1,instr(V_HORA_FIN,':',1)-1),2,'0');
  i_minutos_v:= lpad(substr(V_HORA_FIN,instr(V_HORA_FIN,':',1)+1,2),2,'0');
    V_HORA_FIN:=i_horas_v || ':'||i_minutos_v;
END IF;

i_formato_fecha_inicio:= to_date(to_char(V_FECHA_INICIO,'DD/MM/YYYY') || V_HORA_INICIO,'DD/MM/YYYY HH24:MI');
i_formato_fecha_fin:= to_date(to_char(V_FECHA_FIN,'DD/MM/YYYY') || V_HORA_FIN,'DD/MM/YYYY HH24:MI');
i_total_dias:=to_number(to_date(i_formato_fecha_fin,'DD/MM/YYYY')-to_date(i_formato_fecha_inicio,'DD/MM/YYYY'))+1;


i_total_horas:=i_total_dias*
 to_number(to_DATE('01/01/2000' || to_char(i_formato_fecha_fin,'HH24:MI'),'DD/MM/YYYY HH24:MI')-
        to_DATE('01/01/2000' || to_char(i_formato_fecha_inicio,'HH24:MI'),'DD/MM/YYYY HH24:MI') )*24*60
;

--(round(to_number())*60*24,0));
 --Chequea solapamiento
  --A?adido 6 de abril 2010
  --añadido chm 15/03/2021 --incidencia fichaje
IF V_ID_TIPO_AUSENCIA <> 998 THEN
         i_operacion_solapamiento:=chequea_solapamientos(v_id_ano ,
                                v_id_funcionario,
                                v_id_tipo_ausencia,--
                                v_fecha_inicio,
                                v_fecha_fin,
                                v_hora_inicio ,
                                v_hora_fin);

          -- i_operacion_solapamiento:=0;
           --Se deja meter permisos en un mismo dias para bomberos
           IF length(i_operacion_solapamiento) > 1 and  V_ID_TIPO_FUNCIONARIO <> 23 then
                   i_todo_ok_B:=1;
                   msgBasico:='Operacion no realizada.' || i_operacion_solapamiento ;
                   return;
           END IF;

          --Fecha Ausencia Fin > inicio
          IF i_total_horas <= 0 THEN
             msgsalida:='Fecha de la Ausencia. Fin debe ser igual o mayor que la de Inicio.';
             rollback;
             return;
          END IF;

END IF;
--chm 13/02/2020
--Buscamos las minutos que tiene para ese mes.
   BEGIN
         select total-utilizadas
           into i_horas_quedan
           from BOLsa_CONCILIA
          where
                id_ano=V_ID_ANO AND
                id_funcionario=V_ID_FUNCIONARIO;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                   i_horas_quedan:=0;

    END;

    --NO LE QUEDAN HORAS PARA ESE MES.
    IF (i_horas_quedan <= 0  OR  i_horas_quedan <  i_total_horas )  AND V_ID_TIPO_AUSENCIA = 50 THEN
           i_todo_ok_B:=1;
           msgBasico:='Operacion no realizada. Horas solicitadas mayor que disponible. Horas Disponibles'||' '||i_horas_quedan/60 || 'h.';
           msgsalida:=msgbasico;
             rollback;
         return;
    END IF;
----BOLSA



--Chequeo si es un HORA_SINDICAL
IF V_ID_TIPO_AUSENCIA > 500 AND V_ID_TIPO_AUSENCIA <> 998 THEN

  CHEQUEO_HSINDICAL (V_ID_ANO ,
          V_ID_FUNCIONARIO ,
          V_ID_TIPO_FUNCIONARIO ,
          V_ID_TIPO_AUSENCIA ,
          V_FECHA_INICIO ,
          V_FECHA_FIN ,
          V_HORA_INICIO  ,
          V_HORA_FIN  ,
          i_total_horas,
                        i_todo_ok_B ,
                        msgbasico);

   --Hay errores fin
    IF i_todo_ok_B=1 then
          msgsalida:=msgbasico;
           rollback;
         return;
    END IF;
END IF;




--INSERTA AUSENCIA Y ENVIA CORREO
 inserta_ausencias(   V_ID_ANO ,
        V_ID_FUNCIONARIO ,
        V_ID_TIPO_FUNCIONARIO ,
        V_ID_TIPO_AUSENCIA ,
        V_FECHA_INICIO ,
        V_FECHA_FIN ,
        V_HORA_INICIO ,
        V_HORA_FIN  ,
        V_JUSTIFICACION ,
        i_total_horas ,
        i_todo_ok_B,
        msgbasico);
--Hay errores fin
IF i_todo_ok_B=1 then
 msgsalida:=msgbasico;
   rollback;
   return;
END IF;


COMMIT;
msgsalida:='La solicitud de ausencia ha sido enviada para su firma.';
todook:='0';
END AUSENCIAS_NEW;
/

