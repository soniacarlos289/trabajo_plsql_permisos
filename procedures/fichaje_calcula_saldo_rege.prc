CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_CALCULA_SALDO_REGE" (
          V_ID_PRIMER_FICHAJE in varchar2,
          V_ID_SEGUNDO_FICHAJE in varchar2,
          V_ID_FUNCIONARIO in number,V_ID_TIPO_FUNCIONARIO number,
          v_pin     in number,

          msgsalida out varchar2,todook out varchar2) is

 v_cadena_t varchar2(22222);

  msgBasico        varchar2(255);

  PRIMER_SEC            number;
  PRIMER_RELOJ          varchar2(3);
  PRIMER_AUSENCIA       number;
  PRIMER_TIPOTRANS      number;
  PRIMER_PERIODO         varchar2(3);
  PRIMER_FECHA_FICHAJE  date;
  Poriginal_FECHA_FICHAJE date;

  segundo_SEC            number;
  segundo_RELOJ          varchar2(3);
  segundo_AUSENCIA       number;
  segundo_TIPOTRANS      number;
  segundo_PERIODO         varchar2(3);
  segundo_FECHA_FICHAJE  date;
  Soriginal_FECHA_FICHAJE date;

  i_fichajes_dia  number;

  i_p1d          date;
  i_p1h          date;
  i_p2d          date;
  i_p2h          date;
  i_p3d          date;
  i_p3h          date;
  i_po1d         date;
  i_po1h         date;
  i_po2d         date;
  i_po2h         date;
  i_po3d         date;
  i_po3h         date;
  i_doce date;
  i_horas_saldo  number;
  i_horas_fichadas number;
   dia_semana number;

  I_SIN_CALENDARIO number;
  i_turno number;
   i_turnos number;
   i_contar_comida    number;
    i_libre     number;
    i_incidencia number;
    V_INCIDENCIA_OBS varchar2(3000);
    I_ID_FUNCIONARIO  varchar2(3000);
    i_alerta_8 number;
    i_alerta_4 number;
    i_alerta_5 number;
    i_alerta_6 number;

    i_id_calendario number;
