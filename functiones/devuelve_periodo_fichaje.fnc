create or replace function rrhh.DEVUELVE_PERIODO_FICHAJE(I_ID_FUNCIONARIO IN VARCHAR2,V_PIN in varchar2, d_fecha_fichaje in date,i_horas_f in number)
return varchar2 is  Result varchar2(122);

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

   i_periodo        varchar2(4);


   I_SIN_CALENDARIO number;


   i_contar_comida number;
     i_libre number;
     i_turnos number;
     i_cuantos_mayor number;
     i_cuantos_menor number;
begin

I_SIN_CALENDARIO :=1;

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



    IF  I_SIN_CALENDARIO <> 0 THEN

        IF  i_horas_f < i_p1d then
          i_periodo:='P1';
        END IF;

        IF i_p1d <= i_horas_f and i_horas_f  <=i_p1h then
             i_periodo:='P1';
        END IF;

        IF  i_horas_f >= i_p1h and i_p2h is null  then
          i_periodo:='P1';
        ELSE IF   i_horas_f  >i_p1h and i_p2d> i_horas_f then
                         --Puede ser p1 o p2
                         --FICHAJES MAYORES
                         BEGIN
                          select count(*)
                                 into i_cuantos_mayor
                          from transacciones
                          where

                                    ((tipotrans = '2') OR (numserie = 0) or
                                      (dedo='17' and tipotrans='3') OR
                                     (tipotrans = '2') OR
                                     (dedo='49' and tipotrans='3') OR
                                     (tipotrans in (55,39,40))) and
                                      lpad(pin,4,'0')=lpad(V_PIN,4,'0') and length(pin)<= 4
                                     AND FECHA=TO_dATE(TO_CHAR(d_fecha_fichaje,'DD/MM/YYYY'),'DD/MM/YYYY')
                                     and   to_char(hora,'hh24mi') > i_horas_f ;

		                     EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                   i_cuantos_mayor:=0;
                         END;

                         --PERiodo 2
                         IF i_cuantos_mayor = 0 THEN
                              i_periodo:='P1';
                         ELSE  IF i_cuantos_mayor = 1 THEN
                                    i_periodo:='P2';

                                ELSE --tenemos mas de 2 fichajes en periodo 2.
                                    i_periodo:='P1';

                               END IF;


                         END IF;



             END IF;
        END IF;

        IF i_p2d <= i_horas_f and i_horas_f  <= i_p2h then
            IF   i_periodo = 'P1' THEN --chm 25/02/2019 tambien esta en p1
                  BEGIN
                          select count(*)
                                 into i_cuantos_mayor
                          from transacciones
                          where

                                    ((tipotrans = '2') OR (numserie = 0) or
                                      (dedo='17' and tipotrans='3') OR
                                     (tipotrans = '2') OR
                                     (dedo='49' and tipotrans='3') OR
                                     (tipotrans in (55,39,40))) and
                                      lpad(pin,4,'0')=lpad(V_PIN,4,'0') and length(pin)<= 4
                                     AND FECHA=TO_dATE(TO_CHAR(d_fecha_fichaje,'DD/MM/YYYY'),'DD/MM/YYYY')
                                     and   to_char(hora,'hh24mi') > i_horas_f ;

		                     EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                   i_cuantos_mayor:=0;
                         END;

                         --PERiodo 2
                         IF i_cuantos_mayor = 0 THEN
                              i_periodo:='P1';
                         ELSE  IF i_cuantos_mayor = 1 THEN
                                    i_periodo:='P2';

                                ELSE --tenemos mas de 2 fichajes en periodo 2.
                                    i_periodo:='P1';

                               END IF;


                         END IF;

            ELSE
                    i_periodo:='P2';
            END IF;
        END IF;

        IF  i_horas_f >= i_p2h and i_p3h is null  then
          i_periodo:='P2';
        END IF;

        IF i_p3d <= i_horas_f and i_horas_f  <= i_p3h then
                    i_periodo:='P3';
        END IF;

          IF  i_horas_f > i_p3h then
          i_periodo:='P3';
        END IF;
     END IF;
  result:=i_periodo;
  return(Result);
end DEVUELVE_PERIODO_FICHAJE;
/

