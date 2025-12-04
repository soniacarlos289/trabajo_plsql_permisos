CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_GUARDA_CONFIGURACION" (
          V_ID_FUNCIONARIO in number,
          V_RELOJ_FICHAJE in varchar2,
          V_CAMPO_ALERT in varchar2,
          V_CAMPO_JORNADA in varchar2,
          V_CAMPO_PTO_FICHAJE in varchar2,
          V_CAMPO_CALENDARIO in varchar2,
          v_audit_usuario in varchar2,
          msgsalida out varchar2,todook out varchar2) is


  v_campo                 varchar2(2000);
  pos                     number;
  pos2                    number;

 --Campo Alerta

  i_alert_1               number;
  i_alert_2               number;
  i_alert_3               number;
  i_alert_4               number;
  i_alert_5               number;
  i_alert_6               number;
  i_alert_7               number;
  i_alert_8               number;
  i_alert_9               number;



  i_alertas_SIN           number;
   i_incidencia           number;

 --CAMPO PTO FICHAJE
  campo_pto_todos          varchar2(100);

  i_pto_fichaje            number;
  i_reloj                  number;
  i_operacion              number;
  i_longitud               number;
  i_longitud_fichajes      number;

 --CAMPO JORNADA
  campo_jornada_CAMBIO     varchar2(10);
  campo_jornada_fecha_ini  varchar2(10);
  campo_jornada_fecha_fin  varchar2(10);
  campo_jornada_libre      varchar2(10);
  campo_jornada_comida     varchar2(10);
  campo_jornada_bolsa      varchar2(10);
  campo_dias               varchar2(10);
  campo_horas_semanales    varchar2(10);
  campo_horas_diarias      varchar2(10);
  campo_reduccion          varchar2(10);

  i_cambia_jornada         number;
  d_jornada_Fecha_inicio   date;
  d_jornada_Fecha_fin      date;
  i_jornada_dias           number;
  d_jornada_horas_dias     date;
  i_jornada_reducion       number;
  i_jornada_horas_semanales number;
  i_jornada_libre          numbeR;
  i_jornada_comida         number;
  i_jornada_bolsa          number;
  i_jornada_bolsa_con      number;
  i_dias_semana            varchar2(12);

  v_id_calendario          varchar2(2);
  v_jornada_comida         varchar2(2);
  v_jornada_libre          varchar2(2);

begin

/*
todook:='1';
  msgsalida:=V_CAMPO_ALERT;

   return;
rollback;*/


----ALERTAS
 i_alertas_SIN :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_SIN'),0);
 i_alert_1     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_1'),0);
 i_alert_2     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_2'),0);
 i_alert_3     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_3'),0);
 i_alert_4     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_4'),0);
 i_alert_5     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT,'ALERTA_5'),0);
 i_alert_6     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_6'),0);
 i_alert_7     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_7'),0);
 i_alert_8     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_8'),0);
 i_alert_9     :=nvl(devuelve_valor_campo( V_CAMPO_ALERT ,'ALERTA_9'),0);


 --Insertamos las alertas.
 i_incidencia:=1;
 BEGIN
   insert into fichaje_funcionario_alerta
     (id_funcionario,
      sin_alertas,
      alerta_0,
      alerta_1,
      alerta_2,
      alerta_3,
      alerta_4,
      alerta_5,
      alerta_6,
      alerta_7,
      alerta_8,
      alerta_9,
      audit_usuario,
      audit_fecha)
   values
     (v_id_funcionario,
      i_alertas_sin,
      1,
      i_alert_1,
      i_alert_1,
      i_alert_3,
      i_alert_4,
      i_alert_5,
      i_alert_6,
      i_alert_7,
      i_alert_8,
      i_alert_9,
      101217,
      sysdate);
 EXCEPTION
   WHEN DUP_VAL_ON_INDEX THEN
     i_incidencia := 0;
 END;


 IF  i_incidencia = 0 then
              update fichaje_funcionario_alerta
                 set id_funcionario = v_id_funcionario,
                     sin_alertas =  i_alertas_sin,
                     alerta_0 = 1,
                     alerta_1 = i_alert_1,
                     alerta_2 = i_alert_2,
                     alerta_3 = i_alert_3,
                     alerta_4 = i_alert_4,
                     alerta_5 = i_alert_5,
                     alerta_6 = i_alert_6,
                     alerta_7 = i_alert_7,
                     alerta_8 = i_alert_8,
                     alerta_9 = i_alert_9,
                     audit_usuario = 101217,
                     audit_fecha = sysdate
               where id_funcionario = v_id_funcionario;
 END IF;


----FIN ALERTAS

