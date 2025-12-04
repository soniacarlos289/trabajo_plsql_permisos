CREATE OR REPLACE PROCEDURE RRHH."MOV_BOLSA_DESCUENTO_ENFERME"
       (V_ID_ANO in number,
         V_ID_FUNCIONARIO in number, V_ID_TIPO_FUNCIONARIO in number,
         V_FECHA_INICIO in date,
         v_num_dias_tiene_per in number,
        todo_ok_Basico out integer,msgBasico out varchar2) is


v_id_tipo_permiso varchar2(6);
i_horario number;
i_minutos_descuentos number;
v_dni varchar2(10);
i_id_mes number;
i_id_ano number;
i_id_ano2 number;
i_exceso_en_horas  number;
i_excesos_en_minutos  number;
 v_dni2 varchar2(16);
 i_id_funcionario2 varchar2(6);
 i_acumulador number;
 i_hora_excesos number;
 i_horas_minutos number;
 i_saldo_ant number;
 i_Saldo_a_restar number;
 i_queda number;
 i_saldo_ant2 number;
begin

todo_ok_basico:=0;
msgBasico:='';
i_horario:=0;
v_dni:='';
i_exceso_en_horas:=0;
i_excesos_en_minutos:=0;


--Primero buscamos que jornada tiene 40 horas o 37,5
BEGIN
    select count(*)
    into i_horario
    from jornada_funcionario
    where  lpad(id_funcionario,6,'0')=lpad(V_ID_FUNCIONARIO,6,'0');
    EXCEPTION
           WHEN NO_DATA_FOUND THEN
             i_horario:=0;--37,5 horas
END;

IF i_horario =0 THEN
   i_minutos_descuentos:= v_num_dias_tiene_per * 210; --37,5 horas .3:30
ELSE
   i_minutos_descuentos:= v_num_dias_tiene_per * 225; --40 horas 3:45
END IF;
--Añadido por peticion de Fmuniz
--4 horas para bomberos ,policias y aguas
IF  V_ID_TIPO_FUNCIONARIO =21 OR V_ID_TIPO_FUNCIONARIO =23 OR
  V_ID_TIPO_FUNCIONARIO =30 tHEN
     i_minutos_descuentos:= v_num_dias_tiene_per * 240; --4 horas
END IF;


BEGIN
    select distinct periodo,id_ano
    into i_id_mes ,i_id_ano
    from bolsa_periodo
    where  V_FECHA_INICIO between Fecha_inicio and fecha_fin;
    EXCEPTION
           WHEN NO_DATA_FOUND THEN
            i_id_mes:='0';
     END;

if i_id_mes = '0' THEN
   i_id_mes:=13;
   i_id_ano:=2017;
