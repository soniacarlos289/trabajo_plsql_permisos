CREATE OR REPLACE FUNCTION RRHH.HORAS_MIN_ENTRE_DOS_FECHAS(fecha1 date,fecha2 date,opcion varchar2) RETURN number IS
i_cuenta_h number;
i_cuenta_m number;

v_horas_f1 number;
v_horas_f2 number;

v_minutos_f1 number;
v_minutos_f2 number;

BEGIN
 --mayor f1
 --menor f2



   v_horas_f1:= to_number(to_char(fecha1,'hh24'));
   v_horas_f2:= to_number(to_char(fecha2,'hh24'));

   v_minutos_f1:= to_number(to_char(fecha1,'mi'));
   v_minutos_f2:= to_number(to_char(fecha2,'mi'));

   IF  v_minutos_f2> v_minutos_f1 THEN
     v_horas_f2:=v_horas_f2+1;
     i_cuenta_m:=60-v_minutos_f2+v_minutos_f1;
     i_cuenta_h:=v_horas_f1-v_horas_f2;
   ELSE
     i_cuenta_m:=v_minutos_f1-v_minutos_f2;
     i_cuenta_h:=v_horas_f1-v_horas_f2;
   END IF;

    IF opcion='H' then
      RETURN i_cuenta_h;
    ELSE
       RETURN i_cuenta_m;
    END IF;


END;
/

