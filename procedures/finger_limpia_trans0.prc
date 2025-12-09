CREATE OR REPLACE PROCEDURE RRHH."FINGER_LIMPIA_TRANS0" (i_funcionario  in varchar2,
                                                 v_fecha_p in date) is

   i_id_funcionario number;
   v_pin            varchar2(4);
   i_reloj         varchar2(4);
   i_ausencia       number;
   i_numserie       number;
   i_claveomesa     number;
   d_fecha_fichaje  date;
   d_audit_fecha    date;
   v_audit_usuario  number;
   i_tipotrans      number;
   i_p1d           number;
   i_p1h            number;
   i_p2d            number;
   i_p2h            number;
   i_p3d            number;
   i_p3h            number;
   i_po1d           number;
   i_po1h            number;
   i_po2d            number;
   i_po2h            number;
   i_po3d            number;
   i_po3h            number;
   i_horas_f        number;
   i_horas_f_anterior number;
   i_periodo        varchar2(4);
   i_tipo_funcionario2 number;
   i_encontrado     number;
   I_SIN_CALENDARIO number;
   hinicio          number;
   hfin             number;
   hinicio_com      number;
   hfin_com         number;

   i_contar_comida number;
                                         i_libre number; i_turnos number;


   i_dia               VARCHAR2(12);
   I_ID_SEC_ENTRADA    NUMBER;
   I_ID_SEC            NUMBER;
   I_ID_SEC_ANTERIOR   NUMBER;

   v_fichaje_viejo     VARCHAr2(135);
   v_fichaje_nuevo     VARCHAr2(135);
   v_fecha_viejo         VARCHAr2(135);
   v_fecha_nuevo         VARCHAr2(135);
   d_fecha_viejo       date;
   d_fecha_nuevo       date;
   i_par_fichaje    number;
   i_descarta_fichaje number;
    msgsalida  varchar2(360);
    todook number;

    i_id_func_ant number;

    i_numero_fichaje number;

    i_diferencia_saldo number;
      i_valido_ant number;
       i_cuantos_reloj number;
       i_alerta_7 number;
       i_validos number;

 --Funcionarios en activo
 CURSOR C0 is
       select distinct id_funcionario,

       nvl(tipo_funcionario2,0)

  from personal_new
 where ( fecha_baja is null
    or (fecha_baja > sysdate and
       fecha_baja < to_date('01/01/2050', 'dd/mm/yyyy')))
    and id_funcionario=i_funcionario and rownum<2
        order by 1 desc;



 --FICHAJES
 CURSOR C2 (v_id_funcionario varchar2)is
       select
              id_sec,
              pin,
              TO_DATE(to_char(fecha_fichaje,'dd/mm/yyyy hh24:mi'),'dd/mm/yyyy hh24:mi'),
              reloj,
              ausencia,
              numserie,
              tipotrans,
              periodo,
              to_char(fecha_fichaje,'hh24mi') as horas_f
        from fichaje_funcionario_tran
        where id_funcionario=v_id_funcionario
      and   to_date(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy')=v_fecha_p
      and computadas=0
        order by fecha_fichaje;

Begin

i_id_func_ant:=0;
 --abrimos cursor.
 OPEN C0;
  LOOP
   FETCH C0
    into  i_id_funcionario,   i_tipo_funcionario2;
   EXIT WHEN C0%NOTFOUND;

                i_numero_fichaje:=0;
                v_fichaje_viejo:=null;
                v_fichaje_nuevo:=null;
                v_fecha_viejo:=null;
                v_fecha_nuevo:=null;
                i_par_fichaje:=  0;
                d_fecha_viejo:=null;
                d_fecha_nuevo:=null;
                i_id_sec_anterior:=0;
                       i_validos:=0;

                --FECHA DE CALCULO DE SALDO
                OPEN C2 ( i_id_funcionario);

                LOOP
                FETCH C2
                     INTO I_ID_SEC, V_PIN, d_fecha_fichaje,  i_reloj,   i_ausencia,
                     i_numserie,i_tipotrans,  I_PERIoDO,i_horas_f;
                EXIT WHEN C2%NOTFOUND;




                    finger_busca_jornada_fun(i_id_funcionario,
                                         d_fecha_fichaje,
                                         i_p1d,
                                         i_p1h,
                                         i_p2d,
                                         i_p2h,
                                         i_p3d,
                                         i_p3h,
                                         i_po1d,
                                         i_po1h,
                                         i_po2d,
                                         i_po2h,
                                         i_po3d,
                                         i_po3h,
                                         i_contar_comida,
                                         i_libre,i_turnos,
                                         i_sin_calendario);

                       i_numero_fichaje:=i_numero_fichaje+1;

                        hinicio:=-1;
                        hfin:=-11;
                        --Buscamos ausencias en le dia
                        --descartamos los fichajes que esten entre los dos horas
                        --damos por delante o por detras 30 minutos mas.
                        Begin
                         select to_number(to_char(fecha_inicio-((1*0.5)/24),'hh24mi')) as hinicio ,
                                to_number(to_char(fecha_fin+((1*0.5)/24),'hh24mi')) as hfin
                                into hinicio,hfin
                         from ausencia
                         where to_date(to_char(fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy')=to_date(to_char(d_fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') and
                                JUSTIFICADO='SI' and
                                id_estado=80 and id_funcionario=I_id_funcionario;
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                              hinicio:=-1;
                              hfin:=-11;
                        when too_many_rows THEN
                              hinicio:=800;
                              hfin:=1430;
                        END;

                        --descartamos los fichajes que esten entre los dos horas
                        --compensatorios
                        Begin
                         select to_number(to_char(to_Date('01/01/1900 ' || nvl(hora_inicio,'00:00'),'dd/mm/yyyy hh24:mi'),'hh24mi'))-15 as hinicio ,
                                to_number(to_char(to_Date('01/01/1900 ' || nvl(hora_fin,'00:00'),'dd/mm/yyyy hh24:mi')   ,'hh24mi'))+15 as hfin
                                into hinicio_com,hfin_com
                         from permiso
                         where to_date(to_char(fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy')=to_date(to_char(d_fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') and
                                id_tipo_permiso='15000' and
                                id_estado=80 and id_funcionario=I_id_funcionario;
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                              hinicio_com:=-1;
                              hfin_com:=-11;
                        when too_many_rows THEN
                               hinicio_com:=800;
                                hfin_com:=1430;
                        END;


                        --chm 30/01/2019
                        --VAlido el fichaje anterior, que lo he descartado
                        --Siguiente fichaje pasa al siguiente periodo.

                        IF  i_valido_ant = 1 then

                              IF i_horas_f>= i_p2d THEN
                                   update fichaje_funcionario_tran
                                     set valido=1
                                    where id_sec=i_id_sec_anterior;
                              commit;
                               i_validos:= i_validos +1 ;
                              END IF;

                        END IF;

                        IF i_RELOJ <> 'MA' AND i_RELOJ <> '90' AND i_RELOJ <> '91' THEN

                             IF   i_horas_f > i_po1d and  i_horas_f < i_po1h then
                                         --incidencia
                                         hinicio:=-1;
                             end if;

                        END IF;

                        -- suma fichaje
                        i_par_fichaje:= i_par_fichaje+1;

                        v_fecha_nuevo:=to_char(D_fecha_fichaje ,'dd/mm/yyyy');
                        d_fecha_nuevo:=D_fecha_fichaje;

                        IF V_FECHA_NUEVO <> v_fecha_viejo THEN
                         i_par_fichaje:=  1;
                         i_numero_fichaje:=1;
                        END IF;

                        i_descarta_fichaje:=0;
                        --ausencia
                        --descarto el fichaje
                      IF ((( i_horas_f >= hinicio  and i_horas_f <= hfin and
                           (i_horas_f >= i_po1d  and   i_horas_f <= i_po1h)) OR --compesatori 15000
                             ( i_horas_f >= hinicio_com  and i_horas_f <= hfin_com and
                               (i_horas_f > i_po1d  and   i_horas_f < i_po1h))) and  i_numero_fichaje>1) AND
                               v_fecha_viejo = v_fecha_nuevo

                           THEN
                              update fichaje_funcionario_tran
                              set valido=0
                               where id_sec=i_id_sec;
                              commit;

                              i_valido_ant:=1;
                              i_validos:= i_validos -1;
                      ELSE
                              i_valido_ant:=0;
                              i_validos:= i_validos +1;
                      END IF;


                       --------REVISAR--------
                      --Si la diferencia es mayor 5 minutos se coge el fichaje
                       i_diferencia_saldo:=(d_fecha_nuevo- d_fecha_viejo)*60*24;

                       IF i_diferencia_saldo > 4 and  i_id_func_ant=i_id_funcionario THEN

                                  i_par_fichaje :=0;
                       ELSE IF  i_id_func_ant=i_id_funcionario THEN
                                  i_par_fichaje:=  1;--Descarto ese fichaje
                                    update fichaje_funcionario_tran
                                    set valido=0
                                    where id_sec=i_id_sec;
                            END IF;
                       END IF;



                          v_fichaje_viejo:=v_fichaje_nuevo;
                          v_fecha_viejo:=v_fecha_nuevo;
                          d_fecha_viejo:=d_fecha_nuevo;
                          i_id_func_ant:=i_id_funcionario;
                           i_id_sec_anterior:= i_id_sec;
                           i_horas_f_anterior:=i_horas_f;

                         --COMPROBACION RELOJ

                     IF i_RELOJ <> 'MA' AND i_RELOJ <> '90' AND i_RELOJ <> '91' AND i_RELOJ <> '92' THEN
                       i_cuantos_reloj := 1;
                       Begin
                        select count(*)
                         into i_cuantos_reloj
                         from FICHAJE_FUNCIONARIO_RELOJ
                         where id_funcionario=i_id_funcionario and
                         relojes =i_RELOJ;
                       EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                               i_cuantos_reloj:=0;
                        END;


                        --INCIDENCIAS fichaje distinto reloj 7
                        IF  i_cuantos_reloj= 0 THEN

                                --comprobacion alerta esta activa
                              BEGIN
                                select alerta_7
                                into i_alerta_7
                               from fichaje_funcionario_alerta
                               where    id_funcionario=I_id_funcionario;
                          EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                 i_alerta_7:=0;

                           END;
                          IF i_alerta_7 = 1 then
                             BEGIN
                               insert into rrhh.fichaje_incidencia
                                  (id_incidencia, id_tipo_incidencia, nombre_fichero, audit_usuario, audit_fecha, fecha_incidencia, id_funcionario, nombre_ape, id_estado_inc, observaciones)
                               values
                                  ( rrhh.sec_id_incidencia_fihaje.nextval,
                                  7, '',101217,sysdate, d_fecha_fichaje,i_ID_FUNCIONARIO,  '', 0, 'Sede diferente');
                               EXCEPTION
                                  WHEN DUP_VAL_ON_INDEX THEN
                                      i_cuantos_reloj := 0;
                               END;
                           END IF;
                          END IF;

                      END IF;

                END LOOP;
                CLOSE C2;


         IF  i_valido_ant = 1 and i_validos<2 then
                                   update fichaje_funcionario_tran
                                     set valido=1
                                    where id_sec=i_id_sec_anterior;
                              commit;
                               i_validos:= i_validos +1 ;


                        END IF;


 END LOOP;
 CLOSE C0;



  commit;

end FINGER_LIMPIA_TRANS0;
/