----Punto Fichaje---
-- P_T0;P10X3*P18X3*P17X3*P11X1*

    i_longitud_fichajes:=length(V_CAMPO_PTO_FICHAJE);

   IF     i_longitud_fichajes > 6 THEN
    i_longitud:=4;

    --TODOS PTOS DE FICHAJE
     i_pto_fichaje:=-1;
     campo_pto_todos:='P_T';

     pos:=instr(V_CAMPO_PTO_FICHAJE, campo_pto_todos,1,1)+3;
     pos2:=instr (V_CAMPO_PTO_FICHAJE,';', pos,1);

     IF pos2-pos> 0 and pos2-pos<6  then
         v_campo:=substr(V_CAMPO_PTO_FICHAJE, pos,pos2-pos);
         IF   es_numero(v_campo) = 0 then
              i_pto_fichaje:=to_number(v_campo);
         ELSE
              i_pto_fichaje:=-1;
         END  IF;
      END IF;

      --INSERTAR TODOS LOS FICHAJES
      IF i_pto_fichaje = 1  THEN

           --borro todos los puntos.
           delete fichaje_funcionario_reloj where id_funcionario=v_id_funcionario;
           --INSERTO TODO LOS PUNTOS
           insert into fichaje_funcionario_reloj
             (select id_sec_fun_reloj.nextval,v_id_funcionario,numero,
                     v_audit_usuario, sysdate  from relojes where activo='S');
      ELSE
         WHILE i_longitud_fichajes > i_longitud LOOP

          if  instr( V_CAMPO_PTO_FICHAJE ,'P',1) > 0 then
            i_reloj:=substr( V_CAMPO_PTO_FICHAJE , instr( V_CAMPO_PTO_FICHAJE ,'P',i_longitud)+1,2);
          else
            i_reloj:=10;
          ENd if;

            i_operacion:=substr(  V_CAMPO_PTO_FICHAJE ,instr(V_CAMPO_PTO_FICHAJE ,'X',i_longitud)+1,1);
            i_longitud:=instr( V_CAMPO_PTO_FICHAJE ,'*',i_longitud)+1;

            --0 el pto fichaje no cambia,
            --1  pto fichaje nuevo
            --3 borrar pto fichaje
            -- P_T0;P10X0*P18X3*P17X3*P11X1*

            IF   i_operacion = 1 OR I_operacion = 3 THEN
                 IF i_operacion = 1 THEN
                   insert into fichaje_funcionario_reloj
                     (id_sec_func_reloj, id_funcionario, relojes, audit_usuario, audit_fecha)
                   values
                     (id_sec_fun_reloj.nextval, v_id_funcionario,i_reloj, v_audit_usuario, sysdate);
                 ELSE
                     delete fichaje_funcionario_reloj where relojes = i_reloj;
                 END IF;
            END IF;

          END LOOP;

      END IF;
   END IF;--LONGITUD CON MAS DE UN PUNTO
----FIN Punto Fichaje---


---JORNADA---
--CAMBIA1;J_FI01/01/2017;J_FF;J_DI5;J_HD07:12;J_RE10 ;J_HS08:00;J_BO1;J_HC0;J_LI0;DIAS_SEMANA1111100;J_BOC1;

