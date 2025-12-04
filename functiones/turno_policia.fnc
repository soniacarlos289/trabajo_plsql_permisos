create or replace function rrhh.TURNO_POLICIA(V_claveomesa in varchar2, i_pin varchar2)  return varchar2 is

Result varchar2(512);


i_encontrado number;
i_encontrado_ant number;
i_encontrado_pos number;

d_fecha_fichaje date;
d_fecha_fichaje_ant date;
d_fecha_fichaje_pos date;


i_diferencia_saldo_ant number;
i_diferencia_saldo_pos number;
i_id_funcionario number;
horas_f number;
horas_f_ant number;
horas_f_pos number;
horas_f_pri number;
horas_f_seg number;
 i_fichaje number;
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
   I_SIN_CALENDARIO number;

   v_FICHAJE        varchar2(10);
   v_fichaje_aux   varchar2(10);

   v_turno_a    number;
   v_turno_b    number;


   v_turno_c    number;
   v_turno_d    number;

   p_sector   number;
   s_sector   number;
   t_sector   number;
   i_po3h_aux number;

   horas_f_seg_aux number;

   i_contar_comida  number;
  i_libre number;
  i_turnos  number;
begin

    i_encontrado:=1;

    --Buscamos transaccion
    BEGIN
        select     FECHA_FICHAJE,id_funcionario,to_char(fecha_fichaje,'hh24mi') as horas_f
                   into d_fecha_fichaje,i_id_funcionario,horas_f
        from   fichaje_funcionario_tran
       where   numserie=v_claveomesa and rownum<2 and valido=1
                 and pin= i_pin;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN

                  i_encontrado:=0;
    END;


    IF  i_encontrado = 1 THEN

       i_encontrado_ant:=1;
       ----Buscamos transaccion_anterior
      BEGIN
        select     FECHA_FICHAJE,to_char(fecha_fichaje,'hh24mi') as horas_f
                   into d_fecha_fichaje_ant,horas_f_ant
        from   fichaje_funcionario_tran t ,
        (select max(numserie) as numserie from fichaje_funcionario_tran  where
           numserie<v_claveomesa and pin= i_pin and valido=1) p
       where   t.numserie=p.numserie and rownum<2
                 and pin= i_pin;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN

                i_encontrado_pos:=0;
       END;

        i_encontrado_pos:=1;
       ----Buscamos transaccion_posterior
       BEGIN
        select     FECHA_FICHAJE,to_char(fecha_fichaje,'hh24mi') as horas_f
                   into d_fecha_fichaje_pos,horas_f_pos
        from   fichaje_funcionario_tran t ,
        (select min(numserie) as numserie from fichaje_funcionario_tran  where
           numserie>v_claveomesa and pin= i_pin and valido=1) p
       where   t.numserie=p.numserie and rownum<2
                 and pin= i_pin;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN

                i_encontrado_pos:=0;
       END;

       i_diferencia_saldo_ant:=0;
       i_diferencia_saldo_pos:=0;
       i_fichaje:=1;


       IF  i_encontrado_ant = 1 then
              i_diferencia_saldo_ant:=(d_fecha_fichaje - d_fecha_fichaje_ant)*60*24;
       END IF;

       IF  i_encontrado_pos = 1 then
              i_diferencia_saldo_pos:=(d_fecha_fichaje_pos - d_fecha_fichaje)*60*24;
       END IF;

        IF i_diferencia_saldo_ant =0  THEN
           i_fichaje:=1;
       END IF;

       IF i_diferencia_saldo_pos =0  THEN
           i_fichaje:=2;
       END IF;

       IF i_diferencia_saldo_ant > i_diferencia_saldo_pos  AND
           i_diferencia_saldo_pos > 0 THEN
            --FICHAJE_POSTERIOR--->
             i_fichaje:=1;
           ELSE IF i_diferencia_saldo_ant < i_diferencia_saldo_pos  AND
                      i_diferencia_saldo_ant > 0 then
                       --FICHAJE_ANTERIOR--->
                       i_fichaje:=2;
           END IF;

       END IF;

       -- DESCARTAR_ESTA
       IF i_diferencia_saldo_ant =0 and  i_diferencia_saldo_pos    =0 THEN
           i_fichaje:=0;
           result:=i_fichaje;
           return(Result);
       END IF;


       --buscamos periodo del fichaje

         finger_busca_jornada_fun(i_id_funcionario,
                                         D_fecha_fichaje,
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
            /*     BEGIN
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
                    into  i_p1d,i_p1h,
                          i_p2d,i_p2h,
                          i_p3d,i_p3h ,
                          i_po1d,i_po1h,
                          i_po2d,i_po2h,
                          i_po3d,i_po3h
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
                 END;  */



    IF  i_fichaje=1 THEN --FICHAJE POSTEIOR
        horas_f_pri:=horas_f;
        horas_f_seg:=horas_f_pos;

    ELSE
        horas_f_pri:=horas_f_ant;
        horas_f_seg:=horas_f;

    END IF;

    v_turno_a:=0;

    --comprobamos fichaje
    --si esta fuera de los periodos
    IF horas_f_pri <=  i_po1d and  horas_f_seg >= i_po1h       THEN
          v_turno_a:=1;
          result:=v_turno_a;
          return(Result);
    ELSE  IF horas_f_pri <=  i_po2d and  horas_f_seg  >= i_po2h           THEN
                               v_turno_a:=2;
                               result:=v_turno_a;
                               return(Result);
          ELSE IF horas_f_pri <=  i_po3d and  horas_f_seg  >= i_po3h
            and( abs(horas_f_seg- i_po3h)<300)        THEN      --cambiado 26/05/2018 a 300
                                 v_turno_a:=3;
                                 result:=v_turno_a;
                                return(Result);
               END IF;
          END IF;
    END IF;

    --sigo buscando
        i_po3h_aux:=i_po3h+2000;
        IF horas_f_seg < 1000 THEN
            horas_f_seg_aux:=2000+horas_f_seg;
        END IF;

        IF ( horas_f_pri >=  i_po1d and  horas_f_pri <=    i_po1h  ) and
           ( horas_f_seg >=  i_po1d and  horas_f_seg <=    i_po1h  )    THEN

              v_turno_a:=1;
              result:=v_turno_a;
              return(Result);

         ELSE  IF ( horas_f_pri >=  i_po2d and  horas_f_pri <=    i_po2h  ) and
                  ( horas_f_seg >=  i_po2d and  horas_f_seg <=    i_po2h  )  THEN
                                   v_turno_a:=2;
                                   result:=v_turno_a;
                                   return(Result);
              ELSE IF ( horas_f_pri >=  i_po3d and  horas_f_pri <=   i_po3h  ) and
                       ( horas_f_seg_aux >=  i_po3d and  horas_f_seg_aux <=  i_po3h_aux  )
                                              THEN
                                     v_turno_a:=3;
                                     result:=v_turno_a;
                                     return(Result);
                   END IF;
              END IF;
        END IF;



    --Sigo buscando
    --comprobamos fichaje
    --si esta dentro uno de los dos fichajes y el otro no


      --Primer ficha comprendido en p1
      IF ( horas_f_pri >=  i_po1d and  horas_f_pri <=    i_po1h  )    THEN

           IF    abs(i_po2d -horas_f_pri) > abs(i_po1h-horas_f_seg) then
                  v_turno_a:=1;
                  result:=v_turno_a;
                  return(Result);
           ELSE
                  v_turno_a:=2;
                  result:=v_turno_a;
                  return(Result);
           END IF;

      END IF;

      --Segundo ficha comprendido en p1
      IF ( horas_f_seg >=  i_po1d and  horas_f_seg <=    i_po1h  )    THEN
            IF    abs(i_po3d -horas_f_pri) > abs(i_po1h-horas_f_seg) then
                  v_turno_a:=3;
                  result:=v_turno_a;
                  return(Result);
           ELSE
                  v_turno_a:=1;
                  result:=v_turno_a;
                  return(Result);
           END IF;
      END IF;


       --Primer fichaje comprendido en p2
      IF ( horas_f_pri >=  i_po2d and  horas_f_pri <=    i_po2h  )    THEN

           IF    abs(i_po3d -horas_f_pri) > abs(i_po1h-horas_f_seg) then
                  v_turno_a:=1;
                  result:=v_turno_a;
                  return(Result);
           ELSE
                  v_turno_a:=3;
                  result:=v_turno_a;
                  return(Result);
           END IF;

      END IF;










  END IF;
   result:=0;
       return(Result);

  return(Result);
end TURNO_POLICIA;
/

