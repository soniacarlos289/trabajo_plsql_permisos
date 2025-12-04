create or replace procedure rrhh.AUSENCIAS_ALTA_RRHH(
          V_ID_ANO in out number,
          V_ID_FUNCIONARIO in number,
          V_ID_TIPO_FUNCIONARIO in out varchar2,
          V_ID_TIPO_AUSENCIA in varchar2,
          V_ID_ESTADO_AUSENCIA in varchar2,
          V_FECHA_INICIO in DATE,
          V_FECHA_FIN in DATE,
          V_HORA_INICIO  in varchar2,
          V_HORA_FIN  in varchar2,
          V_JUSTIFICACION in varchar2,V_OBSERVACIONES in varchar2,
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
i_contador_laboral number;
i_contador_natural number;
v_total_horas_mete varchar2(12);
 i_horas_quedan number;

i_id_tipo_funcionario number;
begin
 i_todo_ok_B:='1';

  if V_ID_ANO = 0 AND to_number(V_ID_TIPO_AUSENCIA)>500 THEN
   V_ID_ANO:=substr(to_char( V_FECHA_INICIO,'DD/MM/YYYY'),7,4);
 END IF;

 if V_ID_ANO = 0 THEN
   V_ID_ANO:=to_char(sysdate,'YYYY');
 END IF;


BEGIN
    select tipo_funcionario2 into  i_id_tipo_funcionario
    from personal_new
    where id_funcionario=v_id_funcionario and rownum<2;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          i_id_tipo_funcionario :=0;
END;

 IF i_id_tipo_funcionario=0  then
           todook:=1;
           msgsalida:='Operacion no realizada. Funcionario no puede ser identificado como bombero,policia o SNP';
           return;
  END IF;


 i_total_dias:=0;

    --Obtengo los dias comprendidos entre las dos fechas naturales y laborales
    BEGIN
         SELECT count(*) as contador_laboral,
         to_number(V_FECHA_FIN-V_FECHA_INICIO)+1
         into i_contador_laboral,i_contador_natural
         from calendario_laboral
          where id_dia between V_FECHA_INICIO and
                               V_FECHA_FIN and laboral='SI';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
           i_total_dias:=0;
    END;


i_formato_fecha_inicio:= to_date(to_char(V_FECHA_INICIO,'DD/MM/YYYY') || V_HORA_INICIO,'DD/MM/YYYY HH24:MI');
i_formato_fecha_fin:= to_date(to_char(V_FECHA_FIN,'DD/MM/YYYY') || V_HORA_FIN,'DD/MM/YYYY HH24:MI');

 --Compruebo Calendario
    IF i_id_tipo_funcionario  = 21 OR
      i_id_tipo_funcionario  = 23 OR
       i_id_tipo_funcionario = 50   OR
       i_id_tipo_funcionario  = 40 OR
       i_id_tipo_funcionario  = 30 then
         i_total_dias:=to_number(to_date(i_formato_fecha_fin,'DD/MM/YYYY')-to_date(i_formato_fecha_inicio,'DD/MM/YYYY'))+1;
       ELSE  IF  i_id_tipo_funcionario  = 10 THEN
                  i_total_dias:=to_number(i_contador_LABORAL);
             END IF;


    END IF;

--i_total_dias:=to_number(to_date(i_formato_fecha_fin,'DD/MM/YYYY')-to_date(i_formato_fecha_inicio,'DD/MM/YYYY'))+1;
--msgsalida:=i_total_dias || ' ' || i_contador_laboral;
   --return;

i_total_horas:=round(i_total_dias*
 to_number(to_DATE('01/01/2000' || to_char(i_formato_fecha_fin,'HH24:MI'),'DD/MM/YYYY HH24:MI')-
        to_DATE('01/01/2000' || to_char(i_formato_fecha_inicio,'HH24:MI'),'DD/MM/YYYY HH24:MI') )*24*60
);






--(round(to_number())*60*24,0));
--Solapamiento

 --Solapamiento entre permisos
 --Cambiado esta mal
   i_contador:=0;
   BEGIN
       select count(*)
       into  i_contador
       from  permiso
       where ( (fecha_inicio between V_fecha_inicio and V_fecha_fin) OR
              (fecha_fin between V_fecha_inicio and V_fecha_fin) ) and
              id_funcionario=V_id_funcionario and
              id_ano=V_id_ano and (ANULADO='NO' OR ANULADO IS NULL)
              and id_estado not in ('30','31','32','40','41') and id_tipo_permiso <> '15000';
   EXCEPTION
          WHEN NO_DATA_FOUND THEN
          i_contador:=0;
   END;

   IF i_contador > 0 and  i_ID_TIPO_FUNCIONARIO <> 23 then
          todook:=1;
            msgsalida:='Operacion no realizada. Ya existen permisos en esas fechas.';
           return;
   END IF;

   --Solapamiento y ausencias
  BEGIN
       select count(*)
       into  i_contador
       from  ausencia
       where ((FECHA_INICIO  between
             i_formato_fecha_inicio and  i_formato_fecha_fin         ) OR
             (FECHA_FIN  between
             i_formato_fecha_inicio and  i_formato_fecha_fin         ))  AND
             id_funcionario=V_id_funcionario and
             id_ano=V_id_ano and (ANULADO='NO' OR ANULADO IS NULL)
              and id_estado not in ('30','31','32','40','41')
             ;
  EXCEPTION
          WHEN NO_DATA_FOUND THEN
          i_contador:=0;
  END;

  IF i_contador > 0  and  i_ID_TIPO_FUNCIONARIO <> 23 then
           todook:=1;
           msgsalida:='Operacion no realizada. Existen una ausencia entre esas fechas.';
           return;
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
    IF (i_horas_quedan <= 0  OR  i_horas_quedan <  i_total_horas)  AND V_ID_TIPO_AUSENCIA = 50 THEN
           i_todo_ok_B:=1;
           msgBasico:='Operacion no realizada. Horas solicitadas mayor que disponible. Horas Disponibles'||' '||i_horas_quedan/60 || 'h.';
           RETURN;
    END IF;