----campos jornada


  i_cambia_jornada       :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'CAMBIA'),0         );
  d_jornada_Fecha_inicio :=to_date(devuelve_valor_campo( V_CAMPO_JORNADA ,'J_FI'),'DD/mm/yyyy');
  d_jornada_Fecha_fin    :=to_date(devuelve_valor_campo( V_CAMPO_JORNADA ,'J_FF'),'DD/mm/yyyy');
  i_jornada_dias         :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'J_DI'),0           );
  v_campo                :=nvl(  devuelve_valor_campo( V_CAMPO_JORNADA ,'J_HS'),0           );
  d_jornada_horas_dias   :=to_date('01/01/1900 ' ||   devuelve_valor_campo( V_CAMPO_JORNADA ,'J_HD'),'DD/MM/YYYY HH24:MI');
  i_jornada_reducion     :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'J_RE'),0           );
  i_jornada_bolsa        :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'J_BO'),0           );
  i_jornada_bolsa_con    :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'J_BOC'),0          );
  i_jornada_comida       :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'J_HC'),0           );
  i_jornada_libre        :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'J_LI'),0           );
  i_dias_semana          :=nvl(    devuelve_valor_campo( V_CAMPO_JORNADA ,'DIAS_SEMANA'),0    );


   v_id_calendario:= V_CAMPO_CALENDARIO;


   IF i_cambia_jornada = 1 then


        if   v_campo = '08:00' then
               i_jornada_horas_semanales:=40;
         else if   v_campo = '07:30' then
                  i_jornada_horas_semanales:=37.5;
              else
                    i_jornada_horas_semanales:=37;
              END IF;
         end if;

      IF    i_jornada_comida =1 then
        v_jornada_comida:='SI' ;
      ELSE
        v_jornada_comida:='NO' ;
      END IF;

      IF    i_jornada_libre =1 then
        v_jornada_libre:='SI' ;
      ELSE
        v_jornada_libre:='NO' ;
      END IF;

     --PERIODO DE LA JORNADA NO ESTA SOLAPADO
     i_operacion:=  FINGER_JORNADA_SOLAPA(d_jornada_Fecha_inicio,
                                          d_jornada_Fecha_fin,
                                          V_ID_FUNCIONARIO);

     IF  i_operacion > 0 then
         todook:='1';
         msgsalida:='Las Fechas de Inicio y/o fin no son correctas.';
         return;
         rollback;
     END IF;

     IF d_jornada_Fecha_fin is null THEN
       /*FECHA FIN ES NULA */

      i_incidencia := 1;
      begin
       insert into fichaje_funcionario_jornada
        (id_funcionario, id_calendario, fecha_inicio, fecha_fin, horas_semanales, reduccion, horas_jornada,
        dias, contar_comida, libre, audit_usuario, audit_fecha, bolsa,bolsa_con,dias_semana)
       values
        (v_id_funcionario, v_id_calendario, d_jornada_Fecha_inicio,    d_jornada_Fecha_fin ,
         i_jornada_horas_semanales, i_jornada_reducion, d_jornada_horas_dias, i_jornada_dias,
         v_jornada_comida, v_jornada_libre, v_audit_usuario, sysdate, i_jornada_bolsa,i_jornada_bolsa_con,i_dias_semana );
       EXCEPTION
       WHEN DUP_VAL_ON_INDEX THEN
          i_incidencia := 0;
        END;

       /* cambiado CHM 11/11/2020*/
       IF i_incidencia =1 then
          update fichaje_funcionario_jornada
         set fecha_fin=d_jornada_Fecha_inicio -1
         where id_funcionario = v_id_funcionario and fecha_fin is null AND FECHA_INICIO<d_jornada_Fecha_inicio-1;
       else
         update fichaje_funcionario_jornada
            set id_calendario = v_id_calendario,
                fecha_inicio =d_jornada_Fecha_inicio,
                fecha_fin = d_jornada_Fecha_fin,
                horas_semanales = i_jornada_horas_semanales,
                reduccion = i_jornada_reducion,
                horas_jornada = d_jornada_horas_dias,
                dias = i_jornada_dias,
                contar_comida = v_jornada_comida,
                libre =v_jornada_libre,
                audit_usuario = v_audit_usuario,
                audit_fecha =sysdate,
                bolsa = i_jornada_bolsa,
                bolsa_con =i_jornada_bolsa_con,
                dias_semana = i_dias_semana
          where id_funcionario = v_id_funcionario
            and fecha_inicio = d_jornada_Fecha_inicio
            and fecha_fin is null;
       end if;


     ELSE --FECHA FIN NO ES NULA
        insert into fichaje_funcionario_jornada
        (id_funcionario, id_calendario, fecha_inicio, fecha_fin, horas_semanales, reduccion, horas_jornada, dias, contar_comida, libre, audit_usuario, audit_fecha, bolsa,bolsa_con,dias_semana)

         (select id_funcionario, id_calendario,  d_jornada_Fecha_fin +1,   null ,
         horas_semanales, reduccion, horas_jornada, dias,
         contar_comida, libre, v_audit_usuario, sysdate, bolsa,bolsa_con,dias_semana
         from fichaje_funcionario_jornada
          where id_funcionario = v_id_funcionario and fecha_fin is null);

       update fichaje_funcionario_jornada
       set fecha_fin=d_jornada_Fecha_inicio -1
       where id_funcionario = v_id_funcionario and fecha_fin is null and fecha_inicio<> d_jornada_Fecha_fin +1;

       insert into fichaje_funcionario_jornada
        (id_funcionario, id_calendario, fecha_inicio, fecha_fin, horas_semanales, reduccion, horas_jornada, dias, contar_comida, libre, audit_usuario, audit_fecha, bolsa,bolsa_con,dias_semana)
       values
        (v_id_funcionario, v_id_calendario, d_jornada_Fecha_inicio,    d_jornada_Fecha_fin ,
         i_jornada_horas_semanales, i_jornada_reducion, d_jornada_horas_dias, i_jornada_dias,
         v_jornada_comida, v_jornada_libre, v_audit_usuario, sysdate, i_jornada_bolsa,i_jornada_bolsa_con,i_dias_semana );

     END IF;


   END IF;--FIN CAMBIO DE JORNADA
---FIN JORNADA--

--POR DONDE FICHA
update funcionario_fichaje
   set  id_tipo_fichaje = V_RELOJ_FICHAJE ,
       id_usuario = v_audit_usuario,
       fecha_modi = sysdate
 where id_funcionario = v_id_funcionario;
--

COMMIT;
msgsalida:='Se ha guardado correctamente';
todook:='0';
END FICHAJE_GUARDA_CONFIGURACION;
/