begin

  PRIMER_SEC:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'S');
  PRIMER_RELOJ:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'R');
  PRIMER_AUSENCIA:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'A');
  PRIMER_TIPOTRANS:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'T');
  PRIMER_PERIODO:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'P');
  PRIMER_FECHA_FICHAJE:= to_date(devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'F'),'dd/mm/yyyy hh24:mi');
    Poriginal_FECHA_FICHAJE:=PRIMER_FECHA_FICHAJE;
  segundo_SEC:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'S');
  segundo_RELOJ:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'R');
  segundo_AUSENCIA:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'A');
  segundo_TIPOTRANS:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'T');
  segundo_PERIODO:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'P');
  segundo_FECHA_FICHAJE:= to_date(devuelve_valor_campo(V_ID_segundo_FICHAJE ,'F'),'dd/mm/yyyy hh24:mi');
   Soriginal_FECHA_FICHAJE:=segundo_FECHA_FICHAJE;
   I_SIN_CALENDARIO :=1;


     --Si da 1 se ejecuta desde la web
                --si da 2 se ejecuta desde pl/sql
                select tO_char(to_date('07/01/2019','dd/mm/yyyy'), 'D') into  dia_semana  from dual;

                If dia_semana = 1 THEN
                  dia_semana:=1;
                ELSE
                  dia_semana:=0;
                End if;



  --lee la jornada para ese día
  --buscamos periodo del fichaje
      BEGIN
      select distinct to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p1_fle_desde,'hh24:mi') ,'dd/mm/yyyy hh24:mi')  as p1d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p1_fle_hasta,'hh24:mi'), 'dd/mm/yyyy hh24:mi')  as p1h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p2_fle_desde, 'hh24:mi'),'dd/mm/yyyy hh24:mi')  as p2d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p2_fle_hasta, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as p2h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p3_fle_desde, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as p3d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p3_fle_hasta, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as p3h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p1_obl_desde, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po1d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p1_obl_hasta, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po1h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p2_obl_desde, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po2d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p2_obl_hasta, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po2h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p3_obl_desde, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po3d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(p3_obl_hasta, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po3h,
              to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || '12:00','dd/mm/yyyy hh24:mi') as doce,
                 DECODE(CONTAR_COMIDA,'SI',1,0)
                          ,DECODE(LIBRE,'SI',1,0),DECODE(TURNO,'SI',1,0),t.id_calendario
            into  i_p1d,i_p1h,
                  i_p2d,i_p2h,
                  i_p3d,i_p3h ,
                  i_po1d,i_po1h,
                  i_po2d,i_po2h,
                  i_po3d,i_po3h  ,i_doce,
                   i_contar_comida,i_libre,i_turnos  , i_id_calendario
        from FICHAJE_CALENDARIO_JORNADA t, fichaje_funcionario_jornada ff,  fichaje_calendario fc
        where t.id_calendario=ff.id_calendario and
               t.id_calendario=fc.id_calendario and
           id_funcionario=V_id_funcionario and
           dia=DECODE(to_number(to_char(PRIMER_FECHA_FICHAJE,'d'))+dia_semana,1,8, to_char(PRIMER_FECHA_FICHAJE,'d')+dia_semana)
            and  to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy') between ff.fecha_inicio  and nvl(ff.fecha_fin,sysdate+1)
            and  to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy') between t.fecha_inicio   and nvl(t.fecha_fin,sysdate+1)
            and rownum<2;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           I_SIN_CALENDARIO :=0;
       END;



       i_fichajes_dia :=1;
       --FICHAJES DIA --añadido chm 03/05/2018
       BEGIN
         Select Count(*) into i_fichajes_dia
         from  fichaje_funcionario ff
            where    to_date(to_char(FECHA_FICHAJE_ENTRADA,'dd/mm/yyyy'),'dd/mm/yyyy') =to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy')
                  and  id_funcionario=V_id_funcionario and computadas=0;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           i_fichajes_dia   :=0;
       END;

         i_fichajes_dia:=i_fichajes_dia+1;

      --chm 25/02/2019
      -- bibliotecas
      IF   PRIMER_PERIODO  = 'P1' and SEGUNDO_PERIODO='P2' and i_id_calendario =10 THEN
         IF PRIMER_FECHA_FICHAJE < i_doce THEN
            SEGUNDO_PERIODO:='P1';--cambiamos al periodo 2
         ELSE
             PRIMER_PERIODO:='P2' ;
         END IF;
      END IF;

      IF   PRIMER_PERIODO  = 'P1' and SEGUNDO_PERIODO='P2'  THEN
        IF  PRIMER_FECHA_FICHAJE > i_p1h and SEGUNDO_FECHA_FICHAJE> i_p1h THEN
             PRIMER_PERIODO := 'P2';--cambiamos al periodo 2
        END IF;
      END IF;

      IF   PRIMER_PERIODO  = 'P1' THEN
        IF  PRIMER_FECHA_FICHAJE < i_p1d THEN
             PRIMER_FECHA_FICHAJE:=i_p1d;
        END IF;

      END IF;

      IF   PRIMER_PERIODO  = 'P1'   THEN
        IF   SEGUNDO_FECHA_FICHAJE> i_p1h THEN
             SEGUNDO_FECHA_FICHAJE:=i_p1h;
        END IF;
      END IF;


      IF   PRIMER_PERIODO  = 'P2' and SEGUNDO_PERIODO='P2'  THEN
        IF  PRIMER_FECHA_FICHAJE < i_p2d THEN
             PRIMER_FECHA_FICHAJE:=i_p2d;
        END IF;

        IF  SEGUNDO_FECHA_FICHAJE > i_p2h THEN
              SEGUNDO_FECHA_FICHAJE:=i_p2h;
        END IF;

      END IF;

      --PERIODO TURNO 3 FALTABA
      --CHM 27/01/2019
      IF   PRIMER_PERIODO  = 'P3' and SEGUNDO_PERIODO='P3'  THEN
        IF  PRIMER_FECHA_FICHAJE < i_p3d THEN
             PRIMER_FECHA_FICHAJE:=i_p3d;
        END IF;

        IF  SEGUNDO_FECHA_FICHAJE > i_p3h THEN
              SEGUNDO_FECHA_FICHAJE:=i_p3h;
         END IF;
        END IF;


      i_horas_saldo:=(SEGUNDO_FECHA_FICHAJE-PRIMER_FECHA_FICHAJE)*24*60;
      i_horas_fichadas:=(Soriginal_FECHA_FICHAJE- Poriginal_FECHA_FICHAJE)*24*60;

       --SALDO CUENTA TODO CON LACOMIDA O LIBRE O 0.
      IF  i_horas_saldo< 0 OR  i_contar_comida = 1 OR i_libre= 1   then
        i_horas_saldo:=i_horas_fichadas;

      END IF;

      IF  v_id_tipo_funcionario = 21 THEN
         i_turno:=substr(PRIMER_PERIODO,2,1);
      ELSE
        i_turno:=0;
      END IF;

      --INCIDENCIAS------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------

      --comprobacion alerta esta activa
                      BEGIN
                            select alerta_8,alerta_4,alerta_5,alerta_6
                            into i_alerta_8, i_alerta_4,  i_alerta_5,  i_alerta_6
                           from fichaje_funcionario_alerta
                           where    id_funcionario=V_id_funcionario;
                      EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                             i_alerta_8:=0;
                             i_alerta_4:=0;
                             i_alerta_5:=0;
                             i_alerta_6:=0;

                       END;


      --- 8  Fichaje Supera 8 horas
        IF  i_horas_fichadas >= 500  and i_alerta_8=1  AND  V_ID_TIPO_FUNCIONARIO<>21 THEN
         V_INCIDENCIA_OBS:='Saldo fichado: '  || i_horas_saldo ;
         BEGIN
           insert into rrhh.fichaje_incidencia
              (id_incidencia, id_tipo_incidencia, nombre_fichero, audit_usuario, audit_fecha, fecha_incidencia, id_funcionario, nombre_ape, id_estado_inc, observaciones)
           values
              ( rrhh.sec_id_incidencia_fihaje.nextval,
                8, '',101217,sysdate, to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy'),V_ID_FUNCIONARIO,  '', 0, V_INCIDENCIA_OBS);
           EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                  i_incidencia := 0;
           END;
      END IF;


       i_incidencia := 0;


      --INCIDENCIA   LIMITES---------------------------------------------------------------------
      --- 4  4  Limite Entrada superado
      ---5  5  Limite Salida no alcanzado
      ---6  6  Limite Ent/Sal Superados.      --30minutos entra
      IF PRIMER_PERIODO='P1' and PRIMER_FECHA_FICHAJE > i_po1d+(1/(24*60))*30  THEN
         i_incidencia := 4;
          V_INCIDENCIA_OBS:='Entrada: ' ||   to_char(PRIMER_FECHA_FICHAJE,'hh24:mi')
                             || '<--> Obligatorio:'  ||   to_char(i_po1d,'hh24:mi');
      END IF;

      IF PRIMER_PERIODO='P1' and SEGUNDO_FECHA_FICHAJE < i_po1h  THEN
         IF i_incidencia = 4  then
            i_incidencia := 6;
             V_INCIDENCIA_OBS:='Entrada/Salida: ' ||   to_char(PRIMER_FECHA_FICHAJE,'hh24:mi')
                             || '/' || to_char(SEGUNDO_FECHA_FICHAJE,'hh24:mi') ||
                               '<--> Obligatorio:'  ||   to_char(i_po1d,'hh24:mi') || '/' || to_char(i_po1h,'hh24:mi');
         ELSE IF to_number(to_char(i_po1h,'hh24mi'))-to_number(to_char(SEGUNDO_FECHA_FICHAJE,'hh24mi'))< 120 THEN --chm 14/05/2018
            i_incidencia := 5;
             V_INCIDENCIA_OBS:='Salida: ' ||   to_char(SEGUNDO_FECHA_FICHAJE,'hh24:mi')
                             || '<--> Obligatorio:'  ||   to_char(i_po1h,'hh24:mi');
              END IF;
         END IF;
      END IF;

      IF  i_incidencia<> 0 and V_ID_TIPO_FUNCIONARIO<>23 and i_turnos=0
          and   to_number(to_char(PRIMER_FECHA_FICHAJE,'d'))+dia_semana<>7 --sabado chm 19/02/2019
        THEN
       IF  (i_alerta_4=1 AND  i_incidencia=4) OR (i_alerta_5=1 AND  i_incidencia=5) or (i_alerta_6=1 AND  i_incidencia=6) THEN
         BEGIN
           insert into rrhh.fichaje_incidencia
              (id_incidencia, id_tipo_incidencia, nombre_fichero, audit_usuario, audit_fecha, fecha_incidencia, id_funcionario, nombre_ape, id_estado_inc, observaciones)
           values
              ( rrhh.sec_id_incidencia_fihaje.nextval,
                i_incidencia, '',101217,sysdate, to_date(to_char(Poriginal_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy'),V_ID_FUNCIONARIO,  '', 0, V_INCIDENCIA_OBS);
           EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                  i_incidencia := 0;
           END;
         END IF;
      END IF;



      BEGIN
        insert into fichaje_funcionario
                 (id_secuencia, id_funcionario, pin, fecha_fichaje_entrada, fecha_fichaje_salida, reloj_entrada, reloj_salida, id_sec_salida, id_sec_entrada, horas_fichadas, horas_saldo, festivo, ausencia, turno, audit_usuario, audit_fecha, horas_jornada, id_calendario
                 ,ID_FICHAJE_DIA
                 )
        values
                 (sec_id_fichaje.nextval, v_id_funcionario, v_pin, Poriginal_FECHA_FICHAJE, Soriginal_FECHA_FICHAJE,PRIMER_RELOJ, SEGUNDO_RELOJ, SEGUNDO_SEC, PRIMER_SEC, i_horas_fichadas,i_horas_saldo, 0, 0,i_turno, 101217,sysdate, '',  i_id_calendario,i_fichajes_dia  );

        EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
           I_SIN_CALENDARIO :=0;
        END;

COMMIT;
msgsalida:=v_cadena_t;
todook:='0';
END  FICHAJE_CALCULA_SALDO_REGE;
/