----BOLSA concilia


--Fecha Ausencia Fin > inicio
IF i_total_horas <= 0 THEN
   msgsalida:='Fecha de la Ausencia. Fin debe ser igual o mayor que la de Inicio.' ||V_HORA_INICIO
   || ' '|| i_total_horas || ' ' ||
    i_total_horas || ' ' ||
   i_formato_fecha_inicio || ' '||i_formato_fecha_fin;
   rollback;
   return;
END IF;


--Chequeo si es un HORA_SINDICAL
IF V_ID_TIPO_AUSENCIA > 500 THEN

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
    IF  i_todo_ok_B=1 then
    todook:=1;
          msgsalida:=msgbasico;
           rollback;
         return;
    END IF;
END IF;




--INSERTA AUSENCIA Y ENVIA CORREO
 inserta_ausencias_RRHH(   V_ID_ANO ,
        V_ID_FUNCIONARIO ,
        V_ID_TIPO_FUNCIONARIO ,
        V_ID_TIPO_AUSENCIA ,
        V_FECHA_INICIO ,
        V_FECHA_FIN ,
        V_HORA_INICIO ,
        V_HORA_FIN  ,
        V_JUSTIFICACION ,
        V_OBSERVACIONES,
        i_total_horas ,
        i_todo_ok_B,
        msgbasico);
--Hay errores fin
IF  i_todo_ok_B=1 then
 msgsalida:=msgbasico;
   rollback;
   return;
END IF;

--Metemos la ausencia en el finger. --a?adido dia 6 de abril 2010
--El funcionario Ficha ??
v_total_horas_mete:=lpad(trunc(i_total_horas/60),2,'0') || ':' || lpad(mod(i_total_horas,60),2,'0');

                 i_ficha:=1;
                 BEGIN
                      SELECT
                              distinct codpers
                              into i_codpers
                      FROM
                              personal_new p  ,presenci pr,
                              apliweb_usuario u
                      WHERE
                              p.id_funcionario=V_ID_FUNCIONARIO  and
                              lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and --cambiado 29/03/2010
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
                 EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
                 END;
/*msgsalida:= 'TOTAL HORAS' || i_total_horas
         ||   ' ID_A?O' || V_id_ano
         || ' ID_FUNCIONARIO' || V_id_funcionario
         || ' IFECHA_INICIO' || v_fecha_inicio
         || ' V_hora_inicio' || V_hora_inicio
         || ' V_hora_fin' || V_hora_fin
         || ' i_codpers' || i_codpers
         || ' v_total_horas_mete' || v_total_horas_mete ;
   rollback;
   return;                               */
         if i_ficha=1 then
            mete_fichaje_finger_NEW(V_id_ano ,
                                V_id_funcionario ,
                                v_fecha_inicio,
                                V_hora_inicio ,
                                V_hora_fin ,
                                i_codpers ,
                                v_total_horas_mete ,'00000',
                                 i_todo_ok_B ,
                                msgbasico);
         end if;


COMMIT;
msgsalida:='La ausencia se ha incorporado al sistema';
todook:='0';
END AUSENCIAS_ALTA_RRHH;
/

