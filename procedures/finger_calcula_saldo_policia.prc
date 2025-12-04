CREATE OR REPLACE PROCEDURE RRHH."FINGER_CALCULA_SALDO_POLICIA" (i_funcionario   in varchar2,
                                                 v_fecha_p in date) is

   i_id_funcionario number;
   v_pin            varchar2(4);
   v_pin2            varchar2(4);
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
   i_periodo        varchar2(4);
   i_tipo_funcionario2 number;
   i_encontrado     number;
   I_SIN_CALENDARIO number;
   hinicio          number;
   hfin             number;
   hinicio_com      number;
   hfin_com         number;

   i_dia               VARCHAR2(12);
   I_ID_SEC_ENTRADA    NUMBER;
   I_ID_SEC            NUMBER;

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

    i_numero_fichaje number;

    i_diferencia_saldo number;
    i_fichajes_P1 number;
    i_fichajes_P2 number;
    i_fichajes_P3 number;

    i_fichaje_p1_cuantos numbeR;
    i_fichaje_p2_cuantos numbeR;
    i_fichaje_p3_cuantos numbeR;

    i_contar_comida    number;
    i_libre     number;
    i_turnos number;
    i_hora number;
    fecha_p date;
     i_cuantos_reloj number;
 --Funcionarios en activo
 CURSOR C0 is
       select id_funcionario,

       nvl(tipo_funcionario2,0)

  from personal_new
 where ( fecha_baja is null
    or (fecha_baja > sysdate and
       fecha_baja < to_date('01/01/2050', 'dd/mm/yyyy')))
       and (id_funcionario=i_funcionario OR 0=i_funcionario)
       and tipo_funcionario2=21
        order by 1 desc;



 --FICHAJES
 CURSOR C2 (v_id_funcionario varchar2,f_fecha_pc2 date)is
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
        where id_funcionario=v_id_funcionario  and valido=1
       and   to_DAte(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy')
          between f_fecha_pc2-1 and f_fecha_pc2+1
        order by fecha_fichaje;

Begin
/*
   IF v_fecha_p ='0' THEN --AYER

          select   to_char(sysdate,'HH24') into i_hora from dual ;
          if i_hora < 13 then
             fecha_p:= to_Date(to_char(sysdate-1,'dd/mm/yyyy'),'dd/mm/yyyy');
          else
             fecha_p:= to_Date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy');
          end if;
   ELSE
          fecha_p:= to_Date(v_fecha_p,'dd/mm/yyyy');
   END IF;

 */
   fecha_p:=v_fecha_p;


 --abrimos cursor.
 OPEN C0;
  LOOP
   FETCH C0
    into  i_id_funcionario,   i_tipo_funcionario2;
   EXIT WHEN C0%NOTFOUND;

          begin
          select nvl(lpad(pin,4,'0'),0),nvl(lpad(pin2,4,'0'),0) into v_pin,v_pin2 from funcionario_fichaje
          where id_funcionario= i_id_funcionario;
          EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                             v_pin :=-1;
                             v_pin2 :=-1;
         END;

         finger_lee_trans(v_pin,fecha_p);
          
         if  v_pin2 > 0 then
               finger_lee_trans(v_pin2,fecha_p);
         end if;

         delete fichaje_funcionario
         where  id_funcionario= i_id_funcionario and
                to_DAte(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')= fecha_p;




                i_numero_fichaje:=0;
                i_par_fichaje:=  0;

                v_fichaje_viejo:=null;
                v_fichaje_nuevo:=null;
                v_fecha_viejo:=null;
                v_fecha_nuevo:=null;
                i_par_fichaje:=  0;
                d_fecha_viejo:=null;
                d_fecha_nuevo:=null;

                i_fichaje_p1_cuantos:=0;
                i_fichaje_p2_cuantos:=0;
                i_fichaje_p3_cuantos:=0;

                i_contar_comida:=0;
                i_libre:=0;



                --FECHA DE CALCULO DE SALDO
                OPEN C2 ( i_id_funcionario, fecha_p);

                LOOP
                FETCH C2
                     INTO I_ID_SEC, V_PIN, d_fecha_fichaje,  i_reloj,   i_ausencia,
                     i_numserie,i_tipotrans,  I_PERIoDO,i_horas_f;
                EXIT WHEN C2%NOTFOUND;

                 i_numero_fichaje:=i_numero_fichaje+1;
                 I_SIN_CALENDARIO :=1;

                 --buscamos periodo del fichaje
                    finger_busca_jornada_fun(i_id_funcionario,
                                         fecha_p,
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
                                         /*

                 BEGIN
                   select to_char(p1_fle_desde,'hh24mi') as p1d,
                          to_char(p1_fle_hasta,'hh24mi') as p1h,
                          to_char(p2_fle_desde,'hh24mi') as p2d,
                          to_char(p2_fle_hasta,'hh24mi') as p2h,
                          to_char(p3_fle_desde,'hh24mi') as p3d,
                          to_char(p3_fle_hasta,'hh24mi') as p3h,
                          to_char(p1_obl_desde,'hh24mi') as po1d,
                          to_char(p1_obl_hasta,'hh24mi') as po1h,
                          to_char(p2_obl_desde,'hh24mi') as po2d,
                          to_char(p2_obl_hasta,'hh24mi') as po2h,
                          to_char(p3_obl_desde,'hh24mi') as po3d,
                          to_char(p3_obl_hasta,'hh24mi') as po3h
                          , DECODE(CONTAR_COMIDA,'SI',1,0)
                          ,DECODE(LIBRE,'SI',1,0)
                    into  i_p1d,i_p1h,
                          i_p2d,i_p2h,
                          i_p3d,i_p3h ,
                          i_po1d,i_po1h,
                          i_po2d,i_po2h,
                          i_po3d,i_po3h ,
                          i_contar_comida,i_libre
                   from FICHAJE_CALENDARIO_JORNADA t, fichaje_funcionario_jornada ff
                   where t.id_calendario=ff.id_calendario and
                         id_funcionario=I_id_funcionario and
                         dia=DECODE(to_char(D_fecha_fichaje,'d'),1,8, to_char(D_fecha_fichaje,'d')) AND
                         to_date('01/01/2018','DD/mm/YYYY') between ff.fecha_inicio  and
                                                              nvl(ff.fecha_fin,sysdate+1) AND
                          to_date('01/01/2018','DD/mm/YYYY') between t.fecha_inicio  and
                                                                nvl(t.fecha_fin,sysdate+1);
                 EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                      I_SIN_CALENDARIO :=0;
                 END;    */

                IF  I_SIN_CALENDARIO <> 0 THEN



                        hinicio:=-1;
                        hfin:=-11;
                        --Buscamos ausencias en le dia
                        --descartamos los fichajes que esten entre los dos horas
                        Begin
                         select to_number(to_char(fecha_inicio,'hh24mi'))-30 as hinicio ,
                                to_number(to_char(fecha_fin,'hh24mi'))+30 as hfin
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

                        --contamos los fichajes de cada periodo
                        Begin
                             select  count(*)
                                      into i_fichajes_P1
                             from fichaje_funcionario_tran
                             where id_funcionario=I_id_funcionario  and valido=1 and
                                   to_DAte(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') =to_date(to_char(d_fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') and
                                   periodo='P1';
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                                   i_fichajes_P1:=-1;
                        END;


                        Begin
                             select  count(*)
                                      into i_fichajes_P2
                             from fichaje_funcionario_tran
                             where id_funcionario=I_id_funcionario  and valido=1 and
                                   to_DAte(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') =to_date(to_char(d_fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') and
                                   periodo='P2';
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                                   i_fichajes_P2:=-1;
                        END;

                        Begin
                             select  count(*)
                                      into i_fichajes_P3
                             from fichaje_funcionario_tran
                             where id_funcionario=I_id_funcionario  and valido=1 and
                                   to_DAte(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') =to_date(to_char(d_fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') and
                                   periodo='P3';
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                                   i_fichajes_P3:=-1;
                        END;



                        if  i_fichajes_P1=0 then
                             i_fichajes_P1:=-1;
                        end if;

                        if  i_fichajes_P2=0 then
                             i_fichajes_P2:=-1;
                        end if;

                        if  i_fichajes_P3=0 then
                             i_fichajes_P3:=-1;
                        end if;

                        IF  i_tipo_funcionario2 = 21  THEN
                               i_periodo := 'P' ||turno_policia(i_numserie, V_pin);
                        END IF;

                        -- suma fichaje
                      i_par_fichaje:= i_par_fichaje+1;
                      v_fichaje_nuevo:= i_par_fichaje ||     ';S' || i_id_sec ||
                                                             ';R' || I_reloj ||
                                                             ';A' || I_Ausencia ||
                                                             ';T' || i_tipotrans ||
                                                             ';P' || i_periodo ||
                                                             ';F' ||  to_char(D_fecha_fichaje ,'dd/mm/yyyy hh24:mi') ||';';

                      v_fecha_nuevo:=to_char(D_fecha_fichaje ,'dd/mm/yyyy');
                       d_fecha_nuevo:=D_fecha_fichaje;

                      --NO SEA POLICIA PUEDE SER OTRO DÍA
                      IF V_FECHA_NUEVO <> v_fecha_viejo AND  i_tipo_funcionario2 <> 21   THEN
                         i_par_fichaje:=  1;
                         i_numero_fichaje:=1;
                         i_fichaje_p1_cuantos:=0;
                         i_fichaje_p2_cuantos:=0;
                         i_fichaje_p3_cuantos:=0;
                      END IF;

                      --cuantos fichajes llevamos por periodo
                        IF I_PERIoDO ='P1' THEN
                              i_fichaje_p1_cuantos:=i_fichaje_p1_cuantos+1;
                        ELSE  IF I_PERIoDO ='P2' THEN
                                  i_fichaje_p2_cuantos:=i_fichaje_p2_cuantos+1;
                              ELSE  IF I_PERIoDO ='P3' THEN
                                        i_fichaje_p3_cuantos:=i_fichaje_p3_cuantos+1;
                                    END IF;
                              END IF;
                        END IF;

                      i_descarta_fichaje:=0;
                      --ausencia
                      --descarto el fichaje
                      IF (
                             ( i_horas_f >= hinicio  and i_horas_f <= hfin and
                               i_horas_f >= i_po1d  and   i_horas_f <= i_po1h ) OR --compesatori 15000
                             ( i_horas_f >= hinicio_com  and i_horas_f <= hfin_com and
                               i_horas_f > i_po1d  and   i_horas_f < i_po1h   ) OR

                             ( i_horas_f >= hinicio  and i_horas_f <= hfin and
                               i_horas_f >= i_po2d  and   i_horas_f <= i_po2h ) OR
                             ( i_horas_f >= hinicio_com  and i_horas_f <= hfin_com and
                               i_horas_f > i_po2d  and   i_horas_f < i_po2h) OR

                             ( i_horas_f >= hinicio  and i_horas_f <= hfin and
                               i_horas_f >= i_po3d  and   i_horas_f <= i_po3h) OR
                             ( i_horas_f >= hinicio_com  and i_horas_f <= hfin_com and
                               i_horas_f > i_po3d  and   i_horas_f < i_po3h)

                               ) and
                               ( i_numero_fichaje>1

                                          )


                           THEN
                          IF  i_par_fichaje = 2 then
                             IF  i_fichajes_P1=2 AND I_PERIoDO='P1' THEN
                                  i_descarta_fichaje:=0;--No lo descarto solo dos fichajes
                             ELSE   IF  i_fichajes_P2=2 AND I_PERIoDO='P2' THEN
                                            i_descarta_fichaje:=0;--No lo descarto solo dos fichajes
                                    ELSE   IF  i_fichajes_P3=2 AND I_PERIoDO='P3' THEN
                                                i_descarta_fichaje:=0;--No lo descarto solo dos fichajes
                                           ELSE
                                                i_par_fichaje:=  1;--Descarto ese fichaje
                                                i_descarta_fichaje:=1;
                                           END IF;
                                    END IF;
                             END IF;

                          ELSE
                              i_par_fichaje:= 0;
                              i_descarta_fichaje:=1;
                          END IF;

                      END IF;

                     --FICHAJE POESTERIOR AL OBLIGATORIO CON AUSENCIA
                    if (i_horas_f > i_po1h OR i_horas_f <= i_po1d ) and  I_PERIoDO='P1'
                              AND  i_fichajes_P1<> i_fichaje_p1_cuantos
                              AND (hinicio_com<>-1 or hinicio<>-1) and  i_numero_fichaje>1
                               and i_descarta_fichaje=0
                              THEN
                          i_descarta_fichaje:=1;
                         IF  i_par_fichaje = 2 then
                             i_par_fichaje:=1;
                         else
                             i_par_fichaje:=0;
                         end if;
                      end if;

                      --Si la diferencia es mayor 5 minutos se coge el fichaje
                      i_diferencia_saldo:=(d_fecha_nuevo- d_fecha_viejo)*60*24;
                      --policias
                      IF  i_tipo_funcionario2 = 21 and i_diferencia_saldo > 690 THEN


                           --turno de policia
                           i_periodo := 'P' || turno_policia(i_numserie, V_pin) ;


                        --INCIDENCIAS fichaje TURNO POLICIA NO ESTABLECIDO
                         IF  i_periodo= 'P0' THEN
                         BEGIN
                           insert into rrhh.fichaje_incidencia
                              (id_incidencia, id_tipo_incidencia, nombre_fichero, audit_usuario, audit_fecha, fecha_incidencia, id_funcionario, nombre_ape, id_estado_inc, observaciones)
                           values
                              ( rrhh.sec_id_incidencia_fihaje.nextval,
                              3, '',101217,sysdate, d_fecha_fichaje,i_ID_FUNCIONARIO,  '', 0, 'Turno no establecido');
                           EXCEPTION
                              WHEN DUP_VAL_ON_INDEX THEN
                                  i_cuantos_reloj := 0;
                           END;
                          END IF;



                          -- IF i_periodo= 'P0' THEN
                             --descartamos el fichaje pero el primero,no el utlimo
                             v_fichaje_viejo:=v_fichaje_nuevo;
                             v_fecha_viejo:=v_fecha_nuevo;
                             d_fecha_viejo:=d_fecha_nuevo;
                           --END IF;

                           IF  i_par_fichaje = 2 then
                             i_par_fichaje:=1;
                            else
                             i_par_fichaje:=0;
                           end if;
                      END IF;

                      IF i_par_fichaje = 2   THEN

                          --Si la diferencia es mayor 5 minutos se coge el fichaje
                          i_diferencia_saldo:=(d_fecha_nuevo- d_fecha_viejo)*60*24;


                          IF i_diferencia_saldo > 4 THEN

                                 fichaje_calcula_saldo_rege(v_fichaje_viejo ,
                                                    v_fichaje_nuevo ,
                                                     i_id_funcionario , i_tipo_funcionario2 ,
                                                     v_pin ,
                                                     msgsalida ,
                                                     todook );

                                  i_par_fichaje :=0;
                           ELSE
                                  i_par_fichaje:=  1;--Descarto ese fichaje
                                  i_descarta_fichaje:=1;
                           END IF;
                      ELSE
                           i_diferencia_saldo:=(d_fecha_nuevo- d_fecha_viejo)*60*24;

                           IF i_diferencia_saldo < 5 THEN
                                i_par_fichaje :=1;
                                i_descarta_fichaje:=1;
                           END IF;

                      END IF;

                      IF i_descarta_fichaje = 0 then
                          v_fichaje_viejo:=v_fichaje_nuevo;
                          v_fecha_viejo:=v_fecha_nuevo;
                          d_fecha_viejo:=d_fecha_nuevo;
                      end if;


               END IF;  --CALENDARIO

                END LOOP;
                CLOSE C2;

                     --CALCULAMOS SALDO DIARIO RESUMES
                delete fichaje_funcionario_resu_dia where id_funcionario=i_id_funcionario and id_dia=fecha_p;
                finger_calcula_saldo_resumen(i_id_funcionario, fecha_p);


 END LOOP;
 CLOSE C0;



  commit;

end FINGER_CALCULA_SALDO_POLICIA;
/