end if;


   -- Insertamos
   i_exceso_en_horas:= trunc(i_minutos_descuentos/60,0)*-1;
   i_excesos_en_minutos:=(i_minutos_descuentos  - trunc(i_minutos_descuentos/60,0)*60)*-1;



   --CONSULTA A LA DEL AÑO ANTERIORES
   --2016
    BEGIN
     select id_funcionario,
          sum(horas_excesos),
          sum(horas_minutos),
          id_ano
          into i_id_funcionario2,i_hora_excesos,i_horas_minutos,i_id_ano2
    from bolsa_saldo
    where lpad(id_funcionario,6,'0')=lpad(V_ID_FUNCIONARIO,6,'0')
          and    id_ano=2017
    group by id_funcionario,desc_motivo_ACUMULAr,id_ano ;
     EXCEPTION
           WHEN NO_DATA_FOUND THEN
            i_hora_excesos:=0;--37,5 horas
            i_horas_minutos:=0;
     END;

   i_saldo_ant:= i_hora_excesos*60+i_horas_minutos;--lo que nos queda bolsa ant.
   --chm
   --17/07/2015
   IF i_saldo_ant <= 0 then
     i_saldo_ant:= 0;
   end if;

   i_Saldo_a_restar:=(i_exceso_en_horas*60+i_excesos_en_minutos)*-1;--lo que vamos a restar

   --CHM
   --17/07/2015
   IF i_Saldo_a_restar <= i_saldo_ant THEN
      --SE PUEDE QUITAR AÑO 2015 HAY SALDO
       insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                2017,
                13,
                2,--to_number(v_id_tipo_movimiento),
               V_FECHA_INICIO,
                0,--ANULADO
                0,
                                 'Permiso: 11100. 1 movimiento',
                  i_exceso_en_horas,
                  i_excesos_en_minutos,
                 '101115',
                sysdate,
                sec_id_bolsa_mov.nextval
             );
             commit;
   ELSE -- NO HAY SALDO SUFICIENTE 2017
     --BUSCAMOS SALDO 2018
     BEGIN
     select id_funcionario,
          sum(horas_excesos),
          sum(horas_minutos),
          id_ano
          into i_id_funcionario2,i_hora_excesos,i_horas_minutos,i_id_ano2
    from bolsa_saldo
    where lpad(id_funcionario,6,'0')=lpad(V_ID_FUNCIONARIO,6,'0') and
        id_ano=2018 --Busqueda bolsa Actual
    group by id_funcionario,desc_motivo_ACUMULAr,id_ano ;
     EXCEPTION
           WHEN NO_DATA_FOUND THEN
            i_hora_excesos:=0;--37,5 horas
            i_horas_minutos:=0;
     END;

        i_saldo_ant2:= i_hora_excesos*60+i_horas_minutos;--lo que nos queda bolsa ACTUAL
        --chm
         --17/07/2015
        IF i_saldo_ant2 <= 0 then
           i_saldo_ant2:= 0;
         end if;


       IF   i_Saldo_a_restar <= i_saldo_ant + i_saldo_ant2 THEN
            ----SE PUEDE QUITAR AÑO 2015 y 2016 HAY SALDO
            --2 movimientos.
             i_exceso_en_horas:= trunc(i_saldo_ant/60,0)*-1;
              i_excesos_en_minutos:=(i_saldo_ant  - trunc(i_saldo_ant/60,0)*60)*-1;

              /*Bolsa 2016 saldo anterior*/
               insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                2017, ---AÑO PASADO
                13,
                2,
              V_FECHA_INICIO,
                0,--ANULADO
                0,
                  'Permiso: 11100. 2 movimientos,completado con bolsa del 2017',
                  i_exceso_en_horas,
                  i_excesos_en_minutos,
                '101115',
                sysdate,
                sec_id_bolsa_mov.nextval);

              --Completamos AÑO 2017
              i_queda:=i_saldo_ant-i_Saldo_a_restar;
              i_exceso_en_horas:= trunc(i_queda/60,0);
              i_excesos_en_minutos:=(i_queda  - trunc(i_queda/60,0)*60);

              insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                2018,
                13,
                2,
              V_FECHA_INICIO,
                0,--ANULADO
                0,
               'Permiso: 11100. 2 movimientos,completado con bolsa del 2018',
                 i_exceso_en_horas,
                  i_excesos_en_minutos,
                 '101115',
                sysdate,
                sec_id_bolsa_mov.nextval);

       ELSE
         todo_ok_basico:=1;
         msgBasico:='No hay horas para hacer el descuento por enfermedad.';

        ----NO QUEDA SALDO HAY QUE COMPLETAR CON LA DE ESTE AÑO 2015
            --3 movimientos.
       /*       i_exceso_en_horas:= trunc(i_saldo_ant/60,0)*-1;
              i_excesos_en_minutos:=(i_saldo_ant  - trunc(i_saldo_ant/60,0)*60)*-1;

               insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                2013, ---AÑO PASADO
                13,
                2,
              to_date(V_FECHA_INICIO,'dd/mm/yyyy'),
                0,--ANULADO
                0,
                  'Permiso: 11100. 3 movimientos,completado con bolsa del 2014 y 2015',
                  i_exceso_en_horas,
                  i_excesos_en_minutos,
                '101115',
                sysdate,
                sec_id_bolsa_mov.nextval);

              --Completamos AÑO 2014
              i_queda:=i_saldo_ant2*-1;
              i_exceso_en_horas:= trunc(i_queda/60,0);
              i_excesos_en_minutos:=(i_queda  - trunc(i_queda/60,0)*60);

              insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                2014,
                13,
                2,
              to_date(V_FECHA_INICIO,'dd/mm/yyyy'),
                0,--ANULADO
                0,
               'Permiso: 11100. 3 movimientos,completado con bolsa del 2013 y 2015',
                 i_exceso_en_horas,
                  i_excesos_en_minutos,
                 '101115',
                sysdate,
                sec_id_bolsa_mov.nextval);

            --Completamos AÑO 2015
              i_queda:=(i_saldo_ant2+i_saldo_ant)-i_Saldo_a_restar;
              i_exceso_en_horas:= trunc(i_queda/60,0);
              i_excesos_en_minutos:=(i_queda  - trunc(i_queda/60,0)*60);

              insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                2015,
                13,
                2,
              to_date(V_FECHA_INICIO,'dd/mm/yyyy'),
                0,--ANULADO
                0,
               'Permiso: 11100.3 movimientos,completado con bolsa del 2013 y 2014',
                 i_exceso_en_horas,
                  i_excesos_en_minutos,
                 '101115',
                sysdate,
                sec_id_bolsa_mov.nextval);*/


       END IF;

   END IF;


             commit;







end MOV_BOLSA_DESCUENTO_ENFERME;
/

